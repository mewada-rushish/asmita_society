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
  });
}
