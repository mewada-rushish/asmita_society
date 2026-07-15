import 'package:equatable/equatable.dart';
import '../data/models/invite_model.dart';

abstract class VisitorState extends Equatable {
  const VisitorState();

  @override
  List<Object?> get props => [];
}

class VisitorInitial extends VisitorState {}

class VisitorLoading extends VisitorState {}

class VisitorHistoryLoaded extends VisitorState {
  final List<dynamic> history;

  const VisitorHistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

class VisitorCreateSuccess extends VisitorState {
  final PreApprovedInvite invite;

  const VisitorCreateSuccess({required this.invite});

  @override
  List<Object?> get props => [invite];
}

class VisitorError extends VisitorState {
  final String message;

  const VisitorError({required this.message});

  @override
  List<Object?> get props => [message];
}
