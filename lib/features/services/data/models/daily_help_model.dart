class DailyHelpModel {
  final int id;
  final int societyId;
  final String name;
  final String phone;
  final String role;
  final String? photoUrl;
  final String? kycStatus;
  final bool isActive;

  DailyHelpModel({
    required this.id,
    required this.societyId,
    required this.name,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.kycStatus,
    required this.isActive,
  });

  factory DailyHelpModel.fromJson(Map<String, dynamic> json) {
    return DailyHelpModel(
      id: json['id'] as int,
      societyId: json['society_id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      photoUrl: json['photo_url'] as String?,
      kycStatus: json['kyc_status'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
