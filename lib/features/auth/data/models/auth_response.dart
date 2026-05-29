import 'user_model.dart';

class AuthResponse {
  final String status;
  final String token;
  final UserModel? data;

  String get role => data?.userType ?? 'resident';
  bool get isExistingUser => token.isNotEmpty;

  AuthResponse({
    required this.status,
    required this.token,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] ?? 'error',
      token: json['token'] ?? '',
      data: json['data'] != null ? UserModel.fromJson(json['data']) : null,
    );
  }
}