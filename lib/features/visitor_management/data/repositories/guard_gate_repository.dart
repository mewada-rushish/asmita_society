import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env_config.dart';

class GuardGateRepository {
  final Dio _dio;

  GuardGateRepository(this._dio);

  /// Fetches expected pre-approved invites for today
  Future<List<dynamic>> getExpectedInvites() async {
    try {
      final response = await _dio.get(EnvConfig.gateExpectedInvites);
      final data = response.data;
      if (response.statusCode == 200) {
        return (data['invites'] ?? data['data'] ?? []) as List<dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch expected invites');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Fetch Expected Invites');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Fetch Expected Invites Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Searches for a pre-approved invite by 6-digit code
  Future<Map<String, dynamic>> searchInvite(String code) async {
    try {
      final response = await _dio.get(
        EnvConfig.gateSearchInvite,
        queryParameters: {'code': code},
      );
      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        return data['invite'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Invite not found');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Search Invite');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Search Invite Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Checks in a pre-approved visitor
  Future<void> checkInPreApproved(String inviteId) async {
    try {
      final response = await _dio.post(EnvConfig.gateCheckInInvite(inviteId));
      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = response.data;
        throw Exception(data['message'] ?? 'Failed to check in');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Check-in Invite');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Check-in Invite Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Submits an unannounced visitor entry
  Future<Map<String, dynamic>> submitWalkInVisitor(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(EnvConfig.createVisitorEntry, data: payload);
      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (data is Map<String, dynamic>) ? data : {};
      } else {
        final errorMsg = data is Map ? (data['message'] ?? data['error']) : null;
        throw Exception(errorMsg ?? 'Failed to create walk-in visitor');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Submit Walk-in Visitor');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Submit Walk-in Visitor Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Fetches currently checked-in visitors
  Future<List<dynamic>> getCheckedInVisitors() async {
    try {
      final response = await _dio.get(EnvConfig.gateCheckedInLogs);
      final data = response.data;
      if (response.statusCode == 200) {
        return (data['entries'] ?? data['data'] ?? []) as List<dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch checked-in visitors');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Fetch Checked-in Visitors');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Fetch Checked-in Visitors Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Checks out a visitor
  Future<void> checkOutVisitor(String id, {required bool isPreApproved, String? inviteGuestId}) async {
    try {
      final url = isPreApproved ? EnvConfig.gateCheckOutInvite(id) : EnvConfig.guardVisitorCheckOut(id);
      final body = isPreApproved && inviteGuestId != null ? {'invite_guest_id': inviteGuestId} : null;
      final response = isPreApproved ? await _dio.post(url, data: body) : await _dio.patch(url);
      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        final data = response.data;
        throw Exception(data['message'] ?? 'Failed to check out');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Check-out Visitor');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Check-out Visitor Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Fetches history of visitors checked in by the guard
  Future<List<dynamic>> getGuardHistory() async {
    try {
      Response walkInsResp;
      try {
        walkInsResp = await _dio.get(EnvConfig.guardVisitorEntries);
      } catch (e) {
        throw Exception('Failed to fetch guard history walk-ins: $e');
      }

      Response? gateLogsResp;
      try {
        gateLogsResp = await _dio.get(EnvConfig.gateLogs);
      } catch (e) {
        debugPrint('Warning: Failed to fetch gateLogs (endpoint might not be deployed yet): $e');
      }

      final List<dynamic> mergedHistory = [];

      if (walkInsResp.statusCode == 200) {
        final data = walkInsResp.data;
        if (data is Map) {
          final entries = (data['entries'] ?? data['data'] ?? []) as List<dynamic>;
          mergedHistory.addAll(entries.map((e) => {
            ...e as Map<String, dynamic>,
            'record_type': 'WALK_IN',
          }));
        } else if (data is List) {
          mergedHistory.addAll(data.map((e) => {
            ...e as Map<String, dynamic>,
            'record_type': 'WALK_IN',
          }));
        }
      }

      if (gateLogsResp != null && gateLogsResp.statusCode == 200) {
        final data = gateLogsResp.data;
        if (data is Map) {
          final entries = (data['entries'] ?? data['data'] ?? []) as List<dynamic>;
          mergedHistory.addAll(entries.map((e) => {
            ...e as Map<String, dynamic>,
            'record_type': 'PRE_APPROVED',
          }));
        } else if (data is List) {
          mergedHistory.addAll(data.map((e) => {
            ...e as Map<String, dynamic>,
            'record_type': 'PRE_APPROVED',
          }));
        } else {
          debugPrint('Warning: gateLogs returned non-JSON 200 response: $data');
        }
      }

      // Sort descending by date
      mergedHistory.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? a['requested_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? b['requested_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      return mergedHistory;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Fetch Guard History');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Fetch Guard History Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  Exception _handleDioError(DioException e, String context) {
    String msg = 'Network error during $context';
    if (e.response?.data != null) {
      if (e.response!.data is Map) {
        msg = e.response!.data['message'] ?? e.response!.data['error'] ?? msg;
      } else {
        msg = 'Server Error: ${e.response!.statusCode}';
      }
    }
    return Exception(msg);
  }
}
