class UserPreferencesModel {
  final int id;
  final bool pushNotifications;
  final bool emailAlerts;
  final String language;
  final String appTheme;
  final bool biometricLogin;

  UserPreferencesModel({
    required this.id,
    this.pushNotifications = true,
    this.emailAlerts = false,
    this.language = 'English',
    this.appTheme = 'System Default',
    this.biometricLogin = false,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      id: json['id'] as int? ?? 0,
      pushNotifications: json['push_notifications'] == 1 || json['push_notifications'] == true,
      emailAlerts: json['email_alerts'] == 1 || json['email_alerts'] == true,
      language: json['language'] as String? ?? 'English',
      appTheme: json['app_theme'] as String? ?? 'System Default',
      biometricLogin: json['biometric_login'] == 1 || json['biometric_login'] == true,
    );
  }
}
