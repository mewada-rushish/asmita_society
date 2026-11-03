import 'package:equatable/equatable.dart';

abstract class HistoryRequestEvent extends Equatable {
  const HistoryRequestEvent();
  @override
  List<Object?> get props => [];
}

class LoadHistoryRequest extends HistoryRequestEvent {
  final bool showLoading;
  const LoadHistoryRequest({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}

class ApproveRequest extends HistoryRequestEvent {
  final int id;
  final DateTime startDate;
  final DateTime endDate;

  const ApproveRequest({
    required this.id,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [id, startDate, endDate];
}