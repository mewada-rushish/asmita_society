import 'api_client.dart';

class AuthService {
  Future<Map<String, dynamic>> verifyUser(String phone, String otp) async {
    final response = await ApiClient.instance.post(
      'auth/verify.php',
      data: {'phone': phone, 'otp': otp},
    );
    return response.data;
  }
}