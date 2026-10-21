import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../models/industrial_visit_model.dart';

class IndustrialVisitRepository {
  final Dio dio;

  IndustrialVisitRepository({required this.dio});

  /// Fetches industrial visit requests with optional filters and merges pre-approved VIP invites
  Future<List<IndustrialVisitModel>> getVisits({
    String? status,
    String? arrivalMode,
    int? departmentId,
    int? hostUserId,
    int? propertyId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (propertyId != null) queryParams['property_id'] = propertyId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (arrivalMode != null && arrivalMode.isNotEmpty) queryParams['arrival_mode'] = arrivalMode;
      if (departmentId != null) queryParams['department_id'] = departmentId;
      if (hostUserId != null) queryParams['host_user_id'] = hostUserId;

      // Query both industrial visits and resident pre-approved VIP invites
      final results = await Future.wait([
        dio.get(
          EnvConfig.industrialVisits,
          queryParameters: queryParams,
        ).catchError((e) {
          debugPrint('[IndustrialVisitRepository] visits error: $e');
          return Response(requestOptions: RequestOptions(), statusCode: 500);
        }),
        dio.get(
          EnvConfig.myPreApprovedInvites,
        ).catchError((e) {
          debugPrint('[IndustrialVisitRepository] pre-approved invites error: $e');
          return Response(requestOptions: RequestOptions(), statusCode: 500);
        }),
      ]);

      final visitResp = results[0];
      final inviteResp = results[1];

      final List<IndustrialVisitModel> visits = [];
      final Set<String> seenKeys = {};

      if (visitResp.statusCode == 200 && visitResp.data != null) {
        final data = visitResp.data;
        final list = (data['data'] ?? data['visits'] ?? (data is List ? data : [])) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final v = IndustrialVisitModel.fromJson(item);
            visits.add(v);
            if (v.passCode != null && v.passCode!.isNotEmpty) {
              seenKeys.add(v.passCode!);
            }
            seenKeys.add('REQ-${v.id}');
          }
        }
      }

      if (inviteResp.statusCode == 200 && inviteResp.data != null) {
        final data = inviteResp.data;
        final list = (data['invites'] ?? data['data'] ?? (data is List ? data : [])) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final passCode = item['pass_code']?.toString();
            final id = int.tryParse(item['id']?.toString() ?? '') ?? 0;
            if (passCode != null && seenKeys.contains(passCode)) continue;
            if (seenKeys.contains('REQ-$id')) continue;

            final rawStatus = item['status']?.toString().toLowerCase();
            IndustrialVisitStatus vStatus = IndustrialVisitStatus.approved;
            if (rawStatus == 'used' || rawStatus == 'inside') {
              vStatus = IndustrialVisitStatus.checkedIn;
            } else if (rawStatus == 'cancelled' || rawStatus == 'expired') {
              vStatus = IndustrialVisitStatus.rejected;
            }

            final name = (item['visitor_name'] != null && item['visitor_name'].toString().trim().isNotEmpty)
                ? item['visitor_name'].toString().trim()
                : (item['company_name'] ?? item['title'] ?? 'VIP Guest').toString();

            visits.add(IndustrialVisitModel(
              id: id,
              requestNumber: 'VIP-${passCode ?? id}',
              propertyId: int.tryParse(item['society_id']?.toString() ?? '') ?? (propertyId ?? 115),
              visitorName: name,
              visitorMobile: item['mobile_number']?.toString(),
              arrivalMode: 'PEDESTRIAN',
              vehicleNumber: item['vehicle_number']?.toString(),
              status: vStatus,
              statusToken: item['qr_code']?.toString(),
              passCode: passCode,
              passCodeExpiresAt: DateTime.tryParse(item['valid_to']?.toString() ?? ''),
              purpose: item['purpose']?.toString() ?? item['title']?.toString() ?? 'VIP Visit',
              deliveryCompany: item['company_name']?.toString() ?? 'VIP Guest',
              departmentName: 'Executive Suite',
              notes: '${item['invite_type'] ?? "Guest"} Pass',
              createdAt: DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now(),
              checkInAt: rawStatus == 'used' ? DateTime.tryParse(item['updated_at']?.toString() ?? '') : null,
              isPreApproved: true,
            ));
          }
        }
      }

      visits.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      return visits;
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
    int? propertyId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'vehicle_number': vehicleNumber,
        'visitor_name': visitorName,
        'gate_id': gateId,
      };
      if (propertyId != null) payload['property_id'] = propertyId;

      final response = await dio.post(
        EnvConfig.industrialGuardDraft,
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] createVehicleDraft error: $e');
      rethrow;
    }
  }

  /// Lists active vehicle draft slips at Gate 2
  Future<List<dynamic>> getActiveVehicleDrafts({int? propertyId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (propertyId != null) queryParams['property_id'] = propertyId;

      final response = await dio.get(
        EnvConfig.industrialGuardDrafts,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
    int? propertyId,
    int gateId = 1,
  }) async {
    try {
      final payload = <String, dynamic>{
        'delivery_company': deliveryCompany,
        'recipient_name': recipientName,
        'recipient_user_id': recipientUserId,
        'photo_base64': photoBase64,
        'gate_id': gateId,
      };
      if (propertyId != null) payload['property_id'] = propertyId;

      final response = await dio.post(
        EnvConfig.industrialDelivery,
        data: payload,
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
  Future<Map<String, dynamic>> clockInDuty({required int gateId, int? propertyId}) async {
    try {
      final payload = <String, dynamic>{
        'gate_id': gateId,
      };
      if (propertyId != null) payload['property_id'] = propertyId;

      final response = await dio.post(
        EnvConfig.industrialGuardClockIn,
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] clockInDuty error: $e');
      rethrow;
    }
  }

  /// Guard Duty Clock-Out
  Future<Map<String, dynamic>> clockOutDuty({int? propertyId}) async {
    try {
      final payload = <String, dynamic>{};
      if (propertyId != null) payload['property_id'] = propertyId;

      final response = await dio.post(
        EnvConfig.industrialGuardClockOut,
        data: payload.isNotEmpty ? payload : null,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] clockOutDuty error: $e');
      rethrow;
    }
  }

  /// Fetches industrial property settings
  Future<Map<String, dynamic>> getSettings({int? propertyId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (propertyId != null) queryParams['property_id'] = propertyId;

      final response = await dio.get(
        EnvConfig.industrialSettings,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
    int? propertyId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'enabled': enabled,
        'duration_minutes': durationMinutes,
      };
      if (reason != null) payload['reason'] = reason;
      if (propertyId != null) payload['property_id'] = propertyId;

      final response = await dio.post(
        EnvConfig.industrialOutageMode,
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[IndustrialVisitRepository] setOutageMode error: $e');
      rethrow;
    }
  }

  static String get baseUrl => EnvConfig.baseUrl;
}
