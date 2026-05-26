class AuthResponse {
  final bool isExistingUser;
  final String role;
  final String token;

  AuthResponse({
    required this.isExistingUser, 
    required this.role, 
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      isExistingUser: json['user_exists'] ?? false,
      role: json['role'] ?? 'resident',
      token: json['token'] ?? '',
    );
  }
}