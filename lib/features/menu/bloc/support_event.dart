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
