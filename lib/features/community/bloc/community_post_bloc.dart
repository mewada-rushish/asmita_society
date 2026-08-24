import 'package:flutter_bloc/flutter_bloc.dart';
import 'community_post_event.dart';
import 'community_post_state.dart';

class CommunityPostBloc extends Bloc<CommunityPostEvent, CommunityPostState> {
  CommunityPostBloc() : super(const CommunityPostState()) {
    on<LoadCommunityPosts>((event, emit) async {
      emit(state.copyWith(status: CommunityPostStatus.loading));
      // Simulate network load
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(status: CommunityPostStatus.loaded));
    });

    on<AddCommunityPost>((event, emit) {
      final updatedPosts = List.of(state.posts)..insert(0, event.post);
      emit(state.copyWith(posts: updatedPosts));
    });
  }
}
