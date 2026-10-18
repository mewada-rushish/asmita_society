import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../models/industrial_visit_model.dart';

class IndustrialVisitRepository {
  final Dio dio;

  IndustrialVisitRepository({required this.dio});

  /// Fetches industrial visit requests with optional filters
  Future<List<IndustrialVisitModel>> getVisits({
    String? status,
    String? arrivalMode,
    int? departmentId,
    int? hostUserId,
    int propertyId = 114,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'property_id': propertyId,
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (arrivalMode != null && arrivalMode.isNotEmpty) queryParams['arrival_mode'] = arrivalMode;
      if (departmentId != null) queryParams['department_id'] = departmentId;
      if (hostUserId != null) queryParams['host_user_id'] = hostUserId;

      final response = await dio.get(
        EnvConfig.industrialVisits,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final list = (data['data'] ?? data['visits'] ?? data) as List<dynamic>;
        return list.map((item) => IndustrialVisitModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[IndustrialVisitRepository] getVisits Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] getVisits error: $e');
      rethrow;
    }
  }

  /// Gate 2: Creates a single-use vehicle draft slip
  Future<Map<String, dynamic>> createVehicleDraft({
    required String vehicleNumber,
    required String visitorName,
    required int gateId,
    int propertyId = 114,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.industrialGuardDraft,
        data: {
          'vehicle_number': vehicleNumber,
          'visitor_name': visitorName,
          'gate_id': gateId,
          'property_id': propertyId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] createVehicleDraft error: $e');
      rethrow;
    }
  }

  /// Lists active vehicle draft slips at Gate 2
  Future<List<dynamic>> getActiveVehicleDrafts({int propertyId = 114}) async {
    try {
      final response = await dio.get(
        EnvConfig.industrialGuardDrafts,
        queryParameters: {'property_id': propertyId},
      );
      final data = response.data;
      return (data['data'] ?? data['drafts'] ?? []) as List<dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] getActiveVehicleDrafts error: $e');
      rethrow;
    }
  }

