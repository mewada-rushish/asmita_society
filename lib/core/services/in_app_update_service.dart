import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';

enum UpdateCheckStatus {
  noUpdateAvailable,
  updateStarted,
  updateCompleted,
  notSupported,
  error,
}

/// Centralized service to manage Google Play In-App Updates (Play Core).
///
/// Supports both:
/// 1. Flexible Updates: Downloads in the background, then prompts to restart.
/// 2. Immediate Updates: Full-screen modal managed by Google Play for critical releases.
class InAppUpdateService {
  static bool _isChecking = false;

  /// Checks for an update from Google Play.
  ///
  /// [forceImmediate]: If `true`, prioritizes the immediate blocking flow.
  /// [showNoUpdateToast]: Useful when triggered manually by the user (e.g. "Check for Updates" button).
  static Future<UpdateCheckStatus> checkForUpdate({
    BuildContext? context,
    bool forceImmediate = false,
    bool showNoUpdateToast = false,
  }) async {
    if (Platform.isIOS) {
      return _checkIosAppStoreUpdate(
        context: context,
        forceImmediate: forceImmediate,
        showNoUpdateToast: showNoUpdateToast,
      );
    }

    // Play In-App Updates is Android-exclusive
    if (!Platform.isAndroid) {
      if (showNoUpdateToast && context != null && context.mounted) {
        AsmitaToast.show(
          context,
          message: 'In-app updates are only available on Android and iOS.',
          type: AsmitaToastType.info,
        );
      }
      return UpdateCheckStatus.notSupported;
    }

    if (_isChecking) return UpdateCheckStatus.updateStarted;
    _isChecking = true;

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // 1. Immediate Update path (for mandatory/critical updates)
        if (forceImmediate && updateInfo.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          _isChecking = false;
          return result == AppUpdateResult.success
              ? UpdateCheckStatus.updateCompleted
              : UpdateCheckStatus.error;
        }

        // 2. Flexible Update path (standard seamless background download)
        if (updateInfo.flexibleUpdateAllowed) {
          final startResult = await InAppUpdate.startFlexibleUpdate();
          if (startResult == AppUpdateResult.success) {
            // Once downloaded, prompt the user via Asmita custom toast/snackbar
            if (context != null && context.mounted) {
              AsmitaToast.show(
                context,
                message: 'Update downloaded. Restart to apply.',
                type: AsmitaToastType.success,
                duration: const Duration(days: 1),
                actionLabel: 'RESTART',
                bottomOffset: 96.0,
                onAction: () {
                  InAppUpdate.completeFlexibleUpdate();
                },
              );
            } else {
              await InAppUpdate.completeFlexibleUpdate();
            }
            _isChecking = false;
            return UpdateCheckStatus.updateCompleted;
          }
        } else if (updateInfo.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          _isChecking = false;
          return result == AppUpdateResult.success
              ? UpdateCheckStatus.updateCompleted
              : UpdateCheckStatus.error;
        }
      } else {
        if (showNoUpdateToast && context != null && context.mounted) {
          AsmitaToast.show(
            context,
            message: 'You are on the latest version of My AsmitA.',
            type: AsmitaToastType.success,
          );
        }
        _isChecking = false;
        return UpdateCheckStatus.noUpdateAvailable;
      }
    } catch (e) {
      debugPrint('[InAppUpdateService] Play in-app update check failed (normal in dev/sideload): $e');
      if (showNoUpdateToast && context != null && context.mounted) {
        AsmitaToast.show(
          context,
          message: 'Unable to check Google Play updates currently.',
          type: AsmitaToastType.info,
        );
      }
      _isChecking = false;
      return UpdateCheckStatus.error;
    }

    _isChecking = false;
    return UpdateCheckStatus.noUpdateAvailable;
  }

  /// Checks the Apple App Store for a newer version of the app on iOS.
  static Future<UpdateCheckStatus> _checkIosAppStoreUpdate({
    BuildContext? context,
    bool forceImmediate = false,
    bool showNoUpdateToast = false,
  }) async {
    if (_isChecking) return UpdateCheckStatus.updateStarted;
    _isChecking = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      final response = await dio.get(
        'https://itunes.apple.com/lookup',
        queryParameters: {'bundleId': packageInfo.packageName},
      );

      final data = response.data;
      final results = (data is Map ? data['results'] : null) as List?;
      if (results == null || results.isEmpty) {
        _isChecking = false;
        return UpdateCheckStatus.noUpdateAvailable;
      }

      final appInfo = results.first as Map<String, dynamic>;
      final storeVersion = appInfo['version'] as String?;
      final trackViewUrl = appInfo['trackViewUrl'] as String?;

      if (storeVersion != null && _isNewerVersion(storeVersion, packageInfo.version)) {
        if (context != null && context.mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: !forceImmediate,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Update Available'),
              content: Text(
                'A new version (v$storeVersion) of My AsmitA is available on the App Store.',
              ),
              actions: [
                if (!forceImmediate)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Later'),
                  ),
                FilledButton(
                  onPressed: () async {
                    if (!forceImmediate) {
                      Navigator.of(dialogContext).pop();
                    }
                    final uri = Uri.tryParse(
                      trackViewUrl ?? 'https://apps.apple.com/app/id6839494489',
                    );
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          );
        }
        _isChecking = false;
        return UpdateCheckStatus.updateStarted;
      }

      if (showNoUpdateToast && context != null && context.mounted) {
        AsmitaToast.show(
          context,
          message: 'You are on the latest version of My AsmitA.',
          type: AsmitaToastType.success,
        );
      }
      _isChecking = false;
      return UpdateCheckStatus.noUpdateAvailable;
    } catch (e) {
      debugPrint('[InAppUpdateService] iOS App Store update check failed: $e');
      if (showNoUpdateToast && context != null && context.mounted) {
        AsmitaToast.show(
          context,
          message: 'Unable to check App Store updates currently.',
          type: AsmitaToastType.info,
        );
      }
      _isChecking = false;
      return UpdateCheckStatus.error;
    }
  }

  /// Returns `true` if [storeVersion] is strictly greater than [currentVersion].
  static bool _isNewerVersion(String storeVersion, String currentVersion) {
    final storeParts = storeVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = storeParts.length > currentParts.length ? storeParts.length : currentParts.length;

    for (var i = 0; i < maxLen; i++) {
      final s = i < storeParts.length ? storeParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (s > c) return true;
      if (s < c) return false;
    }
    return false;
  }
}
