import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/services/location_geofence_service.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../../features/dashboard/widgets/asmita_pre_approve_wizard.dart';

/// Dedicated Employee Gate Attendance Scanner:
/// - Designed strictly for employee on-site check-in & check-out.
/// - Scans the official Main Gate Reception / Checkout QR standee.
/// - Validates the gate QR payload (`/visitor/checkin`, `societyId`, `gate=1` or `GATE-1`).
/// - Rejects non-gate or visitor pass QR codes with an instructional message.
/// - Automatically toggles attendance state (IN <-> OUT) and shows instant toast.
class EmployeeGateAttendanceScannerScreen extends StatefulWidget {
  final VoidCallback? onAttendanceRecorded;

  const EmployeeGateAttendanceScannerScreen({
    super.key,
    this.onAttendanceRecorded,
  });

  @override
  State<EmployeeGateAttendanceScannerScreen> createState() =>
      _EmployeeGateAttendanceScannerScreenState();
}

class _EmployeeGateAttendanceScannerScreenState
    extends State<EmployeeGateAttendanceScannerScreen> {
  bool _isProcessing = false;
  late final MobileScannerController _scannerController =
      MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    facing: CameraFacing.back,
    autoStart: true,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBack() {
    _scannerController.stop();
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  /// Evaluates whether the scanned QR code corresponds to an authorized Gate Standee.
  /// Valid formats from PropertyQrPosterModal:
  /// - `https://admin.myasmita.com/visitor/checkin?societyId=114&gate=1...`
  /// - `http://.../visitor/checkin?...`
  /// - `GATE-1`, `GATE-2`, `GATE_1`
  /// - JSON with `gate` or `gate_id`
  Map<String, dynamic>? _parseGateQr(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return null;

    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.hasQuery) {
        final gateParam = uri.queryParameters['gate'] ??
            uri.queryParameters['gate_id'] ??
            uri.queryParameters['gateId'];
        final societyParam = uri.queryParameters['societyId'] ??
            uri.queryParameters['society_id'];

        if (gateParam != null && gateParam.isNotEmpty) {
          return {
            'gate': gateParam,
            'gateName': 'Gate $gateParam (Main Reception)',
            'societyId': societyParam ?? '114',
            'raw': trimmed,
          };
        }
      }
    } catch (_) {}

    // Check JSON payload
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final gateVal = decoded['gate'] ?? decoded['gate_id'] ?? decoded['gateId'];
          if (gateVal != null) {
            return {
              'gate': gateVal.toString(),
              'gateName': 'Gate $gateVal (Main Reception)',
              'societyId': decoded['society_id']?.toString() ?? '114',
              'raw': trimmed,
            };
          }
        }
      } catch (_) {}
    }

    // Direct string format like "GATE-1" or "GATE_1"
    final directGateMatch = RegExp(r'^GATE[\-_ ]?(\d+)$', caseSensitive: false).firstMatch(trimmed);
    if (directGateMatch != null) {
      final num = directGateMatch.group(1);
      return {
        'gate': num,
        'gateName': 'Gate $num (Main Reception)',
        'societyId': '114',
        'raw': trimmed,
      };
    }

    return null;
  }

  Future<void> _processGateScan(String rawCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final gateInfo = _parseGateQr(rawCode);

    if (gateInfo == null) {
      // Invalid QR scanned (e.g. random text or visitor pass)
      await _scannerController.stop();
      HapticFeedback.heavyImpact();

      if (!mounted) return;
      AsmitaToast.show(
        context,
        message: 'Invalid Gate QR. Please scan the Main Gate Reception QR standee.',
        type: AsmitaToastType.error,
      );

      // Resume scanning after brief cooldown
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
      return;
    }

    // Gate verified - proceed with Check-in / Check-out toggle
    await _scannerController.stop();
    HapticFeedback.mediumImpact();

    final scannedSocietyId = int.tryParse(gateInfo['societyId']?.toString() ?? '') ?? 114;

    // Strict Physical Geofence Verification (Max 50 meters from Gate)
    if (mounted) {
      AsmitaToast.show(
        context,
        message: 'Verifying GPS proximity at entrance...',
        type: AsmitaToastType.info,
        duration: const Duration(milliseconds: 1500),
      );
    }

    final geofenceResult = await LocationGeofenceService.verifySocietyProximity(
      societyId: scannedSocietyId,
      defaultRadius: 50.0,
    );

    if (!geofenceResult.isAllowed) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        AsmitaToast.show(
          context,
          message: geofenceResult.errorMessage ?? 'Physical presence within 50m of entrance is required to check in.',
          type: AsmitaToastType.error,
          duration: const Duration(seconds: 4),
        );
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() => _isProcessing = false);
          _scannerController.start();
        }
      }
      return;
    }

    int userId = 0;
    if (mounted) {
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          userId = authState.user.userId;
        }
      } catch (_) {}
    }

    // Read previous status from local Hive app_cache
    final cacheKey = 'employee_gate_attendance_$userId';
    bool isCurrentlyCheckedIn = false;
    String? lastRecordedTime;
    try {
      if (Hive.isBoxOpen('app_cache')) {
        final record = Hive.box('app_cache').get(cacheKey);
        if (record is Map && record['status'] == 'IN') {
          isCurrentlyCheckedIn = true;
          if (record['timestamp'] != null) {
            final parsedTime = DateTime.tryParse(record['timestamp'].toString());
            if (parsedTime != null) {
              lastRecordedTime = DateFormat('hh:mm a').format(parsedTime);
            }
          }
        }
      }
    } catch (_) {}

    final gateName = gateInfo['gateName'] as String;

    if (!mounted) return;

    // Present interactive modal asking employee to confirm Check In or Check Out
    final chosenStatus = await _showAttendanceActionModal(
      context: context,
      gateName: gateName,
      isCurrentlyCheckedIn: isCurrentlyCheckedIn,
      distanceMeters: geofenceResult.distanceMeters,
      lastRecordedTime: lastRecordedTime,
    );

    if (chosenStatus == null) {
      // User dismissed or cancelled the modal - resume scanner
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
      return;
    }

    final newStatus = chosenStatus;
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);

    try {
      if (Hive.isBoxOpen('app_cache')) {
        await Hive.box('app_cache').put(cacheKey, {
          'user_id': userId,
          'status': newStatus,
          'timestamp': now.toIso8601String(),
          'gate': gateInfo['gate'],
          'gate_name': gateName,
          'latitude': geofenceResult.currentLatitude,
          'longitude': geofenceResult.currentLongitude,
          'distance': geofenceResult.distanceMeters,
        });
      }
    } catch (_) {}

    // Persist real-time gate movement to backend server
    final scannedGateId = int.tryParse(gateInfo['gate']?.toString() ?? '');
    if (userId > 0) {
      AsmitaPreApproveWizard.recordEmployeeMovement(
        societyId: scannedSocietyId,
        employeeId: userId,
        status: newStatus,
        recordedAt: now,
        gateId: scannedGateId,
        gateName: gateName,
        notes: 'QR Scan check-$newStatus at $gateName (${geofenceResult.distanceMeters != null ? "${geofenceResult.distanceMeters!.round()}m from gate" : "geofenced"})',
        latitude: geofenceResult.currentLatitude,
        longitude: geofenceResult.currentLongitude,
      );
    }

    if (!mounted) return;

    if (newStatus == 'IN') {
      AsmitaToast.show(
        context,
        message: 'Checked in at $gateName at $timeStr',
        type: AsmitaToastType.success,
      );
    } else {
      AsmitaToast.show(
        context,
        message: 'Checked out at $gateName at $timeStr',
        type: AsmitaToastType.info,
      );
    }

    widget.onAttendanceRecorded?.call();
    Navigator.of(context).pop();
  }

  /// Clean interactive modal bottom sheet asking employee to confirm Check In or Check Out
  Future<String?> _showAttendanceActionModal({
    required BuildContext context,
    required String gateName,
    required bool isCurrentlyCheckedIn,
    required double? distanceMeters,
    String? lastRecordedTime,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row with Gate Name and Close
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AsmitaPalette.deepNavy.withValues(alpha: isDark ? 0.3 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gate Attendance',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: onSurfaceColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gateName,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: onSurfaceColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(null),
                        icon: Icon(Icons.close_rounded, color: onSurfaceColor.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Location & Geofence Verified Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF059669),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            distanceMeters != null
                                ? 'GPS Proximity Verified (${distanceMeters.round()}m from gate)'
                                : 'GPS Proximity Verified (<50m entrance zone)',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Current Duty Status Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrentlyCheckedIn
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Current Status: ',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: onSurfaceColor.withValues(alpha: 0.65),
                          ),
                        ),
                        Text(
                          isCurrentlyCheckedIn ? 'Checked IN (On Duty)' : 'Checked OUT (Off Duty)',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isCurrentlyCheckedIn
                                ? const Color(0xFF059669)
                                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                          ),
                        ),
                        if (lastRecordedTime != null && lastRecordedTime.isNotEmpty) ...[
                          const Spacer(),
                          Text(
                            lastRecordedTime,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              color: onSurfaceColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons: Check In vs Check Out
                  // 1. Check IN Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(sheetContext).pop('IN'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isCurrentlyCheckedIn ? 'Confirm Check IN Again' : 'Check IN (Mark Entry)',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Check OUT Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(sheetContext).pop('OUT'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isCurrentlyCheckedIn
                              ? const Color(0xFFDC2626)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(14),
                          border: isCurrentlyCheckedIn
                              ? null
                              : Border.all(
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                  width: 1.2,
                                ),
                          boxShadow: isCurrentlyCheckedIn
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: isCurrentlyCheckedIn
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isCurrentlyCheckedIn ? 'Check OUT (Mark Exit)' : 'Check OUT (Mark Departure)',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: isCurrentlyCheckedIn
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _scannerController.stop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              fit: BoxFit.cover,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue ?? '';
                  if (code.isNotEmpty) {
                    _processGateScan(code);
                  }
                }
              },
            ),
            _buildScannerOverlay(context, isDark),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AsmitaPrimaryHeader(
                subtitleOverride: 'Gate Check-In & Out',
                allowPropertySwitching: false,
                showBackButton: true,
                onBackPressed: _handleBack,
                onProfilePressed: () {},
                trailingActions: IconButton(
                  icon: const Icon(Icons.flash_on_rounded, size: 20),
                  tooltip: 'Flashlight',
                  color: Theme.of(context).colorScheme.onSurface,
                  onPressed: () async {
                    try {
                      await _scannerController.toggleTorch();
                    } catch (_) {}
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context, bool isDark) {
    final size = MediaQuery.of(context).size;
    final scanWindowSize = size.width * 0.72;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: scanWindowSize,
            height: scanWindowSize,
            decoration: BoxDecoration(
              border: Border.all(color: AsmitaPalette.deepNavyDark, width: 2.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AsmitaPalette.deepNavyDark.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanWindowSize - 32,
                    height: 2,
                    color: AsmitaPalette.actionRed.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Scan Gate Reception QR to Check In / Out',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
