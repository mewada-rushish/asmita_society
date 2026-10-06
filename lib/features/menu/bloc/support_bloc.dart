import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/support_repository.dart';
import 'support_event.dart';
import 'support_state.dart';

class SupportBloc extends Bloc<SupportEvent, SupportState> {
  final SupportRepository repository;

  SupportBloc({required this.repository}) : super(SupportInitial()) {
    on<LoadSupport>(_onLoadSupport);
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
}
