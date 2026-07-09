import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:asmita_society/core/security/encryption_service.dart';
import '../data/repositories/community_repository.dart';
import '../data/models/chat_message_model.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository repository;
  int? _currentUserId;
  String? _currentUserName;

  CommunityBloc({required this.repository}) : super(CommunityInitial()) {
    on<LoadCommunityMessages>(_onLoadMessages);
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
    emit(CommunityLoading());
    try {
      _currentUserId = event.currentUserId ?? _currentUserId;
      _currentUserName = event.currentUserName ?? _currentUserName;
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName);
      emit(CommunityLoaded(messages));
    } catch (e) {
      emit(const CommunityError('Failed to load community messages.'));
    }
  }

  Future<void> _onSendTextMessage(SendTextMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    try {
      String encryptor(String plain) => EncryptionService.encrypt(plain, repository.groupKey);

      final encryptedMsg = ChatMessageModel.createEncrypted(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today, ${_getCurrentFormattedTime()}',
        type: 'text',
        content: event.text,
        encryptor: encryptor,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName);
      emit(CommunityLoaded(messages));
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> _onSendAudioMessage(SendAudioMessage event, Emitter<CommunityState> emit) async {
    if (state is! CommunityLoaded) return;
    final currentState = state as CommunityLoaded;

    try {
      String encryptor(String plain) => EncryptionService.encrypt(plain, repository.groupKey);

      final encryptedMsg = ChatMessageModel.createEncrypted(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today, ${_getCurrentFormattedTime()}',
        type: 'audio',
        content: event.duration,
        encryptor: encryptor,
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
      String encryptor(String plain) => EncryptionService.encrypt(plain, repository.groupKey);

      final encryptedMsg = ChatMessageModel.createEncrypted(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today, ${_getCurrentFormattedTime()}',
        type: 'poll',
        content: event.question,
        pollOptions: event.options,
        allowMultipleAnswers: event.allowMultipleAnswers,
        encryptor: encryptor,
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
      String encryptor(String plain) => EncryptionService.encrypt(plain, repository.groupKey);

      final encryptedMsg = ChatMessageModel.createEncrypted(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'You',
        isMe: true,
        time: 'Today, ${_getCurrentFormattedTime()}',
        type: 'image',
        content: event.imagePath,
        encryptor: encryptor,
      );

      await repository.sendMessage(encryptedMsg, senderId: _currentUserId);
      final messages = await repository.getMessages(currentUserId: _currentUserId, currentUserName: _currentUserName);
      emit(CommunityLoaded(messages));
    } catch (e) {
      emit(currentState);
    }
  }
}
