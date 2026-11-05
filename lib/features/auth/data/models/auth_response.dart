import 'user_model.dart';

class AuthResponse {
  final String status;
  final String token;
  final UserModel? data;

  String get role {
    final pRole = data?.primaryRole.trim();
    if (pRole != null && pRole.isNotEmpty && pRole.toLowerCase() != 'resident') {
      return pRole;
    }
    if (data?.systemRole != null && data!.systemRole!.trim().isNotEmpty) {
      return data!.systemRole!.trim();
    }
    if (data?.secondaryRole != null && data!.secondaryRole!.trim().isNotEmpty) {
      return data!.secondaryRole!.trim();
    }
    if (pRole != null && pRole.isNotEmpty) {
      return pRole;
    }
    return 'resident';
  }
  bool get isExistingUser => token.isNotEmpty;

  AuthResponse({
    required this.status,
    required this.token,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] ?? 'error',
      token: json['token'] ?? json['access_token'] ?? '',
      // Check for 'data' key or fallback to 'user' key commonly used in APIs
      data: json['data'] != null 
          ? UserModel.fromJson(json['data']) 
          : (json['user'] != null ? UserModel.fromJson(json['user']) : null),
    );
  }
}