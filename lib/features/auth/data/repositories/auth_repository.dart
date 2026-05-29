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
      final errorMessage = e.response?.data['message'] ?? 'Failed to initiate login. Please try again.';
      throw Exception(errorMessage);
    }
  }

  /// Step 2: Validate OTP and Retrieve Session Token (or Registration Flag)
  Future<AuthResponse> verifyOtp(String mobile, String otp) async {
    try {
      final response = await _dio.post(
        EnvConfig.loginVerify,
        data: {
          'mobile': mobile,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
        // ASSUMPTION: Update these keys based on how your backend flags a missing user
        if (response.data['status'] == 'registration_required' || response.data['is_new_user'] == true) {
          throw Exception('REGISTRATION_REQUIRED'); 
        } else if (response.data['status'] == 'success') {
          return AuthResponse.fromJson(response.data);
        }
      }
      throw Exception('Invalid verification response');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Invalid OTP or session expired.';
      throw Exception(errorMessage);
    }
  }

  /// Step 3: Complete Onboarding and Register New User in Database
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
      // Assuming your EnvConfig has EnvConfig.register, otherwise fallback to explicit path
      final endpoint = '/auth/register'; 
      
      final response = await _dio.post(
        endpoint,
        data: {
          'mobile_number': mobile,
          'full_name': fullName,
          'email_id': email,
          'gender': gender,
          'society': society,
          'tower': tower,
          'floor': floor,
          'flat': flat,
          'ownership_type': role,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming registration returns the same session structure as login (Token + User Object)
        return AuthResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Registration failed.');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Failed to complete registration. Please try again.';
      throw Exception(errorMessage);
    }
  }
}