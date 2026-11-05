import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/preferences_repository.dart';
import '../data/models/user_preferences_model.dart';
import 'preferences_event.dart';
import 'preferences_state.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final PreferencesRepository repository;

  PreferencesBloc({
    required this.repository,
    PreferencesState? initialState,
  }) : super(initialState ?? PreferencesLoaded(repository.getInitialPreferences())) {
    on<LoadPreferences>(_onLoadPreferences);
    on<UpdatePreferences>(_onUpdatePreferences);
  }

  Future<void> _onLoadPreferences(LoadPreferences event, Emitter<PreferencesState> emit) async {
    // If not showing loading and we don't have loaded preferences, show loading
    if (event.showLoading && state is! PreferencesLoaded) {
      emit(PreferencesLoading());
    }

    // Hydrate from secure storage first in case local storage was unseeded
    try {
      final localHydrated = await repository.hydrateFromSecureStorage();
      if (state is! PreferencesLoaded || (state as PreferencesLoaded).items?.appTheme != localHydrated.appTheme) {
        emit(PreferencesLoaded(localHydrated));
      }
    } catch (_) {}

    try {
      final item = await repository.getPreferences();
      emit(PreferencesLoaded(item ?? repository.getInitialPreferences()));
    } catch (e) {
      if (state is! PreferencesLoaded) {
        emit(PreferencesError(e.toString()));
      }
    }
  }

  Future<void> _onUpdatePreferences(UpdatePreferences event, Emitter<PreferencesState> emit) async {
    try {
      final current = state is PreferencesLoaded
          ? (state as PreferencesLoaded).items
          : repository.getInitialPreferences();

      final updated = UserPreferencesModel(
        id: current?.id ?? 0,
        pushNotifications: event.pushNotifications ?? current?.pushNotifications ?? true,
        emailAlerts: event.emailAlerts ?? current?.emailAlerts ?? false,
        language: event.language ?? current?.language ?? 'English',
        appTheme: event.appTheme ?? current?.appTheme ?? 'System Default',
        biometricLogin: event.biometricLogin ?? current?.biometricLogin ?? false,
        approvalSound: current?.approvalSound ?? 'asmita_alert_1',
        notificationSound: current?.notificationSound ?? 'asmita_notification_1',
      );

      // 1. Immediately persist locally (Hive & SecureStorage) for cold-start persistence
      repository.saveToLocalCache(updated);

      // 2. Optimistically emit state immediately before network call (0ms switching latency)
      emit(PreferencesLoaded(updated));

      // 3. Fire asynchronous remote network PUT in background
      final Map<String, dynamic> data = {};
      if (event.pushNotifications != null) data['push_notifications'] = event.pushNotifications;
      if (event.emailAlerts != null) data['email_alerts'] = event.emailAlerts;
      if (event.language != null) data['language'] = event.language;
      if (event.appTheme != null) data['app_theme'] = event.appTheme;
      if (event.biometricLogin != null) data['biometric_login'] = event.biometricLogin;

      await repository.updatePreferences(data);
    } catch (e) {
      debugPrint('Background preferences network sync error: $e');
    }
  }
}

