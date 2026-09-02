import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/community_post_repository.dart';
import 'community_post_event.dart';
import 'community_post_state.dart';

class CommunityPostBloc extends Bloc<CommunityPostEvent, CommunityPostState> {
  final CommunityPostRepository repository;

  CommunityPostBloc({required this.repository}) : super(const CommunityPostState()) {
    on<LoadCommunityPosts>((event, emit) async {
      emit(state.copyWith(status: CommunityPostStatus.loading));
      try {
        final posts = await repository.getPosts();
        emit(state.copyWith(
          status: CommunityPostStatus.loaded,
          posts: posts,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: CommunityPostStatus.error,
          errorMessage: e.toString(),
        ));
      }
    });

    on<AddCommunityPost>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));
      try {
        // Assume API returns the created post with its generated ID
        final newPost = await repository.createPost(event.post);
        final updatedPosts = List.of(state.posts)..insert(0, newPost);
        emit(state.copyWith(posts: updatedPosts, isSubmitting: false));
      } catch (e) {
        // Fallback or show error
        emit(state.copyWith(
          status: CommunityPostStatus.error,
          errorMessage: e.toString(),
          isSubmitting: false,
        ));
        // Also might want to revert the status back to loaded so it doesn't stay in error state forever
        emit(state.copyWith(status: CommunityPostStatus.loaded));
      }
    });

    on<DeleteCommunityPost>((event, emit) async {
      // Optimistically remove the post from the UI so Dismissible doesn't crash
      final previousPosts = List.of(state.posts);
      final updatedPosts = state.posts.where((post) => post.id != event.postId).toList();
      emit(state.copyWith(posts: updatedPosts));
      
      try {
        await repository.deletePost(event.postId);
      } catch (e) {
        // Revert on error
        emit(state.copyWith(posts: previousPosts));
      }
    });
  }
}
