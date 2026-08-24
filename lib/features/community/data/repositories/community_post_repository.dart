import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/community_post_model.dart';

abstract class CommunityPostRepository {
  Future<List<CommunityPostModel>> getPosts();
  Future<CommunityPostModel> createPost(CommunityPostModel post);
}

class ApiCommunityPostRepository implements CommunityPostRepository {
  final Dio dio;

  ApiCommunityPostRepository({required this.dio});

  @override
  Future<List<CommunityPostModel>> getPosts() async {
    try {
      final response = await dio.get('/app-api/community/posts');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> rawPosts = data['posts'] ?? [];
          return rawPosts.map((json) => CommunityPostModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching community posts: $e');
      rethrow;
    }
  }

  @override
  Future<CommunityPostModel> createPost(CommunityPostModel post) async {
    try {
      final payload = post.toJson();
      // Remove id if it exists, as the backend will generate it
      payload.remove('id');
      
      final response = await dio.post(
        '/app-api/community/posts',
        data: payload,
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['post'] != null) {
          return CommunityPostModel.fromJson(data['post']);
        }
      }
      throw Exception('Failed to create post');
    } catch (e) {
      debugPrint('Error creating community post: $e');
      rethrow;
    }
  }
}
