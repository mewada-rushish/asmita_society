import 'package:equatable/equatable.dart';
import '../data/models/support_ticket_model.dart';

abstract class SupportState extends Equatable {
  const SupportState();
  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportLoaded extends SupportState {
  final List<SupportTicketModel> items;
  const SupportLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class SupportError extends SupportState {
  final String message;
  const SupportError(this.message);
  @override
  List<Object?> get props => [message];
}
