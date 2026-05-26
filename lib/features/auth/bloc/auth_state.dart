abstract class AuthState { const AuthState(); }

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String phoneNumber;
  AuthOtpSent({required this.phoneNumber});
}

class AuthSuccess extends AuthState {
  final bool isExistingUser;
  final String token;
  final String role;
  const AuthSuccess({required this.isExistingUser, required this.token, required this.role});
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}