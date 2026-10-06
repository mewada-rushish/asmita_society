import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/history_request_model.dart';
import '../data/repositories/history_request_repository.dart';
import 'historyrequest_event.dart';
import 'historyrequest_state.dart';

class HistoryRequestBloc extends Bloc<HistoryRequestEvent, HistoryRequestState> {
  final HistoryRequestRepository repository;

  HistoryRequestBloc({required this.repository}) : super(HistoryRequestInitial()) {
    on<LoadHistoryRequest>(_onLoadHistoryRequest);
    on<ApproveRequest>(_onApproveRequest);
  }

  Future<void> _onLoadHistoryRequest(LoadHistoryRequest event, Emitter<HistoryRequestState> emit) async {
    if (event.showLoading) emit(HistoryRequestLoading());
    try {
      final items = await repository.getIncomingRequests();
      emit(HistoryRequestLoaded(items));
    } catch (e) {
      emit(HistoryRequestError(e.toString()));
    }
  }

  Future<void> _onApproveRequest(ApproveRequest event, Emitter<HistoryRequestState> emit) async {
    try {
      final success = await repository.approveRequest(event.id, event.startDate, event.endDate);
      if (success && state is HistoryRequestLoaded) {
        final currentItems = (state as HistoryRequestLoaded).items;
        final updatedItems = currentItems.map((r) {
          if (r.id == event.id) {
            return HistoryRequestModel(
              id: r.id,
              ownerUserId: r.ownerUserId,
              ownerName: r.ownerName,
              status: 'APPROVED',
              createdAt: r.createdAt,
            );
          }
          return r;
        }).toList();
        emit(HistoryRequestLoaded(updatedItems));
      }
    } catch (e) {
      // Don't emit error to avoid taking down the whole list view, maybe a specific event or log
    }
  }
}
