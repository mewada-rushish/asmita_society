class UserModel {
  final int userId;
  final String fullName;
  final String userType;
  final String accountType;
  final int? societyId;
  final String? emailId;
  final String? mobileNumber;
  final String? gender;
  final String? profilePictureUrl;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.userType,
    required this.accountType,
    this.societyId,
    this.emailId,
    this.mobileNumber,
    this.gender,
    this.profilePictureUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      userType: json['user_type'] ?? 'resident',
      accountType: json['account_type'] ?? 'app',
      societyId: json['society_id'],
      emailId: json['email_id'],
      mobileNumber: json['mobile_number'],
      gender: json['gender'],
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'user_type': userType,
      'account_type': accountType,
      'society_id': societyId,
      'email_id': emailId,
      'mobile_number': mobileNumber,
      'gender': gender,
      'profile_picture_url': profilePictureUrl,
    };
  }
}