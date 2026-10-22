import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_dialog.dart';
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
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Director Role Dashboard:
/// - Executive overview and real-time visitor KPI metrics
/// - Personal VIP visitor log with expedited approval/rejection
/// - Quick direct contact hotlines to floor receptionist & security gate
/// - VIP Pre-approval & pass scheduling wizard integration
class DirectorDashboardView extends StatefulWidget {
  final List<IndustrialVisitModel>? visits;
  final VoidCallback? onContactReceptionist;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId)? onAcknowledgeVisit;

  const DirectorDashboardView({
    super.key,
    this.visits,
    this.onContactReceptionist,
    this.onDecideVisit,
    this.onAcknowledgeVisit,
  });

  @override
  State<DirectorDashboardView> createState() => _DirectorDashboardViewState();
}

class _DirectorDashboardViewState extends State<DirectorDashboardView> {
  @override
  void initState() {
    super.initState();
    if (widget.visits == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
        } catch (_) {}
      });
    }
  }

  void _handleContactReceptionist(BuildContext context) {
    if (widget.onContactReceptionist != null) {
      widget.onContactReceptionist!();
    } else {
      _showContactReceptionistSheet(context);
    }
  }

  Future<void> _showPreApproveModal(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (!PropertyRoleResolver.canIssuePasses(user)) {
      AsmitaToast.show(
        context,
        message: 'Your role does not have permission to issue visitor passes.',
        type: AsmitaToastType.error,
      );
      return;
    }
    await showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Issue VIP Pass',
        content: AsmitaPreApproveWizard(),
      ),
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
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
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
      title: 'Campus Support Hotlines',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHotlineTile(
            context,
            icon: Icons.support_agent_rounded,
            title: 'Floor 8 Reception Desk',
            subtitle: 'Ext: 101 • Dedicated Executive Support',
            onCall: () {
              Navigator.pop(context);
              AsmitaToast.show(
                context,
                message: 'Connecting to Floor Reception (Ext 101)...',
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
    );
  }

  Widget _buildHotlineTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onCall,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AsmitaPalette.deepNavy, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
        ),
        trailing: ElevatedButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.phone, size: 14),
          label: const Text(
            'Call',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.deepNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AsmitaPalette.deepNavy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: Text(
                    visit.visitorName.isNotEmpty
                        ? visit.visitorName[0].toUpperCase()
                        : 'V',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.visitorName,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        visit.deliveryCompany ?? visit.purpose ?? 'VIP Visitor',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (visit.passCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'PASS #${visit.passCode}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
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
    final pendingCount = visits.where((v) => v.isPending).length;
    final approvedCount = visits
        .where((v) => v.status == IndustrialVisitStatus.approved)
        .length;
    final checkedInCount = visits
        .where((v) => v.status == IndustrialVisitStatus.checkedIn)
        .length;

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
            child: RefreshIndicator(
              color: AsmitaPalette.deepNavy,
              onRefresh: () async {
                if (widget.visits == null) {
                  context.read<IndustrialVisitBloc>().add(
                    const LoadIndustrialVisits(),
                  );
                }
              },
              child: isLoading
                  ? const Center(
                      child: AsmitaLoadingIndicator(
                        color: AsmitaPalette.deepNavy,
                        size: 32,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Executive KPI Stat Cards
                          _buildKpiRow(
                            context,
                            pendingCount: pendingCount,
                            approvedCount: approvedCount,
                            checkedInCount: checkedInCount,
                          ),
                          const SizedBox(height: 20),

                          // 4-Icon Executive Action Grid
                          _buildFourIconGrid(context),
                          const SizedBox(height: 18),

                          // 2-Column Waiting Grid (Who is Waiting, Waiting Since)
                          _buildWaitingGrid(context, visits),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(
    BuildContext context, {
    required int pendingCount,
    required int approvedCount,
    required int checkedInCount,
  }) {
    return Row(
      children: [
        _kpiCard(
          context,
          label: 'Pending',
          value: '$pendingCount',
          color: AsmitaPalette.actionRed,
          icon: Icons.pending_actions_rounded,
          showPulse: pendingCount > 0,
        ),
        const SizedBox(width: 8),
        _kpiCard(
          context,
          label: 'Approved',
          value: '$approvedCount',
          color: AsmitaPalette.deepNavy,
          icon: Icons.verified_rounded,
        ),
        const SizedBox(width: 8),
        _kpiCard(
          context,
          label: 'Inside HQ',
          value: '$checkedInCount',
          color: AsmitaPalette.successGreen,
          icon: Icons.meeting_room_rounded,
        ),
      ],
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool showPulse = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Squircle Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.25 : 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: color, size: 20),
                    if (showPulse)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: color,
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
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AsmitaPalette.textDarkModeMain
                    : AsmitaPalette.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildFourIconGrid(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _ExecutiveActionItem(
        title: 'Pre-Approve',
        icon: Icons.event_available_rounded,
        containerColor: isDark
            ? AsmitaPalette.surfaceDark
            : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
        iconColor: isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy,
        onTap: () => _showPreApproveModal(context),
      ),
      _ExecutiveActionItem(
        title: 'Issue VIP Pass',
        icon: Icons.workspace_premium_rounded,
        containerColor: isDark
            ? AsmitaPalette.surfaceDark
            : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
        iconColor: isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy,
        onTap: () => _showVipPassModal(context),
      ),
      _ExecutiveActionItem(
        title: 'Car Valet',
        icon: Icons.directions_car_filled_rounded,
        containerColor: isDark
            ? AsmitaPalette.surfaceDark
            : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
        iconColor: isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy,
        onTap: () => _showCarValetModal(context),
      ),
      _ExecutiveActionItem(
        title: 'Security',
        icon: Icons.shield_rounded,
        containerColor: isDark
            ? AsmitaPalette.surfaceDark
            : AsmitaPalette.actionRed.withValues(alpha: 0.08),
        iconColor: AsmitaPalette.actionRed,
        onTap: () => _showSecurityModal(context),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
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
          Text(
            'Quick Actions',
            style: textTheme.titleLarge?.copyWith(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AsmitaPalette.textDarkModeMain
                  : AsmitaPalette.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: actions.map((action) {
              return Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    action.onTap();
                  },
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: action.containerColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          action.icon,
                          color: action.iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AsmitaPalette.textDarkModeMain
                              : AsmitaPalette.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2-COLUMN WAITING GRID (Who is Waiting & Waiting Since)
  // =========================================================================
  // =========================================================================
  // WAITING QUEUE (When empty: indicates no one's waiting. When waiting: Name, Waiting Since, and Queue Waiting After Them)
  // =========================================================================
  Widget _buildWaitingGrid(
    BuildContext context,
    List<IndustrialVisitModel> visits,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waitingVisits = visits
        .where((v) => v.isPending || v.heldAtGate)
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

  // =========================================================================
  // FUNCTIONAL MODAL: ISSUE VIP PASS
  // =========================================================================
  void _showVipPassModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    bool escortRequired = true;
    String accessScope = 'Floor 8 Executive HQ';

    showAsmitaBottomSheet(
      context: context,
      title: 'Issue Executive VIP Pass',
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
                    'Pre-authorizes instant priority gate clearance with executive protocol.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AsmitaPalette.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AsmitaTextField(
                    label: 'VIP Visitor Name * (Mandatory)',
                    hint: 'e.g. Dr. Rajesh Verma',
                    icon: Icons.person_outline,
                    controller: nameCtrl,
                  ),
                  const SizedBox(height: 14),
                  AsmitaTextField(
                    label: 'Company / Organization / Title',
                    hint: 'e.g. KPMG / Board Member / Govt Delegate',
                    icon: Icons.business_outlined,
                    controller: orgCtrl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AsmitaTextField(
                          label: 'Mobile Number',
                          hint: '9876543210',
                          icon: Icons.phone_outlined,
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AsmitaTextField(
                          label: 'Vehicle No (Optional)',
                          hint: 'MH 04 AB 1234',
                          icon: Icons.directions_car_outlined,
                          controller: vehicleCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AsmitaSelectField<String>(
                    label: 'VIP Access Level',
                    hint: 'Select VIP clearance tier',
                    value: accessScope,
                    prefixIcon: Icons.lock_open_rounded,
                    items: const [
                      AsmitaSelectItem(
                        value: 'Floor 8 Executive HQ',
                        label: 'Floor 8 Executive HQ Suite',
                        subtitle: 'Director cabin & private boardroom suite',
                        icon: Icons.apartment_rounded,
                      ),
                      AsmitaSelectItem(
                        value: 'Boardroom Suite',
                        label: 'Boardroom & Conference Wing',
                        subtitle: 'High-security executive boardroom access',
                        icon: Icons.meeting_room_rounded,
                      ),
                      AsmitaSelectItem(
                        value: 'Full Campus Access',
                        label: 'Full Industrial Campus Access',
                        subtitle:
                            'Unrestricted clearance across all campus wings',
                        icon: Icons.verified_user_rounded,
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => accessScope = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: const Text(
                      'Assign Gate 1 VIP Escort',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Security staff escorts guest directly to your executive cabin.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AsmitaPalette.textLight,
                      ),
                    ),
                    value: escortRequired,
                    activeTrackColor: AsmitaPalette.deepNavy,
                    onChanged: (val) =>
                        setModalState(() => escortRequired = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        AsmitaToast.show(
                          context,
                          message: 'Visitor Name is mandatory for VIP Passes.',
                          type: AsmitaToastType.error,
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      final randomPass = 'VIP-${1000 + Random().nextInt(9000)}';
                      final org = orgCtrl.text.trim().isNotEmpty
                          ? orgCtrl.text.trim()
                          : 'Executive Guest';
                      final phone = phoneCtrl.text.trim();
                      final vehicle = vehicleCtrl.text.trim();

                      // Auto-provision department & persist VIP pass on backend
                      final authState = context.read<AuthBloc>().state;
                      final user = authState is AuthAuthenticated
                          ? authState.user
                          : null;
                      final flat = user?.flatMappings.isNotEmpty == true
                          ? user!.flatMappings.first
                          : null;

                      if (user != null) {
                        final payload = {
                          'society_id': user.societyId,
                          'tower_id': flat?.towerId ?? 1,
                          'unit_id': flat?.flatId ?? 1,
                          'resident_id': user.userId,
                          'invite_type': 'Guest',
                          'invite_sub_type': 'ONCE',
                          'title': '$name VIP Pass',
                          'visitor_name': name,
                          'mobile_number': phone,
                          'company_name': org,
                          'vehicle_number': vehicle,
                          'purpose': 'VIP Pass - $accessScope',
                          'department_name': accessScope,
                          'max_guest_count': 1,
                          'valid_from': DateTime.now().toIso8601String(),
                          'valid_to': DateTime.now()
                              .add(const Duration(hours: 24))
                              .toIso8601String(),
                          'is_private': escortRequired,
                        };

                        try {
                          context.read<VisitorBloc>().add(
                            CreatePreApprovedInviteEvent(payload: payload),
                          );
                          context.read<IndustrialVisitBloc>().add(
                            const LoadIndustrialVisits(),
                          );
                        } catch (_) {}
                      }

                      _showVipPassSuccessDialog(
                        context,
                        passCode: randomPass,
                        visitorName: name,
                        organization: org,
                        accessScope: accessScope,
                        hasEscort: escortRequired,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Generate VIP Pass',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

  void _showVipPassSuccessDialog(
    BuildContext context, {
    required String passCode,
    required String visitorName,
    required String organization,
    required String accessScope,
    required bool hasEscort,
  }) {
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
                Icons.workspace_premium_rounded,
                color: AsmitaPalette.deepNavy,
                size: 38,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'VIP Pass Issued',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$visitorName • $organization',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AsmitaPalette.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: passCode,
                    size: 140,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AsmitaPalette.deepNavy,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AsmitaPalette.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#$passCode',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AsmitaPalette.deepNavy,
                    ),
                  ),
                  Text(
                    accessScope,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AsmitaPalette.textLight,
                    ),
                  ),
                  if (hasEscort) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AsmitaPalette.successGreen.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '✓ Gate 1 Escort Officer Assigned',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AsmitaPalette.successGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: passCode));
                      HapticFeedback.selectionClick();
                      AsmitaToast.show(
                        context,
                        message: 'Pass Code #$passCode copied to clipboard',
                        type: AsmitaToastType.success,
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text(
                      'Copy Code',
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
                      'Done',
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
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
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
            onCall: () {
              Navigator.pop(context);
              _callContact('Emergency Response', '+919820110911');
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Quick Security Dispatches',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    try {
                      final dio = AsmitaDioClient(SecureStorageService()).dio;
                      dio
                          .post(
                            '${EnvConfig.baseUrl}/app-api/security/dispatch',
                            data: {
                              'society_id': societyId,
                              'type': 'VIP_ESCORT',
                              'destination': 'Gate 1 Main Portico',
                              'priority': 'HIGH',
                            },
                          )
                          .ignore();
                    } catch (_) {}

                    AsmitaToast.show(
                      context,
                      message:
                          'VIP Escort Officer dispatched to Gate 1 Main Portico.',
                      type: AsmitaToastType.success,
                    );
                  },
                  icon: const Icon(Icons.person_pin_circle_rounded, size: 16),
                  label: const Text(
                    'Request Escort',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.deepNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    try {
                      final dio = AsmitaDioClient(SecureStorageService()).dio;
                      dio
                          .post(
                            '${EnvConfig.baseUrl}/app-api/security/dispatch',
                            data: {
                              'society_id': societyId,
                              'type': 'EXPRESS_CLEARANCE',
                              'destination': 'All Security Gates',
                              'priority': 'HIGH',
                            },
                          )
                          .ignore();
                    } catch (_) {}

                    AsmitaToast.show(
                      context,
                      message:
                          'Priority Express clearance alert transmitted to all gates.',
                      type: AsmitaToastType.info,
                    );
                  },
                  icon: const Icon(
                    Icons.notification_important_rounded,
                    size: 16,
                  ),
                  label: const Text(
                    'Express Lane Alert',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.actionRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
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

class _ExecutiveActionItem {
  final String title;
  final IconData icon;
  final Color containerColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ExecutiveActionItem({
    required this.title,
    required this.icon,
    required this.containerColor,
    required this.iconColor,
    required this.onTap,
  });
}
