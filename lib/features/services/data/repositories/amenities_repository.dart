import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/amenity_model.dart';
import '../models/amenity_booking_model.dart';

class AmenitiesRepository {
  final Dio _dio;

  AmenitiesRepository({Dio? dio})
    : _dio = dio ?? AsmitaDioClient(SecureStorageService()).dio;

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
      final msg = _extractError(e, 'Failed to load amenities');
      throw Exception(msg);
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
      final msg = _extractError(e, 'Failed to load my bookings');
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> bookAmenity({
    required int amenityId,
    required int societyId,
    required int userId,
    required int flatId,
    required DateTime bookingDate,
    required DateTime startTime,
    required DateTime endTime,
    String? purpose,
    int? expectedGuests,
    String? specialNotes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amenity_id': amenityId,
        'society_id': societyId,
        'user_id': userId,
        'flat_id': flatId,
        'booking_date': bookingDate.toIso8601String(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      };
      if (purpose != null) payload['purpose'] = purpose;
      if (expectedGuests != null) payload['expected_guests'] = expectedGuests;
      if (specialNotes != null) payload['special_notes'] = specialNotes;

      final response = await _dio.post(
        '/app-api/amenities/book',
        data: payload,
      );
      return {
        'success': response.data['success'] == true,
        'message':
            response.data['message']?.toString() ?? 'Booked successfully',
        'is_override': response.data['is_override'] == true,
      };
    } on DioException catch (e) {
      final msg = _extractError(e, 'Failed to book amenity');
      throw Exception(msg);
    }
  }

  String _extractError(DioException e, String fallback) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ??
          data['error']?.toString() ??
          e.message ??
          fallback;
    }
    return e.message ?? fallback;
  }
}
