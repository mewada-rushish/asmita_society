import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/team_invite_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late TeamInviteRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = TeamInviteRepository(dio: mockDio);
  });

  group('TeamInviteRepository - generateInvite', () {
    test('successfully generates invite with all parameters', () async {
      when(
        () => mockDio.post(
          EnvConfig.generateInvite,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.generateInvite),
          statusCode: 200,
          data: {
            'success': true,
            'rawToken': 'test_token_abc',
            'inviteUrl': 'https://admin.myasmita.com/invite/join/test_token_abc',
            'expiresAt': '2026-11-12T01:41:20.000Z',
            'tokenType': 'ONBOARDING',
            'id': 42,
            'smsSent': true,
          },
        ),
      );

      final result = await repository.generateInvite(
        societyId: 114,
        targetRole: 'Corporate Employee',
        departmentId: 3,
        departmentName: 'Accounts',
        recipientName: 'John Doe',
        recipientPhone: '9876543210',
      );

      expect(result['success'], isTrue);
      expect(result['rawToken'], equals('test_token_abc'));
      expect(result['inviteUrl'], contains('test_token_abc'));
      expect(result['smsSent'], isTrue);

      verify(
        () => mockDio.post(
          EnvConfig.generateInvite,
          data: {
            'token_type': 'ONBOARDING',
            'society_id': 114,
            'target_role': 'Corporate Employee',
            'max_usage': 1,
            'validity_hours': 168,
            'department_id': 3,
            'department_name': 'Accounts',
            'recipient_name': 'John Doe',
            'recipient_phone': '9876543210',
          },
        ),
      ).called(1);
    });

    test('throws Exception when API returns failure message', () async {
      when(
        () => mockDio.post(
          EnvConfig.generateInvite,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.generateInvite),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Society ID is required',
          },
        ),
      );

      expect(
        () => repository.generateInvite(
          societyId: 0,
          targetRole: 'Corporate Employee',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Society ID is required'),
        )),
      );
    });

    test('handles DioException with backend error payload', () async {
      when(
        () => mockDio.post(
          EnvConfig.generateInvite,
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: EnvConfig.generateInvite),
          response: Response(
            requestOptions: RequestOptions(path: EnvConfig.generateInvite),
            statusCode: 403,
            data: {'message': 'Unauthorized to issue invites'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.generateInvite(
          societyId: 114,
          targetRole: 'Corporate Employee',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Unauthorized to issue invites'),
        )),
      );
    });
  });

  group('TeamInviteRepository - getDelegationStatus', () {
    test('returns delegation map on successful status query', () async {
      when(
        () => mockDio.get(
          EnvConfig.employeeDelegationStatus,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.employeeDelegationStatus),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'outgoingDelegation': null,
              'incomingDelegations': [
                {
                  'id': 12,
                  'is_active': true,
                  'delegator': {
                    'full_name': 'Jane Director',
                    'primary_role': 'Director',
                    'role_power': 500,
                  },
                },
              ],
            },
          },
        ),
      );

      final status = await repository.getDelegationStatus(societyId: 114);
      expect(status, isNotNull);
      expect(status!['incomingDelegations'], isNotEmpty);
      expect(status['incomingDelegations'][0]['delegator']['full_name'], equals('Jane Director'));
    });

    test('returns null on DioException without crashing', () async {
      when(
        () => mockDio.get(
          EnvConfig.employeeDelegationStatus,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: EnvConfig.employeeDelegationStatus),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final status = await repository.getDelegationStatus(societyId: 114);
      expect(status, isNull);
    });
  });

  group('TeamInviteRepository - getSocietyDepartments', () {
    test('returns list of departments when available', () async {
      when(
        () => mockDio.get(
          '${EnvConfig.baseUrl}/api/public/visitor/departments',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/public/visitor/departments'),
          statusCode: 200,
          data: {
            'success': true,
            'departments': [
              {'id': 1, 'name': 'Information Technology'},
              {'id': 2, 'name': 'Finance & Accounts'},
            ],
          },
        ),
      );

      final depts = await repository.getSocietyDepartments(114);
      expect(depts.length, equals(2));
      expect(depts[0]['name'], equals('Information Technology'));
    });

    test('returns empty list on failure', () async {
      when(
        () => mockDio.get(
          '${EnvConfig.baseUrl}/api/public/visitor/departments',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/public/visitor/departments'),
          type: DioExceptionType.connectionError,
        ),
      );

      final depts = await repository.getSocietyDepartments(114);
      expect(depts, isEmpty);
    });
  });
}
