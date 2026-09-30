import 'package:dio/dio.dart';
import '../models/history_request_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class HistoryRequestRepository {
  final Dio dio;

  HistoryRequestRepository({required this.dio});

  Future<List<HistoryRequestModel>> getIncomingRequests() async {
    try {
      final response = await dio.get('\/history-requests/incoming');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        return rawList.map((e) => HistoryRequestModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching history requests: \');
      return [];
    }
  }

  Future<bool> approveRequest(int id, DateTime startDate, DateTime endDate) async {
    try {
      final response = await dio.patch(
        '\/history-requests/\/approve',
        data: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        }
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error approving history request: \');
      return false;
    }
  }
}
