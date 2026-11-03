import 'package:equatable/equatable.dart';
import '../data/models/history_request_model.dart';

abstract class HistoryRequestState extends Equatable {
  const HistoryRequestState();
  @override
  List<Object?> get props => [];
}

class HistoryRequestInitial extends HistoryRequestState {}

class HistoryRequestLoading extends HistoryRequestState {}

class HistoryRequestLoaded extends HistoryRequestState {
  final List<HistoryRequestModel> items;
  const HistoryRequestLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class HistoryRequestError extends HistoryRequestState {
  final String message;
  const HistoryRequestError(this.message);
  @override
  List<Object?> get props => [message];
}
