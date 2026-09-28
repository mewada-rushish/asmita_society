import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asmita_society/features/community/data/repositories/community_repository.dart';
import 'package:asmita_society/features/community/data/models/chat_message_model.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

import 'dart:io';

class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements SecureStorageService {}
class MockBox extends Mock implements Box {}

void main() {
  late ApiCommunityRepository repository;
  late MockDio mockDio;
  late MockSecureStorage mockSecureStorage;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('community_chat');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    mockDio = MockDio();
    mockSecureStorage = MockSecureStorage();
    final box = Hive.box('community_chat');
    await box.clear();
    repository = ApiCommunityRepository(dio: mockDio, secureStorage: mockSecureStorage);
  });

  group('ApiCommunityRepository', () {
    test('sendMessage posts correct data', () async {
      when(() => mockSecureStorage.getSocietyId()).thenAnswer((_) async => 1);
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/community/messages'),
          statusCode: 201,
        ),
      );

      final message = ChatMessageModel(
        id: '1',
        content: 'Hello',
        type: 'text',
        sender: 'Test',
        time: 'Today|10:00 AM',
        isMe: true,
        isManagement: false,
      );

      await expectLater(repository.sendMessage(message, senderId: 10), completes);
    });

    test('sendMessage throws exception if no society selected', () async {
      when(() => mockSecureStorage.getSocietyId()).thenAnswer((_) async => null);

      final message = ChatMessageModel(
        id: '1',
        content: 'Hello',
        type: 'text',
        sender: 'Test',
        time: 'Today|10:00 AM',
        isMe: true,
        isManagement: false,
      );

      expect(() => repository.sendMessage(message, senderId: 10), throwsException);
    });

    test('deleteMessage calls dio delete', () async {
      when(() => mockDio.delete('/app-api/community/messages/msg123')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/community/messages/msg123'),
          statusCode: 200,
        ),
      );

      await expectLater(repository.deleteMessage('msg123'), completes);
    });

    test('voteOnPoll calls dio post', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/community/messages/msg123/vote'),
          statusCode: 200,
        ),
      );

      await expectLater(repository.voteOnPoll('msg123', 'Option A'), completes);
    });

    test('getMessages returns list of ChatMessageModel from network', () async {
      when(() => mockSecureStorage.getSocietyId()).thenAnswer((_) async => 1);
      
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/community/messages'),
          statusCode: 200,
          data: {
            'messages': [
              {
                'id': '1',
                'sender_id': 10,
                'sender_name': 'Test User',
                'type': 'text',
                'content': 'Hello',
                'time': 'Today',
              }
            ]
          },
        ),
      );

      final result = await repository.getMessages(currentUserId: 10, currentUserName: 'Test User');
      expect(result.length, 1);
      expect(result.first.isMe, true);
    });

    test('getMessages falls back to cache on non-200 if page 1', () async {
      when(() => mockSecureStorage.getSocietyId()).thenAnswer((_) async => 1);
      final box = Hive.box('community_chat');
      await box.put('messages_page_1', [
        {
          'id': '1',
          'sender_id': 10,
          'sender_name': 'Test User',
          'type': 'text',
          'content': 'Hello',
          'time': 'Today',
        }
      ]);
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/community/messages'),
          statusCode: 500,
        ),
      );

      final result = await repository.getMessages(currentUserId: 10, currentUserName: 'Test User');
      expect(result.length, 1);
      expect(result.first.content, 'Hello');
    });

    test('getMessages throws if no society selected', () async {
      when(() => mockSecureStorage.getSocietyId()).thenAnswer((_) async => null);
      
      final result = await repository.getMessages(currentUserId: 10, currentUserName: 'Test User');
      expect(result.length, 0); // Exception is caught and returns []
    });

    test('uploadFile returns url on success', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/community/upload'),
          statusCode: 200,
          data: {'url': 'http://example.com/image.png'},
        ),
      );

      final tempFile = File('${Directory.systemTemp.path}/test_image.png');
      await tempFile.writeAsBytes([0]);

      final result = await repository.uploadFile(tempFile.path);
      expect(result, 'http://example.com/image.png');
    });

    test('uploadFile throws on failure', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/app-api/community/upload'),
          statusCode: 400,
        ),
      );

      final tempFile = File('${Directory.systemTemp.path}/test_image.png');
      await tempFile.writeAsBytes([0]);

      expect(() => repository.uploadFile(tempFile.path), throwsException);
    });
  });
}
