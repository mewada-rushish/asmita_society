import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/daily_help_model.dart';

class DailyHelpRepository {
  final Dio _dio;

  DailyHelpRepository({Dio? dio}) : _dio = dio ?? AsmitaDioClient(SecureStorageService()).dio;

  Future<List<DailyHelpModel>> getDailyHelpList({int? societyId}) async {
    try {
      final response = await _dio.get(
        '/app-api/daily-help',
        queryParameters: societyId != null ? {'society_id': societyId} : {},
      );

      if (response.data is List) {
        return (response.data as List).map((e) => DailyHelpModel.fromJson(e)).toList();
      } else if (response.data is Map && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => DailyHelpModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load daily help: ${e.response?.data ?? e.message}');
    }
  }

  Future<DailyHelpModel> addDailyHelpProvider({
    required int societyId,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/app-api/daily-help',
        data: {
          'society_id': societyId,
          'name': name,
          'phone': phone,
          'role': role,
        },
      );

      if (response.data['success'] == true) {
        return DailyHelpModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add contact');
      }
    } on DioException catch (e) {
      throw Exception('Failed to add contact: ${e.response?.data ?? e.message}');
    }
  }
}
