import '../data/models/auth_response.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String mobile;
  AuthOtpSent({required this.mobile});
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated({required this.user});
}

// --- NEW: Triggers the router to open Registration Screen ---
class AuthRegistrationRequired extends AuthState {
  final String mobile;
  AuthRegistrationRequired({required this.mobile});
}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}