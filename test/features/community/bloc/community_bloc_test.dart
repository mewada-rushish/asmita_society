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

    blocTest<CommunityBloc, CommunityState>(
      'emits updated state when LoadMoreMessages is called',
      build: () {
        when(() => mockCommunityRepository.getMessages(
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              page: any(named: 'page'),
            )).thenAnswer((_) async => [testMessage]);
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: false),
      act: (bloc) => bloc.add(const LoadMoreMessages()),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<CommunityLoaded>().having((s) => s.messages.length, 'length', 2),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits failed state when SendTextMessage fails',
      build: () {
        when(() => mockCommunityRepository.sendMessage(any(), senderId: any(named: 'senderId')))
            .thenThrow(Exception('Failed'));
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendTextMessage('My message')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp added length', 2),
        isA<CommunityLoaded>().having((s) => s.messages[0].isFailed, 'isFailed', true),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits updated state when SendPollMessage is called',
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
      act: (bloc) => bloc.add(const SendPollMessage(
        question: 'Q1', 
        options: {'A': 0, 'B': 0}, 
        allowMultipleAnswers: false
      )),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'length', 2),
        isA<CommunityLoaded>(),
      ],
    );
    blocTest<CommunityBloc, CommunityState>(
      'emits updated state when VoteOnPollMessage is called',
      build: () {
        when(() => mockCommunityRepository.voteOnPoll(any(), any())).thenAnswer((_) async {});
        return communityBloc;
      },
      seed: () => CommunityLoaded([
        ChatMessageModel.createMessage(
          id: 'test_poll',
          sender: 'Test',
          isMe: false,
          time: 'Today',
          type: 'poll',
          content: 'Q1',
          pollOptions: {'A': 0, 'B': 0},
        )
      ], hasReachedMax: true),
      act: (bloc) => bloc.add(const VoteOnPollMessage(messageId: 'test_poll', option: 'A')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages[0].pollOptions?['A'], 'option A votes', 1),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits updated state when SendAudioMessage succeeds',
      build: () {
        when(() => mockCommunityRepository.uploadFile(any())).thenAnswer((_) async => 'url');
        when(() => mockCommunityRepository.sendMessage(any(), senderId: any(named: 'senderId'))).thenAnswer((_) async {});
        when(() => mockCommunityRepository.getMessages(
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              page: any(named: 'page'),
            )).thenAnswer((_) async => [testMessage]);
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendAudioMessage('10:00', 'path')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp length', 2),
        isA<CommunityLoaded>(),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits failed state when SendAudioMessage fails',
      build: () {
        when(() => mockCommunityRepository.uploadFile(any())).thenThrow(Exception('Upload failed'));
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendAudioMessage('10:00', 'path')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp length', 2),
        isA<CommunityLoaded>().having((s) => s.messages[0].isFailed, 'isFailed', true),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits updated state when SendImageMessage succeeds',
      build: () {
        when(() => mockCommunityRepository.uploadFile(any())).thenAnswer((_) async => 'url');
        when(() => mockCommunityRepository.sendMessage(any(), senderId: any(named: 'senderId'))).thenAnswer((_) async {});
        when(() => mockCommunityRepository.getMessages(
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              page: any(named: 'page'),
            )).thenAnswer((_) async => [testMessage]);
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendImageMessage('path')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp length', 2),
        isA<CommunityLoaded>(),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits failed state when SendImageMessage fails',
      build: () {
        when(() => mockCommunityRepository.uploadFile(any())).thenThrow(Exception('Upload failed'));
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendImageMessage('path')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp length', 2),
        isA<CommunityLoaded>().having((s) => s.messages[0].isFailed, 'isFailed', true),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits updated state when SendDocumentMessage succeeds',
      build: () {
        when(() => mockCommunityRepository.uploadFile(any())).thenAnswer((_) async => 'url');
        when(() => mockCommunityRepository.sendMessage(any(), senderId: any(named: 'senderId'))).thenAnswer((_) async {});
        when(() => mockCommunityRepository.getMessages(
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              page: any(named: 'page'),
            )).thenAnswer((_) async => [testMessage]);
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendDocumentMessage('path', 'f.pdf', '1MB')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp length', 2),
        isA<CommunityLoaded>(),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits failed state when SendDocumentMessage fails',
      build: () {
        when(() => mockCommunityRepository.uploadFile(any())).thenThrow(Exception('Upload failed'));
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendDocumentMessage('path', 'f.pdf', '1MB')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp length', 2),
        isA<CommunityLoaded>().having((s) => s.messages[0].isFailed, 'isFailed', true),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits failed state when SendPollMessage fails',
      build: () {
        when(() => mockCommunityRepository.sendMessage(any(), senderId: any(named: 'senderId'))).thenThrow(Exception('Upload failed'));
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: true),
      act: (bloc) => bloc.add(const SendPollMessage(question: 'Q', options: {'A': 0}, allowMultipleAnswers: false)),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages.length, 'temp length', 2),
        isA<CommunityLoaded>().having((s) => s.messages[0].isFailed, 'isFailed', true),
      ],
    );
    blocTest<CommunityBloc, CommunityState>(
      'emits failed state when VoteOnPollMessage fails (catches gracefully)',
      build: () {
        when(() => mockCommunityRepository.voteOnPoll(any(), any())).thenThrow(Exception('Failed to vote'));
        return communityBloc;
      },
      seed: () => CommunityLoaded([
        ChatMessageModel.createMessage(
          id: 'test_poll',
          sender: 'Test',
          isMe: false,
          time: 'Today',
          type: 'poll',
          content: 'Q1',
          pollOptions: {'A': 0, 'B': 0},
        )
      ], hasReachedMax: true),
      act: (bloc) => bloc.add(const VoteOnPollMessage(messageId: 'test_poll', option: 'A')),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.messages[0].pollOptions?['A'], 'option A votes', 1),
      ],
    );

    blocTest<CommunityBloc, CommunityState>(
      'emits reverted state when LoadMoreMessages fails',
      build: () {
        when(() => mockCommunityRepository.getMessages(
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              page: any(named: 'page'),
            )).thenThrow(Exception('Failed'));
        return communityBloc;
      },
      seed: () => CommunityLoaded([testMessage], hasReachedMax: false),
      act: (bloc) => bloc.add(const LoadMoreMessages()),
      expect: () => [
        isA<CommunityLoaded>().having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<CommunityLoaded>().having((s) => s.isLoadingMore, 'isLoadingMore', false),
      ],
    );

    test('event props are correct', () {
      expect(const LoadCommunityMessages(currentUserId: 1, currentUserName: 'John').props, [1, 'John', false]);
      expect(const LoadMoreMessages(currentUserId: 1, currentUserName: 'John').props, [1, 'John']);
      expect(const SendTextMessage('hello', replyToMessageId: '123', replyToContent: 'hi').props, ['hello', '123', 'hi']);
      expect(const SendAudioMessage('1:00', 'path').props, ['1:00', 'path']);
      expect(const SendPollMessage(question: 'Q', options: {'A': 0}, allowMultipleAnswers: true).props, ['Q', {'A': 0}, true]);
      expect(const VoteOnPollMessage(messageId: '1', option: 'A').props, ['1', 'A']);
      expect(const SendImageMessage('path').props, ['path']);
      expect(const SendDocumentMessage('path', 'file.pdf', '1MB').props, ['path', 'file.pdf', '1MB']);
    });

    test('state props are correct', () {
      expect(CommunityInitial().props, []);
      expect(CommunityLoading().props, []);
      expect(CommunityLoaded([testMessage]).props, [[testMessage], false, false, false, const <String>{}, null]);
      expect(const CommunityError('error').props, ['error']);
    });
  });
}
