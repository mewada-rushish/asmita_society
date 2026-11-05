import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/user_preferences_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:flutter/foundation.dart';

class PreferencesRepository {
  final Dio dio;
  final SecureStorageService _secureStorage;
  UserPreferencesModel? _cachedPreferences;

  PreferencesRepository({
    required this.dio,
    SecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorageService();

  /// Synchronously hydrates preferences from local encrypted storage (Hive app_cache)
  /// or returns the current in-memory cache to guarantee zero cold-start flicker.
  UserPreferencesModel getInitialPreferences() {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    String? cachedTheme;
    String? cachedLanguage;
    bool cachedBiometric = false;
    bool cachedPush = true;
    bool cachedEmail = false;
    String cachedApprovalSound = 'asmita_alert_1';
    String cachedNotifSound = 'asmita_notification_1';

    if (Hive.isBoxOpen('app_cache')) {
      final box = Hive.box('app_cache');
      cachedTheme = box.get('pref_app_theme') as String?;
      cachedLanguage = box.get('pref_language') as String?;
      cachedBiometric = (box.get('pref_biometric_login') as bool?) ?? false;
      cachedPush = (box.get('pref_push_notifications') as bool?) ?? true;
      cachedEmail = (box.get('pref_email_alerts') as bool?) ?? false;
      cachedApprovalSound = (box.get('pref_approval_sound') as String?) ?? 'asmita_alert_1';
      cachedNotifSound = (box.get('pref_notification_sound') as String?) ?? 'asmita_notification_1';
    }

    _cachedPreferences = UserPreferencesModel(
      id: 0,
      appTheme: cachedTheme ?? 'System Default',
      language: cachedLanguage ?? 'English',
      biometricLogin: cachedBiometric,
      pushNotifications: cachedPush,
      emailAlerts: cachedEmail,
      approvalSound: cachedApprovalSound,
      notificationSound: cachedNotifSound,
    );

    return _cachedPreferences!;
  }

  /// Instantly saves preferences to both in-memory cache and local storage (Hive & SecureStorage).
  void saveToLocalCache(UserPreferencesModel preferences) {
    _cachedPreferences = preferences;

    if (Hive.isBoxOpen('app_cache')) {
      final box = Hive.box('app_cache');
      box.put('pref_app_theme', preferences.appTheme);
      box.put('pref_language', preferences.language);
      box.put('pref_biometric_login', preferences.biometricLogin);
      box.put('pref_push_notifications', preferences.pushNotifications);
      box.put('pref_email_alerts', preferences.emailAlerts);
      box.put('pref_approval_sound', preferences.approvalSound);
      box.put('pref_notification_sound', preferences.notificationSound);
    }

    // Persist to hardware-backed secure storage in the background
    _secureStorage.saveAppTheme(preferences.appTheme);
    _secureStorage.saveLanguage(preferences.language);
    _secureStorage.saveBiometricLogin(preferences.biometricLogin);
    _secureStorage.saveApprovalSound(preferences.approvalSound);
    _secureStorage.saveNotificationSound(preferences.notificationSound);
  }

  /// Hydrates preferences from SecureStorageService in case Hive was uninitialized.
  Future<UserPreferencesModel> hydrateFromSecureStorage() async {
    try {
      final storedTheme = await _secureStorage.getAppTheme();
      final storedLang = await _secureStorage.getLanguage();
      final storedBio = await _secureStorage.getBiometricLogin();
      final storedApprovalSound = await _secureStorage.getApprovalSound();
      final storedNotifSound = await _secureStorage.getNotificationSound();

      final current = getInitialPreferences();
      final updated = UserPreferencesModel(
        id: current.id,
        pushNotifications: current.pushNotifications,
        emailAlerts: current.emailAlerts,
        language: storedLang ?? current.language,
        appTheme: storedTheme ?? current.appTheme,
        biometricLogin: storedBio,
        approvalSound: storedApprovalSound,
        notificationSound: storedNotifSound,
      );

      saveToLocalCache(updated);
      return updated;
    } catch (_) {
      return getInitialPreferences();
    }
  }

  Future<UserPreferencesModel?> getPreferences() async {
    try {
      final response = await dio.get(EnvConfig.userPreferences);
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        UserPreferencesModel? model;
        if (data is Map) {
          if (data['data'] is Map) {
            model = UserPreferencesModel.fromJson(
              Map<String, dynamic>.from(data['data'] as Map),
            );
          } else {
            model = UserPreferencesModel.fromJson(
              Map<String, dynamic>.from(data),
            );
          }
        }
        if (model != null) {
          saveToLocalCache(model);
          return model;
        }
      }
      return getInitialPreferences();
    } catch (e) {
      debugPrint('Error fetching preferences: $e');
      return getInitialPreferences();
    }
  }

  Future<bool> updatePreferences(Map<String, dynamic> data) async {
    try {
      final response = await dio.put(
        EnvConfig.userPreferences,
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Error updating preferences: \${e.response?.statusCode} \${e.response?.data}');
      } else {
        debugPrint('Error updating preferences: \$e');
      }
      return false;
    }
  }
}
