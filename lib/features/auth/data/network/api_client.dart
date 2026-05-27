import 'package:dio/dio.dart';

class ApiClient {
  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: 'https://your-domain.com/api/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  static void setupInterceptors() {
    instance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer YOUR_SAVED_TOKEN';
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Handle session expiration
          }
          return handler.next(e);
        },
      ),
    );
  }
}