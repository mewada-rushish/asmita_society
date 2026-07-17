import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/visitor_repository.dart';
import 'visitor_event.dart';
import 'visitor_state.dart';

class VisitorBloc extends Bloc<VisitorEvent, VisitorState> {
  final VisitorRepository visitorRepository;

  VisitorBloc({required this.visitorRepository}) : super(VisitorInitial()) {
    on<LoadMyHistory>(_onLoadMyHistory);
    on<CreatePreApprovedInviteEvent>(_onCreatePreApprovedInvite);
  }

  Future<void> _onLoadMyHistory(LoadMyHistory event, Emitter<VisitorState> emit) async {
    if (!event.isRefresh) {
      emit(VisitorLoading());
    }
    try {
      final history = await visitorRepository.getMyHistory(event.residentId);
      emit(VisitorHistoryLoaded(history: history));
    } catch (e) {
      emit(VisitorError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreatePreApprovedInvite(CreatePreApprovedInviteEvent event, Emitter<VisitorState> emit) async {
    emit(VisitorLoading());
    try {
      final invite = await visitorRepository.createPreApprovedInvite(event.payload);
      emit(VisitorCreateSuccess(invite: invite));
    } catch (e) {
      emit(VisitorError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
