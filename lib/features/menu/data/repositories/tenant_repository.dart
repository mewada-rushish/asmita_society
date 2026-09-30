import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/tenant_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class TenantRepository {
  final Dio dio;

  TenantRepository({required this.dio});

  Future<List<TenantModel>> getTenants() async {
    try {
      final response = await dio.get(EnvConfig.tenants);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        final members = rawList.map((e) => TenantModel.fromJson(e)).toList();
        saveToCache(members);
        return members;
      }
      return getCachedTenants();
    } catch (e) {
      debugPrint('Error fetching tenants: $e');
      return getCachedTenants();
    }
  }

  List<TenantModel> getCachedTenants() {
    final cached = Hive.box('app_cache').get('tenants');
    if (cached != null) {
      try {
        final List<dynamic> rawList = cached;
        return rawList.map((e) => TenantModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        debugPrint('Error parsing cached tenants: $e');
      }
    }
    return [];
  }

  void saveToCache(List<TenantModel> members) {
    // Save only members with valid backend IDs (exclude injected primary member)
    final cacheableMembers = members.where((m) => m.id > 0).toList();
    Hive.box('app_cache').put('tenants', cacheableMembers.map((e) => e.toJson()).toList());
  }

  Future<TenantModel?> addTenant({
    required String name,
    required String relationship,
    String? contactNumber,
    bool isEmergencyContact = false,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.tenants,
        data: {
          'name': name,
          'relationship': relationship,
          'contact_number': contactNumber,
          'is_emergency_contact': isEmergencyContact,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TenantModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error adding family member: $e');
      return null;
    }
  }

  Future<bool> updateTenant(int id, {
    required String name,
    required String relationship,
    String? contactNumber,
    required bool isEmergencyContact,
  }) async {
    try {
      final response = await dio.put(
        '${EnvConfig.tenants}/$id',
        data: {
          'name': name,
          'relationship': relationship,
          'contact_number': contactNumber,
          'is_emergency_contact': isEmergencyContact,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating family member: $e');
      return false;
    }
  }

  Future<bool> deleteTenant(int id) async {
    try {
      final response = await dio.delete('${EnvConfig.tenants}/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting family member: $e');
      return false;
    }
  }

  Future<bool> requestHistoryAccess(int tenantId) async {
    try {
      final response = await dio.post(
        '${EnvConfig.tenants}/history-requests',
        data: {'tenant_id': tenantId},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error requesting history access: $e');
      return false;
    }
  }
}
