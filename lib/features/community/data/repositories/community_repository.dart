import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';

import 'package:dio/dio.dart';

abstract class CommunityRepository {
  Future<List<ChatMessageModel>> getMessages({int? currentUserId, String? currentUserName, int page = 1});
  Future<void> sendMessage(ChatMessageModel message, {int? senderId});
  Future<String?> uploadFile(String filePath);
}

class ApiCommunityRepository implements CommunityRepository {
  final Dio dio;

  ApiCommunityRepository({required this.dio});

  @override
  Future<List<ChatMessageModel>> getMessages({int? currentUserId, String? currentUserName, int page = 1}) async {
    try {
      // Hardcoded society_id to 101 for now
      final response = await dio.get('/app-api/community/messages', queryParameters: {
        'society_id': 101,
        'page': page,
        'limit': 20,
      });
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawMessages = response.data['messages'] ?? [];
        return rawMessages.map((json) {
          final int senderId = json['sender_id'] is int ? json['sender_id'] : int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0;
          
          final apiSenderName = json['sender_name']?.toString().trim() ?? '';
          final localUserName = currentUserName?.trim() ?? '';

          // Identify if message is from "me" based on sender_name or ID
          final isMe = (currentUserId != null && currentUserId == senderId && senderId != 0) || 
                       (localUserName.isNotEmpty && apiSenderName.isNotEmpty && localUserName.toLowerCase() == apiSenderName.toLowerCase()) ||
                       (apiSenderName == 'You'); 
          final isManagement = (apiSenderName.toLowerCase() == 'management' || senderId == 0);

          return ChatMessageModel.fromJson(
            json as Map<String, dynamic>,
            isMe: isMe,
            isManagement: isManagement,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      // If API fails, return empty list or throw
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  @override
  Future<void> sendMessage(ChatMessageModel message, {int? senderId}) async {
    try {
      final payload = message.toApiJson(101, senderId: senderId);
      await dio.post('/app-api/community/messages', data: payload);
    } catch (e) {
      if (e is DioException) {
        debugPrint('Error sending message: ${e.message} | Response: ${e.response?.data}');
      } else {
        debugPrint('Error sending message: $e');
      }
      rethrow;
    }
  }

  @override
  Future<String?> uploadFile(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await dio.post('/app-api/community/upload', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        return response.data['url']?.toString();
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Error uploading file: ${e.message} | Response: ${e.response?.data}');
      } else {
        debugPrint('Error uploading file: $e');
      }
      return null;
    }
  }
}
