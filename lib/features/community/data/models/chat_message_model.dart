import 'dart:convert';
import 'package:intl/intl.dart';

/// Represents a message model for community chat.
/// Holds the E2E encrypted ciphertext payload for database sync,
/// and helper methods for encrypting/decrypting the content payload.
class ChatMessageModel {
  final String id;
  final String sender;
  final bool isMe;
  final String time;
  final String type; // 'text', 'audio', 'poll'
  final bool isManagement;
  
  // Encrypted base64 payload containing E2E encrypted content JSON
  final String encryptedContent;
  
  // Decrypted fields (local only, not sent in plain text over network/DB)
  final String content;
  final Map<String, int>? pollOptions;
  final bool allowMultipleAnswers;

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.isMe,
    required this.time,
    required this.type,
    this.isManagement = false,
    required this.encryptedContent,
    this.content = '',
    this.pollOptions,
    this.allowMultipleAnswers = false,
  });

  /// Factory constructor to decrypt and unpack a ChatMessageModel from its encrypted state.
  factory ChatMessageModel.decryptPayload({
    required String id,
    required String sender,
    required bool isMe,
    required String time,
    required String type,
    bool isManagement = false,
    required String encryptedContent,
    required String Function(String) decryptor,
  }) {
    String decryptedContent = '';
    Map<String, int>? pollOpts;
    bool allowMulti = false;

    try {
      final decryptedJsonString = decryptor(encryptedContent);
      final decoded = json.decode(decryptedJsonString) as Map<String, dynamic>;
      decryptedContent = decoded['content'] as String? ?? '';
      if (decoded['pollOptions'] != null) {
        pollOpts = (decoded['pollOptions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as int),
        );
      }
      allowMulti = decoded['allowMultipleAnswers'] as bool? ?? false;
    } catch (e) {
      decryptedContent = '[Decryption Failed: $e]\nRaw Payload: $encryptedContent';
    }

    return ChatMessageModel(
      id: id,
      sender: sender,
      isMe: isMe,
      time: time,
      type: type,
      isManagement: isManagement,
      encryptedContent: encryptedContent,
      content: decryptedContent,
      pollOptions: pollOpts,
      allowMultipleAnswers: allowMulti,
    );
  }

  /// Encrypts and packs plain content into a ChatMessageModel.
  static ChatMessageModel createEncrypted({
    required String id,
    required String sender,
    required bool isMe,
    required String time,
    required String type,
    bool isManagement = false,
    required String content,
    Map<String, int>? pollOptions,
    bool allowMultipleAnswers = false,
    required String Function(String) encryptor,
  }) {
    final payloadMap = <String, dynamic>{
      'content': content,
    };
    if (pollOptions != null) {
      payloadMap['pollOptions'] = pollOptions;
      payloadMap['allowMultipleAnswers'] = allowMultipleAnswers;
    }
    final payloadJson = json.encode(payloadMap);
    final encryptedContent = encryptor(payloadJson);

    return ChatMessageModel(
      id: id,
      sender: sender,
      isMe: isMe,
      time: time,
      type: type,
      isManagement: isManagement,
      encryptedContent: encryptedContent,
      content: content,
      pollOptions: pollOptions,
    );
  }

  /// Parses an API JSON response and decrypts the content payload.
  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String Function(String) decryptor, {bool isMe = false, bool isManagement = false}) {
    String timeStr = '';
    if (json['created_at'] != null) {
      try {
        final dateTime = DateTime.parse(json['created_at'].toString()).toLocal();
        final now = DateTime.now();
        final formatter = DateFormat('hh:mm a');
        final timeFormatted = formatter.format(dateTime);
        if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
          timeStr = 'Today, $timeFormatted';
        } else if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day - 1) {
          timeStr = 'Yesterday, $timeFormatted';
        } else {
          timeStr = DateFormat('dd MMM, hh:mm a').format(dateTime);
        }
      } catch (e) {
        timeStr = json['created_at'].toString();
      }
    }

    return ChatMessageModel.decryptPayload(
      id: json['id'].toString(),
      sender: json['sender_name'] as String? ?? 'Unknown',
      isMe: isMe,
      time: timeStr,
      type: json['message_type'] as String? ?? 'text',
      isManagement: isManagement,
      encryptedContent: (json['encrypted_content']?.toString().isNotEmpty == true) 
          ? json['encrypted_content'].toString() 
          : 'MISSING_FIELD: ${json.toString()}',
      decryptor: decryptor,
    );
  }

  /// Converts the message into the JSON structure expected by POST /api/community/messages
  Map<String, dynamic> toApiJson(int societyId, int keyVersion, {int? senderId}) {
    final payload = <String, dynamic>{
      "society_id": societyId,
      "message_type": type,
      "encrypted_content": encryptedContent,
      "key_version": keyVersion,
    };
    if (senderId != null && senderId != 0) {
      payload["sender_id"] = senderId;
    }
    return payload;
  }
}
