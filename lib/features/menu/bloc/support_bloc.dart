import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/support_repository.dart';
import 'support_event.dart';
import 'support_state.dart';

class SupportBloc extends Bloc<SupportEvent, SupportState> {
  final SupportRepository repository;

  SupportBloc({required this.repository}) : super(SupportInitial()) {
    on<LoadSupport>(_onLoadSupport);
    on<CreateSupportTicket>(_onCreateSupportTicket);
    on<ReplySupportTicket>(_onReplySupportTicket);
    on<CloseSupportTicket>(_onCloseSupportTicket);
  }

  Future<void> _onLoadSupport(LoadSupport event, Emitter<SupportState> emit) async {
    if (event.showLoading) emit(SupportLoading());
    try {
      final items = await repository.getTickets();
      emit(SupportLoaded(items));
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }

  Future<void> _onCreateSupportTicket(CreateSupportTicket event, Emitter<SupportState> emit) async {
    try {
      final success = await repository.createTicket(
        title: event.subject,
        description: event.message,
        category: event.category,
      );
      if (success != null) add(const LoadSupport(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onReplySupportTicket(ReplySupportTicket event, Emitter<SupportState> emit) async {
    try {
      final success = await repository.addTicketMessage(event.ticketId, event.message);
      if (success != null) add(const LoadSupport(showLoading: false));
    } catch (_) {}
  }

  Future<void> _onCloseSupportTicket(CloseSupportTicket event, Emitter<SupportState> emit) async {
    try {
      final success = await repository.updateTicket(event.ticketId, status: 'CLOSED');
      if (success) add(const LoadSupport(showLoading: false));
    } catch (_) {}
  }
}
