import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/amenity_model.dart';
import '../models/amenity_booking_model.dart';

class AmenitiesRepository {
  final Dio _dio;

  AmenitiesRepository({Dio? dio}) : _dio = dio ?? AsmitaDioClient(SecureStorageService()).dio;

  Future<List<AmenityModel>> getAmenities({int? societyId}) async {
    try {
      final response = await _dio.get(
        '/app-api/amenities',
        queryParameters: societyId != null ? {'society_id': societyId} : {},
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => AmenityModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load amenities: ${e.response?.data ?? e.message}');
    }
  }

  Future<List<AmenityBookingModel>> getMyBookings({int? societyId}) async {
    try {
      final response = await _dio.get(
        '/app-api/amenities/my-bookings',
        queryParameters: societyId != null ? {'society_id': societyId} : {},
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => AmenityBookingModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load my bookings: ${e.response?.data ?? e.message}');
    }
  }

  Future<bool> bookAmenity({
    required int amenityId,
    required int societyId,
    required int userId,
    required int flatId,
    required DateTime bookingDate,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _dio.post('/app-api/amenities/book', data: {
        'amenity_id': amenityId,
        'society_id': societyId,
        'user_id': userId,
        'flat_id': flatId,
        'booking_date': bookingDate.toIso8601String(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      });
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to book amenity');
    }
  }
}
