import 'package:equatable/equatable.dart';
import '../data/models/chat_message_model.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class LoadCommunityMessages extends CommunityEvent {
  final int? currentUserId;
  final String? currentUserName;
  final bool isRefresh;
  const LoadCommunityMessages({this.currentUserId, this.currentUserName, this.isRefresh = false});
  
  @override
  List<Object?> get props => [currentUserId, currentUserName, isRefresh];
}

class StartPolling extends CommunityEvent {
  final bool Function()? isAtBottom;
  const StartPolling({this.isAtBottom});
}

class StopPolling extends CommunityEvent {}

class PollMessages extends CommunityEvent {}

class LoadMoreCommunityMessages extends CommunityEvent {}

class ToggleMessageSelection extends CommunityEvent {
  final String messageId;
  const ToggleMessageSelection(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ClearMessageSelection extends CommunityEvent {}

class SetReplyToMessage extends CommunityEvent {
  final ChatMessageModel message;
  const SetReplyToMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearReplyToMessage extends CommunityEvent {}

class DeleteSelectedMessages extends CommunityEvent {}

class StarSelectedMessages extends CommunityEvent {}

class SendTextMessage extends CommunityEvent {
  final String text;
  final String? replyToMessageId;
  final String? replyToContent;

  const SendTextMessage(this.text, {this.replyToMessageId, this.replyToContent});

  @override
  List<Object?> get props => [text, replyToMessageId, replyToContent];
}

class SendContactMessage extends CommunityEvent {
  final String name;
  final String phone;

  const SendContactMessage(this.name, this.phone);

  @override
  List<Object?> get props => [name, phone];
}

class SendAudioMessage extends CommunityEvent {
  final String duration;
  final String audioPath;

  const SendAudioMessage(this.duration, this.audioPath);

  @override
  List<Object?> get props => [duration, audioPath];
}

class SendPollMessage extends CommunityEvent {
  final String question;
  final Map<String, int> options;
  final bool allowMultipleAnswers;

  const SendPollMessage({
    required this.question, 
    required this.options,
    this.allowMultipleAnswers = false,
  });

  @override
  List<Object?> get props => [question, options, allowMultipleAnswers];
}

class VoteOnPollMessage extends CommunityEvent {
  final String messageId;
  final String option;

  const VoteOnPollMessage({
    required this.messageId,
    required this.option,
  });

  @override
  List<Object?> get props => [messageId, option];
}

class SendImageMessage extends CommunityEvent {
  final String imagePath;

  const SendImageMessage(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class SendDocumentMessage extends CommunityEvent {
  final String documentPath;
  final String fileName;
  final String fileSize;

  const SendDocumentMessage(this.documentPath, this.fileName, this.fileSize);

  @override
  List<Object?> get props => [documentPath, fileName, fileSize];
}
