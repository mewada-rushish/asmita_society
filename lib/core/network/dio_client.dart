import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../security/secure_storage_service.dart';

class AsmitaDioClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  AsmitaDioClient(this.secureStorage) : dio = Dio() {
    dio.options.baseUrl = 'https://societyapi.asmitagroup.com';
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final publicPaths = [
          '/api/auth/login/initiate', 
          '/api/auth/login/verify', 
          '/api/auth/register'
        ];
        final isPublic = publicPaths.any((path) => options.path.contains(path));

        if (!isPublic) {
          final token = await secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        FirebaseCrashlytics.instance.recordError(
          e,
          e.stackTrace,
          reason: 'Network request failure: ${e.requestOptions.path}',
        );
        return handler.next(e);
      },
    ));
  }
}