import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';
import '../models/auth_response.dart';

/// Repository responsible for authentication, OTP verification, and user onboarding.
/// Communicates with the backend API via a secure Dio instance.
class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? Dio();

  /// Initiates an OTP login request.
  Future<bool> initiateLogin(String mobile) async {
    try {
      final response = await _dio.post(
        EnvConfig.loginInitiate,
        data: {'mobile': mobile},
      );

      final data = _ensureMap(response.data);
      return response.statusCode == 200 && data['status'] == 'success';
    } on DioException catch (e) {
      throw _parseError(e, 'Failed to initiate login.');
    }
  }

  /// Verifies the OTP.
  /// Intercepts 401 errors to check for 'REGISTRATION_REQUIRED' business signals.
  Future<AuthResponse> verifyOtp(String mobile, String otp) async {
    try {
      final response = await _dio.post(
        EnvConfig.loginVerify,
        data: {'mobile': mobile, 'otp': otp},
      );

      final data = _ensureMap(response.data);
      if (data['status'] == 'registration_required' || data['is_new_user'] == true) {
        throw Exception('REGISTRATION_REQUIRED');
      }

      if (data['status'] == 'success') {
        return AuthResponse.fromJson(data);
      }

      throw Exception('Invalid verification response');
    } on DioException catch (e) {
      // Logic to handle 401 as a registration signal rather than a network failure
      if (e.response?.statusCode == 401) {
        final data = _ensureMap(e.response?.data);
        if (data.isNotEmpty && (data['status'] == 'registration_required' || data['is_new_user'] == true)) {
          throw Exception('REGISTRATION_REQUIRED');
        }
      }
      
      throw _parseError(e, 'Invalid OTP or session expired.');
    }
  }

  /// Completes the onboarding process for new users.
  Future<AuthResponse> registerUser({
    required String mobile,
    required String fullName,
    required String email,
    required String gender,
    required String society,
    required String tower,
    required String floor,
    required String flat,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        EnvConfig.register,
        data: {
          'mobile_number': mobile,
          'full_name': fullName,
          'email_id': email,
          'gender': gender,
          'society_id': society,
          'tower_id': tower,
          'floor_id': floor,
          'flat_id': flat,
          'ownership_type': role,
        },
      );

      final data = _ensureMap(response.data);
      return AuthResponse.fromJson(data);
    } on DioException catch (e) {
      throw _parseError(e, 'Registration request failed.');
    }
  }

  /// Uploads a profile picture to the backend.
  Future<String> uploadProfilePicture(dynamic file, {String? token}) async {
    try {
      final String filePath = file.path;
      final formData = FormData.fromMap({
        'profile_picture': await MultipartFile.fromFile(filePath),
      });

      // Assuming the token is injected via an interceptor
      final options = token != null 
          ? Options(headers: {'Authorization': 'Bearer $token'}) 
          : null;

      final response = await _dio.post(
        '${EnvConfig.baseUrl}/app-api/users/upload-profile-picture',
        data: formData,
        options: options,
      );

      final data = _ensureMap(response.data);
      if (data['success'] == true && data['profile_picture_url'] != null) {
        return data['profile_picture_url'];
      }
      
      throw Exception('Failed to get profile picture URL');
    } on DioException catch (e) {
      throw _parseError(e, 'Failed to upload profile picture.');
    }
  }

  /// Inform the backend that the session is terminating
  Future<void> logout(int? userId, String? userType) async {
    try {
      await _dio.post(
        EnvConfig.logout,
        data: {
          'user_id': userId,
          'user_type': userType,
        },
      );
    } catch (_) {
      // Ignore network errors during logout, we will clear session locally anyway
    }
  }

  /// Safely converts response data into a Map, even if it arrived as a String or List.
  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  /// Centralized error parser to handle Dio exceptions consistently.
  Exception _parseError(DioException e, String defaultMessage) {
    final data = _ensureMap(e.response?.data);
    final message = data['message'] ?? e.message;
    return Exception(message ?? defaultMessage);
  }
}