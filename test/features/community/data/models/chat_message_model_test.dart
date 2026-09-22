import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/community/data/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel', () {
    test('copyWith works correctly', () {
      final message = ChatMessageModel(
        id: '1',
        sender: 'Alice',
        isMe: true,
        time: '10:00 AM',
        type: 'text',
        content: 'Hello',
      );
      
      final updatedMessage = message.copyWith(
        content: 'Hello World',
        isStarred: true,
      );
      
      expect(updatedMessage.id, '1');
      expect(updatedMessage.sender, 'Alice');
      expect(updatedMessage.content, 'Hello World');
      expect(updatedMessage.isStarred, true);
    });

    test('parsePayload parses text message correctly', () {
      final message = ChatMessageModel.parsePayload(
        id: '2',
        sender: 'Bob',
        isMe: false,
        time: '11:00 AM',
        type: 'text',
        contentPayload: 'Plain text message',
      );
      
      expect(message.id, '2');
      expect(message.sender, 'Bob');
      expect(message.isMe, false);
      expect(message.type, 'text');
      expect(message.content, 'Plain text message');
    });

    test('parsePayload parses poll message correctly', () {
      final payload = '{"content":"What color?","pollOptions":{"Red":1,"Blue":2},"allowMultipleAnswers":false}';
      
      final message = ChatMessageModel.parsePayload(
        id: '3',
        sender: 'Charlie',
        isMe: true,
        time: '12:00 PM',
        type: 'poll',
        contentPayload: payload,
      );
      
      expect(message.type, 'poll');
      expect(message.content, 'What color?');
      expect(message.pollOptions?['Red'], 1);
      expect(message.pollOptions?['Blue'], 2);
      expect(message.allowMultipleAnswers, false);
    });

    test('fromJson parses correctly for text', () {
      final json = {
        'id': '1',
        'sender_name': 'John',
        'created_at': '2023-10-10T10:00:00Z',
        'message_type': 'text',
        'content': 'Hello',
      };
      final message = ChatMessageModel.fromJson(json, isMe: true);
      expect(message.id, '1');
      expect(message.sender, 'John');
      expect(message.isMe, true);
      expect(message.type, 'text');
    });

    test('createMessage creates a message with basic fields', () {
      final message = ChatMessageModel.createMessage(
        id: '1', sender: 'John', isMe: true, time: 'Today', type: 'poll', content: 'Q?',
        pollOptions: {'A': 0},
      );
      expect(message.pollOptions?['A'], 0);
    });
  });
}
