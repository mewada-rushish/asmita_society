abstract class AuthEvent {}

class AuthInitiateRequested extends AuthEvent {
  final String mobile;
  AuthInitiateRequested({required this.mobile});
}

class AuthVerifyRequested extends AuthEvent {
  final String mobile;
  final String otp;
  AuthVerifyRequested({required this.mobile, required this.otp});
}

class AuthLogoutRequested extends AuthEvent {}