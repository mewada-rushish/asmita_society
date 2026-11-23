import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
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
    // Play In-App Updates is Android-exclusive
    if (!Platform.isAndroid) {
      if (showNoUpdateToast && context != null && context.mounted) {
        AsmitaToast.show(
          context,
          message: 'In-app updates via Google Play are only available on Android.',
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
            // Once downloaded, prompt the user or complete update
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'An update has been downloaded. Restart to apply.',
                    style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
                  ),
                  duration: const Duration(days: 1),
                  action: SnackBarAction(
                    label: 'RESTART',
                    textColor: Colors.amberAccent,
                    onPressed: () {
                      InAppUpdate.completeFlexibleUpdate();
                    },
                  ),
                ),
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
}
