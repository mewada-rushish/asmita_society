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
