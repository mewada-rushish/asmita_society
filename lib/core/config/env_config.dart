/// Defines the operational environment for the application.
enum AppEnvironment { development, production }

/// Central configuration for API environment endpoints and base URLs.
class EnvConfig {
  static AppEnvironment get currentEnvironment => AppEnvironment.production;


  /// Resolves the base URL based on the current environment and platform.
  /// Resolves the base URL using dart-define with a fallback to production.
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Default fallback to production backend
    return 'https://admin.myasmita.com';
  }

  /// Endpoint for initiating OTP dispatch.
  static String get loginInitiate => '$baseUrl/app-api/auth/otp/initiate';

  /// Endpoint for verifying OTP.
  static String get loginVerify => '$baseUrl/app-api/auth/otp/verify';

  /// Endpoint for checking user approval status.
  static String get loginStatus => '$baseUrl/app-api/auth/otp/status';

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

  /// Guard Endpoints
  static String get gateSearchInvite => '$baseUrl/app-api/gate/pre-approved-invites/search';
  static String get gateExpectedInvites => '$baseUrl/app-api/gate/pre-approved-invites/expected';
  static String get gateLogs => '$baseUrl/app-api/gate/logs';
  static String get gateCheckedInLogs => '$baseUrl/app-api/gate/logs';
  static String gateCheckInInvite(String id) => '$baseUrl/app-api/gate/pre-approved-invites/$id/check-in';
  static String gateCheckOutInvite(String id) => '$baseUrl/app-api/gate/pre-approved-invites/$id/check-out';
  static String get guardVisitorEntries => '$baseUrl/app-api/guard/visitor-entries';
  static String guardVisitorCheckOut(String id) => '$baseUrl/app-api/visitor-entries/$id/check-out';
  static String get createVisitorEntry => '$baseUrl/app-api/visitor-entries';

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

  /// Endpoints for Menu Sub-Pages
  static String get familyMembers => '$baseUrl/app-api/family-members';
  static String get userVehicles => '$baseUrl/app-api/vehicles';
  static String get userPets => '$baseUrl/app-api/pets';
  static String get parkingSlots => '$baseUrl/app-api/parking-slots';
  static String get committeeMembers => '$baseUrl/app-api/committee-members';
  static String get societyRules => '$baseUrl/app-api/rules';
  static String get societyDocuments => '$baseUrl/app-api/documents';
  static String get supportTickets => '$baseUrl/app-api/support-tickets';
  static String get userPreferences => '$baseUrl/app-api/user-preferences';
}
