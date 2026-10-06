import 'dart:async';
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
    on<StartPolling>(_onStartPolling);
    on<StopPolling>(_onStopPolling);
    on<PollMessages>(_onPollMessages);
    on<LoadCommunityMessages>(_onLoadMessages);
    on<LoadMoreCommunityMessages>(_onLoadMoreCommunityMessages);
    on<ToggleMessageSelection>(_onToggleMessageSelection);
    on<ClearMessageSelection>(_onClearMessageSelection);
    on<SetReplyToMessage>(_onSetReplyToMessage);
    on<ClearReplyToMessage>(_onClearReplyToMessage);
    on<DeleteSelectedMessages>(_onDeleteSelectedMessages);
    on<StarSelectedMessages>(_onStarSelectedMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendAudioMessage>(_onSendAudioMessage);
    on<SendPollMessage>(_onSendPollMessage);
    on<VoteOnPollMessage>(_onVoteOnPollMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<SendDocumentMessage>(_onSendDocumentMessage);
  }

  bool _isPollingActive = false;
  int _pollingFailures = 0;
  bool Function()? _isAtBottomCallback;
  Timer? _pollingTimer;

  void _onStartPolling(StartPolling event, Emitter<CommunityState> emit) {
    if (_isPollingActive) return;
    _isAtBottomCallback = event.isAtBottom;
    _isPollingActive = true;
    _pollingFailures = 0;
    _scheduleNextPoll();
  }

  void _onStopPolling(StopPolling event, Emitter<CommunityState> emit) {
    _isPollingActive = false;
    _pollingTimer?.cancel();
  }

  void _scheduleNextPoll() {
    _pollingTimer?.cancel();
    if (!_isPollingActive) return;
    final backoffSeconds = _calculateBackoff(_pollingFailures);
    _pollingTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (_isPollingActive && !isClosed) {
        add(PollMessages());
      }
    });
  }

  Future<void> _onPollMessages(
    PollMessages event,
    Emitter<CommunityState> emit,
  ) async {
    if (!_isPollingActive) return;

    final isAtBottom = _isAtBottomCallback?.call() ?? true;
    if (!isAtBottom) {
      _scheduleNextPoll();
      return;
    }

    final currentState = state;
    if (currentState is! CommunityLoaded || _isFetching) {
      _scheduleNextPoll();
      return;
    }

    try {
      await _fetchAndMergeLatestMessages(currentState, emit);
      _pollingFailures = 0;
    } catch (e) {
      _pollingFailures++;
    } finally {
      _scheduleNextPoll();
    }
  }

  int _calculateBackoff(int failures) {
    if (failures == 0) return 10;
    int backoff = 10;
    for (int i = 0; i < failures; i++) {
      backoff *= 2;
    }
    return backoff > 60 ? 60 : backoff;
  }

  void _onToggleMessageSelection(
    ToggleMessageSelection event,
    Emitter<CommunityState> emit,
  ) {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;
    final newSelection = Set<String>.from(currentState.selectedMessageIds);
    if (newSelection.contains(event.messageId)) {
      newSelection.remove(event.messageId);
    } else {
      newSelection.add(event.messageId);
    }
    emit(currentState.copyWith(selectedMessageIds: newSelection));
  }

  void _onClearMessageSelection(
    ClearMessageSelection event,
    Emitter<CommunityState> emit,
  ) {
    if (state is! CommunityLoaded) return;
    emit((state as CommunityLoaded).copyWith(selectedMessageIds: const {}));
  }

  void _onSetReplyToMessage(
    SetReplyToMessage event,
    Emitter<CommunityState> emit,
  ) {
    if (state is! CommunityLoaded) return;
    emit((state as CommunityLoaded).copyWith(replyingToMessage: event.message));
  }

  void _onClearReplyToMessage(
    ClearReplyToMessage event,
    Emitter<CommunityState> emit,
  ) {
    if (state is! CommunityLoaded) return;
    emit((state as CommunityLoaded).copyWith(clearReplyingToMessage: true));
  }

  Future<void> _onDeleteSelectedMessages(
    DeleteSelectedMessages event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;
    final idsToDelete = currentState.selectedMessageIds.toList();

    final updatedMessages = currentState.messages
        .where((m) => !idsToDelete.contains(m.id))
        .toList();

    emit(
      currentState.copyWith(
        messages: updatedMessages,
        selectedMessageIds: const {},
      ),
    );

    for (final id in idsToDelete) {
      if (!id.startsWith('temp_')) {
        try {
          await repository.deleteMessage(id);
        } catch (e) {
          debugPrint('Failed to delete message $id');
        }
      }
    }
  }

  void _onStarSelectedMessages(
    StarSelectedMessages event,
    Emitter<CommunityState> emit,
  ) {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;
    final updatedMessages = currentState.messages.map((m) {
      if (currentState.selectedMessageIds.contains(m.id)) {
        return m.copyWith(isStarred: !m.isStarred);
      }
      return m;
    }).toList();

    emit(
      currentState.copyWith(
        messages: updatedMessages,
        selectedMessageIds: const {},
      ),
    );
  }

  String _getCurrentFormattedTime() {
    final now = DateTime.now();
    return DateFormat('hh:mm a').format(now);
  }

  Future<void> _onLoadMessages(
    LoadCommunityMessages event,
    Emitter<CommunityState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(CommunityLoading());
    }
    try {
      _currentUserId = event.currentUserId ?? _currentUserId;
      _currentUserName = event.currentUserName ?? _currentUserName;
      _currentPage = 1;
      _isFetching = true;
      final messages = await repository.getMessages(
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
        page: _currentPage,
      );
      emit(CommunityLoaded(messages, hasReachedMax: messages.length < 20));
    } catch (e) {
      emit(const CommunityError('Failed to load community messages.'));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onLoadMoreCommunityMessages(
    LoadMoreCommunityMessages event,
    Emitter<CommunityState> emit,
  ) async {
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
        emit(
          CommunityLoaded(
            [...currentState.messages, ...moreMessages],
            hasReachedMax: moreMessages.length < 20,
            isLoadingMore: false,
          ),
        );
      }
    } catch (e) {
      _currentPage--;
      emit(currentState.copyWith(isLoadingMore: false));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessageModel.createMessage(
      id: tempId,
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'text',
      content: event.text,
      replyToMessageId: event.replyToMessageId,
      replyToContent: event.replyToContent,
    );

    emit(currentState.copyWith(messages: [tempMsg, ...currentState.messages]));

    try {
      await repository.sendMessage(tempMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(currentState, emit);
    } catch (e) {
      final messages = (state as CommunityLoaded).messages.map((m) {
        if (m.id == tempId) return m.copyWith(isFailed: true);
        return m;
      }).toList();
      emit(currentState.copyWith(messages: messages));
    }
  }

  Future<void> _onSendAudioMessage(
    SendAudioMessage event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    final tempMsg = ChatMessageModel.createMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'audio',
      content: '${event.audioPath}|${event.duration}',
      replyToMessageId: event.replyToMessageId,
      replyToContent: event.replyToContent,
    );

    emit(currentState.copyWith(messages: [tempMsg, ...currentState.messages]));

    try {
      final String? uploadedUrl = await repository.uploadFile(event.audioPath);
      if (uploadedUrl == null) throw Exception('Upload failed');

      final content = '$uploadedUrl|${event.duration}';

      final finalMsg = tempMsg.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
      );

      await repository.sendMessage(finalMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(
        currentState,
        emit,
        isUploadingAttachment: false,
      );
    } catch (e) {
      final messages = (state as CommunityLoaded).messages.map((m) {
        if (m.id == tempMsg.id) return m.copyWith(isFailed: true);
        return m;
      }).toList();
      emit(
        currentState.copyWith(messages: messages, isUploadingAttachment: false),
      );
    }
  }

  Future<void> _onSendPollMessage(
    SendPollMessage event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessageModel.createMessage(
      id: tempId,
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'poll',
      content: event.question,
      pollOptions: event.options,
      allowMultipleAnswers: event.allowMultipleAnswers,
    );

    emit(currentState.copyWith(messages: [tempMsg, ...currentState.messages]));

    try {
      await repository.sendMessage(tempMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(currentState, emit);
    } catch (e) {
      final messages = (state as CommunityLoaded).messages.map((m) {
        if (m.id == tempId) return m.copyWith(isFailed: true);
        return m;
      }).toList();
      emit(currentState.copyWith(messages: messages));
    }
  }

  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    final tempMsg = ChatMessageModel.createMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'image',
      content: event.imagePath,
      replyToMessageId: event.replyToMessageId,
      replyToContent: event.replyToContent,
    );

    emit(currentState.copyWith(messages: [tempMsg, ...currentState.messages]));

    try {
      final String? uploadedUrl = await repository.uploadFile(event.imagePath);
      if (uploadedUrl == null) throw Exception('Upload failed');

      final finalMsg = tempMsg.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: uploadedUrl,
      );

      await repository.sendMessage(finalMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(
        currentState,
        emit,
        isUploadingAttachment: false,
      );
    } catch (e) {
      final messages = (state as CommunityLoaded).messages.map((m) {
        if (m.id == tempMsg.id) return m.copyWith(isFailed: true);
        return m;
      }).toList();
      emit(
        currentState.copyWith(messages: messages, isUploadingAttachment: false),
      );
    }
  }

  Future<void> _onVoteOnPollMessage(
    VoteOnPollMessage event,
    Emitter<CommunityState> emit,
  ) async {
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

  Future<void> _fetchAndMergeLatestMessages(
    CommunityLoaded currentState,
    Emitter<CommunityState> emit, {
    bool isUploadingAttachment = false,
  }) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final newMessages = await repository.getMessages(
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
        page: 1,
      );
      final newIds = newMessages.map((m) => m.id).toSet();
      final olderMessages = currentState.messages
          .where((m) => !m.id.startsWith('temp_') && !newIds.contains(m.id))
          .toList();
      emit(
        CommunityLoaded(
          [...newMessages, ...olderMessages],
          hasReachedMax: currentState.hasReachedMax,
          isUploadingAttachment: isUploadingAttachment,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onSendDocumentMessage(
    SendDocumentMessage event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    final tempMsg = ChatMessageModel.createMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'document',
      content: '${event.documentPath}|${event.fileName}|${event.fileSize}',
      replyToMessageId: event.replyToMessageId,
      replyToContent: event.replyToContent,
    );

    emit(currentState.copyWith(messages: [tempMsg, ...currentState.messages]));

    try {
      final String? uploadedUrl = await repository.uploadFile(
        event.documentPath,
      );
      if (uploadedUrl == null) throw Exception('Upload failed');

      final finalMsg = tempMsg.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '$uploadedUrl|${event.fileName}|${event.fileSize}',
      );

      await repository.sendMessage(finalMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(
        currentState,
        emit,
        isUploadingAttachment: false,
      );
    } catch (e) {
      final messages = (state as CommunityLoaded).messages.map((m) {
        if (m.id == tempMsg.id) return m.copyWith(isFailed: true);
        return m;
      }).toList();
      emit(
        currentState.copyWith(messages: messages, isUploadingAttachment: false),
      );
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
