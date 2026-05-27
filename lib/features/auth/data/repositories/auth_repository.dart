import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final Dio _dio;

  // Dependency injection friendly, falls back to a default Dio instance if none provided
  AuthRepository({Dio? dio}) : _dio = dio ?? Dio();

  /// Step 1: Request OTP Dispatch
  Future<bool> initiateLogin(String mobile) async {
    try {
      final response = await _dio.post(
        EnvConfig.loginInitiate,
        data: {'mobile': mobile},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return true;
      }
      return false;
    } on DioException catch (e) {
      // Pass the exact backend error message down to the UI (e.g., "User record not found")
      final errorMessage = e.response?.data['message'] ?? 'Failed to initiate login. Please try again.';
      throw Exception(errorMessage);
    }
  }

  /// Step 2: Validate OTP and Retrieve Session Token
  Future<AuthResponse> verifyOtp(String mobile, String otp) async {
    try {
      final response = await _dio.post(
        EnvConfig.loginVerify,
        data: {
          'mobile': mobile,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        // Parse the secure backend JSON payload directly into our Dart model
        return AuthResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid verification response');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Invalid OTP or session expired.';
      throw Exception(errorMessage);
    }
  }
}