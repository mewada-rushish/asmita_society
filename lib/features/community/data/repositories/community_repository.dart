import 'dart:typed_data';
import 'package:asmita_society/core/security/encryption_service.dart';
import '../models/chat_message_model.dart';

import 'package:dio/dio.dart';

abstract class CommunityRepository {
  Uint8List get groupKey;
  Future<List<ChatMessageModel>> getMessages({int? currentUserId, String? currentUserName});
  Future<void> sendMessage(ChatMessageModel message, {int? senderId});
}

class ApiCommunityRepository implements CommunityRepository {
  final Dio dio;
  late final Uint8List _groupKey;

  ApiCommunityRepository({required this.dio}) {
    // Hardcoding a static 32-byte key for testing so that it doesn't change on Hot Restart.
    // In production, this would be fetched securely from the backend and decrypted locally.
    _groupKey = Uint8List.fromList(List.filled(32, 1)); // 32 bytes of 1s
  }

  @override
  Uint8List get groupKey => _groupKey;

  @override
  Future<List<ChatMessageModel>> getMessages({int? currentUserId, String? currentUserName}) async {
    try {
      // Hardcoded society_id to 101 for now
      final response = await dio.get('/app-api/community/messages', queryParameters: {'society_id': 101});
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawMessages = response.data['messages'] ?? [];
        return rawMessages.map((json) {
          final int senderId = json['sender_id'] is int ? json['sender_id'] : int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0;
          
          final apiSenderName = json['sender_name']?.toString().trim() ?? '';
          final localUserName = currentUserName?.trim() ?? '';

          // Identify if message is from "me" based on sender_name or ID
          final isMe = (currentUserId != null && currentUserId == senderId && senderId != 0) || 
                       (localUserName.isNotEmpty && apiSenderName.isNotEmpty && localUserName.toLowerCase() == apiSenderName.toLowerCase()) ||
                       (apiSenderName == 'You' || senderId == 0); 
          final isManagement = (apiSenderName.toLowerCase() == 'management');

          return ChatMessageModel.fromJson(
            json as Map<String, dynamic>,
            (payload) => EncryptionService.decrypt(payload, _groupKey),
            isMe: isMe,
            isManagement: isManagement,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      // If API fails, return empty list or throw
      print('Error fetching messages: $e');
      return [];
    }
  }

  @override
  Future<void> sendMessage(ChatMessageModel message, {int? senderId}) async {
    try {
      final payload = message.toApiJson(101, 1, senderId: senderId);
      await dio.post('/app-api/community/messages', data: payload);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
