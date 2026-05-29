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

// --- NEW: Dispatched from the Registration Screen ---
class AuthRegisterRequested extends AuthEvent {
  final String mobile;
  final String fullName;
  final String email;
  final String gender;
  final String society;
  final String tower;
  final String floor;
  final String flat;
  final String role;

  AuthRegisterRequested({
    required this.mobile,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.society,
    required this.tower,
    required this.floor,
    required this.flat,
    required this.role,
  });
}

class AuthLogoutRequested extends AuthEvent {}