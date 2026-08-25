import 'package:equatable/equatable.dart';

class CommunityPostModel extends Equatable {
  final String id;
  final String title;
  final String contentJson; // Quill document JSON string
  final String authorName;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  const CommunityPostModel({
    required this.id,
    required this.title,
    required this.contentJson,
    required this.authorName,
    this.status = 'approved',
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      contentJson: json['content_json']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'approved',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'].toString()) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content_json': contentJson,
      'author_name': authorName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, contentJson, authorName, status, createdAt, startDate, endDate];
}
