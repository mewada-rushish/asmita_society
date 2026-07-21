import 'dart:convert';
import 'package:intl/intl.dart';

/// Represents a message model for community chat.
/// Content is stored in plaintext on the client side, and encrypted
/// on the backend API before database storage.
class ChatMessageModel {
  final String id;
  final String sender;
  final bool isMe;
  final String time;
  final String type; // 'text', 'audio', 'poll'
  final bool isManagement;
  
  final String content;
  final String? replyToMessageId;
  final String? replyToContent;
  final Map<String, int>? pollOptions;
  final bool allowMultipleAnswers;
  
  final bool isStarred;
  final bool isPinned;
  final Map<String, List<String>>? reactions;

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.isMe,
    required this.time,
    required this.type,
    this.isManagement = false,
    this.content = '',
    this.replyToMessageId,
    this.replyToContent,
    this.pollOptions,
    this.allowMultipleAnswers = false,
    this.isStarred = false,
    this.isPinned = false,
    this.reactions,
  });

  ChatMessageModel copyWith({
    String? id,
    String? sender,
    bool? isMe,
    String? time,
    String? type,
    bool? isManagement,
    String? content,
    String? replyToMessageId,
    String? replyToContent,
    Map<String, int>? pollOptions,
    bool? allowMultipleAnswers,
    bool? isStarred,
    bool? isPinned,
    Map<String, List<String>>? reactions,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      isMe: isMe ?? this.isMe,
      time: time ?? this.time,
      type: type ?? this.type,
      isManagement: isManagement ?? this.isManagement,
      content: content ?? this.content,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      pollOptions: pollOptions ?? this.pollOptions,
      allowMultipleAnswers: allowMultipleAnswers ?? this.allowMultipleAnswers,
      isStarred: isStarred ?? this.isStarred,
      isPinned: isPinned ?? this.isPinned,
      reactions: reactions ?? this.reactions,
    );
  }

  /// Factory constructor to parse a new message payload.
  factory ChatMessageModel.parsePayload({
    required String id,
    required String sender,
    required bool isMe,
    required String time,
    required String type,
    bool isManagement = false,
    required String contentPayload,
    String? replyToMessageId,
  }) {
    String parsedContent = '';
    String? parsedReplyToContent;
    Map<String, int>? pollOpts;
    bool allowMulti = false;

    try {
      final decoded = json.decode(contentPayload) as Map<String, dynamic>;
      parsedContent = decoded['content'] as String? ?? '';
      parsedReplyToContent = decoded['replyToContent'] as String?;
      if (decoded['pollOptions'] != null) {
        pollOpts = (decoded['pollOptions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as int),
        );
      }
      allowMulti = decoded['allowMultipleAnswers'] as bool? ?? false;
    } catch (e) {
      // Fallback if contentPayload is just a plain string instead of JSON
      parsedContent = contentPayload;
    }

    return ChatMessageModel(
      id: id,
      sender: sender,
      isMe: isMe,
      time: time,
      type: type,
      isManagement: isManagement,
      content: parsedContent,
      replyToMessageId: replyToMessageId,
      replyToContent: parsedReplyToContent,
      pollOptions: pollOpts,
      allowMultipleAnswers: allowMulti,
      isStarred: false,
      isPinned: false,
      reactions: null,
    );
  }

  /// Packs plain content into a JSON string payload for sending.
  static ChatMessageModel createMessage({
    required String id,
    required String sender,
    required bool isMe,
    required String time,
    required String type,
    bool isManagement = false,
    required String content,
    String? replyToMessageId,
    String? replyToContent,
    Map<String, int>? pollOptions,
    bool allowMultipleAnswers = false,
  }) {
    return ChatMessageModel(
      id: id,
      sender: sender,
      isMe: isMe,
      time: time,
      type: type,
      isManagement: isManagement,
      content: content,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      pollOptions: pollOptions,
      allowMultipleAnswers: allowMultipleAnswers,
      isStarred: false,
      isPinned: false,
      reactions: null,
    );
  }

  /// Parses an API JSON response
  factory ChatMessageModel.fromJson(Map<String, dynamic> jsonResponse, {bool isMe = false, bool isManagement = false}) {
    String timeStr = '';
    if (jsonResponse['created_at'] != null) {
      try {
        final dateTime = DateTime.parse(jsonResponse['created_at'].toString()).toLocal();
        final now = DateTime.now();
        final formatter = DateFormat('hh:mm a');
        final timeFormatted = formatter.format(dateTime);
        if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
          timeStr = 'Today|$timeFormatted';
        } else if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day - 1) {
          timeStr = 'Yesterday|$timeFormatted';
        } else {
          timeStr = '${DateFormat('dd, MMM, yyyy').format(dateTime)}|$timeFormatted';
        }
      } catch (e) {
        timeStr = jsonResponse['created_at'].toString();
      }
    }

    return ChatMessageModel.parsePayload(
      id: jsonResponse['id'].toString(),
      sender: jsonResponse['sender_name'] as String? ?? 'Unknown',
      isMe: isMe,
      time: timeStr,
      type: jsonResponse['message_type'] as String? ?? 'text',
      isManagement: isManagement,
      contentPayload: jsonResponse['content']?.toString() ?? '',
      replyToMessageId: jsonResponse['reply_to_message_id']?.toString(),
    );
  }

  /// Converts the message into the JSON structure expected by POST /api/community/messages
  Map<String, dynamic> toApiJson(int societyId, {int? senderId}) {
    final payloadMap = <String, dynamic>{
      'content': content,
    };
    if (replyToContent != null) {
      payloadMap['replyToContent'] = replyToContent;
    }
    if (pollOptions != null) {
      payloadMap['pollOptions'] = pollOptions;
      payloadMap['allowMultipleAnswers'] = allowMultipleAnswers;
    }
    final contentPayload = json.encode(payloadMap);

    final payload = <String, dynamic>{
      "society_id": societyId,
      "message_type": type,
      "content": contentPayload,
    };
    if (replyToMessageId != null) {
      payload['reply_to_message_id'] = int.tryParse(replyToMessageId!);
    }
    if (senderId != null && senderId != 0) {
      payload["sender_id"] = senderId;
    }
    return payload;
  }
}
