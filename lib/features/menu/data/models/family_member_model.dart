class FamilyMemberModel {
  final int id;
  final String name;
  final String relationship;
  final bool isEmergencyContact;
  final String? avatarUrl;

  FamilyMemberModel({
    required this.id,
    required this.name,
    required this.relationship,
    this.isEmergencyContact = false,
    this.avatarUrl,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      isEmergencyContact: json['is_emergency_contact'] == 1 || json['is_emergency_contact'] == true,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'is_emergency_contact': isEmergencyContact ? 1 : 0,
      'avatar_url': avatarUrl,
    };
  }
}
