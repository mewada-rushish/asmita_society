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
  Future<List<dynamic>> getMyHistory(int residentId) async {
    try {
      // Fetch both simultaneously
      final responses = await Future.wait([
        _dio.get(EnvConfig.myPreApprovedInvites),
        _dio.get(EnvConfig.residentVisitorRequests, queryParameters: {'user_id': residentId}),
      ]);

      final invitesResp = responses[0];
      final requestsResp = responses[1];
      
      debugPrint('Invites Response: ${invitesResp.statusCode} ${invitesResp.data}');
      debugPrint('Requests Response: ${requestsResp.statusCode} ${requestsResp.data}');

      final List<dynamic> mergedHistory = [];

      if (invitesResp.statusCode == 200) {
        final data = invitesResp.data;
        // The backend might not have 'success': true
        final invitesList = (data['invites'] ?? data['entries'] ?? data['data'] ?? (data is List ? data : [])) as List<dynamic>;
        mergedHistory.addAll(invitesList.map((e) => {
          ...e,
          'record_type': 'PRE_APPROVED'
        }));
      }

      if (requestsResp.statusCode == 200) {
        final data = requestsResp.data;
        final requestsList = (data['requests'] ?? data['entries'] ?? data['data'] ?? (data is List ? data : [])) as List<dynamic>;
        mergedHistory.addAll(requestsList.map((e) => {
          ...e,
          'record_type': 'WALK_IN'
        }));
      }

      // Sort by created_at or valid_from descending
      mergedHistory.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? a['valid_from']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? b['valid_from']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
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
