import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../security/secure_storage_service.dart';
import '../config/env_config.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:crypto/crypto.dart';

class AsmitaDioClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  AsmitaDioClient(this.secureStorage) : dio = Dio() {
    dio.options.baseUrl = EnvConfig.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(context: SecurityContext(withTrustedRoots: false));
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          if (host == 'admin.myasmita.com') {
            const expectedHash = '8214e3b5f14e0e56df8ca5f49513ca3ff4c4de07b48c4b13756502f4f121ed45';
            final actualHash = sha256.convert(cert.der).toString();
            debugPrint('Certificate Pinning: Expected: $expectedHash, Actual: $actualHash');
            return actualHash == expectedHash;
          }
          return false;
        };
        return client;
      },
    );
    
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final publicPaths = [
          '/app-api/auth/otp/initiate', 
          '/app-api/auth/otp/verify', 
          '/app-api/auth/otp/register'
        ];
        final isPublic = publicPaths.any((path) => options.path.contains(path));

        if (!isPublic) {
          final token = await secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final societyId = await secureStorage.getSocietyId();
          if (societyId != null) {
            options.headers['x-society-id'] = societyId.toString();
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Clear session on 401 Unauthorized
          await secureStorage.clearSession();
          // Optionally, a global event bus or navigator key could redirect to login here.
          // For now, modifying the error message so the UI can prompt the user to log in again.
          final customError = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: e.error,
            message: 'Session expired. Please log in again.',
          );
          return handler.next(customError);
        }

        if (e.type != DioExceptionType.connectionTimeout && 
            e.type != DioExceptionType.receiveTimeout && 
            e.type != DioExceptionType.sendTimeout &&
            e.type != DioExceptionType.connectionError &&
            e.type != DioExceptionType.unknown) {
          FirebaseCrashlytics.instance.recordError(
            e,
            e.stackTrace,
            reason: 'Network request failure: ${e.requestOptions.path}',
          );
        }
        return handler.next(e);
      },
    ));
  }
}