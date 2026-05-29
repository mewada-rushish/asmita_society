import 'dart:io';

/// Defines the operational environment for the application.
enum AppEnvironment { development, production }

/// Central configuration for API environment endpoints and base URLs.
class EnvConfig {
  static const AppEnvironment currentEnvironment = AppEnvironment.production;

  static const String _devBaseUrlAndroid = 'http://10.0.2.2:3001';
  static const String _devBaseUrliOS = 'http://localhost:3001';
  static const String _prodBaseUrl = 'https://societyapi.asmitagroup.com';

  /// Resolves the base URL based on the current environment and platform.
  static String get baseUrl {
    if (currentEnvironment == AppEnvironment.production) {
      return _prodBaseUrl;
    }
    
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return Platform.isIOS ? _devBaseUrliOS : _devBaseUrlAndroid;
      default:
        return _prodBaseUrl;
    }
  }

  /// Endpoint for initiating OTP dispatch.
  static String get loginInitiate => '$baseUrl/api/auth/login/initiate';

  /// Endpoint for verifying OTP.
  static String get loginVerify => '$baseUrl/api/auth/login/verify';

  /// Endpoint for registering a new user.
  static String get register => '$baseUrl/api/auth/register';
}