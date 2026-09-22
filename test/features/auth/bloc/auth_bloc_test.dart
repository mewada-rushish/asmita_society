import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/auth/data/models/auth_response.dart';

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
        when(
          () => mockAuthRepository.initiateLogin(any()),
        ).thenAnswer((_) async => true);
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const AuthInitiateRequested(mobile: '1234567890')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthOtpSent>().having(
          (state) => state.mobile,
          'mobile',
          '1234567890',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when AuthInitiateRequested fails',
      build: () {
        when(
          () => mockAuthRepository.initiateLogin(any()),
        ).thenThrow(Exception('Network error'));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const AuthInitiateRequested(mobile: '1234567890')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (state) => state.message,
          'message',
          contains('Network error'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when AuthCheckRequested fails',
      build: () {
        when(() => mockSecureStorageService.getToken()).thenThrow(Exception());
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthApprovedNeedsLogin] when AuthCheckStatusRequested returns APPROVED',
      build: () {
        when(
          () => mockAuthRepository.checkStatus(any()),
        ).thenAnswer((_) async => 'APPROVED');
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const AuthCheckStatusRequested(mobile: '1234567890')),
      expect: () => [isA<AuthLoading>(), isA<AuthApprovedNeedsLogin>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthPendingApproval] when AuthCheckStatusRequested returns PENDING',
      build: () {
        when(
          () => mockAuthRepository.checkStatus(any()),
        ).thenAnswer((_) async => 'PENDING');
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const AuthCheckStatusRequested(mobile: '1234567890')),
      expect: () => [isA<AuthLoading>(), isA<AuthPendingApproval>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthRegistrationRequired] when AuthVerifyRequested requires registration',
      build: () {
        when(
          () => mockAuthRepository.verifyOtp(any(), any()),
        ).thenThrow(Exception('REGISTRATION_REQUIRED'));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthVerifyRequested(mobile: '1234567890', otp: '123456'),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthRegistrationRequired>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthPendingApproval] when AuthVerifyRequested returns PENDING_APPROVAL',
      build: () {
        when(
          () => mockAuthRepository.verifyOtp(any(), any()),
        ).thenThrow(Exception('PENDING_APPROVAL'));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthVerifyRequested(mobile: '1234567890', otp: '123456'),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthPendingApproval>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when AuthVerifyRequested fails',
      build: () {
        when(
          () => mockAuthRepository.verifyOtp(any(), any()),
        ).thenThrow(Exception('Unknown Error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthVerifyRequested(mobile: '1234567890', otp: '123456'),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    // AuthRegisterRequested Tests
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthPendingApproval] when AuthRegisterRequested returns PENDING_APPROVAL',
      build: () {
        when(
          () => mockAuthRepository.registerUser(
            mobile: any(named: 'mobile'),
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            gender: any(named: 'gender'),
            society: any(named: 'society'),
            tower: any(named: 'tower'),
            floor: any(named: 'floor'),
            flat: any(named: 'flat'),
            role: any(named: 'role'),
            profilePicture: any(named: 'profilePicture'),
          ),
        ).thenThrow(Exception('PENDING_APPROVAL'));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          mobile: '1234567890',
          fullName: 'Test',
          email: 'test@example.com',
          gender: 'Male',
          society: 'Soc',
          tower: 'T',
          floor: 'F',
          flat: 'Flat',
          role: 'Role',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthPendingApproval>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when AuthRegisterRequested fails',
      build: () {
        when(
          () => mockAuthRepository.registerUser(
            mobile: any(named: 'mobile'),
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            gender: any(named: 'gender'),
            society: any(named: 'society'),
            tower: any(named: 'tower'),
            floor: any(named: 'floor'),
            flat: any(named: 'flat'),
            role: any(named: 'role'),
            profilePicture: any(named: 'profilePicture'),
          ),
        ).thenThrow(Exception('Register Error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          mobile: '1234567890',
          fullName: 'Test',
          email: 'test@example.com',
          gender: 'Male',
          society: 'Soc',
          tower: 'T',
          floor: 'F',
          flat: 'Flat',
          role: 'Role',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits nothing if state is not AuthAuthenticated',
      build: () => authBloc,
      act: (bloc) => bloc.add(
        const AuthUpdateProfileRequested(
          fullName: 'New',
          email: 't@example.com',
          mobile: '1234567890',
        ),
      ),
      expect: () => [],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthCheckRequested has token and profile',
      build: () {
        when(
          () => mockSecureStorageService.getToken(),
        ).thenAnswer((_) async => 'token123');
        when(
          () => mockSecureStorageService.read(key: 'user_profile'),
        ).thenAnswer(
          (_) async =>
              '{"id":1, "full_name":"Test User", "primary_role":"owner", "account_type":"app"}',
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.fullName,
          'name',
          'Test User',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthCheckRequested has token but no profile',
      build: () {
        when(
          () => mockSecureStorageService.getToken(),
        ).thenAnswer((_) async => 'token123');
        when(
          () => mockSecureStorageService.read(key: 'user_profile'),
        ).thenAnswer((_) async => null);
        when(
          () => mockSecureStorageService.getUserRole(),
        ).thenAnswer((_) async => 'resident');
        when(
          () => mockSecureStorageService.getUserId(),
        ).thenAnswer((_) async => 2);
        when(
          () => mockSecureStorageService.getUserName(),
        ).thenAnswer((_) async => 'Cached Name');
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.fullName,
          'name',
          'Cached Name',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthNeedsOnboarding] when AuthCheckRequested has no token and not onboarded',
      build: () {
        when(
          () => mockSecureStorageService.getToken(),
        ).thenAnswer((_) async => null);
        when(
          () => mockSecureStorageService.read(key: 'has_seen_onboarding'),
        ).thenAnswer((_) async => 'false');
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthNeedsOnboarding>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthVerifyRequested succeeds',
      build: () {
        when(() => mockAuthRepository.verifyOtp(any(), any())).thenAnswer(
          (_) async => AuthResponse(
            status: 'success',
            token: 'token123',
            data: UserModel(
              userId: 1,
              fullName: 'Test Verify',
              primaryRole: 'owner',
              accountType: 'app',
            ),
          ),
        );
        when(
          () => mockSecureStorageService.saveToken(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserRole(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserId(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserName(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.write(
            key: 'user_profile',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthVerifyRequested(mobile: '1234567890', otp: '123456'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.fullName,
          'name',
          'Test Verify',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when AuthVerifyRequested succeeds but missing token',
      build: () {
        when(() => mockAuthRepository.verifyOtp(any(), any())).thenAnswer(
          (_) async => AuthResponse(status: 'success', token: '', data: null),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthVerifyRequested(mobile: '1234567890', otp: '123456'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          contains('Invalid session payload'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthRegisterRequested succeeds',
      build: () {
        when(
          () => mockAuthRepository.registerUser(
            mobile: any(named: 'mobile'),
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            gender: any(named: 'gender'),
            society: any(named: 'society'),
            tower: any(named: 'tower'),
            floor: any(named: 'floor'),
            flat: any(named: 'flat'),
            role: any(named: 'role'),
            profilePicture: any(named: 'profilePicture'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            status: 'success',
            token: 'token123',
            data: UserModel(
              userId: 1,
              fullName: 'Test Register',
              primaryRole: 'owner',
              accountType: 'app',
            ),
          ),
        );
        when(
          () => mockSecureStorageService.saveToken(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserRole(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserId(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserName(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.write(
            key: 'user_profile',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          mobile: '1234567890',
          fullName: 'Test Register',
          email: 'test@example.com',
          gender: 'Male',
          society: 'Soc',
          tower: 'T',
          floor: 'F',
          flat: 'Flat',
          role: 'Role',
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.fullName,
          'name',
          'Test Register',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthUpdateProfileRequested succeeds',
      build: () {
        when(
          () => mockSecureStorageService.getToken(),
        ).thenAnswer((_) async => 'token123');
        when(
          () => mockAuthRepository.updateProfile(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            mobile: any(named: 'mobile'),
            token: any(named: 'token'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            status: 'success',
            token: '',
            data: UserModel(
              userId: 1,
              fullName: 'Updated Profile',
              primaryRole: 'owner',
              accountType: 'app',
            ),
          ),
        );

        when(
          () => mockSecureStorageService.saveToken(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserRole(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserId(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.saveUserName(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.write(
            key: 'user_profile',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        return authBloc;
      },
      seed: () => AuthAuthenticated(
        user: UserModel(
          userId: 1,
          fullName: 'Old Profile',
          primaryRole: 'owner',
          accountType: 'app',
        ),
      ),
      act: (bloc) => bloc.add(
        const AuthUpdateProfileRequested(
          fullName: 'Updated Profile',
          email: 't@example.com',
          mobile: '1234567890',
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.fullName,
          'name',
          'Updated Profile',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError, AuthAuthenticated] when AuthUpdateProfileRequested fails',
      build: () {
        when(
          () => mockSecureStorageService.getToken(),
        ).thenAnswer((_) async => 'token123');
        when(
          () => mockAuthRepository.updateProfile(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            mobile: any(named: 'mobile'),
            token: any(named: 'token'),
          ),
        ).thenThrow(Exception('Update Error'));

        return authBloc;
      },
      seed: () => AuthAuthenticated(
        user: UserModel(
          userId: 1,
          fullName: 'Old Profile',
          primaryRole: 'owner',
          accountType: 'app',
        ),
      ),
      act: (bloc) => bloc.add(
        const AuthUpdateProfileRequested(
          fullName: 'Updated Profile',
          email: 't@example.com',
          mobile: '1234567890',
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when AuthUpdateProfileRequested returns invalid data',
      build: () {
        when(
          () => mockSecureStorageService.getToken(),
        ).thenAnswer((_) async => 'token123');
        when(
          () => mockAuthRepository.updateProfile(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            mobile: any(named: 'mobile'),
            token: any(named: 'token'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(status: 'success', token: '', data: null),
        );

        return authBloc;
      },
      seed: () => AuthAuthenticated(
        user: UserModel(
          userId: 1,
          fullName: 'Old Profile',
          primaryRole: 'owner',
          accountType: 'app',
        ),
      ),
      act: (bloc) => bloc.add(
        const AuthUpdateProfileRequested(
          fullName: 'Updated Profile',
          email: 't@example.com',
          mobile: '1234567890',
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          contains('Invalid update payload'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when AuthLogoutRequested succeeds',
      build: () {
        when(
          () => mockSecureStorageService.getUserId(),
        ).thenAnswer((_) async => 1);
        when(
          () => mockSecureStorageService.getUserRole(),
        ).thenAnswer((_) async => 'owner');
        when(
          () => mockAuthRepository.logout(any(), any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.clearSession(),
        ).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });
}
