import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/visitor_repository.dart';
import 'visitor_event.dart';
import 'visitor_state.dart';

class VisitorBloc extends Bloc<VisitorEvent, VisitorState> {
  final VisitorRepository visitorRepository;

  VisitorBloc({required this.visitorRepository}) : super(VisitorInitial()) {
    on<LoadMyHistory>(_onLoadMyHistory);
    on<CreatePreApprovedInviteEvent>(_onCreatePreApprovedInvite);
<<<<<<< HEAD
=======
    on<ClearVisitorHistory>((event, emit) => emit(VisitorInitial()));
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
  }

  Future<void> _onLoadMyHistory(LoadMyHistory event, Emitter<VisitorState> emit) async {
    if (!event.isRefresh) {
      emit(VisitorLoading());
    }
    try {
<<<<<<< HEAD
      final history = await visitorRepository.getMyHistory(event.residentId);
=======
      final history = await visitorRepository.getMyHistory(
        residentId: event.residentId,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        visitorTypeId: event.visitorTypeId,
      );
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
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
      if (event.payload['resident_id'] != null) {
        add(LoadMyHistory(residentId: event.payload['resident_id'] as int, isRefresh: true));
      }
    } catch (e) {
      emit(VisitorError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
