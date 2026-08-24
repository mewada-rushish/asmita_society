import 'package:equatable/equatable.dart';
import '../data/models/community_post_model.dart';

abstract class CommunityPostEvent extends Equatable {
  const CommunityPostEvent();

  @override
  List<Object> get props => [];
}

class LoadCommunityPosts extends CommunityPostEvent {}

class AddCommunityPost extends CommunityPostEvent {
  final CommunityPostModel post;

  const AddCommunityPost(this.post);

  @override
  List<Object> get props => [post];
}
