class TenantModel {
  final int id;
  final String name;
  final String relationship;
  final String? contactNumber;
  final bool isEmergencyContact;
  final String? avatarUrl;
  final String? historyRequestStatus;

  TenantModel({
    required this.id,
    required this.name,
    required this.relationship,
    this.contactNumber,
    this.isEmergencyContact = false,
    this.avatarUrl,
    this.historyRequestStatus,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      contactNumber: json['contact_number'] as String?,
      isEmergencyContact: json['is_emergency_contact'] == 1 || json['is_emergency_contact'] == true,
      avatarUrl: json['avatar_url'] as String?,
      historyRequestStatus: json['history_request'] != null ? json['history_request']['status'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'contact_number': contactNumber,
      'is_emergency_contact': isEmergencyContact ? 1 : 0,
      'avatar_url': avatarUrl,
      if (historyRequestStatus != null)
        'history_request': {'status': historyRequestStatus},
    };
  }
}
