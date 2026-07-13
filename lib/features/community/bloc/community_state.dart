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

  const CommunityLoaded(
    this.messages, {
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  CommunityLoaded copyWith({
    List<ChatMessageModel>? messages,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return CommunityLoaded(
      messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [messages, hasReachedMax, isLoadingMore];
}

class CommunityError extends CommunityState {
  final String error;

  const CommunityError(this.error);

  @override
  List<Object?> get props => [error];
}
