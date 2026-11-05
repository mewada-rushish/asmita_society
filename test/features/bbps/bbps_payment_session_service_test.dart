import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/features/bbps/data/services/bbps_payment_session_service.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  setUp(() {
    BbpsSecureConfig.resetForTesting();
    BbpsPaymentSessionService.clearSessionCache();
  });

  tearDown(() {
    BbpsSecureConfig.resetForTesting();
    BbpsPaymentSessionService.clearSessionCache();
  });

  group('BbpsSecureConfig', () {
    test('parses individual flat keys from raw .env string', () {
      const mockEnv = '''
# Setu BBPS Config
SETU_CLIENT_ID="test_client_999"
SETU_CLIENT_SECRET="test_secret_888"
SETU_PARTNER_ID="partner_777"
SETU_ORG_ID="org_666"
SETU_PRODUCT_INSTANCE_ID="inst_555"
SETU_BASE_URL="https://coudc.setu.co/api/v2"
''';

      BbpsSecureConfig.loadFromString(mockEnv);

      expect(BbpsSecureConfig.hasClientCredentials, isTrue);
      expect(BbpsSecureConfig.clientID, equals('test_client_999'));
      expect(BbpsSecureConfig.secret, equals('test_secret_888'));
      expect(BbpsSecureConfig.partnerId, equals('partner_777'));
      expect(BbpsSecureConfig.orgId, equals('org_666'));
      expect(BbpsSecureConfig.productInstanceId, equals('inst_555'));
      expect(BbpsSecureConfig.baseUrl, equals('https://coudc.setu.co/api/v2'));
    });

    test('parses nested SETU_BBPS_CONFIG JSON block properly', () {
      const mockEnvWithJson = '''
SETU_BBPS_ENV="production"
SETU_BBPS_BASE_URL="https://coudc.setu.co/api/v2"
SETU_BBPS_CONFIG='{
  "org_name": "Asmita Test",
  "client_id": "json_client_111",
  "client_secret": "json_secret_222",
  "partner_id": "json_partner_333",
  "org_id": "json_org_444",
  "product_instance_id": "json_inst_555"
}'
''';

      BbpsSecureConfig.loadFromString(mockEnvWithJson);

      expect(BbpsSecureConfig.hasClientCredentials, isTrue);
      expect(BbpsSecureConfig.clientID, equals('json_client_111'));
      expect(BbpsSecureConfig.secret, equals('json_secret_222'));
      expect(BbpsSecureConfig.partnerId, equals('json_partner_333'));
      expect(BbpsSecureConfig.orgId, equals('json_org_444'));
      expect(BbpsSecureConfig.productInstanceId, equals('json_inst_555'));
    });
  });

  group('BbpsPaymentSessionService Direct Setu Clearance', () {
    late MockDio mockStandaloneDio;
    late MockDio mockBackendDio;
    late MockSecureStorage mockSecureStorage;

    setUp(() {
      mockStandaloneDio = MockDio();
      mockBackendDio = MockDio();
      mockSecureStorage = MockSecureStorage();

      when(() => mockSecureStorage.getUserId()).thenAnswer((_) async => 42);
      when(() => mockSecureStorage.read(key: 'user_profile'))
          .thenAnswer((_) async => '{"mobile_number":"9876543210"}');

      // Inject credentials
      BbpsSecureConfig.loadFromString('''
SETU_CLIENT_ID="mock_cid"
SETU_CLIENT_SECRET="mock_sec"
SETU_PARTNER_ID="mock_pid"
SETU_ORG_ID="mock_oid"
SETU_PRODUCT_INSTANCE_ID="mock_inst_id"
SETU_BASE_URL="https://coudc.setu.co/api/v2"
''');
    });

    test('triggers direct Setu /auth/token and /ethereal/link without backend fallback', () async {
      // 1. Mock /auth/token call
      when(() => mockStandaloneDio.post(
            'https://coudc.setu.co/api/v2/auth/token',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            statusCode: 200,
            data: {
              'token': 'mock_bearer_token_xyz',
              'expiresIn': 300,
            },
            requestOptions: RequestOptions(path: '/auth/token'),
          ));

      // 2. Mock /ethereal/link call
      when(() => mockStandaloneDio.post(
            'https://coudc.setu.co/api/v2/ethereal/link',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            statusCode: 200,
            data: {
              'link': 'https://billpay.setu.co/session/direct-test-12345',
              'sessionId': 'sess_123',
            },
            requestOptions: RequestOptions(path: '/ethereal/link'),
          ));

      final service = BbpsPaymentSessionService(
        dio: mockBackendDio,
        standaloneDio: mockStandaloneDio,
        secureStorage: mockSecureStorage,
      );

      final resultUrl = await service.obtainSessionUrl(
        categoryName: 'Electricity',
        mobileNumber: '9876543210',
      );

      expect(resultUrl, equals('https://billpay.setu.co/session/direct-test-12345'));

      // Verify that backend dio was NEVER called (direct client clearance succeeded)
      verifyNever(() => mockBackendDio.post(any(), data: any(named: 'data'), options: any(named: 'options')));

      // Verify standaloneDio called Setu auth and link endpoints with expected payload
      verify(() => mockStandaloneDio.post(
            'https://coudc.setu.co/api/v2/auth/token',
            data: {'clientID': 'mock_cid', 'secret': 'mock_sec'},
          )).called(1);

      verify(() => mockStandaloneDio.post(
            'https://coudc.setu.co/api/v2/ethereal/link',
            data: any(
              named: 'data',
              that: isA<Map<String, dynamic>>()
                  .having((m) => m['orgId'], 'orgId', 'mock_oid')
                  .having((m) => m['mobileNumber'], 'mobileNumber', '9876543210')
                  .having((m) => m['categoryName'], 'categoryName', 'Electricity'),
            ),
            options: any(
              named: 'options',
              that: isA<Options>().having(
                (o) => o.headers?['X-PARTNER-ID'],
                'X-PARTNER-ID',
                'mock_pid',
              ),
            ),
          )).called(1);
    });
  });
}
