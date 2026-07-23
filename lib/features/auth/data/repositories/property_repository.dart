import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';
import '../models/property_models.dart';

class PropertyRepository {
  final Dio _dio;

  PropertyRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<PropertyItem>> getSocieties() async {
    try {
      final response = await _dio.get(EnvConfig.societies);
      final data = _ensureMap(response.data);
      if (data['success'] == true) {
        final items = data['data'] as List;
        return items.map((e) => PropertyItem.fromJson(e, 'society_id', 'society_name')).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<PropertyItem>> getTowers(int societyId) async {
    try {
      final response = await _dio.get(EnvConfig.towers, queryParameters: {'society_id': societyId});
      final data = _ensureMap(response.data);
      if (data['success'] == true) {
        final items = data['data'] as List;
        return items.map((e) => PropertyItem.fromJson(e, 'tower_id', 'tower_name')).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<PropertyItem>> getFloors(int towerId) async {
    try {
      final response = await _dio.get(EnvConfig.floors, queryParameters: {'tower_id': towerId});
      final data = _ensureMap(response.data);
      if (data['success'] == true) {
        final items = data['data'] as List;
        return items.map((e) => PropertyItem.fromJson(e, 'floor_id', 'floor_number')).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<PropertyItem>> getFlats(int floorId) async {
    try {
      final response = await _dio.get(EnvConfig.flats, queryParameters: {'floor_id': floorId});
      final data = _ensureMap(response.data);
      if (data['success'] == true) {
        final items = data['data'] as List;
        return items.map((e) => PropertyItem.fromJson(e, 'flat_id', 'flat_number')).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> linkFlat(int flatId, String role) async {
    try {
      final response = await _dio.post(
        EnvConfig.linkFlat,
        data: {'flat_id': flatId, 'role': role},
      );
      final data = _ensureMap(response.data);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to link property');
      }
    } catch (e) {
      if (e is DioException) {
        final errorData = _ensureMap(e.response?.data);
        throw Exception(errorData['message'] ?? 'Network error occurred');
      }
      throw Exception(e.toString());
    }
  }

  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }
}
