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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                              Text(
                                'Executive Visitors',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AsmitaPalette.textDark,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? AsmitaPalette.actionRed.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isPending ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? AsmitaPalette.actionRed.withValues(alpha: isDark ? 0.15 : 0.08)
                : (isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0x0A0F172A)),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0x050F172A),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVisitDetailsModal(context, visit),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Identity/Type + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildVisitorAvatar(context, visit, isDark, isPending),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.visitorName.isNotEmpty ? visit.visitorName : 'Guest Visitor',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _buildVisitorCategoryBadge(context, visit, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildStatusBadge(context, visit, isDark, isPending),
                  ],
                ),

                // Inset Executive Meta Footer (Clean structured arrival + suite + pass code)
                _buildExecutiveFooter(context, visit, isDark),

                // Pending Decision CTAs
                if (isPending) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleDecide(context, visit.id, 'REJECT'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AsmitaPalette.actionRed,
                            side: BorderSide(
                              color: AsmitaPalette.actionRed.withValues(alpha: 0.8),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleDecide(context, visit.id, 'APPROVE'),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text(
                            'Approve Priority',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.deepNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (visit.status == IndustrialVisitStatus.approved && !isAck) ...[
                  const SizedBox(height: 12),
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

  Widget _buildVisitorAvatar(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
    bool isPending,
  ) {
    if (visit.visitorPhotoUrl != null && visit.visitorPhotoUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.network(
            visit.visitorPhotoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildAvatarFallback(context, visit, isDark, isPending),
          ),
        ),
      );
    }
    return _buildAvatarFallback(context, visit, isDark, isPending);
  }

  Widget _buildAvatarFallback(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
    bool isPending,
  ) {
    List<Color> gradientColors;
    IconData? overlayIcon;
    bool showStarBadge = false;

    if (isPending) {
      gradientColors = const [Color(0xFF991B1B), Color(0xFFDC2626)];
    } else if (visit.isDelivery) {
      gradientColors = const [Color(0xFFD97706), Color(0xFFF59E0B)];
      overlayIcon = Icons.local_shipping_rounded;
    } else if (visit.isPreApproved) {
      gradientColors = const [Color(0xFF1E293B), Color(0xFF27347B)];
      showStarBadge = true;
    } else {
      gradientColors = const [Color(0xFF1E3A8A), Color(0xFF2563EB)];
    }

    final letter = visit.visitorName.isNotEmpty ? visit.visitorName[0].toUpperCase() : 'V';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: isDark ? 0.35 : 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: Center(
            child: overlayIcon != null
                ? Icon(overlayIcon, size: 22, color: Colors.white)
                : Text(
                    letter,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
          ),
        ),
        if (showStarBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVisitorCategoryBadge(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
  ) {
    if (visit.isPreApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.6) : const Color(0xFFFDE68A),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 11, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text(
              'VIP GUEST',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else if (visit.isDelivery) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 13,
            color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 4),
          Text(
            visit.deliveryCompany != null ? '${visit.deliveryCompany} Delivery' : 'Courier Dropoff',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
            ),
          ),
        ],
      );
    }

    final categoryText = visit.purpose ?? 'Executive Guest';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.badge_outlined,
          size: 13,
          color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Text(
          categoryText,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
    bool isPending,
  ) {
    Color bg;
    Color border;
    Color textColor;
    Color dotColor;
    String label;
    bool pulse = false;

    if (isPending) {
      bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
      border = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
      textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
      dotColor = const Color(0xFFEF4444);
      label = 'PENDING';
      pulse = true;
    } else if (visit.status == IndustrialVisitStatus.checkedIn) {
      bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
      border = isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0);
      textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
      dotColor = const Color(0xFF10B981);
      label = 'INSIDE HQ';
      pulse = true;
    } else if (visit.status == IndustrialVisitStatus.approved) {
      bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
      border = isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE);
      textColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
      dotColor = const Color(0xFF3B82F6);
      label = 'APPROVED';
    } else if (visit.status == IndustrialVisitStatus.checkedOut) {
      bg = isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5);
      border = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
      textColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
      dotColor = const Color(0xFF71717A);
      label = 'CHECKED OUT';
    } else {
      bg = visit.status.fillColor(isDark);
      border = visit.status.textColor(isDark).withValues(alpha: 0.3);
      textColor = visit.status.textColor(isDark);
      dotColor = textColor;
      label = visit.status.label.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: pulse
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5.5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveFooter(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
  ) {
    final arrivalTime = visit.checkInAt != null
        ? DateFormat('hh:mm a').format(visit.checkInAt!)
        : (visit.createdAt != null
            ? DateFormat('hh:mm a').format(visit.createdAt!)
            : 'Scheduled');

    final destinationName = visit.departmentName ?? 'Executive Suite';
    final hasPassCode = visit.passCode != null && visit.passCode!.isNotEmpty;
    final hasVehicle = visit.vehicleNumber != null && visit.vehicleNumber!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Time info
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        visit.checkInAt != null ? 'ENTERED' : 'SCHEDULED',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        arrivalTime,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),

          // Destination or Vehicle
          Expanded(
            child: Row(
              children: [
                Icon(
                  hasVehicle ? Icons.directions_car_filled_rounded : Icons.apartment_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasVehicle ? 'VEHICLE' : 'LOCATION',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        hasVehicle ? visit.vehicleNumber! : destinationName,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Security Pass Code Ticket
          if (hasPassCode) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: visit.passCode!));
                HapticFeedback.selectionClick();
                AsmitaToast.show(
                  context,
                  message: 'Pass code #${visit.passCode} copied to clipboard',
                  type: AsmitaToastType.success,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.vpn_key_rounded,
                      size: 11,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#${visit.passCode}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ],
        ],
      ),
    );
  }
}