  /// Gate 1 & 2: Guard delivery intake (Flow C)
  Future<IndustrialVisitModel> createDeliveryVisit({
    required String deliveryCompany,
    required String recipientName,
    int? recipientUserId,
    String? photoBase64,
    int propertyId = 114,
    int gateId = 1,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.industrialDelivery,
        data: {
          'delivery_company': deliveryCompany,
          'recipient_name': recipientName,
          'recipient_user_id': recipientUserId,
          'photo_base64': photoBase64,
          'property_id': propertyId,
          'gate_id': gateId,
        },
      );
      final data = response.data;
      final visitJson = (data['visit'] ?? data['data'] ?? data) as Map<String, dynamic>;
      return IndustrialVisitModel.fromJson(visitJson);
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] createDeliveryVisit error: $e');
      rethrow;
    }
  }

  /// Guard confirms delivery package handover moving status to COLLECTED
  Future<IndustrialVisitModel> confirmDeliveryHandover(int visitId) async {
    try {
      final response = await dio.post(EnvConfig.industrialHandover(visitId));
      final data = response.data;
      final visitJson = (data['visit'] ?? data['data'] ?? data) as Map<String, dynamic>;
      return IndustrialVisitModel.fromJson(visitJson);
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] confirmDeliveryHandover error: $e');
      rethrow;
    }
  }

  /// Host / Delegate / Floor Receptionist decides a visit (APPROVE, REJECT, ASSIGN, REASSIGN, COLLECT_AT_GATE, ALLOW_IN)
  Future<Map<String, dynamic>> handleVisitAction(
    int visitId, {
    required String action,
    int? assignedUserId,
    int? cabinId,
    int? deskId,
    String? rejectionReason,
  }) async {
    try {
      final payload = <String, dynamic>{'action': action};
      if (assignedUserId != null) payload['assigned_user_id'] = assignedUserId;
      if (cabinId != null) payload['cabin_id'] = cabinId;
      if (deskId != null) payload['desk_id'] = deskId;
      if (rejectionReason != null) payload['rejection_reason'] = rejectionReason;

      final response = await dio.patch(
        EnvConfig.industrialAction(visitId),
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] handleVisitAction error: $e');
      rethrow;
    }
  }

  /// Acknowledges an incoming visit request (adds ack_grace_minutes grace period)
  Future<Map<String, dynamic>> acknowledgeVisit(int visitId) async {
    try {
      final response = await dio.post(EnvConfig.industrialAcknowledge(visitId));
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] acknowledgeVisit error: $e');
      rethrow;
    }
  }

  /// Revokes an already approved pass code
  Future<Map<String, dynamic>> revokePass(int visitId, {required String reason}) async {
    try {
      final response = await dio.post(
        '$baseUrl/app-api/industrial/visits/$visitId/revoke',
        data: {'revocation_reason': reason},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] revokePass error: $e');
      rethrow;
    }
  }

  /// Guard Supervisor Manual Override (enforces shift cap unless outage mode is active)
  Future<IndustrialVisitModel> overrideVisit(
    int visitId, {
    required String overrideReason,
    String? photoBase64,
  }) async {
    try {
      final payload = <String, dynamic>{'override_reason': overrideReason};
      if (photoBase64 != null) payload['photo_base64'] = photoBase64;

      final response = await dio.patch(
        EnvConfig.industrialOverride(visitId),
        data: payload,
      );
      final data = response.data;
      final visitJson = (data['visit'] ?? data['data'] ?? data) as Map<String, dynamic>;
      return IndustrialVisitModel.fromJson(visitJson);
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] overrideVisit error: $e');
      rethrow;
    }
  }

  /// Gate pass verification & check-in (marks verified_on_site: true)
  Future<IndustrialVisitModel> checkInPass({
    required int visitId,
    required int gateId,
    String? passCode,
  }) async {
    try {
      final payload = <String, dynamic>{'gate_id': gateId};
      if (passCode != null) payload['pass_code'] = passCode;

      final response = await dio.patch(
        EnvConfig.industrialCheckIn(visitId),
        data: payload,
      );
      final data = response.data;
      final visitJson = (data['visit'] ?? data['data'] ?? data) as Map<String, dynamic>;
      return IndustrialVisitModel.fromJson(visitJson);
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] checkInPass error: $e');
      rethrow;
    }
  }

  /// Gate pass check-out
  Future<IndustrialVisitModel> checkOutPass({
    required int visitId,
    required int gateId,
  }) async {
    try {
      final response = await dio.patch(
        EnvConfig.industrialCheckOut(visitId),
        data: {'gate_id': gateId},
      );
      final data = response.data;
      final visitJson = (data['visit'] ?? data['data'] ?? data) as Map<String, dynamic>;
      return IndustrialVisitModel.fromJson(visitJson);
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] checkOutPass error: $e');
      rethrow;
    }
  }

  /// Guard Duty Clock-In
  Future<Map<String, dynamic>> clockInDuty({required int gateId, int propertyId = 114}) async {
    try {
      final response = await dio.post(
        EnvConfig.industrialGuardClockIn,
        data: {
          'gate_id': gateId,
          'property_id': propertyId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] clockInDuty error: $e');
      rethrow;
    }
  }

  /// Guard Duty Clock-Out
  Future<Map<String, dynamic>> clockOutDuty({int propertyId = 114}) async {
    try {
      final response = await dio.post(
        EnvConfig.industrialGuardClockOut,
        data: {'property_id': propertyId},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] clockOutDuty error: $e');
      rethrow;
    }
  }

  /// Fetches industrial property settings
  Future<Map<String, dynamic>> getSettings({int propertyId = 114}) async {
    try {
      final response = await dio.get(
        EnvConfig.industrialSettings,
        queryParameters: {'property_id': propertyId},
      );
      return (response.data['data'] ?? response.data['settings'] ?? response.data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] getSettings error: $e');
      rethrow;
    }
  }

  /// Admin Outage Mode configuration
  Future<Map<String, dynamic>> setOutageMode({
    required bool enabled,
    int durationMinutes = 60,
    String? reason,
    int propertyId = 114,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.industrialOutageMode,
        data: {
          'enabled': enabled,
          'duration_minutes': durationMinutes,
          'reason': reason,
          'property_id': propertyId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] setOutageMode error: $e');
      rethrow;
    }
  }

  static String get baseUrl => EnvConfig.baseUrl;
}
