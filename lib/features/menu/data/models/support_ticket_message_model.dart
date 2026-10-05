class SupportTicketMessageModel {
  final int id;
  final int ticketId;
  final int userId;
  final String message;
  final String? userName;
  final String? userRole;
  final DateTime? createdAt;

  SupportTicketMessageModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    this.userName,
    this.userRole,
    this.createdAt,
  });

  factory SupportTicketMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketMessageModel(
      id: (json['message_id'] ?? json['id']) as int? ?? 0,
      ticketId: (json['ticket_id'] ?? 0) as int,
      userId: (json['user_id'] ?? 0) as int,
      message: json['message'] as String? ?? '',
      userName: json['users']?['full_name'] as String?,
      userRole: (json['users']?['system_role'] ?? json['users']?['primary_role']) as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
