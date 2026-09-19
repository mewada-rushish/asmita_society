import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
      if (response.statusCode == 201 && data['success'] == true) {
        return data['entry'] ?? {};
      } else {
        throw Exception(data['message'] ?? 'Failed to create walk-in visitor');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Submit Walk-in Visitor');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Submit Walk-in Visitor Failure');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Fetches history of visitors checked in by the guard
  Future<List<dynamic>> getGuardHistory() async {
    try {
      final response = await _dio.get(EnvConfig.guardVisitorEntries);
      final data = response.data;
      if (response.statusCode == 200) {
        return (data['entries'] ?? data['data'] ?? []) as List<dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch guard history');
      }
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
        msg = e.response!.data['message'] ?? msg;
      } else {
        msg = 'Server Error: ${e.response!.statusCode}';
      }
    }
    return Exception(msg);
  }
}
