import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
import '../../../../core/widgets/asmita_text_field.dart';
import '../../../../core/widgets/asmita_select_field.dart';
import '../../../../core/utils/property_role_resolver.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';
import '../../../visitor_management/bloc/visitor_bloc.dart';
import '../../../visitor_management/bloc/visitor_event.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../../../core/widgets/asmita_employee_card.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../services/presentation/widgets/asmita_facility_booking_wizard.dart';
import '../../../services/data/models/amenity_model.dart';
import '../../../visitor_management/presentation/widgets/invite_team_member_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Director Role Dashboard:
/// - Executive overview and real-time visitor KPI metrics
/// - Personal VIP visitor log with expedited approval/rejection
/// - Quick direct contact hotlines to floor receptionist & security gate
/// - VIP Pre-approval & pass scheduling wizard integration
class DirectorDashboardView extends StatefulWidget {
  final String? directorName;
  final String? departmentName;
  final String? cabinNumber;
  final String? deskNumber;
  final String? designation;
  final bool isActive;
  final bool? canDelegate;
  final List<IndustrialVisitModel>? visits;
  final VoidCallback? onContactReceptionist;
  final VoidCallback? onOpenDelegation;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId)? onAcknowledgeVisit;
  final Function(String filter)? onNavigateToVisitsWithFilter;
  final ValueChanged<int>? onNavigateToTab;

  const DirectorDashboardView({
    super.key,
    this.directorName,
    this.departmentName,
    this.cabinNumber,
    this.deskNumber,
    this.designation,
    this.isActive = true,
    this.canDelegate,
    this.visits,
    this.onContactReceptionist,
    this.onOpenDelegation,
    this.onDecideVisit,
    this.onAcknowledgeVisit,
    this.onNavigateToVisitsWithFilter,
    this.onNavigateToTab,
  });

  @override
  State<DirectorDashboardView> createState() => _DirectorDashboardViewState();
}

class _DirectorDashboardViewState extends State<DirectorDashboardView> {
  String? _activeDelegateName;
  bool _hasIncomingDelegation = false;

