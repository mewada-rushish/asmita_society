import 'dart:io';

enum AppEnvironment { development, production }

class EnvConfig {
  static const AppEnvironment currentEnvironment = AppEnvironment.production;

  static const String _devBaseUrlAndroid = 'http://10.0.2.2:3001';
  static const String _devBaseUrliOS = 'http://localhost:3001';
  static const String _prodBaseUrl = 'https://societyapi.asmitagroup.com';

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

  static String get loginInitiate => '$baseUrl/api/auth/login/initiate';
  static String get loginVerify => '$baseUrl/api/auth/login/verify';
}