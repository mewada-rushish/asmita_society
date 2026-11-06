import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:asmita_society/core/services/property_config_service.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/features/visitor_management/data/models/property_config.dart';

class MockDioClient extends Mock implements AsmitaDioClient {}
class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late MockSecureStorage mockSecureStorage;
  late PropertyConfigService service;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    mockSecureStorage = MockSecureStorage();
    when(() => mockDioClient.dio).thenReturn(mockDio);

    service = PropertyConfigService(
      dioClient: mockDioClient,
      secureStorage: mockSecureStorage,
    );
  });

  group('PropertyConfigService Real-Time Cache Invalidation (R5)', () {
    test('loadConfigForSociety caches config and returns cached on second call', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 200,
          data: {
            'society_id': 115,
            'property_type': 'industrial',
            'pass_rules': {'require_host_approval': true},
          },
        ),
      );

      final config1 = await service.loadConfigForSociety(115);
      expect(config1.societyId, 115);
      verify(() => mockDio.get(any(), options: any(named: 'options'))).called(1);

      // Second call returns cached config without hitting network
      final config2 = await service.loadConfigForSociety(115);
      expect(config2.societyId, 115);
      verifyNever(() => mockDio.get(any(), options: any(named: 'options')));
    });

    test('invalidateCache clears _currentConfig and forces a fresh network fetch', () async {
      int callCount = 0;
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async {
          callCount++;
          return Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 200,
            data: {
              'society_id': 115,
              'property_type': 'industrial',
              'pass_rules': {'version': callCount},
            },
          );
        },
      );

      // Initial fetch
      await service.loadConfigForSociety(115);
      expect(service.currentConfig.societyId, 115);
      expect(callCount, 1);

      // Invalidate cache
      bool notified = false;
      service.addListener(() => notified = true);

      final freshConfig = await service.invalidateCache(115);

      expect(notified, true);
      expect(callCount, 2);
      expect(freshConfig?.societyId, 115);
    });

    test('loadConfigForSociety with forceRefresh: true bypasses cache', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 200,
          data: {
            'society_id': 114,
            'property_type': 'industrial',
          },
        ),
      );

      await service.loadConfigForSociety(114);
      expect(service.currentConfig.societyId, 114);
      verify(() => mockDio.get(any(), options: any(named: 'options'))).called(1);

      // Force refresh
      await service.loadConfigForSociety(114, forceRefresh: true);
      verify(() => mockDio.get(any(), options: any(named: 'options'))).called(1);
    });

    test('updateConfig manually updates cache and notifies listeners', () {
      bool notified = false;
      service.addListener(() => notified = true);

      final customConfig = PropertyConfig.defaultResidential(societyId: 999);
      service.updateConfig(customConfig);

      expect(notified, true);
      expect(service.currentConfig.societyId, 999);
    });
  });
}