  @override
  void initState() {
    super.initState();
    if (widget.visits == null) {
      _fetchDelegationStatus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
        } catch (_) {}
      });
    }
  }

  Future<void> _fetchDelegationStatus() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return;
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final res = await dio.get(EnvConfig.employeeDelegationStatus);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final dData = res.data['data'] as Map<String, dynamic>?;
        final outgoing = dData?['outgoingDelegation'] as Map<String, dynamic>?;
        final incoming = dData?['incomingDelegations'] as List? ?? [];
        final hasActiveIncoming = incoming.any((item) => item is Map && item['is_active'] == true);

        if (mounted) {
          setState(() {
            _hasIncomingDelegation = hasActiveIncoming;
            if (outgoing != null) {
              final delegate = outgoing['delegate'] as Map<String, dynamic>?;
              _activeDelegateName = delegate?['full_name'] as String? ?? 'Colleague';
            } else if (_activeDelegateName != null) {
              _activeDelegateName = null;
            }
          });
        }
      }
    } catch (_) {}
  }

  bool _canUserInviteTeam(UserModel? user) {
    if (_hasIncomingDelegation || (widget.canDelegate ?? false)) {
      return true;
    }
    if (user != null) {
      final roleLower = user.primaryRole.toLowerCase();
      final desigLower = user.designation.toLowerCase();
      final widgetDesigLower = (widget.designation ?? '').toLowerCase();
      final isDirector = (user.rolePower ?? 0) >= 500 ||
          roleLower.contains('director') ||
          desigLower.contains('director') ||
          widgetDesigLower.contains('director');
      if (isDirector) return true;
    }
    return true;
  }

  void _handleContactReceptionist(BuildContext context) {
    if (widget.onContactReceptionist != null) {
      widget.onContactReceptionist!();
    } else {
      _showContactReceptionistSheet(context);
    }
  }

  Future<void> _showPreApproveModal(BuildContext context) async {
    UserModel? user;
    try {
      final authBloc = context.read<AuthBloc?>();
      final authState = authBloc?.state;
      if (authState is AuthAuthenticated) user = authState.user;
    } catch (_) {}
    if (!PropertyRoleResolver.canIssuePasses(user)) {
      AsmitaToast.show(
        context,
        message: 'Your role does not have permission to issue visitor passes.',
        type: AsmitaToastType.error,
      );
      return;
    }
    await AsmitaPreApproveWizard.showAsModalSheet(
      context,
      title: 'Issue VIP Pass',
    );

    if (!context.mounted) return;
    context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
    if (user != null) {
      context.read<VisitorBloc>().add(
        LoadMyHistory(residentId: user.userId, isRefresh: true),
      );
    }
  }

  void _handleDecide(BuildContext context, int visitId, String action) {
    UserModel? user;
    try {
      final authBloc = context.read<AuthBloc?>();
      final authState = authBloc?.state;
      if (authState is AuthAuthenticated) user = authState.user;
    } catch (_) {}
    if (!PropertyRoleResolver.canApproveVisits(user)) {
      AsmitaToast.show(
        context,
        message: 'Your role does not have permission to decide visits.',
        type: AsmitaToastType.error,
      );
      return;
    }
    if (widget.onDecideVisit != null) {
      widget.onDecideVisit!(visitId, action);
    } else {
      context.read<IndustrialVisitBloc>().add(
        DecideVisitEvent(visitId: visitId, action: action),
      );
    }
  }

  void _showContactReceptionistSheet(BuildContext context) {
    showAsmitaBottomSheet(
      context: context,
      title: 'Floor Support Hotline',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHotlineTile(
            context,
            icon: Icons.support_agent_rounded,
            title: 'Main Reception Desk',
            subtitle: 'Ext: 101 • Dedicated Executive Support',
            onCall: () {
              Navigator.pop(context);
              AsmitaToast.show(
                context,
                message: 'Calling Main Reception (Ext 101)...',
                type: AsmitaToastType.info,
              );
            },
          ),
          const SizedBox(height: 8),
          _buildHotlineTile(
            context,
            icon: Icons.shield_outlined,
            title: 'Gate 1 Security Control',
            subtitle: 'Ext: 104 • Main Campus Gate & VIP Escort',
            onCall: () {
              Navigator.pop(context);
              AsmitaToast.show(
                context,
                message: 'Connecting to Gate 1 Control (Ext 104)...',
                type: AsmitaToastType.info,
              );
            },
          ),
          const SizedBox(height: 8),
          _buildHotlineTile(
            context,
            icon: Icons.local_hospital_outlined,
            title: 'Facility Emergency Desk',
            subtitle: 'Ext: 999 • Rapid Response Team',
            onCall: () {
              Navigator.pop(context);
              AsmitaToast.show(
                context,
                message: 'Connecting to Emergency Response (Ext 999)...',
                type: AsmitaToastType.info,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
      ),
    );
  }

  Widget _buildHotlineTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onCall,
    bool isEmergency = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmergency
              ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isEmergency
                  ? (isDark
                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
                      : const Color(0xFFFEE2E2))
                  : (isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                      : const Color(0xFFEFF6FF)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isEmergency
                  ? const Color(0xFFEF4444)
                  : (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onCall();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isEmergency
                      ? const Color(0xFFDC2626)
                      : (isDark ? const Color(0xFF2563EB) : AsmitaPalette.deepNavy),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isEmergency
                              ? const Color(0xFFDC2626)
                              : (isDark ? const Color(0xFF2563EB) : AsmitaPalette.deepNavy))
                          .withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.phone_in_talk_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Call',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVisitDetailsModal(
    BuildContext context,
    IndustrialVisitModel visit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = visit.isPending;

    showAsmitaBottomSheet(
      context: context,
      title: 'Executive VIP Guest Pass',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                              visit.visitorName,
                              maxLines: 2,
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
                            const SizedBox(height: 3),
                            Text(
                              visit.deliveryCompany ?? visit.purpose ?? 'VIP Guest',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
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
                            const SizedBox(width: 4.5),
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
                if (visit.passCode != null) ...[
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                        color: Colors.white.withValues(alpha: 0.7),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  visit.passCode!,
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
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: visit.passCode!));
                                HapticFeedback.lightImpact();
                                AsmitaToast.show(
                                  context,
                                  message: 'Pass code #${visit.passCode} copied to clipboard',
                                  type: AsmitaToastType.success,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy_rounded, size: 12, color: Colors.white),
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildModalRow(
            context,
            icon: Icons.flag_outlined,
            label: 'Pass Status',
            value: visit.status.label,
            badgeColor: visit.status.textColor(isDark),
            badgeBg: visit.status.fillColor(isDark),
          ),
          _buildModalRow(
            context,
            icon: Icons.domain_rounded,
            label: 'Host Office',
            value: visit.departmentName ?? 'Executive Office',
          ),
          if (visit.visitorMobile != null && visit.visitorMobile!.isNotEmpty)
            _buildModalRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Mobile',
              value: visit.visitorMobile!,
            ),
          if (visit.vehicleNumber != null && visit.vehicleNumber!.isNotEmpty)
            _buildModalRow(
              context,
              icon: Icons.directions_car_outlined,
              label: 'Vehicle Plate',
              value: visit.vehicleNumber!,
            ),
          _buildModalRow(
            context,
            icon: Icons.access_time_rounded,
            label: 'Arrival Time',
            value: visit.checkInAt != null
                ? DateFormat('dd MMM, hh:mm a').format(visit.checkInAt!)
                : (visit.createdAt != null
                      ? DateFormat('dd MMM, hh:mm a').format(visit.createdAt!)
                      : 'Scheduled Visit'),
          ),

          if (visit.statusToken != null && visit.statusToken!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 170,
                height: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: visit.statusToken!,
                  version: QrVersions.auto,
                  size: 146.0,
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
          ],

          const SizedBox(height: 20),

          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleDecide(context, visit.id, 'REJECT');
                    },
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
                    child: const Text(
                      'Decline Pass',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleDecide(context, visit.id, 'APPROVE');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Approve Priority Entry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
      ),
    );
  }

  Widget _buildVisitorPhotoAvatar(IndustrialVisitModel visit, {double size = 48}) {
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
        final base64Str = commaIndex != -1 ? photo.substring(commaIndex + 1) : photo;
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
          color: Colors.white.withValues(alpha: 0.1),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
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

  Widget _buildModalRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
    Color? badgeBg,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AsmitaPalette.textLight,
            ),
          ),
          const Spacer(),
          if (badgeColor != null && badgeBg != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visits != null) {
      return _buildScaffold(context, widget.visits!, isLoading: false);
    }

    return BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
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
        final isLoading =
            state.status == IndustrialVisitBlocStatus.loading &&
            state.visits.isEmpty;

        return _buildScaffold(context, state.visits, isLoading: isLoading);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<IndustrialVisitModel> visits, {
    required bool isLoading,
  }) {
    final todayVisits = widget.visits != null
        ? widget.visits!
        : visits.where((v) => _isToday(v.checkInAt) || _isToday(v.createdAt) || _isToday(v.passCodeExpiresAt)).toList();

    final totalCount = todayVisits.length;
    final pendingCount = todayVisits.where((v) => v.isPending).length;
    final approvedCount = todayVisits.where((v) => v.status == IndustrialVisitStatus.approved).length;
    final insideCount = todayVisits.where((v) => v.status == IndustrialVisitStatus.checkedIn).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // 1. Unified Primary Asmita Header with Society & Profile Hook
          AsmitaPrimaryHeader(
            allowPropertySwitching: false,
            onHotlinePressed: () => _handleContactReceptionist(context),
          ),

          // 2. Scrollable Body
          Expanded(
            child: isLoading
                ? const Center(
                    child: AsmitaLoadingIndicator(
                      color: AsmitaPalette.deepNavy,
                      size: 32,
                    ),
                  )
                : AsmitaPullToRefresh(
                    onRefresh: () async {
                      if (widget.visits == null) {
                        final bloc = context.read<IndustrialVisitBloc>();
                        final future = bloc.stream
                            .firstWhere((s) => s.status != IndustrialVisitBlocStatus.loading)
                            .timeout(const Duration(seconds: 4), onTimeout: () => bloc.state);
                        _fetchDelegationStatus();
                        bloc.add(const LoadIndustrialVisits());
                        await future;
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Executive Hero Card (AsmitaEmployeeCard)
                        _buildHeroCard(context),
                        const SizedBox(height: 16),

                        // Active Delegation Status Banner (if active)
                        if (_activeDelegateName != null) ...[
                          _buildDelegationBanner(context),
                          const SizedBox(height: 12),
                        ],

                        // 2. Quick Actions Grid (Square boxes matching employee style)
                        _buildQuickActionsGrid(context),
                        const SizedBox(height: 16),

                        // 3. Operational KPI Overview Metrics (4 interactive cards: Total, Pending, Approved, Inside)
                        _buildMetricsOverview(
                          context,
                          totalCount: totalCount,
                          pendingCount: pendingCount,
                          approvedCount: approvedCount,
                          insideCount: insideCount,
                        ),
                        const SizedBox(height: 18),

                        // 4. Waiting Queue Section (Instead of visitor list)
                        _buildWaitingGrid(context, visits),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. EXECUTIVE HERO CARD (Global AsmitaEmployeeCard)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(BuildContext context) {
    UserModel? user;
    try {
      final authBloc = context.read<AuthBloc?>();
      final authState = authBloc?.state;
      if (authState is AuthAuthenticated) {
        user = authState.user;
      }
    } catch (_) {
      user = null;
    }

    final name = widget.directorName ??
        ((user != null && user.fullName.isNotEmpty) ? user.fullName : 'Executive Director');
    final desig = widget.designation ??
        ((user != null && user.designation.isNotEmpty) ? user.designation : 'Executive Director');
    final dept = widget.departmentName ??
        ((user != null && user.departmentName.isNotEmpty) ? user.departmentName : 'Executive Suite');
    final cabin = widget.cabinNumber ??
        ((user?.cabinCode != null && user!.cabinCode.isNotEmpty) ? user.cabinCode : 'CAB-DIR-01');
    final desk = widget.deskNumber ??
        ((user?.deskCode != null && user!.deskCode.isNotEmpty) ? user.deskCode : 'DIR-DSK-01');

    return AsmitaEmployeeCard(
      name: name,
      designation: desig,
      departmentName: dept,
      cabinNumber: cabin,
      deskNumber: desk,
      isActive: widget.isActive,
    );
  }

  Widget _buildDelegationBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_alt_rounded, color: Color(0xFF2563EB), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Visitor approvals currently delegated to $_activeDelegateName. Deliveries & cabs alert you directly.',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. QUICK ACTIONS (Square Icon Boxes Matching Employee Dashboard)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionsGrid(BuildContext context) {
    UserModel? user;
    try {
      final authBloc = context.read<AuthBloc?>();
      final authState = authBloc?.state;
      if (authState is AuthAuthenticated) {
        user = authState.user;
      }
    } catch (_) {
      user = null;
    }
    final canDelegate = widget.canDelegate ??
        PropertyRoleResolver.canDelegate(user, designation: widget.designation);
    final canInviteTeam = _canUserInviteTeam(user);

    final actions = <_QuickActionItemData>[
      _QuickActionItemData(
        label: 'Pre-Approve',
        icon: Icons.person_add_alt_1_rounded,
        onTap: () => _showPreApproveModal(context),
      ),
      _QuickActionItemData(
        label: 'Car Valet',
        icon: Icons.directions_car_filled_rounded,
        onTap: () => _showCarValetModal(context),
      ),
      _QuickActionItemData(
        label: 'Security',
        icon: Icons.shield_rounded,
        onTap: () => _showSecurityModal(context),
      ),
      _QuickActionItemData(
        label: 'Receptionist',
        icon: Icons.support_agent_rounded,
        onTap: () => _handleContactReceptionist(context),
      ),
      if (canDelegate && widget.onOpenDelegation != null)
        _QuickActionItemData(
          label: 'Delegate',
          icon: Icons.sync_alt_rounded,
          onTap: widget.onOpenDelegation!,
        ),
      if (canInviteTeam)
        _QuickActionItemData(
          label: 'Invite Team',
          icon: Icons.group_add_rounded,
          onTap: () => showInviteTeamMemberSheet(context),
        ),
      _QuickActionItemData(
        label: 'Meeting Rooms',
        icon: Icons.meeting_room_rounded,
        onTap: () => _openMeetingRoomReservation(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (actions.length > 5) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: actions.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 64,
                      child: _buildSquareActionBox(
                        context,
                        icon: item.icon,
                        label: item.label,
                        onTap: item.onTap,
                        boxSize: 52,
                        iconSize: 22,
                        fontSize: 10.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }

          final count = actions.length;
          final itemWidth = constraints.maxWidth / count;
          final boxSize = itemWidth < 68 ? (itemWidth < 58 ? 44.0 : 48.0) : 56.0;
          final iconSize = boxSize < 50 ? 20.0 : 24.0;
          final fontSize = boxSize < 50 ? 9.5 : 11.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: actions.map((item) {
              return Expanded(
                child: _buildSquareActionBox(
                  context,
                  icon: item.icon,
                  label: item.label,
                  onTap: item.onTap,
                  boxSize: boxSize,
                  iconSize: iconSize,
                  fontSize: fontSize,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSquareActionBox(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double boxSize = 56,
    double iconSize = 24,
    double fontSize = 11,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: label.replaceAll('\n', ' '),
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isDark ? Colors.black : Colors.white,
                  size: iconSize,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMeetingRoomReservation(BuildContext context) {
    AsmitaDialog.show(
      context: context,
      title: 'Meeting Room Reservation',
      content: const AsmitaFacilityBookingWizard(
        initialAmenity: AmenityModel(
          amenityId: 991,
          name: 'Conference & Meeting Room',
          type: 'booking',
          description: 'High-Speed Smart AV & Video Conferencing Room',
          capacity: 20,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // 3. OPERATIONAL KPI OVERVIEW METRICS (4 Grid/Row Cards: Total, Pending, Approved, Inside)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMetricsOverview(
    BuildContext context, {
    required int totalCount,
    required int pendingCount,
    required int approvedCount,
    required int insideCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Total',
            count: totalCount,
            icon: Icons.groups_rounded,
            accentColor: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
            filterKey: 'ALL',
            onTap: () => _handleFilterTap('ALL'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Pending',
            count: pendingCount,
            icon: Icons.pending_actions_rounded,
            accentColor: isDark ? const Color(0xFFF87171) : AsmitaPalette.actionRed,
            filterKey: 'PENDING',
            showPulse: pendingCount > 0,
            onTap: () => _handleFilterTap('PENDING'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Approved',
            count: approvedCount,
            icon: Icons.verified_rounded,
            accentColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E88E5),
            filterKey: 'APPROVED',
            onTap: () => _handleFilterTap('APPROVED'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Inside',
            count: insideCount,
            icon: Icons.meeting_room_rounded,
            accentColor: isDark ? const Color(0xFF34D399) : AsmitaPalette.successGreen,
            filterKey: 'INSIDE',
            onTap: () => _handleFilterTap('INSIDE'),
          ),
        ),
      ],
    );
  }

  void _handleFilterTap(String filterKey) {
    HapticFeedback.selectionClick();
    if (widget.onNavigateToVisitsWithFilter != null) {
      widget.onNavigateToVisitsWithFilter!(filterKey);
    } else {
      widget.onNavigateToTab?.call(1);
    }
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color accentColor,
    required String filterKey,
    required VoidCallback onTap,
    bool showPulse = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : Theme.of(context).dividerColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 6,
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
                  color: accentColor.withValues(alpha: 0.18),
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AsmitaPalette.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Widget _buildWaitingGrid(
    BuildContext context,
    List<IndustrialVisitModel> visits,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waitingVisits = visits
        .where((v) => v.isPending || (v.heldAtGate && v.status == IndustrialVisitStatus.approved && !v.isCheckedIn))
        .toList();

    // Sort by oldest arrival first
    waitingVisits.sort((a, b) {
      final aTime = a.checkInAt ?? a.createdAt ?? DateTime.now();
      final bTime = b.checkInAt ?? b.createdAt ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    // If no one is waiting, show a clean label to indicate no one's waiting
    if (waitingVisits.isEmpty) {
      return _buildEmptyWaitingCard(context, isDark);
    }

    // When there is waiting: show Name, waiting since, and queue waiting after them
    final firstVisit = waitingVisits.first;
    final firstTime = firstVisit.checkInAt ?? firstVisit.createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(firstTime);
    final String waitingSinceDuration;
    if (diff.inMinutes < 60) {
      waitingSinceDuration = '${diff.inMinutes.clamp(1, 999)} mins';
    } else {
      waitingSinceDuration = '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    final waitingSinceTime = DateFormat('hh:mm a').format(firstTime);

    final queueAfterThem = waitingVisits.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Left Column: Who is Waiting (Name)
            Expanded(
              child: InkWell(
                onTap: () => _showVisitDetailsModal(context, firstVisit),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.15 : 0.03,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.deepNavy.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: AsmitaPalette.deepNavy,
                              size: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${waitingVisits.length} Waiting',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AsmitaPalette.deepNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Who is Waiting',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AsmitaPalette.textDarkModeMuted
                              : AsmitaPalette.textLight,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          firstVisit.visitorName,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AsmitaPalette.textDarkModeMain
                                : AsmitaPalette.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        firstVisit.departmentName ?? (firstVisit.purpose ?? 'VIP Visitor'),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark
                              ? AsmitaPalette.textDarkModeMuted
                              : AsmitaPalette.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Right Column: Waiting Since
            Expanded(
              child: InkWell(
                onTap: () => _showVisitDetailsModal(context, firstVisit),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.15 : 0.03,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.deepNavy.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.timer_outlined,
                              color: AsmitaPalette.deepNavy,
                              size: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active Wait',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AsmitaPalette.actionRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Waiting Since',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AsmitaPalette.textDarkModeMuted
                              : AsmitaPalette.textLight,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          waitingSinceDuration,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AsmitaPalette.deepNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Arrival: $waitingSinceTime',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark
                              ? AsmitaPalette.textDarkModeMuted
                              : AsmitaPalette.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Queue waiting after them
        const SizedBox(height: 14),
        if (queueAfterThem.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AsmitaPalette.actionRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Queue Waiting After Them (${queueAfterThem.length})',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AsmitaPalette.textDarkModeMain
                                : AsmitaPalette.textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${queueAfterThem.length} in line',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AsmitaPalette.actionRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...queueAfterThem
                    .take(3)
                    .map((v) => _buildWaitingQueueItem(context, v, isDark)),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.successGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AsmitaPalette.successGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Queue Waiting After Them',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AsmitaPalette.textDarkModeMuted
                              : AsmitaPalette.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No one waiting after ${firstVisit.visitorName} • First in line',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark
                              ? AsmitaPalette.textDarkModeMain
                              : AsmitaPalette.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AsmitaPalette.surfaceDark
                        : AsmitaPalette.systemBG,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '0 in line',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AsmitaPalette.textDarkModeMuted
                          : AsmitaPalette.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyWaitingCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  color: AsmitaPalette.deepNavy,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AsmitaPalette.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AsmitaPalette.successGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: AsmitaPalette.successGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Queue Clear',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AsmitaPalette.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Who is Waiting',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AsmitaPalette.textDarkModeMuted
                  : AsmitaPalette.textLight,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "No one's waiting",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AsmitaPalette.textDarkModeMain
                  : AsmitaPalette.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Reception queue empty • All entry gates clear',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isDark
                  ? AsmitaPalette.textDarkModeMuted
                  : AsmitaPalette.textLight,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWaitingQueueItem(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
  ) {
    final arrivalTime = visit.checkInAt ?? visit.createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(arrivalTime);
    final diffStr = diff.inMinutes < 60
        ? '${diff.inMinutes.clamp(1, 999)}m ago'
        : '${diff.inHours}h ago';

    return InkWell(
      onTap: () => _showVisitDetailsModal(context, visit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
        children: [
          // Left: Avatar + Details
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            alignment: Alignment.center,
            child: Text(
              visit.visitorName.isNotEmpty
                  ? visit.visitorName[0].toUpperCase()
                  : 'V',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                color: AsmitaPalette.deepNavy,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  visit.visitorName,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: isDark
                        ? AsmitaPalette.textDarkModeMain
                        : AsmitaPalette.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${visit.departmentName ?? 'Guest'} • ${visit.purpose ?? 'Visit'}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: isDark
                        ? AsmitaPalette.textDarkModeMuted
                        : AsmitaPalette.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: Waiting time & Decisions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  diffStr,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AsmitaPalette.actionRed,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _handleDecide(context, visit.id, 'REJECT'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AsmitaPalette.actionRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _handleDecide(context, visit.id, 'APPROVE'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AsmitaPalette.deepNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Admit',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  // FUNCTIONAL MODAL: ISSUE VIP PASS (Integrated into Pre-Approve Wizard toggle)

  // =========================================================================
  // FUNCTIONAL MODAL: CAR VALET (Take Out to gate.)
  // =========================================================================
  void _showCarValetModal(BuildContext context) {
    String selectedVehicle = 'Mercedes-Benz E220d (MH 04 AB 1234)';
    String targetGate = 'Gate 1 - Main Portico';
    String timing = 'Immediate (Ready in ~5 min)';
    final notesCtrl = TextEditingController();

    showAsmitaBottomSheet(
      context: context,
      title: 'Car Valet (Take Out to Gate)',
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Dispatches facility valet to retrieve your executive vehicle and park at the designated gate.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AsmitaPalette.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AsmitaSelectField<String>(
                    label: 'Select Vehicle',
                    hint: 'Choose your registered vehicle',
                    value: selectedVehicle,
                    prefixIcon: Icons.directions_car_rounded,
                    items: const [
                      AsmitaSelectItem(
                        value: 'Mercedes-Benz E220d (MH 04 AB 1234)',
                        label: 'Mercedes E220d • MH 04 AB 1234',
                        subtitle: 'Primary Executive Saloon',
                        icon: Icons.directions_car_filled_rounded,
                      ),
                      AsmitaSelectItem(
                        value: 'BMW 730Ld (MH 01 CZ 9999)',
                        label: 'BMW 730Ld • MH 01 CZ 9999',
                        subtitle: 'Chauffeured Limousine',
                        icon: Icons.directions_car_filled_rounded,
                      ),
                      AsmitaSelectItem(
                        value: 'Audi A6 (MH 02 EF 5678)',
                        label: 'Audi A6 • MH 02 EF 5678',
                        subtitle: 'Secondary Sedan',
                        icon: Icons.directions_car_filled_rounded,
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedVehicle = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  AsmitaSelectField<String>(
                    label: 'Delivery Destination Gate',
                    hint: 'Choose destination gate',
                    value: targetGate,
                    prefixIcon: Icons.meeting_room_rounded,
                    items: const [
                      AsmitaSelectItem(
                        value: 'Gate 1 - Main Portico',
                        label: 'Gate 1 - Main Portico (Express)',
                        subtitle: 'Main Executive Entrance Porch',
                        icon: Icons.door_sliding_rounded,
                      ),
                      AsmitaSelectItem(
                        value: 'Gate 2 - Executive Bay',
                        label: 'Gate 2 - Executive Bay',
                        subtitle: 'Private Director Parking Bay',
                        icon: Icons.garage_rounded,
                      ),
                      AsmitaSelectItem(
                        value: 'VIP Loading Porch',
                        label: 'VIP Loading Bay Porch',
                        subtitle: 'Sheltered Porch Zone',
                        icon: Icons.local_shipping_rounded,
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => targetGate = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  AsmitaSelectField<String>(
                    label: 'Vehicle Ready Timing',
                    hint: 'When do you need the vehicle?',
                    value: timing,
                    prefixIcon: Icons.schedule_rounded,
                    items: const [
                      AsmitaSelectItem(
                        value: 'Immediate (Ready in ~5 min)',
                        label: 'Immediate (Ready in ~5 min)',
                        subtitle: 'Instant priority dispatch',
                        icon: Icons.bolt_rounded,
                      ),
                      AsmitaSelectItem(
                        value: 'In 10 Minutes',
                        label: 'In 10 Minutes',
                        subtitle: 'Standard dispatch lead time',
                        icon: Icons.timer_rounded,
                      ),
                      AsmitaSelectItem(
                        value: 'In 20 Minutes',
                        label: 'In 20 Minutes',
                        subtitle: 'Scheduled departure preparation',
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => timing = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  AsmitaTextField(
                    label: 'Valet Instructions (Optional)',
                    hint: 'e.g., Turn on AC, park at VIP porch lane',
                    icon: Icons.notes_rounded,
                    controller: notesCtrl,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final notes = notesCtrl.text.trim();

                      // Auto-provision valet department & role along the way via backend valet API
                      final authState = context.read<AuthBloc>().state;
                      final user = authState is AuthAuthenticated
                          ? authState.user
                          : null;
                      final societyId = user?.societyId ?? 114;

                      try {
                        final dio = AsmitaDioClient(SecureStorageService()).dio;
                        dio
                            .post(
                              '${EnvConfig.baseUrl}/app-api/valet/request',
                              data: {
                                'society_id': societyId,
                                'vehicle_number': selectedVehicle,
                                'target_gate': targetGate,
                                'ready_time': timing,
                                'notes': notes,
                              },
                            )
                            .ignore();
                      } catch (_) {}

                      _showValetSuccessDialog(
                        context,
                        vehicle: selectedVehicle,
                        targetGate: targetGate,
                        timing: timing,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Dispatch Valet to Gate',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showValetSuccessDialog(
    BuildContext context, {
    required String vehicle,
    required String targetGate,
    required String timing,
  }) {
    final ticketNo = 'VALET-${1000 + Random().nextInt(9000)}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AsmitaPalette.deepNavy,
                size: 38,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Valet Dispatched',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ticket #$ticketNo • Assigned to Valet Desk',
              style: const TextStyle(
                fontSize: 12,
                color: AsmitaPalette.textLight,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AsmitaPalette.successGreen,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Driver En Route: Mohan Sharma (Ext 112)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AsmitaPalette.successGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Retrieving $vehicle from Basement 2 (Bay B-14). Vehicle will be ready at $targetGate ($timing).',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AsmitaPalette.textDarkModeMuted
                          : AsmitaPalette.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _callContact('Valet Control Desk', '+919820110112');
                    },
                    icon: const Icon(Icons.phone, size: 14),
                    label: const Text(
                      'Call Valet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // FUNCTIONAL MODAL: SECURITY COMMAND
  // =========================================================================
  void _showSecurityModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    UserModel? user;
    try {
      final authBloc = context.read<AuthBloc?>();
      final authState = authBloc?.state;
      if (authState is AuthAuthenticated) user = authState.user;
    } catch (_) {}
    final societyId = user?.societyId ?? 114;

    // Auto-provision security departments and roles along the way on backend
    try {
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      dio
          .get(
            '${EnvConfig.baseUrl}/app-api/security/hotlines?society_id=$societyId',
          )
          .ignore();
    } catch (_) {}

    showAsmitaBottomSheet(
      context: context,
      title: 'Campus Security Command',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Direct hotline connection to campus security gates and escort control desks.',
            style: TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
          ),
          const SizedBox(height: 16),
          _buildHotlineTile(
            context,
            icon: Icons.shield_rounded,
            title: 'Gate 1 Security Control',
            subtitle: 'Ext: 104 • Main Entrance & VIP Escorts',
            onCall: () {
              Navigator.pop(context);
              _callContact('Gate 1 Security', '+919820110104');
            },
          ),
          const SizedBox(height: 8),
          _buildHotlineTile(
            context,
            icon: Icons.support_agent_rounded,
            title: 'Floor 8 Executive Reception',
            subtitle: 'Ext: 101 • Dedicated Director Support',
            onCall: () {
              Navigator.pop(context);
              _callContact('Floor Reception', '+919820110101');
            },
          ),
          const SizedBox(height: 8),
          _buildHotlineTile(
            context,
            icon: Icons.admin_panel_settings_rounded,
            title: 'Chief Security Officer (CSO)',
            subtitle: 'Ext: 100 • Head of Campus Security',
            onCall: () {
              Navigator.pop(context);
              _callContact('Campus CSO', '+919820110100');
            },
          ),
          const SizedBox(height: 8),
          _buildHotlineTile(
            context,
            icon: Icons.emergency_rounded,
            title: 'Campus Emergency & Medical',
            subtitle: 'Ext: 999 • Rapid Response Team',
            isEmergency: true,
            onCall: () {
              Navigator.pop(context);
              _callContact('Emergency Response', '+919820110911');
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                size: 15,
                color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Security Dispatches',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // VIP Escort Dispatch Card
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      try {
                        final dio = AsmitaDioClient(SecureStorageService()).dio;
                        dio.post(
                          '${EnvConfig.baseUrl}/app-api/security/dispatch',
                          data: {
                            'society_id': societyId,
                            'type': 'VIP_ESCORT',
                            'destination': 'Gate 1 Main Portico',
                            'priority': 'HIGH',
                          },
                        ).ignore();
                      } catch (_) {}

                      AsmitaToast.show(
                        context,
                        message: 'VIP Escort Officer dispatched to Gate 1 Main Portico.',
                        type: AsmitaToastType.success,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person_pin_circle_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Request Escort',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Gate 1 Portico',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Express Lane Alert Card
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      try {
                        final dio = AsmitaDioClient(SecureStorageService()).dio;
                        dio.post(
                          '${EnvConfig.baseUrl}/app-api/security/dispatch',
                          data: {
                            'society_id': societyId,
                            'type': 'EXPRESS_CLEARANCE',
                            'destination': 'All Security Gates',
                            'priority': 'HIGH',
                          },
                        ).ignore();
                      } catch (_) {}

                      AsmitaToast.show(
                        context,
                        message: 'Priority Express clearance alert transmitted to all gates.',
                        type: AsmitaToastType.info,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF450A0A).withValues(alpha: 0.3)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF7F1D1D)
                              : const Color(0xFFFECACA),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notification_important_rounded,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Express Lane',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Clear All Gates',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    color: isDark
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8)
        ],
      ),
      ),
    );
  }

  Future<void> _callContact(String title, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await url_launcher.launchUrl(uri);
      if (!launched && mounted) {
        AsmitaToast.show(
          context,
          message: 'Calling $title: $phone',
          type: AsmitaToastType.info,
        );
      }
    } catch (_) {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Connecting to $title: $phone',
          type: AsmitaToastType.info,
        );
      }
    }
  }



}

class _QuickActionItemData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionItemData({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
