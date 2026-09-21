import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_event.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/community/data/repositories/community_post_repository.dart';
import 'package:asmita_society/features/community/data/models/community_post_model.dart';

class MockCommunityPostRepository extends Mock implements CommunityPostRepository {}

class FakeCommunityPost extends Fake implements CommunityPostModel {}

void main() {
  late CommunityPostBloc bloc;
  late MockCommunityPostRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeCommunityPost());
  });

  setUp(() {
    mockRepository = MockCommunityPostRepository();
    bloc = CommunityPostBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('CommunityPostBloc', () {
    final tPost = CommunityPostModel(
      id: '1',
      title: 'Hello',
      contentJson: '{}',
      authorName: 'John',
      status: 'approved',
      createdAt: DateTime.now(),
    );
    final List<CommunityPostModel> tPostList = [tPost];

    test('initial state is CommunityPostState()', () {
      expect(bloc.state, const CommunityPostState());
    });

    blocTest<CommunityPostBloc, CommunityPostState>(
      'emits [loading, loaded] when LoadCommunityPosts succeeds',
      build: () {
        when(() => mockRepository.getPosts()).thenAnswer((_) async => tPostList);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadCommunityPosts()),
      expect: () => [
        const CommunityPostState(status: CommunityPostStatus.loading),
        CommunityPostState(status: CommunityPostStatus.loaded, posts: tPostList),
      ],
      verify: (_) {
        verify(() => mockRepository.getPosts()).called(1);
      },
    );

    blocTest<CommunityPostBloc, CommunityPostState>(
      'emits [loading, error] when LoadCommunityPosts fails',
      build: () {
        when(() => mockRepository.getPosts()).thenThrow(Exception('Failed to fetch posts'));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadCommunityPosts()),
      expect: () => [
        const CommunityPostState(status: CommunityPostStatus.loading),
        const CommunityPostState(
          status: CommunityPostStatus.error,
          errorMessage: 'Exception: Failed to fetch posts',
        ),
      ],
    );

    blocTest<CommunityPostBloc, CommunityPostState>(
      'emits [isSubmitting=true, isSubmitting=false & updated posts] when AddCommunityPost succeeds',
      build: () {
        when(() => mockRepository.createPost(any())).thenAnswer((_) async => tPost);
        return bloc;
      },
      act: (bloc) => bloc.add(AddCommunityPost(tPost)),
      expect: () => [
        const CommunityPostState(isSubmitting: true),
        CommunityPostState(isSubmitting: false, posts: [tPost]),
      ],
    );

    blocTest<CommunityPostBloc, CommunityPostState>(
      'optimistically removes post on DeleteCommunityPost and reverts on failure',
      seed: () => CommunityPostState(status: CommunityPostStatus.loaded, posts: tPostList),
      build: () {
        when(() => mockRepository.deletePost(any())).thenThrow(Exception('Delete failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteCommunityPost('1')),
      expect: () => [
        const CommunityPostState(status: CommunityPostStatus.loaded, posts: []), // Optimistic removal
        CommunityPostState(status: CommunityPostStatus.loaded, posts: tPostList), // Revert
      ],
    );
  });
}
