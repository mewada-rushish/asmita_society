import 'package:equatable/equatable.dart';
import '../data/models/community_post_model.dart';

enum CommunityPostStatus { initial, loading, loaded, error }

class CommunityPostState extends Equatable {
  final CommunityPostStatus status;
  final List<CommunityPostModel> posts;
  final String? errorMessage;

  const CommunityPostState({
    this.status = CommunityPostStatus.initial,
    this.posts = const [],
    this.errorMessage,
  });

  CommunityPostState copyWith({
    CommunityPostStatus? status,
    List<CommunityPostModel>? posts,
    String? errorMessage,
  }) {
    return CommunityPostState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, posts, errorMessage];
}
