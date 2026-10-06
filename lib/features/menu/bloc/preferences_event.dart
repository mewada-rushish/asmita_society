import 'package:equatable/equatable.dart';

abstract class PreferencesEvent extends Equatable {
  const PreferencesEvent();
  @override
  List<Object?> get props => [];
}

class LoadPreferences extends PreferencesEvent {
  final bool showLoading;
  const LoadPreferences({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
