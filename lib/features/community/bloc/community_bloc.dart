import 'package:flutter/foundation.dart';
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
    on<VoteOnPollMessage>(_onVoteOnPollMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<SendDocumentMessage>(_onSendDocumentMessage);
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
        // Append older messages to the end of the array because the newest message is at index 0
        emit(CommunityLoaded(
          [...currentState.messages, ...moreMessages],
          hasReachedMax: moreMessages.length < 20,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      _currentPage--;
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
      await _fetchAndMergeLatestMessages(currentState, emit);
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> _onSendAudioMessage(SendAudioMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;
    
    final tempMsg = ChatMessageModel.createMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'audio',
      content: '${event.audioPath}|${event.duration}',
    );

    emit(currentState.copyWith(messages: [tempMsg, ...currentState.messages]));

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
      await _fetchAndMergeLatestMessages(currentState, emit, isUploadingAttachment: false);
    } catch (e) {
      final filteredMessages = currentState.messages.where((m) => !m.id.startsWith('temp_')).toList();
      emit(currentState.copyWith(messages: filteredMessages, isUploadingAttachment: false));
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
      await _fetchAndMergeLatestMessages(currentState, emit);
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> _onSendImageMessage(SendImageMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;
    
    final tempMsg = ChatMessageModel.createMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'image',
      content: event.imagePath,
    );

    emit(currentState.copyWith(messages: [tempMsg, ...currentState.messages]));

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
      await _fetchAndMergeLatestMessages(currentState, emit, isUploadingAttachment: false);
    } catch (e) {
      final filteredMessages = currentState.messages.where((m) => !m.id.startsWith('temp_')).toList();
      emit(currentState.copyWith(messages: filteredMessages, isUploadingAttachment: false));
    }
  }

  Future<void> _onVoteOnPollMessage(VoteOnPollMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;
    
    // Optimistic UI Update: update the specific poll message in the list
    final updatedMessages = currentState.messages.map((msg) {
      if (msg.id == event.messageId && msg.pollOptions != null) {
        final newOptions = Map<String, int>.from(msg.pollOptions!);
        newOptions[event.option] = (newOptions[event.option] ?? 0) + 1;
        return msg.copyWith(pollOptions: newOptions);
      }
      return msg;
    }).toList();
    
    emit(currentState.copyWith(messages: updatedMessages));
    
    // Attempt to persist the vote to the backend DB
    try {
      await repository.voteOnPoll(event.messageId, event.option);
    } catch (e) {
      debugPrint('Vote on poll backend failed (mocked endpoint): $e');
    }
  }

  Future<void> _fetchAndMergeLatestMessages(CommunityLoaded currentState, Emitter<CommunityState> emit, {bool isUploadingAttachment = false}) async {
    final newMessages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName, page: 1);
    final newIds = newMessages.map((m) => m.id).toSet();
    final olderMessages = currentState.messages.where((m) => !m.id.startsWith('temp_') && !newIds.contains(m.id)).toList();
    emit(CommunityLoaded([...newMessages, ...olderMessages], hasReachedMax: currentState.hasReachedMax, isUploadingAttachment: isUploadingAttachment));
  }

  Future<void> _onSendDocumentMessage(SendDocumentMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;
    
    final tempMsg = ChatMessageModel.createMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'document',
      content: '${event.documentPath}|${event.fileName}|${event.fileSize}',
    );

    emit(currentState.copyWith(messages: [tempMsg, ...currentState.messages]));

    try {
      final String? uploadedUrl = await repository.uploadFile(event.documentPath);
      if (uploadedUrl == null) throw Exception('Upload failed');
      
      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'document',
        content: '$uploadedUrl|${event.fileName}|${event.fileSize}',
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(currentState, emit, isUploadingAttachment: false);
    } catch (e) {
      final filteredMessages = currentState.messages.where((m) => !m.id.startsWith('temp_')).toList();
      emit(currentState.copyWith(messages: filteredMessages, isUploadingAttachment: false));
    }
  }
}
