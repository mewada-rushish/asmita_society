import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../../../core/security/secure_storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Manages the state of the authentication flow (OTP dispatch, verification, and registration).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SecureStorageService secureStorage;

  AuthBloc({
    required this.authRepository,
    required this.secureStorage,
  }) : super(AuthInitial()) {
    on<AuthInitiateRequested>(_onInitiateRequested);
    on<AuthVerifyRequested>(_onVerifyRequested);
    on<AuthRegisterRequested>(_onRegisterRequested); // Added Registration Listener
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onInitiateRequested(
    AuthInitiateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final success = await authRepository.initiateLogin(event.mobile);
      if (success) {
        emit(AuthOtpSent(mobile: event.mobile));
      } else {
        emit(AuthError(message: 'Failed to dispatch OTP payload.'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onVerifyRequested(
    AuthVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await authRepository.verifyOtp(event.mobile, event.otp);
      
      if (response.token.isNotEmpty && response.data != null) {
        await secureStorage.saveToken(response.token);
        await secureStorage.saveUserRole(response.role);

        emit(AuthAuthenticated(user: response.data!));
      } else {
        emit(AuthError(message: 'Invalid session payload received.'));
      }
    } catch (e) {
      final errorString = e.toString();
      // Catch our custom flag from the repository allowing us to gracefully redirect to registration
      if (errorString.contains('REGISTRATION_REQUIRED')) {
        emit(AuthRegistrationRequired(mobile: event.mobile));
      } else {
        emit(AuthError(message: errorString.replaceAll('Exception: ', '')));
      }
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await authRepository.registerUser(
        mobile: event.mobile,
        fullName: event.fullName,
        email: event.email,
        gender: event.gender,
        society: event.society,
        tower: event.tower,
        floor: event.floor,
        flat: event.flat,
        role: event.role,
      );
      
      // Successfully registered and logged in simultaneously 
      if (response.token.isNotEmpty && response.data != null) {
        await secureStorage.saveToken(response.token);
        await secureStorage.saveUserRole(response.role);

        emit(AuthAuthenticated(user: response.data!));
      } else {
        emit(AuthError(message: 'Registration successful but failed to capture session payload.'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await secureStorage.clearSession();
    emit(AuthInitial());
  }
}