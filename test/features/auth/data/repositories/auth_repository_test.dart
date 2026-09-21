import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';
import 'package:asmita_society/core/config/env_config.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AuthRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = AuthRepository(dio: mockDio);
  });

  group('AuthRepository', () {
    test('initiateLogin returns true on success', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.loginInitiate),
          statusCode: 200,
          data: {'status': 'success'},
        ),
      );

      final result = await repository.initiateLogin('1234567890');
      expect(result, isTrue);
    });

    test('initiateLogin throws exception on error', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: EnvConfig.loginInitiate),
          response: Response(
            requestOptions: RequestOptions(path: EnvConfig.loginInitiate),
            statusCode: 400,
            data: {'message': 'Invalid number'},
          ),
        ),
      );

      expect(
        () => repository.initiateLogin('123'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Invalid number'))),
      );
    });
  });
}
