import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/core/constants/design_system.dart';

/// Centralized service to manage Android overlay and battery optimization permissions
/// for MyGate-style instant incoming visitor approval alerts.
class PermissionManagerService {
  static const String _dismissedPrefKey =
      'asmita_gate_permissions_dismissed_v1';
  static bool _isShowingDialog = false;
  static bool _hasDismissedThisSession = false;

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
    bool force = false,
  }) async {
    if (_isShowingDialog) return;

    if (!Platform.isAndroid) {
      if (directToSettingsOnIOS || Platform.isIOS) {
        await openAppSettings();
      } else if (force && context.mounted) {
        _isShowingDialog = true;
        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.layers_rounded,
                    size: 40,
                    color: AsmitaPalette.deepNavy,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Background Overlay & Alert',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AsmitaPalette.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Floating visitor arrival alerts and battery exemptions are active on mobile devices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ).whenComplete(() {
          _isShowingDialog = false;
        });
      }
      return;
    }

    // Check if dismissed before
    if (!force) {
      if (_hasDismissedThisSession) return;
      try {
        final storage = SecureStorageService();
        final dismissed = await storage.read(key: _dismissedPrefKey);
        if (dismissed == 'true') {
          return;
        }
      } catch (_) {}
    }

    bool overlayGranted = false;
    bool batteryGranted = false;
    try {
      overlayGranted = await isOverlayPermissionGranted();
      batteryGranted = await isBatteryOptimizationIgnored();
    } catch (_) {}

    if (!force && overlayGranted && batteryGranted) return;
    if (!context.mounted) return;

    _isShowingDialog = true;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _InstantGateApprovalBottomSheet(
          initialOverlay: overlayGranted,
          initialBattery: batteryGranted,
          onDismissSaved: () async {
            _hasDismissedThisSession = true;
            try {
              final storage = SecureStorageService();
              await storage.write(key: _dismissedPrefKey, value: 'true');
            } catch (_) {}
          },
        ),
      );
    } finally {
      _isShowingDialog = false;
    }
  }
}

class _InstantGateApprovalBottomSheet extends StatefulWidget {
  final bool initialOverlay;
  final bool initialBattery;
  final Future<void> Function() onDismissSaved;

  const _InstantGateApprovalBottomSheet({
    required this.initialOverlay,
    required this.initialBattery,
    required this.onDismissSaved,
  });

  @override
  State<_InstantGateApprovalBottomSheet> createState() =>
      _InstantGateApprovalBottomSheetState();
}

class _InstantGateApprovalBottomSheetState
    extends State<_InstantGateApprovalBottomSheet>
    with WidgetsBindingObserver {
  late bool _overlayGranted;
  late bool _batteryGranted;

  @override
  void initState() {
    super.initState();
    _overlayGranted = widget.initialOverlay;
    _batteryGranted = widget.initialBattery;
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    try {
      final overlay =
          await PermissionManagerService.isOverlayPermissionGranted();
      final battery =
          await PermissionManagerService.isBatteryOptimizationIgnored();
      if (mounted) {
        setState(() {
          _overlayGranted = overlay;
          _batteryGranted = battery;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final allActive = _overlayGranted && _batteryGranted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
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
                  color: (allActive ? Colors.green : AsmitaPalette.actionRed)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allActive
                      ? Icons.check_circle_outline_rounded
                      : Icons.phonelink_ring_rounded,
                  color: allActive ? Colors.green : AsmitaPalette.actionRed,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allActive
                          ? 'Alerts Fully Configured'
                          : 'Instant Gate Approvals',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AsmitaPalette.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allActive
                          ? 'Floating visitor cards and sound alerts are active'
                          : 'Appear on screen like an incoming call',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AsmitaPalette.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            allActive
                ? 'Your phone is configured to receive instant floating visitor approval cards even when other apps are open or the screen is locked.'
                : 'To ensure visitor approval requests pop up immediately even when you are using other apps or your screen is locked, please enable these two permissions:',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildPermissionRow(
            context: context,
            icon: Icons.layers_outlined,
            title: 'Display Over Other Apps',
            subtitle: 'Shows floating approval cards on top of other apps.',
            isGranted: _overlayGranted,
            isDark: isDark,
            onTap: () async {
              await PermissionManagerService.requestOverlayPermission();
              await _refreshPermissions();
            },
          ),
          const SizedBox(height: 12),
          _buildPermissionRow(
            context: context,
            icon: Icons.battery_charging_full_rounded,
            title: 'Unrestricted Battery Access',
            subtitle:
                'Prevents phone from delaying gate alerts when screen is locked.',
            isGranted: _batteryGranted,
            isDark: isDark,
            onTap: () async {
              await PermissionManagerService.requestIgnoreBatteryOptimizations();
              await _refreshPermissions();
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await widget.onDismissSaved();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
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
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await openAppSettings();
            },
            icon: const Icon(Icons.settings_outlined, size: 16),
            label: const Text('Open System App Settings'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: isDark ? Colors.white70 : AsmitaPalette.deepNavy,
              side: BorderSide(
                color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bgColor = isGranted
        ? (isDark
              ? const Color(0xFF065F46).withValues(alpha: 0.25)
              : Colors.green.shade50)
        : (isDark
              ? const Color(0xFF334155).withValues(alpha: 0.4)
              : Colors.grey.shade50);

    final borderColor = isGranted
        ? (isDark ? const Color(0xFF059669) : Colors.green.shade200)
        : (isDark ? const Color(0xFF475569) : Colors.grey.shade200);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: isGranted
                ? Colors.green
                : (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AsmitaPalette.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            const Icon(Icons.check_circle, color: Colors.green, size: 22)
          else
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
