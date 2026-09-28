import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/visitor_repository.dart';
import 'package:asmita_society/core/config/env_config.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late VisitorRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = VisitorRepository(dio: mockDio);
  });

  group('VisitorRepository', () {
    test('getMyHistory parses Map gracefully and handles JSON response', () async {
      when(() => mockDio.get(
            EnvConfig.myPreApprovedInvites,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.myPreApprovedInvites),
          statusCode: 200,
          data: {
            'invites': [
              {'id': 1, 'visitor_name': 'Test Invite', 'created_at': '2023-01-01T10:00:00Z'}
            ]
          },
        ),
      );

      when(() => mockDio.get(
            EnvConfig.residentVisitorRequests,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.residentVisitorRequests),
          statusCode: 200,
          data: {
            'requests': [
              {'id': 2, 'visitor_name': 'Test Walkin', 'created_at': '2023-01-01T11:00:00Z'}
            ]
          },
        ),
      );

      final history = await repository.getMyHistory(residentId: 1);
      expect(history.length, 2);
      expect(history.first['record_type'], 'WALK_IN'); // sorted descending by default
      expect(history.last['record_type'], 'PRE_APPROVED');
    });

    test('getMyHistory safely handles HTML non-JSON response on 404', () async {
      when(() => mockDio.get(
            EnvConfig.myPreApprovedInvites,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.myPreApprovedInvites),
          statusCode: 200, // Misconfigured proxy could return 200 with HTML
          data: '<!DOCTYPE html><html>404 Not Found</html>',
        ),
      );

      when(() => mockDio.get(
            EnvConfig.residentVisitorRequests,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.residentVisitorRequests),
          statusCode: 200,
          data: '<!DOCTYPE html><html>404 Not Found</html>',
        ),
      );

      final history = await repository.getMyHistory(residentId: 1);
      expect(history, isEmpty); // Should not crash
    });
    test('createPreApprovedInvite returns PreApprovedInvite on 201', () async {
      when(() => mockDio.post(EnvConfig.preApprovedInvites, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.preApprovedInvites),
          statusCode: 201,
          data: {
            'success': true,
            'invite': {'id': 1, 'visitor_name': 'John Doe'}
          },
        ),
      );
      final invite = await repository.createPreApprovedInvite({'visitor_name': 'John Doe'});
      expect(invite.id, 1);
    });

    test('createPreApprovedInvite throws exception on non-201', () async {
      when(() => mockDio.post(EnvConfig.preApprovedInvites, data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.preApprovedInvites),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Failed'
          },
        ),
      );
      expect(() => repository.createPreApprovedInvite({'visitor_name': 'John Doe'}), throwsException);
    });

    test('createPreApprovedInvite throws DioException', () async {
      when(() => mockDio.post(EnvConfig.preApprovedInvites, data: any(named: 'data'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: EnvConfig.preApprovedInvites))
      );
      expect(() => repository.createPreApprovedInvite({'visitor_name': 'John Doe'}), throwsException);
    });

    test('getMyHistory parses List gracefully', () async {
      when(() => mockDio.get(EnvConfig.myPreApprovedInvites, queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.myPreApprovedInvites),
          statusCode: 200,
          data: [{'id': 1, 'visitor_name': 'Test Invite', 'created_at': '2023-01-01T10:00:00Z'}],
        ),
      );

      when(() => mockDio.get(EnvConfig.residentVisitorRequests, queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.residentVisitorRequests),
          statusCode: 200,
          data: [{'id': 2, 'visitor_name': 'Test Walkin', 'created_at': '2023-01-01T11:00:00Z'}],
        ),
      );

      final history = await repository.getMyHistory(residentId: 1);
      expect(history.length, 2);
    });

    test('getMyHistory passes correct query parameters', () async {
      when(() => mockDio.get(EnvConfig.myPreApprovedInvites, queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.myPreApprovedInvites),
          statusCode: 200,
          data: [],
        ),
      );

      when(() => mockDio.get(EnvConfig.residentVisitorRequests, queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.residentVisitorRequests),
          statusCode: 200,
          data: [],
        ),
      );

      final start = DateTime(2023, 1, 1);
      final end = DateTime(2023, 1, 2);
      await repository.getMyHistory(
        residentId: 1, 
        status: 'PENDING', 
        startDate: start, 
        endDate: end, 
        visitorTypeId: 2
      );

      verify(() => mockDio.get(EnvConfig.myPreApprovedInvites, queryParameters: {
        'user_id': 1,
        'status': 'PENDING',
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'visitor_type_id': 2,
      })).called(1);
    });

    test('getMyHistory throws exception on network error', () async {
      when(() => mockDio.get(EnvConfig.myPreApprovedInvites, queryParameters: any(named: 'queryParameters'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: EnvConfig.myPreApprovedInvites))
      );
      expect(() => repository.getMyHistory(residentId: 1), throwsException);
    });

    test('getMyHistory throws exception on generic error', () async {
      when(() => mockDio.get(EnvConfig.myPreApprovedInvites, queryParameters: any(named: 'queryParameters'))).thenThrow(
        Exception('Generic Error')
      );
      expect(() => repository.getMyHistory(residentId: 1), throwsException);
    });
  });
}
