import 'dart:io';


/// Defines the operational environment for the application.
enum AppEnvironment { development, production }

/// Central configuration for API environment endpoints and base URLs.
class EnvConfig {
  static AppEnvironment get currentEnvironment => AppEnvironment.production;

  static const String _devBaseUrlAndroid = 'http://192.168.0.87:5000';
  static const String _devBaseUrliOS = 'http://192.168.0.87:5000';
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

  /// Endpoints for Visitor Management
  static String get preApprovedInvites =>
      '$baseUrl/app-api/pre-approved-invites';
  static String get myPreApprovedInvites =>
      '$baseUrl/app-api/pre-approved-invites/my';
  static String get residentVisitorRequests =>
      '$baseUrl/app-api/resident/visitor-requests';
  static String get usersMe => '$baseUrl/app-api/users/me';

  /// Global Search
  static String get globalSearch => '$baseUrl/app-api/search';

  /// Endpoints for Community
  static String get communityMessages => '$baseUrl/app-api/community/messages';
  static String get communityUpload => '$baseUrl/app-api/community/upload';

  /// Endpoints for Properties
  static String get societies => '$baseUrl/app-api/properties/societies';
  static String get towers => '$baseUrl/app-api/properties/towers';
  static String get floors => '$baseUrl/app-api/properties/floors';
  static String get flats => '$baseUrl/app-api/properties/flats';
  static String get linkFlat => '$baseUrl/app-api/properties/link-flat';
}
