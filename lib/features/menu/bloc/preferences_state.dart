import 'package:equatable/equatable.dart';
import '../data/models/user_preferences_model.dart';

abstract class PreferencesState extends Equatable {
  const PreferencesState();
  @override
  List<Object?> get props => [];
}

class PreferencesInitial extends PreferencesState {}

class PreferencesLoading extends PreferencesState {}

class PreferencesLoaded extends PreferencesState {
  final UserPreferencesModel? items;
  const PreferencesLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class PreferencesError extends PreferencesState {
  final String message;
  const PreferencesError(this.message);
  @override
  List<Object?> get props => [message];
}
