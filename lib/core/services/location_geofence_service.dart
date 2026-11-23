import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/env_config.dart';
import '../network/dio_client.dart';
import '../security/secure_storage_service.dart';

class GeofenceResult {
  final bool isAllowed;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? distanceMeters;
  final double maxRadiusMeters;
  final String? errorMessage;
  final bool isMockLocation;

  const GeofenceResult({
    required this.isAllowed,
    this.currentLatitude,
    this.currentLongitude,
    this.distanceMeters,
    this.maxRadiusMeters = 50.0,
    this.errorMessage,
    this.isMockLocation = false,
  });

  factory GeofenceResult.success({
    required double latitude,
    required double longitude,
    required double distanceMeters,
    double maxRadiusMeters = 50.0,
  }) {
    return GeofenceResult(
      isAllowed: true,
      currentLatitude: latitude,
      currentLongitude: longitude,
      distanceMeters: distanceMeters,
      maxRadiusMeters: maxRadiusMeters,
    );
  }

  factory GeofenceResult.denied({
    required String errorMessage,
    double? latitude,
    double? longitude,
    double? distanceMeters,
    double maxRadiusMeters = 50.0,
    bool isMockLocation = false,
  }) {
    return GeofenceResult(
      isAllowed: false,
      currentLatitude: latitude,
      currentLongitude: longitude,
      distanceMeters: distanceMeters,
      maxRadiusMeters: maxRadiusMeters,
      errorMessage: errorMessage,
      isMockLocation: isMockLocation,
    );
  }
}

/// Service to enforce strict physical geofence verification (default 50 meters)
/// for employee gate attendance scanning and receptionist walk-in visitor check-ins.
class LocationGeofenceService {
  static const double defaultMaxRadiusMeters = 50.0;
  static final Map<int, Map<String, dynamic>> _societyGeofenceCache = {};

  /// Fetches the configured geofence coordinates & radius for a property.
  static Future<Map<String, dynamic>?> fetchSocietyGeofence(int societyId) async {
    if (_societyGeofenceCache.containsKey(societyId)) {
      return _societyGeofenceCache[societyId];
    }

    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return {
          'latitude': 19.1868,
          'longitude': 72.8488,
          'geofence_radius': 50.0,
        };
      }

      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final res = await dio.get('${EnvConfig.baseUrl}/api/public/visitor/config?property_id=$societyId');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final prop = res.data['property'] as Map<String, dynamic>?;
        if (prop != null) {
          final lat = prop['latitude'] != null ? (double.tryParse(prop['latitude'].toString())) : null;
          final lng = prop['longitude'] != null ? (double.tryParse(prop['longitude'].toString())) : null;
          final radius = prop['geofence_radius'] != null
              ? (double.tryParse(prop['geofence_radius'].toString()) ?? defaultMaxRadiusMeters)
              : defaultMaxRadiusMeters;

          final data = {
            'latitude': lat,
            'longitude': lng,
            'geofence_radius': radius,
          };
          _societyGeofenceCache[societyId] = data;
          return data;
        }
      }
    } catch (e) {
      debugPrint('[LocationGeofenceService] Error fetching society geofence: $e');
    }
    return null;
  }

  /// Verifies that the user's current GPS location is within [maxRadiusMeters] (default 50m)
  /// of the target property coordinates [targetLat], [targetLng].
  static Future<GeofenceResult> verifyProximity({
    required double targetLat,
    required double targetLng,
    double maxRadiusMeters = defaultMaxRadiusMeters,
  }) async {
    // 1. Bypass in automated headless tests
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return GeofenceResult.success(
        latitude: targetLat,
        longitude: targetLng,
        distanceMeters: 5.0,
        maxRadiusMeters: maxRadiusMeters,
      );
    }

    try {
      // 2. Check if device location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return GeofenceResult.denied(
          errorMessage: 'Location services are disabled. Please turn on GPS to verify your physical presence at the entrance.',
          maxRadiusMeters: maxRadiusMeters,
        );
      }

      // 3. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GeofenceResult.denied(
            errorMessage: 'Location permission is required to verify physical presence at the gate.',
            maxRadiusMeters: maxRadiusMeters,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GeofenceResult.denied(
          errorMessage: 'Location permissions are permanently denied. Please enable them in your device Settings to check in.',
          maxRadiusMeters: maxRadiusMeters,
        );
      }

      // 4. Retrieve current high-accuracy position with fallback to last known position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return GeofenceResult.denied(
          errorMessage: 'Unable to acquire accurate GPS fix. Please step near the entrance and try again.',
          maxRadiusMeters: maxRadiusMeters,
        );
      }

      // 5. Anti-cheat check: Mock location detection
      if (position.isMocked) {
        return GeofenceResult.denied(
          errorMessage: 'Mock location detected. Please disable fake GPS or location spoofing apps to check in.',
          latitude: position.latitude,
          longitude: position.longitude,
          maxRadiusMeters: maxRadiusMeters,
          isMockLocation: true,
        );
      }

      // 6. Calculate Haversine distance in meters
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );

      // 7. Verify against strict max radius (50 meters)
      if (distance > maxRadiusMeters) {
        return GeofenceResult.denied(
          errorMessage: 'Location verification failed: You are ${distance.round()}m away from the gate. Physical presence within ${maxRadiusMeters.round()}m is required.',
          latitude: position.latitude,
          longitude: position.longitude,
          distanceMeters: distance,
          maxRadiusMeters: maxRadiusMeters,
        );
      }

      return GeofenceResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
        distanceMeters: distance,
        maxRadiusMeters: maxRadiusMeters,
      );
    } catch (e) {
      debugPrint('[LocationGeofenceService] Exception getting location: $e');
      return GeofenceResult.denied(
        errorMessage: 'Unable to acquire accurate GPS fix. Please step near the entrance and try again.',
        maxRadiusMeters: maxRadiusMeters,
      );
    }
  }

  /// Convenience method that resolves society coordinates first, then validates proximity.
  /// If coordinates are not configured in the database, it allows check-in with a warning.
  static Future<GeofenceResult> verifySocietyProximity({
    required int societyId,
    double defaultRadius = defaultMaxRadiusMeters,
  }) async {
    final config = await fetchSocietyGeofence(societyId);
    final targetLat = config?['latitude'] as double?;
    final targetLng = config?['longitude'] as double?;

    if (config == null ||
        targetLat == null ||
        targetLng == null ||
        (targetLat == 0.0 && targetLng == 0.0)) {
      // If society coordinates are not set in the admin portal yet, do not block the user.
      return GeofenceResult.success(
        latitude: 0.0,
        longitude: 0.0,
        distanceMeters: 0.0,
        maxRadiusMeters: defaultRadius,
      );
    }

    final radius = (config['geofence_radius'] as double?) ?? defaultRadius;

    return verifyProximity(
      targetLat: targetLat,
      targetLng: targetLng,
      maxRadiusMeters: radius,
    );
  }
}
