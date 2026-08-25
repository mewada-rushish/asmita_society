class CommitteeMemberModel {
  final int id;
  final String name;
  final String role;
  final String? phone;
  final String? email;

  CommitteeMemberModel({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
    this.email,
  });

  factory CommitteeMemberModel.fromJson(Map<String, dynamic> json) {
    return CommitteeMemberModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }
}
