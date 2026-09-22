import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/guard_gate_repository.dart';
import 'package:asmita_society/core/config/env_config.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late GuardGateRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = GuardGateRepository(mockDio);
  });

  group('GuardGateRepository', () {
    test('getExpectedInvites returns list of invites on 200', () async {
      when(() => mockDio.get(EnvConfig.gateExpectedInvites)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.gateExpectedInvites),
          statusCode: 200,
          data: {
            'invites': [
              {'id': 1, 'visitor_name': 'Test Invite'}
            ]
          },
        ),
      );

      final invites = await repository.getExpectedInvites();
      expect(invites.length, 1);
      expect(invites.first['visitor_name'], 'Test Invite');
    });

    test('getExpectedInvites throws exception on non-200', () async {
      when(() => mockDio.get(EnvConfig.gateExpectedInvites)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: EnvConfig.gateExpectedInvites),
          response: Response(
            requestOptions: RequestOptions(path: EnvConfig.gateExpectedInvites),
            statusCode: 400,
            data: {'message': 'Bad Request'},
          ),
        ),
      );

      expect(() => repository.getExpectedInvites(), throwsException);
    });

    test('searchInvite returns invite data on success', () async {
      when(() => mockDio.get(EnvConfig.gateSearchInvite, queryParameters: {'code': '123456'})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.gateSearchInvite),
          statusCode: 200,
          data: {
            'success': true,
            'invite': {'id': 2, 'code': '123456'}
          },
        ),
      );

      final invite = await repository.searchInvite('123456');
      expect(invite['id'], 2);
    });

    test('checkInPreApproved completes successfully on 200', () async {
      when(() => mockDio.post(EnvConfig.gateCheckInInvite('123'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.gateCheckInInvite('123')),
          statusCode: 200,
        ),
      );

      await expectLater(repository.checkInPreApproved('123'), completes);
    });

    test('getExpectedInvites returns empty on 200 with missing data', () async {
      when(() => mockDio.get(EnvConfig.gateExpectedInvites)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.gateExpectedInvites),
          statusCode: 200,
          data: {'success': false, 'message': 'No data'},
        ),
      );
      final invites = await repository.getExpectedInvites();
      expect(invites, isEmpty);
    });

    test('getExpectedInvites throws generic exception', () async {
      when(() => mockDio.get(EnvConfig.gateExpectedInvites)).thenThrow(Exception('Generic error'));
      expect(() => repository.getExpectedInvites(), throwsException);
    });

    test('searchInvite throws on non-200', () async {
      when(() => mockDio.get(EnvConfig.gateSearchInvite, queryParameters: {'code': '123456'})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.gateSearchInvite),
          statusCode: 404,
          data: {'message': 'Not found'},
        ),
      );
      expect(() => repository.searchInvite('123456'), throwsException);
    });

    test('searchInvite throws DioException', () async {
      when(() => mockDio.get(EnvConfig.gateSearchInvite, queryParameters: {'code': '123456'})).thenThrow(
        DioException(requestOptions: RequestOptions(path: EnvConfig.gateSearchInvite))
      );
      expect(() => repository.searchInvite('123456'), throwsException);
    });

    test('checkInPreApproved throws on non-200', () async {
      when(() => mockDio.post(EnvConfig.gateCheckInInvite('123'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.gateCheckInInvite('123')),
          statusCode: 400,
          data: {'message': 'Error'},
        ),
      );
      expect(() => repository.checkInPreApproved('123'), throwsException);
    });

    test('checkInPreApproved throws DioException', () async {
      when(() => mockDio.post(EnvConfig.gateCheckInInvite('123'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: EnvConfig.gateCheckInInvite('123')))
      );
      expect(() => repository.checkInPreApproved('123'), throwsException);
    });

    test('submitWalkInVisitor returns entry on 201', () async {
      when(() => mockDio.post(EnvConfig.createVisitorEntry, data: {'name': 'John'})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.createVisitorEntry),
          statusCode: 201,
          data: {'success': true, 'entry': {'id': 1, 'name': 'John'}},
        ),
      );
      final result = await repository.submitWalkInVisitor({'name': 'John'});
      expect(result['id'], 1);
    });

    test('submitWalkInVisitor throws on error', () async {
      when(() => mockDio.post(EnvConfig.createVisitorEntry, data: {'name': 'John'})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.createVisitorEntry),
          statusCode: 400,
          data: {'message': 'Error'},
        ),
      );
      expect(() => repository.submitWalkInVisitor({'name': 'John'}), throwsException);
    });

    test('submitWalkInVisitor throws DioException', () async {
      when(() => mockDio.post(EnvConfig.createVisitorEntry, data: {'name': 'John'})).thenThrow(
        DioException(requestOptions: RequestOptions(path: EnvConfig.createVisitorEntry))
      );
      expect(() => repository.submitWalkInVisitor({'name': 'John'}), throwsException);
    });

    test('getGuardHistory returns list of entries on 200', () async {
      when(() => mockDio.get(EnvConfig.guardVisitorEntries)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.guardVisitorEntries),
          statusCode: 200,
          data: {'entries': [{'id': 1}]},
        ),
      );
      final result = await repository.getGuardHistory();
      expect(result.length, 1);
    });

    test('getGuardHistory throws on non-200', () async {
      when(() => mockDio.get(EnvConfig.guardVisitorEntries)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.guardVisitorEntries),
          statusCode: 400,
          data: {'message': 'Error'},
        ),
      );
      expect(() => repository.getGuardHistory(), throwsException);
    });

    test('getGuardHistory throws DioException', () async {
      when(() => mockDio.get(EnvConfig.guardVisitorEntries)).thenThrow(
        DioException(requestOptions: RequestOptions(path: EnvConfig.guardVisitorEntries))
      );
      expect(() => repository.getGuardHistory(), throwsException);
    });
  });
}
