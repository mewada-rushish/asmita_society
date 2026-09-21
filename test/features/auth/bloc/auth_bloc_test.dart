import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockSecureStorageService mockSecureStorageService;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockSecureStorageService = MockSecureStorageService();
    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      secureStorage: mockSecureStorageService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthOtpSent] when AuthInitiateRequested is successful',
      build: () {
        when(() => mockAuthRepository.initiateLogin(any())).thenAnswer((_) async => true);
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthInitiateRequested(mobile: '1234567890')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthOtpSent>().having((state) => state.mobile, 'mobile', '1234567890'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when AuthInitiateRequested fails',
      build: () {
        when(() => mockAuthRepository.initiateLogin(any())).thenThrow(Exception('Network error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthInitiateRequested(mobile: '1234567890')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message', contains('Network error')),
      ],
    );
  });
}
