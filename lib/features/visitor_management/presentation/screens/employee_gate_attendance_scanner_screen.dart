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
        final siteNameParam = uri.queryParameters['siteName'] ??
            uri.queryParameters['site'] ??
            uri.queryParameters['propertyName'];

        if (gateParam != null && gateParam.isNotEmpty) {
          return {
            'gate': gateParam,
            'gateName': 'Gate $gateParam',
            'societyId': societyParam ?? '114',
            'siteName': siteNameParam,
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

    // Gate verified - proceed to display attendance action modal
    await _scannerController.stop();
    HapticFeedback.mediumImpact();

    final scannedSocietyId = int.tryParse(gateInfo['societyId']?.toString() ?? '') ?? 114;

    // Fetch site config to resolve the real property/site name dynamically
    final siteConfig = await LocationGeofenceService.fetchSocietyGeofence(scannedSocietyId);
    final siteName = gateInfo['siteName']?.toString() ??
        siteConfig?['name']?.toString() ??
        'Site #$scannedSocietyId';

    int userId = 0;
    if (mounted) {
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          userId = authState.user.userId;
        }
      } catch (_) {}
    }

    // Read previous status from local Hive app_cache (scoped per site to avoid multi-site collisions)
    final cacheKey = 'employee_gate_attendance_${userId}_$scannedSocietyId';
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

    // Present interactive modal asking employee to confirm the required action
    final result = await _showAttendanceActionModal(
      context: context,
      societyId: scannedSocietyId,
      siteName: siteName,
      gateName: gateName,
      isCurrentlyCheckedIn: isCurrentlyCheckedIn,
      lastRecordedTime: lastRecordedTime,
    );

    if (result == null) {
      // User dismissed or cancelled the modal - resume scanner
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
      return;
    }

    final newStatus = result.status;
    final geofenceResult = result.geofenceResult;
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);

    // Persist real-time gate movement to backend server with Option B Site authorization verification
    final scannedGateId = int.tryParse(gateInfo['gate']?.toString() ?? '');
    bool isSuccess = false;
    if (userId > 0) {
      isSuccess = await AsmitaPreApproveWizard.recordEmployeeMovement(
        societyId: scannedSocietyId,
        employeeId: userId,
        status: newStatus,
        recordedAt: now,
        gateId: scannedGateId,
        gateName: '$siteName - $gateName',
        notes: 'QR Scan check-$newStatus at $siteName ($gateName) (${geofenceResult.distanceMeters != null ? "${geofenceResult.distanceMeters!.round()}m from gate" : "geofenced"})',
        latitude: geofenceResult.currentLatitude,
        longitude: geofenceResult.currentLongitude,
      );
    }

    if (!mounted) return;

    if (!isSuccess) {
      final errorMsg = AsmitaPreApproveWizard.lastMovementError ??
          'Unable to verify site access permissions. Please contact your administrator.';
      AsmitaToast.show(
        context,
        message: errorMsg,
        type: AsmitaToastType.error,
      );
      setState(() => _isProcessing = false);
      _scannerController.start();
      return;
    }

    try {
      if (Hive.isBoxOpen('app_cache')) {
        await Hive.box('app_cache').put(cacheKey, {
          'user_id': userId,
          'society_id': scannedSocietyId,
          'site_name': siteName,
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

    if (!mounted) return;

    if (newStatus == 'IN') {
      AsmitaToast.show(
        context,
        message: 'Checked in at $siteName ($gateName) at $timeStr',
        type: AsmitaToastType.success,
      );
    } else {
      AsmitaToast.show(
        context,
        message: 'Checked out at $siteName ($gateName) at $timeStr',
        type: AsmitaToastType.info,
      );
    }

    widget.onAttendanceRecorded?.call();
    Navigator.of(context).pop();
  }

  /// Clean interactive modal bottom sheet asking employee to confirm Check In or Check Out
  Future<_GateAttendanceModalResult?> _showAttendanceActionModal({
    required BuildContext context,
    required int societyId,
    required String siteName,
    required String gateName,
    required bool isCurrentlyCheckedIn,
    String? lastRecordedTime,
  }) async {
    return showModalBottomSheet<_GateAttendanceModalResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _GateAttendanceModalSheet(
          societyId: societyId,
          siteName: siteName,
          gateName: gateName,
          isCurrentlyCheckedIn: isCurrentlyCheckedIn,
          lastRecordedTime: lastRecordedTime,
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

class _GateAttendanceModalResult {
  final String status;
  final GeofenceResult geofenceResult;

  _GateAttendanceModalResult({
    required this.status,
    required this.geofenceResult,
  });
}

class _GateAttendanceModalSheet extends StatefulWidget {
  final int societyId;
  final String siteName;
  final String gateName;
  final bool isCurrentlyCheckedIn;
  final String? lastRecordedTime;

  const _GateAttendanceModalSheet({
    required this.societyId,
    required this.siteName,
    required this.gateName,
    required this.isCurrentlyCheckedIn,
    this.lastRecordedTime,
  });

  @override
  State<_GateAttendanceModalSheet> createState() =>
      _GateAttendanceModalSheetState();
}

class _GateAttendanceModalSheetState extends State<_GateAttendanceModalSheet> {
  bool _isVerifyingLocation = true;
  GeofenceResult? _geofenceResult;
  String? _locationError;
  String? _overrideStatus;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isVerifyingLocation = true;
      _locationError = null;
    });

    try {
      final result = await LocationGeofenceService.verifySocietyProximity(
        societyId: widget.societyId,
        defaultRadius: 50.0,
      );
      if (!mounted) return;
      setState(() {
        _isVerifyingLocation = false;
        _geofenceResult = result;
        if (!result.isAllowed) {
          _locationError = result.errorMessage ?? 'Please be near the gate entrance to proceed.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifyingLocation = false;
        _locationError = 'Unable to verify location. Tap to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final isVerified = _geofenceResult != null && _geofenceResult!.isAllowed;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SafeArea(
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
            child: SingleChildScrollView(
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
                              widget.siteName,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: onSurfaceColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gate Attendance • ${widget.gateName}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: onSurfaceColor.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        icon: Icon(Icons.close_rounded, color: onSurfaceColor.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Location Verification Banner with Preloader
                  _buildLocationStatusBanner(isDark),
                  const SizedBox(height: 12),

                  // Current Duty Status Box (Responsive & no overflow)
                  _buildDutyStatusBox(isDark, onSurfaceColor),
                  const SizedBox(height: 20),

                  // SINGLE Context-Aware Action Button (Check IN or Check OUT with toggle)
                  _buildActionButton(isVerified, isDark, onSurfaceColor),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStatusBanner(bool isDark) {
    if (_isVerifyingLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy).withValues(alpha: isDark ? 0.15 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verifying your location...',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF93C5FD) : AsmitaPalette.deepNavy,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_geofenceResult != null && _geofenceResult!.isAllowed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location verified',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationError ?? 'Please be near the gate entrance to proceed.',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFFDC2626),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _checkLocation,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFFDC2626),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyStatusBox(bool isDark, Color onSurfaceColor) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isCurrentlyCheckedIn
                  ? const Color(0xFF10B981)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Current Status: ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: onSurfaceColor.withValues(alpha: 0.65),
                ),
                children: [
                  TextSpan(
                    text: widget.isCurrentlyCheckedIn
                        ? 'Checked IN (On Duty)'
                        : 'Checked OUT (Off Duty)',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: widget.isCurrentlyCheckedIn
                          ? const Color(0xFF059669)
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.lastRecordedTime != null && widget.lastRecordedTime!.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              widget.lastRecordedTime!,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: onSurfaceColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isVerified, bool isDark, Color onSurfaceColor) {
    final defaultTargetStatus = widget.isCurrentlyCheckedIn ? 'OUT' : 'IN';
    final targetStatus = _overrideStatus ?? defaultTargetStatus;
    final isCheckIn = targetStatus == 'IN';
    final buttonColor = isCheckIn ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final buttonLabel = isCheckIn ? 'Check IN (Mark Entry)' : 'Check OUT (Mark Exit)';
    final buttonIcon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;

    final isEnabled = isVerified && !_isVerifyingLocation;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled
                  ? () {
                      Navigator.of(context).pop(
                        _GateAttendanceModalResult(
                          status: targetStatus,
                          geofenceResult: _geofenceResult!,
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.3),
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
                      buttonIcon,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      buttonLabel,
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
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _overrideStatus = (targetStatus == 'IN') ? 'OUT' : 'IN';
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                targetStatus == 'IN'
                    ? 'Need to Check OUT instead?'
                    : 'Need to Check IN instead?',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: onSurfaceColor.withValues(alpha: 0.6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
