import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../security/secure_storage_service.dart';
import '../config/env_config.dart';
import 'dart:io';
import 'package:dio/io.dart';

class AsmitaDioClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  AsmitaDioClient(this.secureStorage) : dio = Dio() {
    dio.options.baseUrl = EnvConfig.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        // Strategy 1: Native system CA root verification (ISRG Root X1 / Let's Encrypt / DigiCert)
        // Automatically validates trusted CA-signed certificates across automated renewals with zero maintenance.
        return HttpClient(context: SecurityContext(withTrustedRoots: true));
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
          final customError = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: 'Session expired. Please log in again.',
            message: 'Session expired. Please log in again.',
          );
          return handler.next(customError);
        }

        // Extract user-friendly message from backend JSON
        String? friendlyMessage;
        if (e.response?.data != null) {
          if (e.response!.data is Map) {
            final data = e.response!.data as Map;
            friendlyMessage = data['message']?.toString() ?? data['error']?.toString();
          } else if (e.response!.data is String && (e.response!.data as String).isNotEmpty) {
            friendlyMessage = e.response!.data.toString();
          }
        }

        if (friendlyMessage == null || friendlyMessage.isEmpty) {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.sendTimeout:
            case DioExceptionType.receiveTimeout:
              friendlyMessage = 'Connection timed out. Please check your internet connection.';
              break;
            case DioExceptionType.connectionError:
              friendlyMessage = 'Unable to connect to server. Please check your network.';
              break;
            default:
              if (e.response?.statusCode == 500) {
                friendlyMessage = 'Server error occurred. Please try again.';
              } else if (e.response?.statusCode == 404) {
                friendlyMessage = 'Requested resource was not found.';
              } else if (e.response?.statusCode == 403) {
                friendlyMessage = 'Permission denied for this action.';
              }
              break;
          }
        }

        final isExpectedHttpError = e.response?.statusCode == 400 ||
                                    e.response?.statusCode == 401 || 
                                    e.response?.statusCode == 403 || 
                                    e.response?.statusCode == 404;

        if (e.type != DioExceptionType.connectionTimeout && 
            e.type != DioExceptionType.receiveTimeout && 
            e.type != DioExceptionType.sendTimeout &&
            e.type != DioExceptionType.connectionError &&
            e.type != DioExceptionType.unknown &&
            !isExpectedHttpError) {
          FirebaseCrashlytics.instance.recordError(
            e,
            e.stackTrace,
            reason: 'Network request failure: ${e.requestOptions.path}',
          );
        }

        if (friendlyMessage != null && friendlyMessage.isNotEmpty) {
          return handler.next(DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: friendlyMessage,
            message: friendlyMessage,
          ));
        }

        return handler.next(e);
      },
    ));
  }
}