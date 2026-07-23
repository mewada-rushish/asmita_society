import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/models/chat_message_model.dart';
import '../../bloc/community_state.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return ApiCommunityRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final communityProvider = NotifierProvider<CommunityNotifier, CommunityState>(() {
  return CommunityNotifier();
});

class CommunityNotifier extends Notifier<CommunityState> {
  late CommunityRepository repository;
  int? _currentUserId;
  String? _currentUserName;
  int _currentPage = 1;
  bool _isFetching = false;

  @override
  CommunityState build() {
    repository = ref.watch(communityRepositoryProvider);
    return CommunityInitial();
  }

  String _getCurrentFormattedTime() {
    final now = DateTime.now();
    return DateFormat('hh:mm a').format(now);
  }

  Future<void> loadMessages({int? currentUserId, String? currentUserName, bool isRefresh = false}) async {
    if (!isRefresh) {
      state = CommunityLoading();
    }
    try {
      _currentUserId = currentUserId ?? _currentUserId;
      _currentUserName = currentUserName ?? _currentUserName;
      _currentPage = 1;
      _isFetching = true;
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName, page: _currentPage);
      state = CommunityLoaded(messages, hasReachedMax: messages.length < 20);
    } catch (e) {
      state = const CommunityError('Failed to load community messages.');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> pollNewMessages() async {
    final currentState = state;
    if (currentState is! CommunityLoaded || _isFetching) return;
    try {
      await _fetchAndMergeLatestMessages(currentState);
    } catch (e) {
      // Silently fail polling so it doesn't disrupt user
    }
  }

  Future<void> loadMoreMessages() async {
    final currentState = state;
    if (currentState is! CommunityLoaded || _isFetching) return;
    if (currentState.hasReachedMax) return;

    try {
      _isFetching = true;
      state = currentState.copyWith(isLoadingMore: true);
      _currentPage++;
      final moreMessages = await repository.getMessages(
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
        page: _currentPage,
      );

      if (moreMessages.isEmpty) {
        state = currentState.copyWith(hasReachedMax: true, isLoadingMore: false);
      } else {
        state = CommunityLoaded(
          [...currentState.messages, ...moreMessages],
          hasReachedMax: moreMessages.length < 20,
          isLoadingMore: false,
        );
      }
    } catch (e) {
      _currentPage--;
      state = currentState.copyWith(isLoadingMore: false);
    } finally {
      _isFetching = false;
    }
  }

  void toggleSelection(String messageId) {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;

    final newSelection = Set<String>.from(currentState.selectedMessageIds);
    if (newSelection.contains(messageId)) {
      newSelection.remove(messageId);
    } else {
      newSelection.add(messageId);
    }
    state = currentState.copyWith(selectedMessageIds: newSelection);
  }

  void clearSelection() {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;
    state = currentState.copyWith(selectedMessageIds: const {});
  }

  void setReplyTo(ChatMessageModel message) {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;
    state = currentState.copyWith(replyingToMessage: message);
  }

  void clearReplyTo() {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;
    state = currentState.copyWith(clearReplyingToMessage: true);
  }

  Future<void> deleteSelectedMessages() async {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;

    final idsToDelete = currentState.selectedMessageIds.toList();
    
    // Optimistic UI update
    final updatedMessages = currentState.messages
        .where((m) => !idsToDelete.contains(m.id))
        .toList();
    
    state = currentState.copyWith(
      messages: updatedMessages,
      selectedMessageIds: const {},
    );

    // Call backend delete
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
  
  void starSelectedMessages() {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;

    final updatedMessages = currentState.messages.map((m) {
      if (currentState.selectedMessageIds.contains(m.id)) {
        return m.copyWith(isStarred: !m.isStarred);
      }
      return m;
    }).toList();
    
    state = currentState.copyWith(
      messages: updatedMessages,
      selectedMessageIds: const {},
    );
  }

  Future<void> sendTextMessage(String text, {String? replyToMessageId, String? replyToContent}) async {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;

    try {
      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'text',
        content: text,
        replyToMessageId: replyToMessageId,
        replyToContent: replyToContent,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(currentState);
    } catch (e) {
      state = currentState;
    }
  }

  Future<void> sendContactMessage(String name, String phone) async {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;

    try {
      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'contact',
        content: '$name|$phone',
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(currentState);
    } catch (e) {
      state = currentState;
    }
  }

  Future<void> sendAudioMessage(String audioPath, String duration) async {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;
    
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessageModel.createMessage(
      id: tempId,
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'audio',
      content: '$audioPath|$duration',
    );

    state = currentState.copyWith(messages: [tempMsg, ...currentState.messages]);

    try {
      final String? uploadedUrl = await repository.uploadFile(audioPath);
      if (uploadedUrl == null) throw Exception('Upload failed');
      
      final content = '$uploadedUrl|$duration';

      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'audio',
        content: content,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      
      if (state is CommunityLoaded) {
        final currentList = (state as CommunityLoaded).messages;
        final updatedList = currentList.map((m) => m.id == tempId ? encryptedMsg : m).toList();
        state = (state as CommunityLoaded).copyWith(messages: updatedList);
      }
      
      if (state is CommunityLoaded) {
        await _fetchAndMergeLatestMessages(state as CommunityLoaded, isUploadingAttachment: false);
      }
    } catch (e) {
      if (state is CommunityLoaded) {
        final filteredMessages = (state as CommunityLoaded).messages.where((m) => m.id != tempId).toList();
        state = (state as CommunityLoaded).copyWith(messages: filteredMessages, isUploadingAttachment: false);
      }
    }
  }

  Future<void> sendPollMessage(String question, Map<String, int> options, bool allowMultipleAnswers) async {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;

    try {
      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'poll',
        content: question,
        pollOptions: options,
        allowMultipleAnswers: allowMultipleAnswers,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      await _fetchAndMergeLatestMessages(currentState);
    } catch (e) {
      state = currentState;
    }
  }

  Future<void> sendImageMessage(String imagePath) async {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;
    
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessageModel.createMessage(
      id: tempId,
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'image',
      content: imagePath,
    );

    state = currentState.copyWith(messages: [tempMsg, ...currentState.messages]);

    try {
      final String? uploadedUrl = await repository.uploadFile(imagePath);
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
      
      if (state is CommunityLoaded) {
        final currentList = (state as CommunityLoaded).messages;
        final updatedList = currentList.map((m) => m.id == tempId ? encryptedMsg : m).toList();
        state = (state as CommunityLoaded).copyWith(messages: updatedList);
      }
      
      if (state is CommunityLoaded) {
        await _fetchAndMergeLatestMessages(state as CommunityLoaded, isUploadingAttachment: false);
      }
    } catch (e) {
      if (state is CommunityLoaded) {
        final filteredMessages = (state as CommunityLoaded).messages.where((m) => m.id != tempId).toList();
        state = (state as CommunityLoaded).copyWith(messages: filteredMessages, isUploadingAttachment: false);
      }
    }
  }

  Future<void> sendDocumentMessage(String documentPath, String fileName, String fileSize) async {
    final currentState = state;
    if (currentState is! CommunityLoaded) return;
    
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessageModel.createMessage(
      id: tempId,
      sender: 'You',
      isMe: true,
      time: 'Today|${_getCurrentFormattedTime()}',
      type: 'document',
      content: '$documentPath|$fileName|$fileSize',
    );

    state = currentState.copyWith(messages: [tempMsg, ...currentState.messages]);

    try {
      final String? uploadedUrl = await repository.uploadFile(documentPath);
      if (uploadedUrl == null) throw Exception('Upload failed');
      
      final encryptedMsg = ChatMessageModel.createMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today|${_getCurrentFormattedTime()}',
        type: 'document',
        content: '$uploadedUrl|$fileName|$fileSize',
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      
      if (state is CommunityLoaded) {
        final currentList = (state as CommunityLoaded).messages;
        final updatedList = currentList.map((m) => m.id == tempId ? encryptedMsg : m).toList();
        state = (state as CommunityLoaded).copyWith(messages: updatedList);
      }
      
      if (state is CommunityLoaded) {
        await _fetchAndMergeLatestMessages(state as CommunityLoaded, isUploadingAttachment: false);
      }
    } catch (e) {
      if (state is CommunityLoaded) {
        final filteredMessages = (state as CommunityLoaded).messages.where((m) => m.id != tempId).toList();
        state = (state as CommunityLoaded).copyWith(messages: filteredMessages, isUploadingAttachment: false);
      }
    }
  }
  


  Future<void> _fetchAndMergeLatestMessages(CommunityLoaded currentState, {bool isUploadingAttachment = false}) async {
    try {
      final newMessages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName, page: 1);
      final newIds = newMessages.map((m) => m.id).toSet();
      final currentMessages = (state as CommunityLoaded).messages;
      
      // Preserve temp messages until they finish uploading
      final tempMessages = currentMessages.where((m) => m.id.startsWith('temp_')).toList();
      final olderMessages = currentMessages.where((m) => !m.id.startsWith('temp_') && !newIds.contains(m.id)).toList();
      
      state = (state as CommunityLoaded).copyWith(
        messages: [...tempMessages, ...newMessages, ...olderMessages], 
        hasReachedMax: currentState.hasReachedMax, 
        isUploadingAttachment: isUploadingAttachment,
      );
    } catch (e) {
      debugPrint('Failed to fetch latest messages during polling: $e');
    }
  }

  Future<void> voteOnPoll(String messageId, String option) async {
    try {
      await repository.voteOnPoll(messageId, option);
    } catch (e) {
      debugPrint('Vote on poll backend failed (mocked endpoint): $e');
    }
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;
    
    final messages = currentState.messages.map((msg) {
      if (msg.id == messageId && msg.pollOptions != null) {
        final newPollOptions = Map<String, int>.from(msg.pollOptions!);
        final currentVoted = List<String>.from(msg.votedOptions);
        
        if (msg.allowMultipleAnswers) {
          if (currentVoted.contains(option)) {
            currentVoted.remove(option);
            newPollOptions[option] = (newPollOptions[option] ?? 1) - 1;
          } else {
            currentVoted.add(option);
            newPollOptions[option] = (newPollOptions[option] ?? 0) + 1;
          }
        } else {
          if (currentVoted.contains(option)) {
            currentVoted.remove(option);
            newPollOptions[option] = (newPollOptions[option] ?? 1) - 1;
          } else {
            if (currentVoted.isNotEmpty) {
              final prev = currentVoted.first;
              newPollOptions[prev] = (newPollOptions[prev] ?? 1) - 1;
              currentVoted.clear();
            }
            currentVoted.add(option);
            newPollOptions[option] = (newPollOptions[option] ?? 0) + 1;
          }
        }
        
        return msg.copyWith(
          pollOptions: newPollOptions,
          votedOptions: currentVoted,
        );
      }
      return msg;
    }).toList();
    
    state = currentState.copyWith(messages: messages);
  }

}