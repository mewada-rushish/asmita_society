import 'package:equatable/equatable.dart';

abstract class PreferencesEvent extends Equatable {
  const PreferencesEvent();
  @override
  List<Object?> get props => [];
}

class LoadPreferences extends PreferencesEvent {
  final bool showLoading;
  const LoadPreferences({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
class UpdatePreferences extends PreferencesEvent {
  final bool? pushNotifications;
  final bool? emailAlerts;
  final String? language;
  final String? appTheme;
  final bool? biometricLogin;

  const UpdatePreferences({
    this.pushNotifications,
    this.emailAlerts,
    this.language,
    this.appTheme,
    this.biometricLogin,
  });

  @override
  List<Object?> get props => [pushNotifications, emailAlerts, language, appTheme, biometricLogin];
}
