import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
import '../../../../core/widgets/asmita_visitor_card.dart';
import '../../../../core/widgets/asmita_bottom_nav_bar.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../visitor_management/bloc/visitor_bloc.dart';
import '../../../visitor_management/bloc/visitor_event.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/utils/property_role_resolver.dart';
import '../../../visitor_management/presentation/widgets/receptionist_reassign_sheet.dart';

class IndustrialVisitsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String initialFilter;

  const IndustrialVisitsScreen({
    super.key,
    this.onBack,
    this.initialFilter = 'ALL',
  });

  @override
  State<IndustrialVisitsScreen> createState() => _IndustrialVisitsScreenState();
}

class _IndustrialVisitsScreenState extends State<IndustrialVisitsScreen> {
  late String _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _acknowledgedIds = {};
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    // Periodic ticker so timestamps and relative countdowns update dynamically
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
      } catch (_) {}
    });
  }

  @override
  void didUpdateWidget(covariant IndustrialVisitsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _selectedFilter = widget.initialFilter;
      });
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showPreApproveModal(BuildContext context) async {
    await AsmitaPreApproveWizard.showAsModalSheet(
      context,
      title: 'Schedule Visitor',
    );

    if (!context.mounted) return;
    context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<VisitorBloc>().add(
        LoadMyHistory(residentId: authState.user.userId, isRefresh: true),
      );
    }
  }

  bool _canUserApproveVisit(BuildContext context, IndustrialVisitModel visit) {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return false;
      final user = authState.user;
      final role = PropertyRoleResolver.normalizeRole(
        user.primaryRole,
        scope: user.roleScope,
        power: user.rolePower,
        isIndustrial: true,
      );

      // Receptionists and Guards never approve/deny host visitor passes
      if (role == 'receptionist' || role == 'guard') {
        return false;
      }

      // Host themselves or designated assigned user can approve
      if (visit.hostUserId != null && visit.hostUserId == user.userId) {
        return true;
      }
      if (visit.assignedToUserId != null && visit.assignedToUserId == user.userId) {
        return true;
      }

      // Directors, CSOs, and Admins can manage / approve campus visits
      return PropertyRoleResolver.canApproveVisits(user);
    } catch (_) {
      return false;
    }
  }

  void _showVisitDetailsModal(
    BuildContext context,
    IndustrialVisitModel visit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = visit.isPending;
    final expiryTime = visit.passCodeExpiresAt;
    final isExpired =
        visit.status == IndustrialVisitStatus.expired ||
        (expiryTime != null && expiryTime.isBefore(DateTime.now()));
    final isWithin30Min = expiryTime != null
        ? DateTime.now().difference(expiryTime).inMinutes.abs() <= 30
        : (visit.createdAt != null &&
            DateTime.now().difference(visit.createdAt!).inMinutes.abs() <= 30);
    final canResend = isExpired && isWithin30Min;

    showAsmitaBottomSheet(
      context: context,
      title: 'Visitor Pass Details',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Executive Boarding Pass / Digital Pass Header Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), AsmitaPalette.deepNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upper Row: Avatar, Visitor Name, Category & Status Pill
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildVisitorPhotoAvatar(visit, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                visit.cleanVisitorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                              if (visit.isVip) ...[
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'VIP',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge in header (Solid white background capsule pill)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                visit.status.iconData,
                                size: 12,
                                color: visit.status.lightTextColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                visit.status.label,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: visit.status.lightTextColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Perforated ticket dash divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: List.generate(
                        24,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              height: 1.5,
                              color: index.isEven
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Lower Section: Full-Width Digital Pass Code Strip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.vpn_key_rounded,
                                      size: 11,
                                      color: Colors.white60,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PASS CODE',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  visit.passCode ?? visit.requestNumber,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (visit.passCode != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: visit.passCode!),
                                  );
                                  HapticFeedback.lightImpact();
                                  AsmitaToast.show(
                                    context,
                                    message:
                                        'Pass code ${visit.passCode} copied!',
                                    type: AsmitaToastType.success,
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Copy',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Structured Information Card
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.35)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: isDark ? 0.3 : 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.flag_rounded,
                    label: 'Current Status',
                    customValue: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: visit.status.fillColor(isDark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        visit.status.label,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: visit.status.textColor(isDark),
                        ),
                      ),
                    ),
                  ),
                  if (visit.cleanPurpose.isNotEmpty) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: 'Purpose of Visit',
                      value: visit.cleanPurpose,
                    ),
                  ],
                  _buildRowDivider(context),
                  _buildDetailRow(
                    context,
                    icon: Icons.business_rounded,
                    label: 'Department',
                    value: visit.departmentName ?? 'General Campus',
                  ),
                  if (visit.hostName != null && visit.hostName!.isNotEmpty) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.person_outline_rounded,
                      label: 'Host Person',
                      value: visit.hostName!,
                    ),
                  ],
                  if (visit.visitorMobile != null &&
                      visit.visitorMobile!.isNotEmpty) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.phone_outlined,
                      label: 'Visitor Contact',
                      value: visit.visitorMobile!,
                      trailing: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(
                          Icons.phone_in_talk_rounded,
                          size: 16,
                          color: AsmitaPalette.successGreen,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: visit.visitorMobile!),
                          );
                          HapticFeedback.lightImpact();
                          AsmitaToast.show(
                            context,
                            message:
                                'Phone number ${visit.visitorMobile} copied!',
                            type: AsmitaToastType.info,
                          );
                        },
                      ),
                    ),
                  ],
                  if (visit.vehicleNumber != null &&
                      visit.vehicleNumber!.isNotEmpty) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicle Plate',
                      customValue: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Text(
                          visit.vehicleNumber!,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                  _buildRowDivider(context),
                  _buildDetailRow(
                    context,
                    icon: Icons.access_time_rounded,
                    label: 'Scheduled Time',
                    value: visit.checkInAt != null
                        ? DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(visit.checkInAt!)
                        : (visit.createdAt != null
                              ? DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(visit.createdAt!)
                              : 'Scheduled Visit'),
                  ),
                  if (visit.checkOutAt != null) ...[
                    _buildRowDivider(context),
                    _buildDetailRow(
                      context,
                      icon: Icons.logout_rounded,
                      label: 'Check Out Time',
                      value: DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(visit.checkOutAt!),
                    ),
                  ],
                ],
              ),
            ),

            // 3. High-Assurance Gate Pass QR Section
            if (visit.statusToken != null && visit.statusToken!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.35)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: isDark ? 0.3 : 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GATE PASS QR VERIFICATION',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Show this QR code at the security checkpoint to scan and verify',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: isDark
                            ? AsmitaPalette.textDarkModeMuted
                            : AsmitaPalette.textLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AsmitaPalette.borderGrey),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: isExpired ? 0.35 : 1.0,
                            child: QrImageView(
                              data: visit.statusToken!,
                              version: QrVersions.auto,
                              size: 140.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AsmitaPalette.deepNavy,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AsmitaPalette.deepNavy,
                              ),
                            ),
                          ),
                        ),
                        if (isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.actionRed.withValues(
                                alpha: 0.9,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PASS EXPIRED',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // 4. Action Buttons (Approve/Deny, Forward, Check In, Wait, Check Out, Share)
            if (isPending && _canUserApproveVisit(context, visit)) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<IndustrialVisitBloc>().add(
                          DecideVisitEvent(visitId: visit.id, action: 'DENY'),
                        );
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text(
                        'Deny Entry',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AsmitaPalette.actionRed,
                        side: const BorderSide(
                          color: AsmitaPalette.actionRed,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<IndustrialVisitBloc>().add(
                          DecideVisitEvent(
                            visitId: visit.id,
                            action: 'APPROVE',
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Approve Entry',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Operational CTA Row for Approved, Forwarded, Waiting, or Checked In visitors
              if (visit.status == IndustrialVisitStatus.approved ||
                  visit.status == IndustrialVisitStatus.onTheWay ||
                  visit.status == IndustrialVisitStatus.waitingToMeet ||
                  visit.isCheckedIn) ...[
                Row(
                  children: [
                    // Wait Button (available when not already waiting and not checked out)
                    if (visit.status != IndustrialVisitStatus.waitingToMeet &&
                        !visit.isCheckedIn) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            try {
                              context.read<IndustrialVisitBloc>().add(
                                DecideVisitEvent(
                                  visitId: visit.id,
                                  action: 'WAITING_TO_MEET',
                                ),
                              );
                              AsmitaToast.show(
                                context,
                                message: 'Visitor marked as Waiting.',
                                type: AsmitaToastType.info,
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(
                            Icons.hourglass_top_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          label: const Text(
                            'Wait',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFD97706),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Forward CTA (when Approved & destination floor has receptionist)
                    if (visit.status == IndustrialVisitStatus.approved &&
                        visit.hasFloorReceptionist)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            try {
                              context.read<IndustrialVisitBloc>().add(
                                SendToLobbyEvent(
                                  visitId: visit.id,
                                  floor: visit.floor,
                                ),
                              );
                              AsmitaToast.show(
                                context,
                                message:
                                    'Visitor forwarded to floor receptionist.',
                                type: AsmitaToastType.success,
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(
                            Icons.forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Forward',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    // Check In CTA (when Approved without floor rec, or when Forwarded / Waiting)
                    if ((visit.status == IndustrialVisitStatus.approved &&
                            !visit.hasFloorReceptionist) ||
                        visit.status == IndustrialVisitStatus.onTheWay ||
                        visit.status == IndustrialVisitStatus.waitingToMeet)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            try {
                              context.read<IndustrialVisitBloc>().add(
                                CheckInPassEvent(
                                  visitId: visit.id,
                                  gateId: 1,
                                  passCode: visit.passCode,
                                ),
                              );
                              AsmitaToast.show(
                                context,
                                message: 'Visitor checked in successfully.',
                                type: AsmitaToastType.success,
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(
                            Icons.how_to_reg_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Check In',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    // Check Out CTA (when Checked In)
                    if (visit.isCheckedIn)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            try {
                              context.read<IndustrialVisitBloc>().add(
                                CheckOutPassEvent(visitId: visit.id, gateId: 1),
                              );
                              AsmitaToast.show(
                                context,
                                message: 'Visitor checked out successfully.',
                                type: AsmitaToastType.success,
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Check Out',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.deepNavy,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Share Pass Summary
              if (visit.passCode != null) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    final summary =
                        'Visitor Pass for ${visit.visitorName}\n'
                        'Pass Code: #${visit.passCode}\n'
                        'Status: ${visit.status.label}\n'
                        'Department: ${visit.departmentName ?? "General Campus"}\n'
                        'Host: ${visit.hostName ?? "General"}';
                    Clipboard.setData(ClipboardData(text: summary));
                    HapticFeedback.lightImpact();
                    AsmitaToast.show(
                      context,
                      message: 'Pass details copied to clipboard!',
                      type: AsmitaToastType.success,
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text(
                    'Share Pass Summary',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              // Resend Approval for Expired Passes (Only within 30 minutes of expiry)
              if (canResend) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _resendApproval(context, visit);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Resend Approval',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.deepNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorPhotoAvatar(
    IndustrialVisitModel visit, {
    double size = 48,
  }) {
    final photo = visit.visitorPhotoUrl?.trim();
    final initial = visit.visitorName.isNotEmpty
        ? visit.visitorName[0].toUpperCase()
        : 'V';

    Widget initialsFallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: size * 0.45,
            color: Colors.white,
          ),
        ),
      );
    }

    Widget content;
    if (photo == null || photo.isEmpty) {
      content = initialsFallback();
    } else if (photo.startsWith('data:image')) {
      try {
        final commaIndex = photo.indexOf(',');
        final base64Str = commaIndex != -1
            ? photo.substring(commaIndex + 1)
            : photo;
        final bytes = base64Decode(base64Str);
        content = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => initialsFallback(),
        );
      } catch (_) {
        content = initialsFallback();
      }
    } else if (!photo.startsWith('http://') &&
        !photo.startsWith('https://') &&
        !photo.startsWith('/') &&
        photo.length > 200) {
      try {
        final bytes = base64Decode(photo);
        content = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => initialsFallback(),
        );
      } catch (_) {
        content = initialsFallback();
      }
    } else {
      String fullUrl = photo;
      if (photo.startsWith('/')) {
        fullUrl = '${EnvConfig.baseUrl}$photo';
      }
      content = CachedNetworkImage(
        imageUrl: fullUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AsmitaSkeleton.bone(
              width: size,
              height: size,
              borderRadius: size / 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => initialsFallback(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _buildRowDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 44,
      endIndent: 12,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? customValue,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: AsmitaPalette.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  customValue ??
                  (value != null
                      ? Text(
                          value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink()),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: AsmitaBottomNavBar.fabBottomPadding(context),
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => _showPreApproveModal(context),
          backgroundColor: AsmitaPalette.deepNavy,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Schedule',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Unified Primary Asmita Header (Property Consistent)
          AsmitaPrimaryHeader(
            subtitleOverride: 'Visits & Passes',
            allowPropertySwitching: false,
            showBackButton: widget.onBack != null || Navigator.canPop(context),
            onBackPressed: widget.onBack,
          ),

          // 2. Scrollable Content Body with Bloc Consumer
          Expanded(
            child: BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
              listener: (context, state) {
                if (state.status == IndustrialVisitBlocStatus.actionSuccess &&
                    state.successMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.successMessage!,
                    type: AsmitaToastType.success,
                  );
                } else if (state.status == IndustrialVisitBlocStatus.error &&
                    state.errorMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.errorMessage!,
                    type: AsmitaToastType.error,
                  );
                }
              },
              builder: (context, state) {
                final isInitialLoading =
                    state.status == IndustrialVisitBlocStatus.initial;

                if (isInitialLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: AsmitaSkeleton(
                      isLoading: true,
                      child: Column(
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Filter visits to current day only (resets automatically at 00:00)
                final todayVisits = state.visits
                    .where((v) => v.isForToday)
                    .toList();

                final filteredVisits = todayVisits.where((v) {
                  if (_selectedFilter == 'PENDING' && !v.isPending) {
                    return false;
                  }
                  if (_selectedFilter == 'APPROVED' &&
                      v.status != IndustrialVisitStatus.approved) {
                    return false;
                  }
                  if (_selectedFilter == 'INSIDE' &&
                      v.status != IndustrialVisitStatus.checkedIn) {
                    return false;
                  }
                  if (_selectedFilter == 'COMPLETED' &&
                      v.status != IndustrialVisitStatus.checkedOut) {
                    return false;
                  }

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final matchName = v.visitorName.toLowerCase().contains(q);
                    final org = v.deliveryCompany ?? v.purpose ?? '';
                    final matchOrg = org.toLowerCase().contains(q);
                    final matchDept = (v.departmentName ?? '')
                        .toLowerCase()
                        .contains(q);
                    final matchPass = (v.passCode ?? '').toLowerCase().contains(
                      q,
                    );
                    final matchVehicle = (v.vehicleNumber ?? '')
                        .toLowerCase()
                        .contains(q);
                    return matchName ||
                        matchOrg ||
                        matchDept ||
                        matchPass ||
                        matchVehicle;
                  }
                  return true;
                }).toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    AsmitaAnimatedRefresh(
                      onRefresh: () async {
                        final bloc = context.read<IndustrialVisitBloc>();
                        final future = bloc.stream
                            .firstWhere(
                              (s) =>
                                  s.status != IndustrialVisitBlocStatus.loading,
                            )
                            .timeout(
                              const Duration(seconds: 4),
                              onTimeout: () => bloc.state,
                            );
                        bloc.add(const LoadIndustrialVisits());
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthAuthenticated) {
                          context.read<VisitorBloc>().add(
                            LoadMyHistory(
                              residentId: authState.user.userId,
                              isRefresh: true,
                            ),
                          );
                        }
                        await future;
                      },
                    ),

                    // Search Box
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : Theme.of(context).dividerColor,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.25 : 0.03,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.trim()),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white
                                  : AsmitaPalette.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search visitor, company, pass code, vehicle...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AsmitaPalette.textLight,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AsmitaPalette.textLight,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : AsmitaPalette.textLight,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top KPI Stat Metrics Cards (Interactive Filter Cards)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                        child: _buildKpiMetrics(context, todayVisits),
                      ),
                    ),

                    // Active Filter Badge (When filtered)
                    if (_selectedFilter != 'ALL')
                      SliverToBoxAdapter(
                        child: _buildActiveFilterHeader(context),
                      ),

                    // Visitor Items or Empty State
                    if (filteredVisits.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                          child: _buildEmptyState(context),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 200),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final visit = filteredVisits[index];
                            return _buildVisitItem(context, visit);
                          }, childCount: filteredVisits.length),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(
    BuildContext context,
    List<IndustrialVisitModel> visits,
  ) {
    final pendingCount = visits.where((v) => v.isPending).length;
    final approvedCount = visits
        .where((v) => v.status == IndustrialVisitStatus.approved)
        .length;
    final insideCount = visits
        .where((v) => v.status == IndustrialVisitStatus.checkedIn)
        .length;
    final totalCount = visits.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Total',
            count: totalCount,
            icon: Icons.groups_rounded,
            accentColor: isDark
                ? const Color(0xFF60A5FA)
                : AsmitaPalette.deepNavy,
            filterKey: 'ALL',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Pending',
            count: pendingCount,
            icon: Icons.pending_actions_rounded,
            accentColor: isDark
                ? const Color(0xFFF87171)
                : AsmitaPalette.actionRed,
            filterKey: 'PENDING',
            showPulse: pendingCount > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Approved',
            count: approvedCount,
            icon: Icons.verified_rounded,
            accentColor: isDark
                ? const Color(0xFF38BDF8)
                : const Color(0xFF1E88E5),
            filterKey: 'APPROVED',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Inside',
            count: insideCount,
            icon: Icons.meeting_room_rounded,
            accentColor: isDark
                ? const Color(0xFF34D399)
                : AsmitaPalette.successGreen,
            filterKey: 'INSIDE',
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color accentColor,
    required String filterKey,
    bool showPulse = false,
  }) {
    final isSelected = _selectedFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? accentColor.withValues(alpha: 0.18)
                    : accentColor.withValues(alpha: 0.08))
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Squircle Icon Container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: isSelected ? 0.45 : 0.18,
                  ),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: accentColor, size: 18),
                    if (showPulse)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? accentColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : AsmitaPalette.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String filterLabel;
    Color filterColor;
    IconData filterIcon;

    switch (_selectedFilter) {
      case 'PENDING':
        filterLabel = 'Pending Approvals';
        filterColor = isDark
            ? const Color(0xFFF87171)
            : AsmitaPalette.actionRed;
        filterIcon = Icons.pending_actions_rounded;
        break;
      case 'APPROVED':
        filterLabel = 'Approved Passes';
        filterColor = isDark
            ? const Color(0xFF38BDF8)
            : const Color(0xFF1E88E5);
        filterIcon = Icons.verified_rounded;
        break;
      case 'INSIDE':
        filterLabel = 'Checked Inside HQ';
        filterColor = isDark
            ? const Color(0xFF34D399)
            : AsmitaPalette.successGreen;
        filterIcon = Icons.meeting_room_rounded;
        break;
      default:
        filterLabel = _selectedFilter;
        filterColor = AsmitaPalette.deepNavy;
        filterIcon = Icons.filter_alt_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: filterColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: filterColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(filterIcon, size: 14, color: filterColor),
                const SizedBox(width: 6),
                Text(
                  filterLabel,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: filterColor,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedFilter = 'ALL');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filterColor.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: filterColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedFilter = 'ALL');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Show All',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AsmitaPalette.deepNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String emptyTitle = 'No Visitors Found';
    String emptySubtitle =
        'There are no visitor records matching your filter criteria.';
    IconData emptyIcon = Icons.badge_outlined;

    if (_selectedFilter == 'PENDING') {
      emptyTitle = 'All Caught Up!';
      emptySubtitle =
          'There are currently no visitors awaiting entry approval.';
      emptyIcon = Icons.done_all_rounded;
    } else if (_selectedFilter == 'INSIDE') {
      emptyTitle = 'Campus Clear';
      emptySubtitle =
          'No active visitors are currently checked inside the premises.';
      emptyIcon = Icons.domain_verification_rounded;
    } else if (_selectedFilter == 'APPROVED') {
      emptyTitle = 'No Approved Passes';
      emptySubtitle =
          'No upcoming approved passes found. Schedule a pass in seconds.';
      emptyIcon = Icons.event_available_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(emptyIcon, size: 42, color: AsmitaPalette.deepNavy),
          ),
          const SizedBox(height: 14),
          Text(
            emptyTitle,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AsmitaPalette.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _resendApproval(BuildContext context, IndustrialVisitModel visit) {
    try {
      context.read<IndustrialVisitBloc>().add(
        DecideVisitEvent(visitId: visit.id, action: 'RESEND'),
      );
      AsmitaToast.show(
        context,
        message: 'Approval request resent to host',
        type: AsmitaToastType.success,
      );
    } catch (e) {
      AsmitaToast.show(
        context,
        message: 'Failed to resend request',
        type: AsmitaToastType.error,
      );
    }
  }

  Widget _buildVisitItem(BuildContext context, IndustrialVisitModel visit) {
    final isPending = visit.isPending;
    final isAck = _acknowledgedIds.contains(visit.id);
    final expiryTime = visit.passCodeExpiresAt;
    final isExpired =
        visit.status == IndustrialVisitStatus.expired ||
        (expiryTime != null && expiryTime.isBefore(DateTime.now()));
    final isWithin30Min = expiryTime != null
        ? DateTime.now().difference(expiryTime).inMinutes.abs() <= 30
        : (visit.createdAt != null &&
            DateTime.now().difference(visit.createdAt!).inMinutes.abs() <= 30);
    final canResend = isExpired && isWithin30Min;
    final canApprove = _canUserApproveVisit(context, visit);

    // Resolve user role
    final authState = context.read<AuthBloc>().state;
    String userRole = '';
    int? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.userId;
      userRole = PropertyRoleResolver.normalizeRole(
        authState.user.primaryRole,
        scope: authState.user.roleScope,
        power: authState.user.rolePower,
        isIndustrial: true,
      );
    }

    final isReceptionist = userRole == 'receptionist';
    final isGuard = userRole == 'guard';
    final isHostOrAssignee = (visit.hostUserId != null && visit.hostUserId == currentUserId) ||
        (visit.assignedToUserId != null && visit.assignedToUserId == currentUserId);

    // Dynamic receptionist front-desk actions (Only for active non-terminal visits)
    Widget? bottomActions;
    final isTerminal = isExpired ||
        visit.status == IndustrialVisitStatus.checkedOut ||
        visit.status == IndustrialVisitStatus.rejected ||
        visit.status == IndustrialVisitStatus.cancelled;

    if ((isReceptionist || isGuard) && !isTerminal) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      bottomActions = Row(
        children: [
          // PTM update/assign button (Receptionist desk action - secondary corporate outlined style)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ReceptionistReassignSheet.show(
                    context,
                    visit: visit,
                    societyId: visit.propertyId,
                    onConfirmReassign: (assignedUser, cabin, desk) {
                      try {
                        context.read<IndustrialVisitBloc>().add(
                          DecideVisitEvent(
                            visitId: visit.id,
                            action: 'REASSIGN',
                            assignedUserId: assignedUser,
                            cabinId: cabin,
                            deskId: desk,
                          ),
                        );
                        AsmitaToast.show(
                          context,
                          message: 'Visitor successfully reassigned!',
                          type: AsmitaToastType.success,
                        );
                      } catch (_) {}
                    },
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 15,
                        color: isDark ? const Color(0xFF93C5FD) : AsmitaPalette.deepNavy,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          visit.hostName != null && visit.hostName!.isNotEmpty
                              ? 'Update PTM'
                              : 'Assign PTM',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF93C5FD) : AsmitaPalette.deepNavy,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Forward (When APPROVED and destination floor has receptionist)
          if (visit.status == IndustrialVisitStatus.approved && visit.hasFloorReceptionist) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<IndustrialVisitBloc>().add(
                      SendToLobbyEvent(
                        visitId: visit.id,
                        floor: visit.floor,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0369A1) : const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forward_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Forward',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Check In (When APPROVED without floor rec, or when Forwarded / Waiting)
          if ((visit.status == IndustrialVisitStatus.approved && !visit.hasFloorReceptionist) ||
              visit.status == IndustrialVisitStatus.onTheWay ||
              visit.status == IndustrialVisitStatus.waitingToMeet) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<IndustrialVisitBloc>().add(
                      CheckInPassEvent(
                        visitId: visit.id,
                        gateId: 1,
                        passCode: visit.passCode,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF27347B),
                          Color(0xFF1A2352),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF27347B).withValues(alpha: 0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.how_to_reg_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Check In',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Check Out (When Checked In)
          if (visit.isCheckedIn) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<IndustrialVisitBloc>().add(
                      CheckOutPassEvent(visitId: visit.id, gateId: 1),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF27347B),
                          Color(0xFF1A2352),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF27347B).withValues(alpha: 0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Check Out',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Only allow Resend if within 30 minutes AND user is either host or receptionist or admin
    final showResend = canResend && (isHostOrAssignee || isReceptionist || canApprove);

    return AsmitaVisitorCard.fromIndustrialVisit(
      visit: visit,
      context: context,
      showSubtitle: false,
      isAcknowledged: isAck,
      onTap: () => _showVisitDetailsModal(context, visit),
      onResend: showResend ? () => _resendApproval(context, visit) : null,
      bottomActions: bottomActions,
      onApprove: (isPending && canApprove)
          ? () {
              context.read<IndustrialVisitBloc>().add(
                DecideVisitEvent(visitId: visit.id, action: 'APPROVE'),
              );
            }
          : null,
      onDeny: (isPending && canApprove)
          ? () {
              context.read<IndustrialVisitBloc>().add(
                DecideVisitEvent(visitId: visit.id, action: 'DENY'),
              );
            }
          : null,
      onAcknowledge: (isPending && canApprove && !isAck)
          ? () {
              setState(() => _acknowledgedIds.add(visit.id));
              context.read<IndustrialVisitBloc>().add(
                AcknowledgeVisitEvent(visit.id),
              );
              AsmitaToast.show(
                context,
                message:
                    'Visitor pass #${visit.passCode ?? visit.id} acknowledged',
                type: AsmitaToastType.success,
              );
            }
          : null,
    );
  }
}
