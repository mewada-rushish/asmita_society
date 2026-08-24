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

  @override
  List<Object?> get props => [id, title, contentJson, authorName, status, createdAt, startDate, endDate];
}
