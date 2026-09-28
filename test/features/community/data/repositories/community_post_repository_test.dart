import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/community/data/repositories/community_post_repository.dart';
import 'package:asmita_society/features/community/data/models/community_post_model.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late ApiCommunityPostRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = ApiCommunityPostRepository(dio: mockDio);
  });

  group('ApiCommunityPostRepository', () {
    final tPost = CommunityPostModel(
      id: '1',
      title: 'Test',
      contentJson: '{}',
      authorName: 'John',
      createdAt: DateTime(2023),
    );

    test('getPosts returns list of posts on success', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'success': true,
            'posts': [
              {
                'id': '1',
                'title': 'Test',
                'content_json': '{}',
                'author_name': 'John',
                'created_at': '2023-01-01T10:00:00Z',
              }
            ]
          },
        ),
      );

      final result = await repository.getPosts();
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('getPosts returns empty list on failure', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'success': false},
        ),
      );

      final result = await repository.getPosts();
      expect(result, isEmpty);
    });

    test('getPosts throws on exception', () async {
      when(() => mockDio.get(any())).thenThrow(Exception('Error'));
      expect(() => repository.getPosts(), throwsException);
    });

    test('createPost returns post on success', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 201,
          data: {
            'success': true,
            'post': {
              'id': '1',
              'title': 'Test',
              'content_json': '{}',
              'author_name': 'John',
              'created_at': '2023-01-01T10:00:00Z',
            }
          },
        ),
      );

      final result = await repository.createPost(tPost);
      expect(result.id, '1');
    });

    test('createPost throws when success is false', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 201,
          data: {'success': false},
        ),
      );

      expect(() => repository.createPost(tPost), throwsException);
    });

    test('createPost throws on exception', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(Exception('Error'));
      expect(() => repository.createPost(tPost), throwsException);
    });

    test('deletePost completes successfully on 200', () async {
      when(() => mockDio.delete(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
        ),
      );

      await expectLater(repository.deletePost('1'), completes);
    });

    test('deletePost throws when status is not 200', () async {
      when(() => mockDio.delete(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
        ),
      );

      expect(() => repository.deletePost('1'), throwsException);
    });

    test('deletePost throws on exception', () async {
      when(() => mockDio.delete(any())).thenThrow(Exception('Error'));
      expect(() => repository.deletePost('1'), throwsException);
    });
  });
}
