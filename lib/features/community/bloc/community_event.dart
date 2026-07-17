import 'package:equatable/equatable.dart';

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

class LoadMoreMessages extends CommunityEvent {
  final int? currentUserId;
  final String? currentUserName;
  const LoadMoreMessages({this.currentUserId, this.currentUserName});
  
  @override
  List<Object?> get props => [currentUserId, currentUserName];
}

class SendTextMessage extends CommunityEvent {
  final String text;
  final String? replyToMessageId;
  final String? replyToContent;

  const SendTextMessage(this.text, {this.replyToMessageId, this.replyToContent});

  @override
  List<Object?> get props => [text, replyToMessageId, replyToContent];
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

class SendImageMessage extends CommunityEvent {
  final String imagePath;

  const SendImageMessage(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}
