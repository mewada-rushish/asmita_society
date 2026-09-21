import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';
import '../models/invite_model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class VisitorRepository {
  final Dio _dio;

  VisitorRepository({required Dio dio}) : _dio = dio; // ignore: prefer_initializing_formals

  /// Creates a new pre-approved invite
  Future<PreApprovedInvite> createPreApprovedInvite(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        EnvConfig.preApprovedInvites,
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      if (response.statusCode == 201 && data['success'] == true) {
        return PreApprovedInvite.fromJson(data['invite']);
      } else {
        throw Exception(data['message'] ?? 'Failed to create invite');
      }
    } on DioException catch (e) {
      String msg = 'Network error';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          msg = e.response!.data['message'] ?? msg;
        } else {
          msg = e.response!.data.toString();
        }
      }
      throw Exception(msg);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Create Invite Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Fetches resident's pre-approved invites and on-the-spot visitor requests
  Future<List<dynamic>> getMyHistory({
    required int residentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? visitorTypeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': residentId,
      };
      if (status != null && status != 'ALL') queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (visitorTypeId != null) queryParams['visitor_type_id'] = visitorTypeId;

      // Fetch both simultaneously
      final responses = await Future.wait([
        _dio.get(EnvConfig.myPreApprovedInvites, queryParameters: queryParams),
        _dio.get(EnvConfig.residentVisitorRequests, queryParameters: queryParams),
      ]);

      final invitesResp = responses[0];
      final requestsResp = responses[1];
      
      debugPrint('Invites Response: ${invitesResp.statusCode} ${invitesResp.data}');
      debugPrint('Requests Response: ${requestsResp.statusCode} ${requestsResp.data}');

      final List<dynamic> mergedHistory = [];

      if (invitesResp.statusCode == 200) {
        final data = invitesResp.data;
        if (data is Map) {
          final invitesList = (data['invites'] ?? data['entries'] ?? data['data'] ?? []) as List<dynamic>;
          mergedHistory.addAll(invitesList.map((e) => {
            ...e,
            'record_type': 'PRE_APPROVED'
          }));
        } else if (data is List) {
          mergedHistory.addAll(data.map((e) => {
            ...e,
            'record_type': 'PRE_APPROVED'
          }));
        } else {
          debugPrint('Unexpected invites response format: ${data.runtimeType}');
        }
      }

      if (requestsResp.statusCode == 200) {
        final data = requestsResp.data;
        if (data is Map) {
          final requestsList = (data['requests'] ?? data['entries'] ?? data['data'] ?? []) as List<dynamic>;
          mergedHistory.addAll(requestsList.map((e) => {
            ...e,
            'record_type': 'WALK_IN'
          }));
        } else if (data is List) {
          mergedHistory.addAll(data.map((e) => {
            ...e,
            'record_type': 'WALK_IN'
          }));
        } else {
          debugPrint('Unexpected requests response format: ${data.runtimeType}');
        }
      }

      // Sort by created_at or valid_from descending (falling back to requested_at if needed)
      mergedHistory.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? a['requested_at']?.toString() ?? a['valid_from']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? b['requested_at']?.toString() ?? b['valid_from']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      debugPrint('mergedHistory count: ${mergedHistory.length}');
      return mergedHistory;
    } on DioException catch (e) {
      String msg = 'Network error fetching history';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          msg = e.response!.data['message'] ?? msg;
        } else {
          msg = 'Server Error: ${e.response!.statusCode}';
        }
      }
      throw Exception(msg);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Fetch History Failure');
      throw Exception('Unexpected error occurred fetching history');
    }
  }
}
