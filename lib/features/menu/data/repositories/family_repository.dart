import 'package:dio/dio.dart';
import '../models/family_member_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class FamilyRepository {
  final Dio dio;

  FamilyRepository({required this.dio});

  Future<List<FamilyMemberModel>> getFamilyMembers() async {
    try {
      final response = await dio.get(EnvConfig.familyMembers);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        return rawList.map((e) => FamilyMemberModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching family members: $e');
      return [];
    }
  }

  Future<FamilyMemberModel?> addFamilyMember({
    required String name,
    required String relationship,
    String? contactNumber,
    bool isEmergencyContact = false,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.familyMembers,
        data: {
          'name': name,
          'relationship': relationship,
          'contact_number': contactNumber,
          'is_emergency_contact': isEmergencyContact,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return FamilyMemberModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error adding family member: $e');
      return null;
    }
  }

  Future<bool> updateFamilyMember(int id, {
    required String name,
    required String relationship,
    String? contactNumber,
    required bool isEmergencyContact,
  }) async {
    try {
      final response = await dio.put(
        '${EnvConfig.familyMembers}/$id',
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

  Future<bool> deleteFamilyMember(int id) async {
    try {
      final response = await dio.delete('${EnvConfig.familyMembers}/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting family member: $e');
      return false;
    }
  }
}
