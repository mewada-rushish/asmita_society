import 'package:equatable/equatable.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class LoadCommunityMessages extends CommunityEvent {
  final int? currentUserId;
  final String? currentUserName;
  const LoadCommunityMessages({this.currentUserId, this.currentUserName});
  
  @override
  List<Object?> get props => [currentUserId, currentUserName];
}

class SendTextMessage extends CommunityEvent {
  final String text;

  const SendTextMessage(this.text);

  @override
  List<Object?> get props => [text];
}

class SendAudioMessage extends CommunityEvent {
  final String duration;

  const SendAudioMessage(this.duration);

  @override
  List<Object?> get props => [duration];
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
