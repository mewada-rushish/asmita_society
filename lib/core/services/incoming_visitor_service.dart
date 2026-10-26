import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asmita_society/main.dart' show rootNavigatorKey;
import 'package:asmita_society/features/visitor_management/data/repositories/industrial_visit_repository.dart';
import 'package:asmita_society/core/di/injection_container.dart' as di;
import 'package:asmita_society/features/visitor_management/presentation/screens/incoming_visitor_screen.dart';

class IncomingVisitorData {
  final int visitId;
  final String visitorName;
  final String? photoUrl;
  final String? department;
  final String? floor;
  final String? purpose;
  final String? gateId;
  final String? vehicleNumber;
  final String? company;
  final String? category;
  final String? cabinCode;
  final String? deskCode;
  final String? visitorPhone;
  final String soundAsset;

  const IncomingVisitorData({
    required this.visitId,
    required this.visitorName,
    this.photoUrl,
    this.department,
    this.floor,
    this.purpose,
    this.gateId,
    this.vehicleNumber,
    this.company,
    this.category,
    this.cabinCode,
    this.deskCode,
    this.visitorPhone,
    this.soundAsset = 'assets/audio/notifications/approvals/AsmitA Alert 1.wav',
  });

  factory IncomingVisitorData.fromMap(Map<String, dynamic> map, {String? soundAsset}) {
    final visitId = int.tryParse(
      map['visit_id']?.toString() ??
      map['visitId']?.toString() ??
      map['entry_id']?.toString() ??
      map['id']?.toString() ??
      '0',
    ) ?? 0;

    final visitorName = map['visitor_name']?.toString() ??
        map['name']?.toString() ??
        map['visitorName']?.toString() ??
        'Visitor';

    final photoUrl = map['photo_url']?.toString() ??
        map['visitor_photo']?.toString() ??
        map['photo']?.toString();

    final department = map['department']?.toString() ??
        map['dept']?.toString() ??
        map['unit']?.toString() ??
        map['flat']?.toString();

    final floor = map['floor']?.toString();
    final purpose = map['purpose']?.toString();
    final gateId = map['gate_id']?.toString() ??
        map['gate']?.toString() ??
        map['gate_name']?.toString();

    final vehicleNumber = map['vehicle_number']?.toString() ??
        map['vehicleNumber']?.toString();

    final company = map['company']?.toString() ??
        map['delivery_company']?.toString() ??
        map['cab_provider']?.toString();

    final category = map['category']?.toString() ??
        map['visitor_type']?.toString() ??
        map['type']?.toString();

    final cabinCode = map['cabin_code']?.toString() ??
        map['assigned_cabin_code']?.toString();

    final deskCode = map['desk_code']?.toString() ??
        map['assigned_desk_code']?.toString();

    final visitorPhone = map['visitor_phone']?.toString() ??
        map['phone']?.toString() ??
        map['mobile']?.toString();

    return IncomingVisitorData(
      visitId: visitId,
      visitorName: visitorName,
      photoUrl: photoUrl,
      department: department,
      floor: floor,
      purpose: purpose,
      gateId: gateId,
      vehicleNumber: vehicleNumber,
      company: company,
      category: category,
      cabinCode: cabinCode,
      deskCode: deskCode,
      visitorPhone: visitorPhone,
      soundAsset: soundAsset ?? 'assets/audio/notifications/approvals/AsmitA Alert 1.wav',
    );
  }
}

class IncomingVisitorService {
  static const MethodChannel _lockScreenChannel = MethodChannel('com.asmita.app/lock_screen');

  /// Currently active or pending visitor call data
  static IncomingVisitorData? pendingCallData;

  /// Flag indicating if the incoming full-screen overlay is already open
  static bool isScreenOpen = false;

  /// Notifier to reactively trigger RootScreen when pendingCallData updates
  static final ValueNotifier<IncomingVisitorData?> pendingCallNotifier =
      ValueNotifier<IncomingVisitorData?>(null);

