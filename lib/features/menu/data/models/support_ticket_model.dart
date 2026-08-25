class SupportTicketModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final String? category;
  final DateTime? createdAt;

  SupportTicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.category,
    this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'Open',
      category: json['category'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
