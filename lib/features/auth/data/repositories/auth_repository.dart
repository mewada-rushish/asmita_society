import 'package:dio/dio.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final Dio _dio = Dio();
  final String _smsUser = 'asmita_india';
  final String _smsPwd = 'Asmita@Oct2025';

  Future<void> sendOtp(String phoneNumber, String otp) async {
    await _dio.post(
      'https://www.smsalert.co.in/api/push.json',
      queryParameters: {
        'user': _smsUser,
        'pwd': _smsPwd,
        'sender': 'ASMSPM',
        'mobileno': phoneNumber,
        'text': '$otp is your OTP for AsmitA India ltd. Enter this code to validate your identity.',
        'template_id': '1607100000000271102',
        'route': 'transactional'
      },
    );
  }

  Future<AuthResponse> verifyOtp(String phoneNumber, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    return AuthResponse(isExistingUser: true, role: 'resident', token: 'jwt_token');
  }
}