import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/community/bloc/community_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_event.dart';
import 'package:asmita_society/features/community/bloc/community_state.dart';
import 'package:asmita_society/features/community/data/repositories/community_repository.dart';
import 'package:asmita_society/features/community/data/models/chat_message_model.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

class FakeChatMessageModel extends Fake implements ChatMessageModel {}

void main() {
  late CommunityBloc communityBloc;
  late MockCommunityRepository mockCommunityRepository;

  final testMessage = ChatMessageModel.createMessage(
    id: 'test_id',
    sender: 'Test User',
    isMe: false,
    time: 'Today|10:00 AM',
    type: 'text',
    content: 'Hello World',
  );

  setUpAll(() {
    registerFallbackValue(FakeChatMessageModel());
  });

  setUp(() {
    mockCommunityRepository = MockCommunityRepository();
    communityBloc = CommunityBloc(repository: mockCommunityRepository);
  });

  tearDown(() {
    communityBloc.close();
  });

  group('CommunityBloc', () {
    test('initial state is CommunityInitial', () {
      expect(communityBloc.state, isA<CommunityInitial>());
    });

    blocTest<CommunityBloc, CommunityState>(
      'emits [CommunityLoading, CommunityLoaded] when LoadCommunityMessages succeeds',
      build: () {
        when(() => mockCommunityRepository.getMessages(
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              page: any(named: 'page'),
            )).thenAnswer((_) async => [testMessage]);
        return communityBloc;
      },
      act: (bloc) => bloc.add(const LoadCommunityMessages(isRefresh: false)),
      expect: () => [
        isA<CommunityLoading>(),
        isA<CommunityLoaded>().having((s) => s.messages.length, 'messages length', 1),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits [CommunityError] when LoadCommunityMessages fails',
      build: () {
        when(() => mockCommunityRepository.getMessages(
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              page: any(named: 'page'),
            )).thenThrow(Exception('Failed to load'));
        return communityBloc;
      },
      act: (bloc) => bloc.add(const LoadCommunityMessages(isRefresh: false)),
      expect: () => [
        isA<CommunityLoading>(),
        const CommunityError('Failed to load community messages.'),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits updated state when SendTextMessage is called',
      build: () {
        when(() => mockCommunityRepository.sendMessage(any(), senderId: any(named: 'senderId')))
            .thenAnswer((_) async {});
        when(() => mockCommunityRepository.getMessages(
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              page: any(named: 'page'),
            )).thenAnswer((_) async => [testMessage]);
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendTextMessage('My message')),
      expect: () => [
        // Optimistic update
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp added length', 2),
        // After refetch
        isA<CommunityLoaded>(),
      ],
    );
  });
}
