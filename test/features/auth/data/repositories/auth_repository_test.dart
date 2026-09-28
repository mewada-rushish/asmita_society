import 'dart:io';
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
    test('verifyOtp returns AuthResponse on success', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.loginVerify),
          statusCode: 200,
          data: {
            'status': 'success',
            'token': 'abc',
            'user': {'user_id': 1, 'full_name': 'Test User', 'primary_role': 'owner', 'account_type': 'app'}
          },
        ),
      );

      final result = await repository.verifyOtp('1234567890', '123456');
      expect(result.token, 'abc');
      expect(result.data!.fullName, 'Test User');
    });

    test('verifyOtp throws REGISTRATION_REQUIRED when backend returns it', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.loginVerify),
          statusCode: 200,
          data: {'status': 'registration_required'},
        ),
      );

      expect(
        () => repository.verifyOtp('1234567890', '123456'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('REGISTRATION_REQUIRED'))),
      );
    });

    test('checkStatus returns APPROVED', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.loginStatus),
          statusCode: 200,
          data: {'success': true, 'status': 'APPROVED'},
        ),
      );

      final result = await repository.checkStatus('1234567890');
      expect(result, 'APPROVED');
    });

    test('checkStatus throws exception on non-200', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: EnvConfig.loginStatus)),
      );

      expect(
        () => repository.checkStatus('123'),
        throwsA(isA<Exception>()),
      );
    });

    test('verifyOtp handles 401 registration_required correctly', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: EnvConfig.loginVerify),
          response: Response(
            requestOptions: RequestOptions(path: EnvConfig.loginVerify),
            statusCode: 401,
            data: {'status': 'registration_required'},
          ),
        ),
      );

      expect(
        () => repository.verifyOtp('1234567890', '123456'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('REGISTRATION_REQUIRED'))),
      );
    });

    test('registerUser returns AuthResponse on success', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.register),
          statusCode: 200,
          data: {
            'status': 'success',
            'token': 'token123',
            'user': {'user_id': 1, 'full_name': 'New User', 'primary_role': 'tenant', 'account_type': 'app'}
          },
        ),
      );

      final result = await repository.registerUser(
        mobile: '123', fullName: 'New User', email: 'e@mail.com', gender: 'M', 
        society: 'S1', tower: 'T1', floor: 'F1', flat: 'F1', role: 'tenant'
      );
      
      expect(result.token, 'token123');
      expect(result.data!.fullName, 'New User');
    });

    test('updateProfile returns AuthResponse on success', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/users/me/update'),
          statusCode: 200,
          data: {
            'success': true,
            'user': {'user_id': 1, 'full_name': 'Updated User', 'primary_role': 'owner', 'account_type': 'app'}
          },
        ),
      );

      final result = await repository.updateProfile(
        fullName: 'Updated User', email: 'up@example.com', mobile: '123', token: 'token'
      );
      
      expect(result.data!.fullName, 'Updated User');
    });

    test('logout completes gracefully', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.logout),
          statusCode: 200,
        ),
      );

      await expectLater(repository.logout(1, 'role', 'role'), completes);
    });

    test('logout ignores network error', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: EnvConfig.logout))
      );

      // Should not throw
      await expectLater(repository.logout(1, 'role', 'role'), completes);
    });

    test('uploadProfilePicture returns url on success', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/users/upload-profile-picture'),
          statusCode: 200,
          data: {'success': true, 'profile_picture_url': 'http://image.png'},
        ),
      );

      final tempFile = File('${Directory.systemTemp.path}/test_image.png');
      await tempFile.writeAsBytes([0]);
      
      final result = await repository.uploadProfilePicture(tempFile, token: 'token');
      expect(result, 'http://image.png');
    });

    test('initiateLogin returns false on non-success status', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.loginInitiate),
          statusCode: 200,
          data: {'status': 'failed'},
        ),
      );
      final result = await repository.initiateLogin('1234567890');
      expect(result, isFalse);
    });

    test('verifyOtp throws PENDING_APPROVAL when backend returns it', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.loginVerify),
          statusCode: 200,
          data: {'status': 'pending_approval'},
        ),
      );
      expect(() => repository.verifyOtp('1234567890', '123456'), throwsException);
    });

    test('verifyOtp throws generic message on other status', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.loginVerify),
          statusCode: 200,
          data: {'status': 'failed', 'message': 'Custom error'},
        ),
      );
      expect(() => repository.verifyOtp('1234567890', '123456'), throwsException);
    });

    test('checkStatus throws when success is false', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.loginStatus),
          statusCode: 200,
          data: {'success': false},
        ),
      );
      expect(() => repository.checkStatus('1234567890'), throwsException);
    });

    test('registerUser throws PENDING_APPROVAL', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.register),
          statusCode: 200,
          data: {'status': 'pending_approval'},
        ),
      );

      expect(() => repository.registerUser(
        mobile: '1', fullName: '2', email: '3', gender: '4', society: '5', 
        tower: '6', floor: '7', flat: '8', role: '9'
      ), throwsException);
    });

    test('registerUser throws generic message', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.register),
          statusCode: 200,
          data: {'status': 'failed', 'message': 'failed'},
        ),
      );

      expect(() => repository.registerUser(
        mobile: '1', fullName: '2', email: '3', gender: '4', society: '5', 
        tower: '6', floor: '7', flat: '8', role: '9'
      ), throwsException);
    });

    test('registerUser handles profilePicture as String', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.register),
          statusCode: 200,
          data: {'status': 'success', 'token': 'abc', 'role': 'owner', 'user': {'user_id': 1}},
        ),
      );

      final tempFile = File('${Directory.systemTemp.path}/test_image.png');
      await tempFile.writeAsBytes([0]);

      final result = await repository.registerUser(
        mobile: '1', fullName: '2', email: '3', gender: '4', society: '5', 
        tower: '6', floor: '7', flat: '8', role: '9', profilePicture: tempFile.path
      );
      expect(result.token, 'abc');
    });

    test('registerUser handles profilePicture as File', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: EnvConfig.register),
          statusCode: 200,
          data: {'status': 'success', 'token': 'abc', 'role': 'owner', 'user': {'user_id': 1}},
        ),
      );

      final tempFile = File('${Directory.systemTemp.path}/test_image2.png');
      await tempFile.writeAsBytes([0]);

      final result = await repository.registerUser(
        mobile: '1', fullName: '2', email: '3', gender: '4', society: '5', 
        tower: '6', floor: '7', flat: '8', role: '9', profilePicture: tempFile
      );
      expect(result.token, 'abc');
    });

    test('registerUser throws if profilePicture file does not exist', () async {
      final tempFile = File('${Directory.systemTemp.path}/non_existent.png');
      if (tempFile.existsSync()) tempFile.deleteSync();

      expect(() => repository.registerUser(
        mobile: '1', fullName: '2', email: '3', gender: '4', society: '5', 
        tower: '6', floor: '7', flat: '8', role: '9', profilePicture: tempFile
      ), throwsException);
    });

    test('uploadProfilePicture throws if URL missing', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/users/upload-profile-picture'),
          statusCode: 200,
          data: {'success': true}, // missing url
        ),
      );

      final tempFile = File('${Directory.systemTemp.path}/test_image.png');
      await tempFile.writeAsBytes([0]);
      
      expect(() => repository.uploadProfilePicture(tempFile), throwsException);
    });

    test('updateProfile throws when response misses user', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/users/me/update'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      expect(() => repository.updateProfile(
        fullName: 'u', email: 'u', mobile: '1'
      ), throwsException);
    });

    test('updateProfile throws DioException', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'), options: any(named: 'options'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/app-api/users/me/update'))
      );

      expect(() => repository.updateProfile(
        fullName: 'u', email: 'u', mobile: '1'
      ), throwsException);
    });

    test('uploadProfilePicture throws on non-200', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/app-api/users/upload-profile-picture'))
      );

      final tempFile = File('${Directory.systemTemp.path}/test_image.png');
      await tempFile.writeAsBytes([0]);
      
      expect(() => repository.uploadProfilePicture(tempFile), throwsException);
    });
  });
}
