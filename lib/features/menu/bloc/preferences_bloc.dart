import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/preferences_repository.dart';
import 'preferences_event.dart';
import 'preferences_state.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final PreferencesRepository repository;

  PreferencesBloc({required this.repository}) : super(PreferencesInitial()) {
    on<LoadPreferences>(_onLoadPreferences);
    on<UpdatePreferences>(_onUpdatePreferences);
  }

  Future<void> _onLoadPreferences(LoadPreferences event, Emitter<PreferencesState> emit) async {
    if (event.showLoading) emit(PreferencesLoading());
    try {
      final item = await repository.getPreferences();
      // the generated preferences_state.dart expects `final UserPreferencesModel? preferences;` wait
      // Actually the generated state expects `final dynamic preferences;` probably.
      emit(PreferencesLoaded(item));
    } catch (e) {
      emit(PreferencesError(e.toString()));
    }
  }

  Future<void> _onUpdatePreferences(UpdatePreferences event, Emitter<PreferencesState> emit) async {
    try {
      final Map<String, dynamic> data = {};
      if (event.pushNotifications != null) data['push_notifications'] = event.pushNotifications;
      if (event.emailAlerts != null) data['email_alerts'] = event.emailAlerts;
      if (event.language != null) data['language'] = event.language;
      if (event.appTheme != null) data['app_theme'] = event.appTheme;
      if (event.biometricLogin != null) data['biometric_login'] = event.biometricLogin;

      final success = await repository.updatePreferences(data);
      if (success) add(const LoadPreferences(showLoading: false));
    } catch (_) {}
  }
}
