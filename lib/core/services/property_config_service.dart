import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../features/visitor_management/data/models/property_config.dart';
import '../config/env_config.dart';
import '../network/dio_client.dart';
import '../security/secure_storage_service.dart';

class PropertyConfigService extends ChangeNotifier {
  final AsmitaDioClient dioClient;
  final SecureStorageService secureStorage;

  PropertyConfig? _currentConfig;
  bool _isLoading = false;

  PropertyConfigService({
    required this.dioClient,
    required this.secureStorage,
  });

  PropertyConfig get currentConfig =>
      _currentConfig ?? PropertyConfig.defaultResidential();

  bool get isLoading => _isLoading;

  Future<PropertyConfig> loadConfigForSociety(int societyId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _currentConfig != null && _currentConfig!.societyId == societyId) {
      return _currentConfig!;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await dioClient.dio.get(
        EnvConfig.propertyVisitorConfig(societyId),
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : jsonDecode(response.data.toString());

        _currentConfig = PropertyConfig.fromJson(data);
        _isLoading = false;
        notifyListeners();
        return _currentConfig!;
      }
    } catch (e) {
      debugPrint('PropertyConfigService: Failed to fetch online config ($e). Using fallback.');
    }

    // Default fallback
    _currentConfig = PropertyConfig.defaultResidential(societyId: societyId);
    _isLoading = false;
    notifyListeners();
    return _currentConfig!;
  }

  void updateConfig(PropertyConfig config) {
    _currentConfig = config;
    notifyListeners();
  }

  /// Real-time cache invalidation (R5).
  /// Clears `_currentConfig` and forces a fresh network fetch from the backend.
  Future<PropertyConfig?> invalidateCache([int? societyId]) async {
    final targetId = societyId ?? _currentConfig?.societyId;
    _currentConfig = null;
    notifyListeners();
    if (targetId != null) {
      return loadConfigForSociety(targetId, forceRefresh: true);
    }
    return null;
  }
}
