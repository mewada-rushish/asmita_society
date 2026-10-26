import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  FutureOr<UserPreferencesModel?> build() async {
    // 1. Instantly load local cached settings so app startup is never blocked
    final localBiometric = await _secureStorage.getBiometricLogin();
    final localLanguage = await _secureStorage.getLanguage();
    final localTheme = await _secureStorage.getAppTheme();
    final localApprovalSound = await _secureStorage.getApprovalSound();
    final localNotifSound = await _secureStorage.getNotificationSound();

    // 2. Asynchronously sync fresh preferences from remote in the background
    unawaited(_syncRemotePreferences());

    return UserPreferencesModel(
      id: 0,
      pushNotifications: true,
      emailAlerts: false,
      language: localLanguage ?? 'English',
      appTheme: localTheme ?? 'System Default',
      biometricLogin: localBiometric,
      approvalSound: localApprovalSound,
      notificationSound: localNotifSound,
    );
  }

  Future<void> _syncRemotePreferences() async {
    try {
      final prefs = await _repository.getPreferences();
      if (prefs != null) {
        await _secureStorage.saveLanguage(prefs.language);
        await _secureStorage.saveAppTheme(prefs.appTheme);
        await _secureStorage.saveBiometricLogin(prefs.biometricLogin);

        final localApprovalSound = await _secureStorage.getApprovalSound();
        final localNotifSound = await _secureStorage.getNotificationSound();

        state = AsyncValue.data(
          UserPreferencesModel(
            id: prefs.id,
            pushNotifications: prefs.pushNotifications,
            emailAlerts: prefs.emailAlerts,
            language: prefs.language,
            appTheme: prefs.appTheme,
            biometricLogin: prefs.biometricLogin,
            approvalSound: localApprovalSound,
            notificationSound: localNotifSound,
          ),
        );
      }
    } catch (e) {
      debugPrint('Background preferences sync error: $e');
    }
  }

  Future<void> fetchPreferences() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _repository.getPreferences();
      final localApprovalSound = await _secureStorage.getApprovalSound();
      final localNotifSound = await _secureStorage.getNotificationSound();
      state = AsyncValue.data(
        UserPreferencesModel(
          id: prefs?.id ?? 0,
          pushNotifications: prefs?.pushNotifications ?? true,
          emailAlerts: prefs?.emailAlerts ?? false,
          language: prefs?.language ?? 'English',
          appTheme: prefs?.appTheme ?? 'System Default',
          biometricLogin: prefs?.biometricLogin ?? false,
          approvalSound: localApprovalSound,
          notificationSound: localNotifSound,
        ),
      );
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
    String? approvalSound,
    String? notificationSound,
  }) async {
    final current = state.value;
    if (current == null) return false;

    if (approvalSound != null) {
      await _secureStorage.saveApprovalSound(approvalSound);
    }
    if (notificationSound != null) {
      await _secureStorage.saveNotificationSound(notificationSound);
    }
    if (biometricLogin != null) {
      await _secureStorage.saveBiometricLogin(biometricLogin);
    }
    if (language != null) {
      await _secureStorage.saveLanguage(language);
    }
    if (appTheme != null) {
      await _secureStorage.saveAppTheme(appTheme);
    }

    final updated = UserPreferencesModel(
      id: current.id,
      pushNotifications: pushNotifications ?? current.pushNotifications,
      emailAlerts: emailAlerts ?? current.emailAlerts,
      language: language ?? current.language,
      appTheme: appTheme ?? current.appTheme,
      biometricLogin: biometricLogin ?? current.biometricLogin,
      approvalSound: approvalSound ?? current.approvalSound,
      notificationSound: notificationSound ?? current.notificationSound,
    );

    // Optimistic UI Update
    state = AsyncValue.data(updated);

    final success = await _repository.updatePreferences({
      'push_notifications': updated.pushNotifications,
      'email_alerts': updated.emailAlerts,
      'language': updated.language,
      'app_theme': updated.appTheme,
      'biometric_login': updated.biometricLogin,
      'approval_sound': updated.approvalSound,
      'notification_sound': updated.notificationSound,
    });

    if (!success) {
      // Keep optimistic sound preference stored locally
    }
    return true;
  }
}
