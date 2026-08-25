import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/models/user_preferences_model.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(
    dio: AsmitaDioClient(SecureStorageService()).dio,
  );
});

final preferencesProvider = AsyncNotifierProvider<PreferencesNotifier, UserPreferencesModel?>(() {
  return PreferencesNotifier();
});

class PreferencesNotifier extends AsyncNotifier<UserPreferencesModel?> {
  PreferencesRepository get _repository => ref.read(preferencesRepositoryProvider);

  @override
  FutureOr<UserPreferencesModel?> build() async {
    final prefs = await _repository.getPreferences();
    return prefs ?? UserPreferencesModel(id: 0);
  }

  Future<void> fetchPreferences() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _repository.getPreferences();
      state = AsyncValue.data(prefs ?? UserPreferencesModel(id: 0));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> updatePreference({
    bool? pushNotifications,
    bool? emailAlerts,
    String? language,
    String? appTheme,
    bool? biometricLogin,
  }) async {
    final current = state.value;
    if (current == null) return false;

    final updated = UserPreferencesModel(
      id: current.id,
      pushNotifications: pushNotifications ?? current.pushNotifications,
      emailAlerts: emailAlerts ?? current.emailAlerts,
      language: language ?? current.language,
      appTheme: appTheme ?? current.appTheme,
      biometricLogin: biometricLogin ?? current.biometricLogin,
    );

    // Optimistic UI Update
    state = AsyncValue.data(updated);

    final success = await _repository.updatePreferences({
      'push_notifications': updated.pushNotifications,
      'email_alerts': updated.emailAlerts,
      'language': updated.language,
      'app_theme': updated.appTheme,
      'biometric_login': updated.biometricLogin,
    });

    if (!success) {
      // Revert on failure
      state = AsyncValue.data(current);
    }
    return success;
  }
}
