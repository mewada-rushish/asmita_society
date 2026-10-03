import 'package:dio/dio.dart';
import '../models/support_ticket_model.dart';
import 'package:asmita_society/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class SupportRepository {
  final Dio dio;

  SupportRepository({required this.dio});

  Future<List<SupportTicketModel>> getTickets() async {
    try {
      final response = await dio.get(EnvConfig.supportTickets);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['tickets'] != null) {
          final List<dynamic> rawList = data['tickets'];
          return rawList.map((e) => SupportTicketModel.fromJson(e)).toList();
        } else if (data is List) { // fallback
          return data.map((e) => SupportTicketModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
      return [];
    }
  }

  Future<SupportTicketModel?> createTicket({
    required String title,
    required String description,
    String? category,
  }) async {
    try {
      final response = await dio.post(
        EnvConfig.supportTickets,
        data: {
          'subject': title,
          'description': description,
          'category': category,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true && data['ticket'] != null) {
          return SupportTicketModel.fromJson(data['ticket']);
        }
        return SupportTicketModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
      return null;
    }
  }

  // Users can't delete tickets, but they could maybe close them (update status).
  // I will just add an update method for completeness.
  Future<bool> updateTicket(int id, {required String status}) async {
    try {
      final response = await dio.put(
        '${EnvConfig.supportTickets}/$id',
        data: {
          'status': status,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating support ticket: $e');
      return false;
    }
  }
}
