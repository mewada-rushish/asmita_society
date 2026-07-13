import 'dart:io';

/// Defines the operational environment for the application.
enum AppEnvironment { development, production }

/// Central configuration for API environment endpoints and base URLs.
class EnvConfig {
  static const AppEnvironment currentEnvironment = AppEnvironment.production;

  static const String _devBaseUrlAndroid = 'http://10.0.2.2:5000';
  static const String _devBaseUrliOS = 'http://localhost:5000';
  static const String _prodBaseUrl = 'https://admin.myasmita.com';

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
  static String get loginInitiate => '$baseUrl/app-api/auth/otp/initiate';


  /// Endpoint for verifying OTP.
  static String get loginVerify => '$baseUrl/app-api/auth/otp/verify';


  /// Endpoint for registering a new user.
  static String get register => '$baseUrl/app-api/auth/otp/register';
  
  /// Endpoint for logging out.
  static String get logout => '$baseUrl/app-api/auth/logout';
  


}