import 'package:equatable/equatable.dart';
import '../data/models/community_post_model.dart';

enum CommunityPostStatus { initial, loading, loaded, error }

class CommunityPostState extends Equatable {
  final CommunityPostStatus status;
  final List<CommunityPostModel> posts;
  final String? errorMessage;
  final bool isSubmitting;

  const CommunityPostState({
    this.status = CommunityPostStatus.initial,
    this.posts = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  CommunityPostState copyWith({
    CommunityPostStatus? status,
    List<CommunityPostModel>? posts,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return CommunityPostState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  List<CommunityPostModel> get activePosts {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final active = posts.where((p) {
      if (p.status != 'approved') return false;
      if (p.startDate != null) {
        final start = DateTime(p.startDate!.year, p.startDate!.month, p.startDate!.day);
        if (start.isAfter(today)) return false;
      }
      if (p.endDate != null) {
        final end = DateTime(p.endDate!.year, p.endDate!.month, p.endDate!.day);
        if (end.isBefore(today)) return false;
      }
      return true;
    }).toList();
    
    active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return active;
  }

  @override
  List<Object?> get props => [status, posts, errorMessage, isSubmitting];
}
