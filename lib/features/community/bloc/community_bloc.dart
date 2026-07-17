import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../data/repositories/community_repository.dart';
import '../data/models/chat_message_model.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository repository;
  int? _currentUserId;
  String? _currentUserName;
  int _currentPage = 1;
  bool _isFetching = false;

  CommunityBloc({required this.repository}) : super(CommunityInitial()) {
    on<LoadCommunityMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendAudioMessage>(_onSendAudioMessage);
    on<SendPollMessage>(_onSendPollMessage);
    on<SendImageMessage>(_onSendImageMessage);
  }

  String _getCurrentFormattedTime() {
    final now = DateTime.now();
    return DateFormat('hh:mm a').format(now);
  }

  Future<void> _onLoadMessages(LoadCommunityMessages event, Emitter<CommunityState> emit) async {
    if (!event.isRefresh) {
      emit(CommunityLoading());
    }
    try {
      _currentUserId = event.currentUserId ?? _currentUserId;
      _currentUserName = event.currentUserName ?? _currentUserName;
      _currentPage = 1;
      _isFetching = true;
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName, page: _currentPage);
      emit(CommunityLoaded(messages, hasReachedMax: messages.length < 20));
    } catch (e) {
      emit(const CommunityError('Failed to load community messages.'));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onLoadMoreMessages(LoadMoreMessages event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded || _isFetching) return;
    final currentState = state as CommunityLoaded;
    if (currentState.hasReachedMax) return;

    try {
      _isFetching = true;
      emit(currentState.copyWith(isLoadingMore: true));
      _currentPage++;
      final moreMessages = await repository.getMessages(
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
        page: _currentPage,
      );

      if (moreMessages.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true, isLoadingMore: false));
      } else {
        // Prepend older messages
        emit(CommunityLoaded(
          [...moreMessages, ...currentState.messages],
          hasReachedMax: moreMessages.length < 20,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onSendTextMessage(SendTextMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    try {
      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'text',
        content: event.text,
        replyToMessageId: event.replyToMessageId,
        replyToContent: event.replyToContent,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      _currentPage = 1;
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName, page: _currentPage);
      emit(CommunityLoaded(messages, hasReachedMax: messages.length < 20));
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> _onSendAudioMessage(SendAudioMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    try {
      final String? uploadedUrl = await repository.uploadFile(event.audioPath);
      if (uploadedUrl == null) throw Exception('Upload failed');
      
      final content = '$uploadedUrl|${event.duration}';

      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'audio',
        content: content,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName);
      emit(CommunityLoaded(messages));
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> _onSendPollMessage(SendPollMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    try {
      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'poll',
        content: event.question,
        pollOptions: event.options,
        allowMultipleAnswers: event.allowMultipleAnswers,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName);
      emit(CommunityLoaded(messages));
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> _onSendImageMessage(SendImageMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    try {
      final String? uploadedUrl = await repository.uploadFile(event.imagePath);
      if (uploadedUrl == null) throw Exception('Upload failed');

      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'image',
        content: uploadedUrl,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName);
      emit(CommunityLoaded(messages));
    } catch (e) {
      emit(currentState);
    }
  }
}
