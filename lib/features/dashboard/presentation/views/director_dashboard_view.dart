import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
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
import '../../../visitor_management/presentation/widgets/acknowledge_action_button.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  final Set<int> _acknowledgedIds = {};
  String _selectedFilter = 'ALL';

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

  void _handleAcknowledge(BuildContext context, int visitId) {
    setState(() => _acknowledgedIds.add(visitId));
    if (widget.onAcknowledgeVisit != null) {
      widget.onAcknowledgeVisit!(visitId);
    } else {
      context.read<IndustrialVisitBloc>().add(AcknowledgeVisitEvent(visitId));
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
          label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.deepNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  void _showVisitDetailsModal(BuildContext context, IndustrialVisitModel visit) {
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
              gradient: const LinearGradient(
                colors: [AsmitaPalette.deepNavy, Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: Text(
                    visit.visitorName.isNotEmpty ? visit.visitorName[0].toUpperCase() : 'V',
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AsmitaPalette.deepNavy),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AsmitaPalette.deepNavy),
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
                      side: const BorderSide(color: AsmitaPalette.actionRed, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Decline Pass', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve Priority Entry', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AsmitaPalette.textLight)),
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
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
        final isLoading = state.status == IndustrialVisitBlocStatus.loading &&
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
    final approvedCount = visits.where((v) => v.status == IndustrialVisitStatus.approved).length;
    final checkedInCount = visits.where((v) => v.status == IndustrialVisitStatus.checkedIn).length;

    final filteredVisits = visits.where((v) {
      if (_selectedFilter == 'PENDING' && !v.isPending) return false;
      if (_selectedFilter == 'APPROVED' && v.status != IndustrialVisitStatus.approved) return false;
      if (_selectedFilter == 'INSIDE' && v.status != IndustrialVisitStatus.checkedIn) return false;
      return true;
    }).toList();

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
                  context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                          // Quick Action Bar
                          _buildQuickActionBar(context),
                          const SizedBox(height: 20),

                          // Section Header with Filter Chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Executive Visitors',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${filteredVisits.length} of ${visits.length} Total',
                                style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Fitted Segmented Filter Bar (Zero cropping, 100% responsive width)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Theme.of(context).dividerColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _segmentedTab(
                                  'ALL',
                                  'All',
                                  count: visits.length,
                                ),
                                _segmentedTab(
                                  'PENDING',
                                  'Pending',
                                  count: pendingCount,
                                  alertColor: AsmitaPalette.actionRed,
                                ),
                                _segmentedTab(
                                  'APPROVED',
                                  'Approved',
                                  count: approvedCount,
                                  alertColor: const Color(0xFF1E88E5),
                                ),
                                _segmentedTab(
                                  'INSIDE',
                                  'Inside',
                                  count: checkedInCount,
                                  alertColor: AsmitaPalette.successGreen,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Visitor List or Empty State
                          if (filteredVisits.isEmpty)
                            _buildEmptyState(context)
                          else
                            ...filteredVisits.map((visit) => _visitorCard(context, visit)),

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
          filterKey: 'PENDING',
          showPulse: pendingCount > 0,
        ),
        const SizedBox(width: 8),
        _kpiCard(
          context,
          label: 'Approved',
          value: '$approvedCount',
          color: const Color(0xFF1E88E5),
          icon: Icons.verified_rounded,
          filterKey: 'APPROVED',
        ),
        const SizedBox(width: 8),
        _kpiCard(
          context,
          label: 'Inside HQ',
          value: '$checkedInCount',
          color: AsmitaPalette.successGreen,
          icon: Icons.meeting_room_rounded,
          filterKey: 'INSIDE',
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
    required String filterKey,
    bool showPulse = false,
  }) {
    final isSelected = _selectedFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedFilter = isSelected ? 'ALL' : filterKey;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.25 : 0.12)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Squircle Icon Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.10),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: color.withValues(alpha: isSelected ? 0.45 : 0.18),
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
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AsmitaPalette.textLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showPreApproveModal(context),
            icon: const Icon(Icons.add_moderator_outlined, size: 18),
            label: const Text(
              'Issue VIP Pass',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.deepNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _handleContactReceptionist(context),
          icon: const Icon(Icons.support_agent_rounded, size: 18),
          label: const Text('Hotlines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AsmitaPalette.deepNavy,
            side: const BorderSide(color: AsmitaPalette.deepNavy, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _segmentedTab(
    String code,
    String label, {
    int? count,
    Color? alertColor,
  }) {
    final isSelected = _selectedFilter == code;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = alertColor ?? AsmitaPalette.deepNavy;
    final hasBadge = count != null && count > 0;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = code);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? highlight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: highlight.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AsmitaPalette.textDark),
                    ),
                  ),
                ),
              ),
              if (hasBadge) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : highlight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : highlight,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 44,
              color: AsmitaPalette.deepNavy,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Pending Appointments',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your executive visitor queue is clear. Issue a pre-approved pass for VIP guests with priority gate clearance.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _showPreApproveModal(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Issue VIP Pass'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.deepNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitorCard(BuildContext context, IndustrialVisitModel visit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = visit.isPending;
    final isAck = _acknowledgedIds.contains(visit.id);

    final statusBg = visit.status.fillColor(isDark);
    final statusText = visit.status.textColor(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AsmitaPalette.actionRed.withValues(alpha: 0.4)
              : Theme.of(context).dividerColor,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? AsmitaPalette.actionRed.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVisitDetailsModal(context, visit),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isPending
                          ? AsmitaPalette.actionRed.withValues(alpha: 0.12)
                          : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                      child: Text(
                        visit.visitorName.isNotEmpty ? visit.visitorName[0].toUpperCase() : 'V',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          color: isPending ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  visit.visitorName,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (visit.passCode != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${visit.passCode}',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AsmitaPalette.deepNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            visit.deliveryCompany ?? visit.purpose ?? 'VIP Guest',
                            style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AsmitaPalette.actionRed.withValues(alpha: 0.12)
                            : statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPending ? 'Pending Approval' : visit.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPending ? AsmitaPalette.actionRed : statusText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: AsmitaPalette.textLight),
                        const SizedBox(width: 4),
                        Text(
                          visit.checkInAt != null
                              ? DateFormat('hh:mm a').format(visit.checkInAt!)
                              : (visit.createdAt != null
                                  ? DateFormat('hh:mm a').format(visit.createdAt!)
                                  : 'Scheduled'),
                          style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
                        ),
                      ],
                    ),
                    if (visit.vehicleNumber != null && visit.vehicleNumber!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.directions_car_rounded, size: 13, color: AsmitaPalette.textLight),
                          const SizedBox(width: 4),
                          Text(
                            visit.vehicleNumber!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleDecide(context, visit.id, 'REJECT'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AsmitaPalette.actionRed,
                            side: const BorderSide(color: AsmitaPalette.actionRed),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleDecide(context, visit.id, 'APPROVE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Approve Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ] else if (visit.status == IndustrialVisitStatus.approved && !isAck) ...[
                  const SizedBox(height: 10),
                  AcknowledgeActionButton(
                    onAcknowledge: () => _handleAcknowledge(context, visit.id),
                    isAcknowledged: isAck,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
