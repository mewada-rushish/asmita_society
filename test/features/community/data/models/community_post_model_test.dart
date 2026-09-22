import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/community/data/models/community_post_model.dart';

void main() {
  group('CommunityPostModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': '1',
        'title': 'Test Post',
        'content_json': '{"text": "Hello"}',
        'author_name': 'John Doe',
        'status': 'approved',
        'created_at': '2023-01-01T10:00:00Z',
        'start_date': '2023-01-01T10:00:00Z',
        'end_date': '2023-01-02T10:00:00Z',
      };
      
      final post = CommunityPostModel.fromJson(json);
      expect(post.id, '1');
      expect(post.title, 'Test Post');
      expect(post.contentJson, '{"text": "Hello"}');
      expect(post.authorName, 'John Doe');
      expect(post.status, 'approved');
      expect(post.createdAt.year, 2023);
      expect(post.startDate?.year, 2023);
      expect(post.endDate?.year, 2023);
    });

    test('fromJson parses with missing optional fields', () {
      final json = {
        'id': '1',
        'title': 'Test Post',
        'content_json': '{"text": "Hello"}',
        'author_name': 'John Doe',
        'created_at': '2023-01-01T10:00:00Z',
      };
      
      final post = CommunityPostModel.fromJson(json);
      expect(post.status, 'approved'); // default
      expect(post.startDate, isNull);
      expect(post.endDate, isNull);
    });

    test('toJson returns expected map', () {
      final post = CommunityPostModel(
        id: '1',
        title: 'Test Post',
        contentJson: '{"text": "Hello"}',
        authorName: 'John Doe',
        status: 'approved',
        createdAt: DateTime.utc(2023, 1, 1, 10),
        startDate: DateTime.utc(2023, 1, 1, 10),
        endDate: DateTime.utc(2023, 1, 2, 10),
      );
      
      final json = post.toJson();
      expect(json['id'], '1');
      expect(json['title'], 'Test Post');
      expect(json['content_json'], '{"text": "Hello"}');
      expect(json['author_name'], 'John Doe');
      expect(json['status'], 'approved');
      expect(json['created_at'], '2023-01-01T10:00:00.000Z');
      expect(json['start_date'], '2023-01-01T10:00:00.000Z');
      expect(json['end_date'], '2023-01-02T10:00:00.000Z');
    });

    test('props contains all fields', () {
      final post = CommunityPostModel(
        id: '1',
        title: 'Test',
        contentJson: '{}',
        authorName: 'John',
        createdAt: DateTime(2023),
      );
      expect(post.props.length, 8);
    });
  });
}
