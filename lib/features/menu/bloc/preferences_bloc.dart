import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/preferences_repository.dart';
import 'preferences_event.dart';
import 'preferences_state.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final PreferencesRepository repository;

  PreferencesBloc({required this.repository}) : super(PreferencesInitial()) {
    on<LoadPreferences>(_onLoadPreferences);
  }

  Future<void> _onLoadPreferences(LoadPreferences event, Emitter<PreferencesState> emit) async {
    if (event.showLoading) emit(PreferencesLoading());
    try {
      final items = await repository.getPreferences();
      emit(PreferencesLoaded(items));
    } catch (e) {
      emit(PreferencesError(e.toString()));
    }
  }
}
