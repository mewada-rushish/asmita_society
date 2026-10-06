import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/history_request_repository.dart';
import 'historyrequest_event.dart';
import 'historyrequest_state.dart';

class HistoryRequestBloc extends Bloc<HistoryRequestEvent, HistoryRequestState> {
  final HistoryRequestRepository repository;

  HistoryRequestBloc({required this.repository}) : super(HistoryRequestInitial()) {
    on<LoadHistoryRequest>(_onLoadHistoryRequest);
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
}