  /// Called whenever a doorbell / visitor arrival notification arrives
  /// (foreground, background launch, or lock screen wake-up).
  static void onIncomingCallReceived(Map<String, dynamic> rawData, {String? soundAsset}) {
    final data = IncomingVisitorData.fromMap(rawData, soundAsset: soundAsset);
    debugPrint('[IncomingVisitorService] onIncomingCallReceived for visitId: ${data.visitId}, visitor: ${data.visitorName}');

    // Keep screen awake while incoming call is ringing
    keepScreenOn(true);

    pendingCallData = data;
    pendingCallNotifier.value = data;

    // If root navigator is mounted and ready, present immediately
    final navState = rootNavigatorKey.currentState;
    final navContext = rootNavigatorKey.currentContext;

    if (navState != null && navContext != null && navContext.mounted) {
      presentScreen(data);
    } else {
      debugPrint('[IncomingVisitorService] Navigator not ready yet; cached in pendingCallData for startup presentation.');
    }
  }

  /// Presents the full-screen IncomingVisitorScreen over any active screen
  static void presentScreen(IncomingVisitorData data) {
    if (isScreenOpen) {
      debugPrint('[IncomingVisitorService] Screen is already open. Skipping duplicate presentation.');
      return;
    }

    final navState = rootNavigatorKey.currentState;
    if (navState == null) {
      debugPrint('[IncomingVisitorService] rootNavigatorKey.currentState is null!');
      return;
    }

    isScreenOpen = true;
    debugPrint('[IncomingVisitorService] Pushing IncomingVisitorScreen onto rootNavigator...');

    navState.push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            IncomingVisitorScreen(data: data),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        fullscreenDialog: true,
      ),
    ).then((_) {
      isScreenOpen = false;
      if (pendingCallData?.visitId == data.visitId) {
        pendingCallData = null;
        pendingCallNotifier.value = null;
      }
      keepScreenOn(false);
    });
  }

  /// Checks if there is a pending call waiting on app startup/mount
  static void checkAndLaunchPendingCall(BuildContext context) {
    if (pendingCallData != null && !isScreenOpen) {
      debugPrint('[IncomingVisitorService] checkAndLaunchPendingCall found pending call: ${pendingCallData!.visitId}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pendingCallData != null && !isScreenOpen) {
          presentScreen(pendingCallData!);
        }
      });
    }
  }

  /// Handles direct actions from lock screen notification shade (Approve / Reject buttons)
  static Future<void> handleBackgroundDecision(Map<String, dynamic> rawData, String action) async {
    final visitId = int.tryParse(
      rawData['visit_id']?.toString() ??
      rawData['visitId']?.toString() ??
      rawData['entry_id']?.toString() ??
      rawData['id']?.toString() ??
      '0',
    ) ?? 0;

    debugPrint('[IncomingVisitorService] handleBackgroundDecision for visitId: $visitId, action: $action');
    if (visitId <= 0) return;

    try {
      di.registerIndustrialDependencies();
      final repo = di.sl<IndustrialVisitRepository>();
      await repo.handleVisitAction(visitId, action: action);
      debugPrint('[IncomingVisitorService] Successfully processed $action in background for visitId: $visitId');
    } catch (e) {
      debugPrint('[IncomingVisitorService] Error in handleBackgroundDecision: $e');
    }
  }

  /// Requests Android to dismiss Keyguard / lock screen if approved
  static Future<bool> dismissKeyguard() async {
    try {
      final res = await _lockScreenChannel.invokeMethod<bool>('dismissKeyguard');
      return res ?? false;
    } catch (e) {
      debugPrint('[IncomingVisitorService] dismissKeyguard error: $e');
      return false;
    }
  }

  /// Controls Android FLAG_KEEP_SCREEN_ON
  static Future<void> keepScreenOn(bool enabled) async {
    try {
      await _lockScreenChannel.invokeMethod('keepScreenOn', {'enabled': enabled});
    } catch (e) {
      debugPrint('[IncomingVisitorService] keepScreenOn error: $e');
    }
  }
}
