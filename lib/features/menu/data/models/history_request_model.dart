class HistoryRequestModel {
  final int id;
  final int ownerUserId;
  final String ownerName;
  final String status;
  final DateTime createdAt;

  HistoryRequestModel({
    required this.id,
    required this.ownerUserId,
    required this.ownerName,
    required this.status,
    required this.createdAt,
  });

  factory HistoryRequestModel.fromJson(Map<String, dynamic> json) {
    return HistoryRequestModel(
      id: json['id'] as int? ?? 0,
      ownerUserId: json['owner_user_id'] as int? ?? 0,
      ownerName: json['owner_name'] as String? ?? 'Owner',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
