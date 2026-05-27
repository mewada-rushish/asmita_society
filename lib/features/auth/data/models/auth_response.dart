class AuthResponse {
  final String status;
  final String token;
  final UserModel? data;

  // Convenience getter to prevent breaking your existing app logic
  String get role => data?.userType ?? 'resident';
  
  // If we receive a token, the user exists in the DB
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

class UserModel {
  final int userId;
  final String fullName;
  final String userType;
  final String accountType;
  final int? societyId;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.userType,
    required this.accountType,
    this.societyId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      userType: json['user_type'] ?? 'resident',
      accountType: json['account_type'] ?? '',
      societyId: json['society_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'user_type': userType,
      'account_type': accountType,
      'society_id': societyId,
    };
  }
}