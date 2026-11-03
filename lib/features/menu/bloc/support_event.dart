import 'package:equatable/equatable.dart';

abstract class SupportEvent extends Equatable {
  const SupportEvent();
  @override
  List<Object?> get props => [];
}

class LoadSupport extends SupportEvent {
  final bool showLoading;
  const LoadSupport({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
class CreateSupportTicket extends SupportEvent {
  final String category;
  final String subject;
  final String priority;
  final String message;

  const CreateSupportTicket({
    required this.category,
    required this.subject,
    required this.priority,
    required this.message,
  });

  @override
  List<Object?> get props => [category, subject, priority, message];
}

class ReplySupportTicket extends SupportEvent {
  final int ticketId;
  final String message;

  const ReplySupportTicket({
    required this.ticketId,
    required this.message,
  });

  @override
  List<Object?> get props => [ticketId, message];
}

class CloseSupportTicket extends SupportEvent {
  final int ticketId;

  const CloseSupportTicket(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}
