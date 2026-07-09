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

  const CommunityLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class CommunityError extends CommunityState {
  final String error;

  const CommunityError(this.error);

  @override
  List<Object?> get props => [error];
}
