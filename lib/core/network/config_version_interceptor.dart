import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef ConfigRefreshCallback = Future<String> Function();

/// Interceptor implementing the Stale Client Protocol [R6]:
/// - Attaches `x-config-version` header to every mutation request (POST, PUT, PATCH, DELETE).
/// - If server returns HTTP 426 (Upgrade Required), refreshes local configuration
///   and automatically retries the original request once.
/// - If the retried request is still rejected with HTTP 426, bubbles up the error to show standard error state.
class ConfigVersionInterceptor extends Interceptor {
  String _configVersion;
  final ConfigRefreshCallback? onRefreshConfig;
  final Dio dio;

  ConfigVersionInterceptor({
    required this.dio,
    String initialConfigVersion = '1',
    this.onRefreshConfig,
  }) : _configVersion = initialConfigVersion;

  String get currentConfigVersion => _configVersion;

  void updateConfigVersion(String newVersion) {
    _configVersion = newVersion;
    debugPrint('[ConfigVersionInterceptor] Updated config_version to: $_configVersion');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Attach current config_version to headers
    options.headers['x-config-version'] = _configVersion;
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final isUpgradeRequired = response?.statusCode == 426;

    if (isUpgradeRequired) {
      final isAlreadyRetried = err.requestOptions.extra['retried_426'] == true;

      if (!isAlreadyRetried && onRefreshConfig != null) {
        debugPrint('[ConfigVersionInterceptor] HTTP 426 encountered. Triggering configuration refresh and single retry...');
        try {
          // 1. Refresh configuration from server
          final newVersion = await onRefreshConfig!();
          updateConfigVersion(newVersion);

          // 2. Prepare request options for single automatic retry
          final retryOptions = err.requestOptions;
          retryOptions.headers['x-config-version'] = newVersion;
          retryOptions.extra['retried_426'] = true;

          // 3. Re-dispatch the request
          final retryResponse = await dio.fetch(retryOptions);
          debugPrint('[ConfigVersionInterceptor] Automatic retry succeeded after configuration refresh.');
          return handler.resolve(retryResponse);
        } catch (refreshOrRetryError) {
          debugPrint('[ConfigVersionInterceptor] Automatic retry failed or rejected again: $refreshOrRetryError');
          // Falls back to standard error state
          return handler.next(err);
        }
      }
    }

    return handler.next(err);
  }
}
