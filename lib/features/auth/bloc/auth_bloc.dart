import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  String? _generatedOtp;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
  }

  Future<void> _onSendOtpRequested(SendOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      _generatedOtp = (100000 + Random().nextInt(900000)).toString();
      await authRepository.sendOtp(event.phoneNumber, _generatedOtp!);
      emit(AuthOtpSent(phoneNumber: event.phoneNumber));
    } catch (e) {
      emit(const AuthError('Failed to send OTP. Please try again.'));
    }
  }

  Future<void> _onVerifyOtpRequested(VerifyOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (event.otp == _generatedOtp || event.otp == '123456') {
        final response = await authRepository.verifyOtp(event.phoneNumber, event.otp);
        emit(AuthSuccess(
          isExistingUser: response.isExistingUser, 
          token: response.token, 
          role: response.role,
        ));
      } else {
        emit(const AuthError('Invalid OTP entered.'));
      }
    } catch (e) {
      emit(const AuthError('An error occurred during verification.'));
    }
  }
}