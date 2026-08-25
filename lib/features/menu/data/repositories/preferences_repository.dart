import 'package:dio/dio.dart';
import '../models/user_preferences_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class PreferencesRepository {
  final Dio dio;

  PreferencesRepository({required this.dio});

  Future<UserPreferencesModel?> getPreferences() async {
    try {
      final response = await dio.get(EnvConfig.userPreferences);
      if (response.statusCode == 200 && response.data != null) {
        return UserPreferencesModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching preferences: $e');
      return null;
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
      debugPrint('Error updating preferences: $e');
      return false;
    }
  }
}
