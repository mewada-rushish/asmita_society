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
    try {
      if (Hive.isBoxOpen('app_cache')) {
        final record = Hive.box('app_cache').get(cacheKey);
        if (record is Map && record['status'] == 'IN') {
          isCurrentlyCheckedIn = true;
        }
      }
    } catch (_) {}

    // Toggle: if currently IN -> Check OUT. If currently OUT -> Check IN.
    final newStatus = isCurrentlyCheckedIn ? 'OUT' : 'IN';
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final gateName = gateInfo['gateName'] as String;

    try {
      if (Hive.isBoxOpen('app_cache')) {
        await Hive.box('app_cache').put(cacheKey, {
          'user_id': userId,
          'status': newStatus,
          'timestamp': now.toIso8601String(),
          'gate': gateInfo['gate'],
          'gate_name': gateName,
        });
      }
    } catch (_) {}

    // Persist real-time gate movement to backend server
    final scannedSocietyId = int.tryParse(gateInfo['societyId']?.toString() ?? '') ?? 1;
    final scannedGateId = int.tryParse(gateInfo['gate']?.toString() ?? '');
    if (userId > 0) {
      AsmitaPreApproveWizard.recordEmployeeMovement(
        societyId: scannedSocietyId,
        employeeId: userId,
        status: newStatus,
        recordedAt: now,
        gateId: scannedGateId,
        gateName: gateName,
        notes: 'QR Scan check-$newStatus at $gateName',
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
