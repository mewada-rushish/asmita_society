import 'user_model.dart';

class AuthResponse {
  final String status;
  final String token;
  final UserModel? data;

<<<<<<< HEAD
  String get role => data?.systemRole ?? data?.primaryRole ?? 'resident';
=======
  String get role {
    if (data?.systemRole != null && data!.systemRole!.isNotEmpty) {
      return data!.systemRole!;
    }
    if (data?.secondaryRole != null && data!.secondaryRole!.isNotEmpty) {
      return data!.secondaryRole!;
    }
    if (data?.primaryRole.isNotEmpty == true) {
      return data!.primaryRole;
    }
    return 'resident';
  }
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
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