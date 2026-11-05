import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';

/// Repository responsible for creating onboarding team member invites,
/// querying delegation status, and fetching society departments.
class TeamInviteRepository {
  final Dio _dio;

  TeamInviteRepository({Dio? dio, SecureStorageService? secureStorage})
      : _dio = dio ?? AsmitaDioClient(secureStorage ?? SecureStorageService()).dio;

  /// Generates a new onboarding invite token and dispatches DLT SMS if phone is provided.
  /// Calls `POST EnvConfig.generateInvite`.
  Future<Map<String, dynamic>> generateInvite({
    required int societyId,
    required String targetRole,
    int? departmentId,
    String? departmentName,
    String? recipientName,
    String? recipientPhone,
    String tokenType = 'ONBOARDING',
    int maxUsage = 1,
    int validityHours = 168,
    int? targetUnitId,
    Map<String, dynamic>? additionalPayload,
  }) async {
    try {
      final payload = <String, dynamic>{
        'token_type': tokenType,
        'society_id': societyId,
        'target_role': targetRole,
        'max_usage': maxUsage,
        'validity_hours': validityHours,
        'department_id': ?departmentId,
        if (departmentName != null && departmentName.trim().isNotEmpty)
          'department_name': departmentName.trim(),
        if (recipientName != null && recipientName.trim().isNotEmpty)
          'recipient_name': recipientName.trim(),
        if (recipientPhone != null && recipientPhone.trim().isNotEmpty)
          'recipient_phone': recipientPhone.trim(),
        'target_unit_id': ?targetUnitId,
      };

      if (additionalPayload != null) {
        payload['payload_json'] = additionalPayload;
      }

      final response = await _dio.post(
        EnvConfig.generateInvite,
        data: payload,
      );

      final data = response.data;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data is Map &&
          data['success'] == true) {
        return Map<String, dynamic>.from(data);
      } else {
        final message = (data is Map ? data['message'] : null) ?? 'Failed to generate invite';
        throw Exception(message.toString());
      }
    } on DioException catch (e) {
      String msg = 'Network error while generating invite';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          final data = e.response!.data as Map;
          msg = data['message']?.toString() ??
              data['error']?.toString() ??
              msg;
        } else {
          msg = e.response!.data.toString();
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = e.message!;
      }
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error generating invite: $e');
    }
  }

  /// Queries current user delegation status to check active incoming delegations.
  /// Calls `GET EnvConfig.employeeDelegationStatus`.
  Future<Map<String, dynamic>?> getDelegationStatus({required int societyId}) async {
    try {
      final response = await _dio.get(
        EnvConfig.employeeDelegationStatus,
        queryParameters: {'society_id': societyId},
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[TeamInviteRepository] Delegation status error: $e');
      return null;
    } catch (e) {
      debugPrint('[TeamInviteRepository] Delegation status unexpected error: $e');
      return null;
    }
  }

  /// Fetches active departments in the society.
  /// Calls `GET $baseUrl/api/public/visitor/departments?society_id=$societyId`.
  Future<List<Map<String, dynamic>>> getSocietyDepartments(int societyId) async {
    try {
      final response = await _dio.get(
        '${EnvConfig.baseUrl}/api/public/visitor/departments',
        queryParameters: {'society_id': societyId},
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final List<dynamic> list =
            response.data['departments'] ?? response.data['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[TeamInviteRepository] Society departments error: $e');
      return [];
    } catch (e) {
      debugPrint('[TeamInviteRepository] Society departments unexpected error: $e');
      return [];
    }
  }
}
