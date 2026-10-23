import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:asmita_society/core/constants/design_system.dart';

/// Centralized service to manage Android overlay and battery optimization permissions
/// for MyGate-style instant incoming visitor approval alerts.
class PermissionManagerService {
  /// Checks whether "Display over other apps" (SYSTEM_ALERT_WINDOW) is granted.
  static Future<bool> isOverlayPermissionGranted() async {
    return await Permission.systemAlertWindow.isGranted;
  }

  /// Requests the overlay permission (navigates user to system settings toggle if needed).
  static Future<bool> requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  /// Checks whether battery optimization is ignored.
  static Future<bool> isBatteryOptimizationIgnored() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Requests ignoring battery optimizations.
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Checks whether notification permission is granted.
  static Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Requests notification permission.
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Checks if all critical background approval permissions are granted.
  static Future<bool> areApprovalPermissionsConfigured() async {
    if (!Platform.isAndroid) {
      return await isNotificationPermissionGranted();
    }
    final overlay = await isOverlayPermissionGranted();
    final notif = await isNotificationPermissionGranted();
    final battery = await isBatteryOptimizationIgnored();
    return overlay && notif && battery;
  }

  /// Displays an AsmitA-branded educational dialog prompting the user
  /// to grant overlay and battery permissions for seamless gate approval alerts.
  static Future<void> showPermissionSetupDialog(
    BuildContext context, {
    bool directToSettingsOnIOS = false,
  }) async {
    if (!Platform.isAndroid) {
      if (directToSettingsOnIOS) {
        await openAppSettings();
      }
      return;
    }

    bool overlayGranted = await isOverlayPermissionGranted();
    bool batteryGranted = await isBatteryOptimizationIgnored();

    if (overlayGranted && batteryGranted) return;
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final bottomInset = MediaQuery.viewPaddingOf(modalContext).bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phonelink_ring_rounded,
                        color: AsmitaPalette.actionRed,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instant Gate Approvals',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AsmitaPalette.deepNavy,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Appear on screen like an incoming call',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AsmitaPalette.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'To ensure visitor approval requests pop up immediately even when you are using other apps or your screen is locked, please enable these two permissions:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPermissionRow(
                  icon: Icons.layers_outlined,
                  title: 'Display Over Other Apps',
                  subtitle: 'Shows floating approval cards on top of other apps.',
                  isGranted: overlayGranted,
                  onTap: () async {
                    await requestOverlayPermission();
                    overlayGranted = await isOverlayPermissionGranted();
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 12),
                _buildPermissionRow(
                  icon: Icons.battery_charging_full_rounded,
                  title: 'Unrestricted Battery Access',
                  subtitle: 'Prevents phone from delaying gate alerts when screen is locked.',
                  isGranted: batteryGranted,
                  onTap: () async {
                    await requestIgnoreBatteryOptimizations();
                    batteryGranted = await isBatteryOptimizationIgnored();
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AsmitaPalette.deepNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isGranted ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: isGranted ? Colors.green.shade700 : AsmitaPalette.deepNavy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AsmitaPalette.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Enable',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AsmitaPalette.actionRed,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
