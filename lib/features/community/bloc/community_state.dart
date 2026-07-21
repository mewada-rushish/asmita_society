import 'package:equatable/equatable.dart';
import '../data/models/chat_message_model.dart';

abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {}

class CommunityLoading extends CommunityState {}

class CommunityLoaded extends CommunityState {
  final List<ChatMessageModel> messages;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isUploadingAttachment;
  final Set<String> selectedMessageIds;
  final ChatMessageModel? replyingToMessage;

  const CommunityLoaded(
    this.messages, {
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isUploadingAttachment = false,
    this.selectedMessageIds = const {},
    this.replyingToMessage,
  });

  CommunityLoaded copyWith({
    List<ChatMessageModel>? messages,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isUploadingAttachment,
    Set<String>? selectedMessageIds,
    ChatMessageModel? replyingToMessage,
    bool clearReplyingToMessage = false,
  }) {
    return CommunityLoaded(
      messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUploadingAttachment: isUploadingAttachment ?? this.isUploadingAttachment,
      selectedMessageIds: selectedMessageIds ?? this.selectedMessageIds,
      replyingToMessage: clearReplyingToMessage ? null : (replyingToMessage ?? this.replyingToMessage),
    );
  }

  @override
  List<Object?> get props => [messages, hasReachedMax, isLoadingMore, isUploadingAttachment, selectedMessageIds, replyingToMessage];
}

class CommunityError extends CommunityState {
  final String error;

  const CommunityError(this.error);

  @override
  List<Object?> get props => [error];
}
