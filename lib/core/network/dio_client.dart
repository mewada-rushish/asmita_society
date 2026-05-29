import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../security/secure_storage_service.dart';

class AsmitaDioClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  AsmitaDioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl, // e.g., 'https://api.asmitaclub.com/v1'
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _setupInterceptors();
  }

  // Expose the configured Dio instance for Repositories to use
  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamically fetch the high-assurance token from hardware keystore
          final token = await _secureStorage.getToken();
          
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // You can also add custom headers here like App Version or OS Type
          options.headers['Accept'] = 'application/json';
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Pass successful responses down the chain
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Critical Security: Token expired or invalid.
            // Clear the local keystore to prevent ghost sessions.
            await _secureStorage.clearSession();
            
            // Note: In your presentation layer or a global router, 
            // you will listen for this unauthenticated state to kick the user back to the LoginScreen.
          }
          
          return handler.next(e);
        },
      ),
    );
  }
}