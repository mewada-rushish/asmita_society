import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';

class SearchRepository {
  final Dio dio;

  SearchRepository({required this.dio});

  /// Fetches live search results from the backend for a given module.
  Future<List<dynamic>> searchInModule({
    required String module,
    required String query,
  }) async {
    try {
      final response = await dio.get(
        EnvConfig.globalSearch,
        queryParameters: {
          'module': module,
          'q': query,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            final results = data['results'] as List<dynamic>? ?? [];
            debugPrint('Search results count: ${results.length} for module: $module');
            return results;
          } else {
            throw Exception(data['message'] ?? 'Failed to search');
          }
        } else {
          throw Exception('Invalid response format: Expected JSON');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Network error during search';
      throw Exception(msg);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Global Search Failure');
      throw Exception('Unexpected error occurred during search');
    }
  }
}
