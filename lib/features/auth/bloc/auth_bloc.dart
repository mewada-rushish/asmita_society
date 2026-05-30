import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../../../core/security/secure_storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../data/models/auth_response.dart';
import '../data/models/user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SecureStorageService secureStorage;

  AuthBloc({
    required this.authRepository,
    required this.secureStorage,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthInitiateRequested>(_onInitiateRequested);
    on<AuthVerifyRequested>(_onVerifyRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await secureStorage.getToken();
      
      if (token != null && token.isNotEmpty) {
        final cachedRole = await secureStorage.getUserRole() ?? 'resident';
        
        final sessionUser = UserModel(
          userId: 0, 
          fullName: 'AsmitA User', 
          userType: cachedRole, 
          accountType: 'app',
        );
        
        emit(AuthAuthenticated(user: sessionUser));
      } else {
        final hasOnboarded = await secureStorage.read(key: 'has_seen_onboarding') == 'true';
        if (hasOnboarded) {
          emit(AuthUnauthenticated());
        } else {
          emit(AuthNeedsOnboarding());
        }
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
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
    emit(AuthUnauthenticated());
  }

  Future<void> _emitAuthenticated(AuthResponse response, Emitter<AuthState> emit) async {
    if (response.token.isNotEmpty && response.data != null) {
      await secureStorage.saveToken(response.token);
      await secureStorage.saveUserRole(response.role);
      emit(AuthAuthenticated(user: response.data!));
    } else {
      emit(const AuthError(message: 'Invalid session payload.'));
    }
  }

  String _formatException(Object e) => e.toString().replaceFirst('Exception: ', '');
}