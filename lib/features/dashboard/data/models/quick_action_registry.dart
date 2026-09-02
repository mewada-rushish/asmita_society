import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

enum QuickActionType {
  preApprove,
  security,
  askSociety,
  posts,
  maintenance,
  dailyHelp,
  raiseAlert,
  myVehicles,
  complaints,
  management,
  opinionPoll,
  utilityPay,
  deliveries,
  amenities,
  emergency,
}

class QuickActionMetadata {
  final QuickActionType type;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color containerColor;
  final bool isUtilityButton;
  
  const QuickActionMetadata({
    required this.type,
    required this.label,
    required this.icon,
    this.iconColor = Colors.white,
    this.containerColor = AsmitaPalette.deepNavy,
    this.isUtilityButton = false,
  });
}

class QuickActionRegistry {
  static const Map<QuickActionType, QuickActionMetadata> allActions = {
    QuickActionType.preApprove: QuickActionMetadata(
      type: QuickActionType.preApprove,
      label: 'Pre-Approve',
      icon: Icons.person_add_alt_1_rounded,
    ),
    QuickActionType.security: QuickActionMetadata(
      type: QuickActionType.security,
      label: 'Security',
      icon: Icons.local_police_outlined,
    ),
    QuickActionType.askSociety: QuickActionMetadata(
      type: QuickActionType.askSociety,
      label: 'Ask Society',
      icon: Icons.quiz_outlined,
    ),
    QuickActionType.posts: QuickActionMetadata(
      type: QuickActionType.posts,
      label: 'Posts',
      icon: Icons.dynamic_feed_rounded,
    ),
    QuickActionType.maintenance: QuickActionMetadata(
      type: QuickActionType.maintenance,
      label: 'Maintenance',
      icon: Icons.request_quote_rounded,
    ),
    QuickActionType.dailyHelp: QuickActionMetadata(
      type: QuickActionType.dailyHelp,
      label: 'Daily Help',
      icon: Icons.face_retouching_natural_rounded,
    ),
    QuickActionType.raiseAlert: QuickActionMetadata(
      type: QuickActionType.raiseAlert,
      label: 'Raise Alert',
      icon: Icons.gpp_bad_outlined,
      iconColor: AsmitaPalette.actionRed,
      isUtilityButton: true,
    ),
    QuickActionType.myVehicles: QuickActionMetadata(
      type: QuickActionType.myVehicles,
      label: 'My Vehicles',
      icon: Icons.directions_car_rounded,
    ),
    QuickActionType.complaints: QuickActionMetadata(
      type: QuickActionType.complaints,
      label: 'Complaints',
      icon: Icons.report_problem_rounded,
      iconColor: AsmitaPalette.actionRed,
    ),
    QuickActionType.management: QuickActionMetadata(
      type: QuickActionType.management,
      label: 'Management',
      icon: Icons.admin_panel_settings_rounded,
    ),
    QuickActionType.opinionPoll: QuickActionMetadata(
      type: QuickActionType.opinionPoll,
      label: 'Opinion Poll',
      icon: Icons.poll_rounded,
    ),
    QuickActionType.utilityPay: QuickActionMetadata(
      type: QuickActionType.utilityPay,
      label: 'Utility Pay',
      icon: Icons.receipt_long_rounded,
    ),
    QuickActionType.deliveries: QuickActionMetadata(
      type: QuickActionType.deliveries,
      label: 'Deliveries',
      icon: Icons.local_shipping_rounded,
    ),
    QuickActionType.amenities: QuickActionMetadata(
      type: QuickActionType.amenities,
      label: 'Amenities',
      icon: Icons.pool_rounded,
    ),
    QuickActionType.emergency: QuickActionMetadata(
      type: QuickActionType.emergency,
      label: 'Emergency',
      icon: Icons.emergency_share_rounded,
      iconColor: AsmitaPalette.actionRed,
    ),
  };

  static const List<QuickActionType> defaultActions = [
    QuickActionType.preApprove,
    QuickActionType.security,
    QuickActionType.askSociety,
    QuickActionType.posts,
    QuickActionType.maintenance,
    QuickActionType.dailyHelp,
    QuickActionType.raiseAlert,
  ];
}
