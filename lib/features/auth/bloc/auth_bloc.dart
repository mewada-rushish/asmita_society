import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../../../core/security/secure_storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../data/models/auth_response.dart';

/// Manages authentication state: OTP lifecycle, registration, and session persistence.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SecureStorageService secureStorage;

  AuthBloc({
    required this.authRepository,
    required this.secureStorage,
  }) : super(AuthInitial()) {
    on<AuthInitiateRequested>(_onInitiateRequested);
    on<AuthVerifyRequested>(_onVerifyRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
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
        emit(const AuthError(message: 'Failed to initiate OTP.'));
      }
    } catch (e) {
      emit(AuthError(message: _formatException(e)));
    }
  }

  Future<void> _onVerifyRequested(
    AuthVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await authRepository.verifyOtp(event.mobile, event.otp);
      await _emitAuthenticated(response, emit);
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('REGISTRATION_REQUIRED')) {
        emit(AuthRegistrationRequired(mobile: event.mobile));
      } else {
        emit(AuthError(message: _formatException(e)));
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
      await _emitAuthenticated(response, emit);
    } catch (e) {
      emit(AuthError(message: _formatException(e)));
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

  /// DRY Helper: Persists session and emits authenticated state.
  Future<void> _emitAuthenticated(AuthResponse response, Emitter<AuthState> emit) async {
    if (response.token.isNotEmpty && response.data != null) {
      await secureStorage.saveToken(response.token);
      await secureStorage.saveUserRole(response.role);
      emit(AuthAuthenticated(user: response.data!));
    } else {
      emit(const AuthError(message: 'Invalid session payload.'));
    }
  }

  /// Sanitizes exception messages to remove 'Exception:' prefix.
  String _formatException(Object e) => e.toString().replaceFirst('Exception: ', '');
}