import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/presentation/widgets/receptionist_reassign_sheet.dart';
import '../../../visitor_management/presentation/screens/guard_pass_check_in_screen.dart';
import '../../../visitor_management/presentation/screens/guard_qr_scanner_screen.dart';

class ReceptionistDashboardView extends StatefulWidget {
  final List<IndustrialVisitModel>? visits;
  final bool initialIsOnDuty;
  final ValueChanged<bool>? onToggleDuty;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId, int? assignedUserId, int? cabinId, int? deskId)?
  onReassignVisit;

  const ReceptionistDashboardView({
    super.key,
    this.visits,
    this.initialIsOnDuty = true,
    this.onToggleDuty,
    this.onDecideVisit,
    this.onReassignVisit,
  });

  @override
  State<ReceptionistDashboardView> createState() =>
      _ReceptionistDashboardViewState();
}

class _ReceptionistDashboardViewState extends State<ReceptionistDashboardView> {
  int _selectedTabIndex = 0;
  late bool _isOnDuty;

  @override
  void initState() {
    super.initState();
    _isOnDuty = widget.initialIsOnDuty;

    if (widget.visits == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
        } catch (_) {}
        try {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            AsmitaPreApproveWizard.loadSocietyFlats(authState.user.societyId);
            AsmitaPreApproveWizard.loadSocietyEmployees(authState.user.societyId);
            AsmitaPreApproveWizard.loadSocietyDepartments(authState.user.societyId);
          }
        } catch (_) {}
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            AsmitaPreApproveWizard.loadSocietyFlats(authState.user.societyId);
            AsmitaPreApproveWizard.loadSocietyEmployees(authState.user.societyId);
            AsmitaPreApproveWizard.loadSocietyDepartments(authState.user.societyId);
          }
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleToggleDuty(bool val) {
    setState(() => _isOnDuty = val);
    if (widget.onToggleDuty != null) {
      widget.onToggleDuty!(val);
    }
    AsmitaToast.show(
      context,
      message: val
          ? 'Reception Desk: You are now On Duty'
          : 'Reception Desk: Marked as Away',
      type: val ? AsmitaToastType.success : AsmitaToastType.info,
    );
  }

  void _handleDecide(BuildContext context, int visitId, String action) {
    if (widget.onDecideVisit != null) {
      widget.onDecideVisit!(visitId, action);
    } else {
      context.read<IndustrialVisitBloc>().add(
        DecideVisitEvent(visitId: visitId, action: action),
      );
    }
  }

  void _handleReassign(
    BuildContext context,
    int visitId,
    int? assignedUserId,
    int? cabinId,
    int? deskId,
  ) {
    if (widget.onReassignVisit != null) {
      widget.onReassignVisit!(visitId, assignedUserId, cabinId, deskId);
    } else {
      context.read<IndustrialVisitBloc>().add(
        DecideVisitEvent(
          visitId: visitId,
          action: 'REASSIGN',
          assignedUserId: assignedUserId,
          cabinId: cabinId,
          deskId: deskId,
        ),
      );
    }
  }

  void _showNewVisitorModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'New Walk-in Visitor',
        content: AsmitaPreApproveWizard(isGuardMode: true),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tab 1: Ground Waiting List (Awaiting Host or inside lobby)
    final waitingList = visits.where((v) => v.isPending).toList();

    // Tab 2: Floor Alerts (Escalated visits, Director visits, unassigned desks)
    final floorAlerts = visits
        .where(
          (v) =>
              v.status == IndustrialVisitStatus.awaitingHost ||
              v.departmentName == 'Executive Office',
        )
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // 1. Unified Primary Asmita Header (Spacious, Uncrowded Title)
          const AsmitaPrimaryHeader(
            allowPropertySwitching: false,
            subtitleOverride: 'Main Entrance • Gate Reception Desk',
          ),

          // 2. Single Continuous Scroll Page
          Expanded(
            child: RefreshIndicator(
              color: AsmitaPalette.deepNavy,
              onRefresh: () async {
                context.read<IndustrialVisitBloc>().add(
                      const LoadIndustrialVisits(),
                    );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Executive Duty Command & Gate Status Banner
                    _buildDutyStatusBanner(context, isDark),

                    // 2. Gate Receptionist Quick Operational Actions
                    _buildQuickActionBar(context),

                    // 3. Modern Segmented Tab Bar Header
                    _buildSegmentedTabBar(
                      context,
                      waitingList.length,
                      floorAlerts.length,
                      isDark,
                    ),

                    // 4. Content Area: Inline Visit Cards or Empty State
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: AsmitaLoadingIndicator(
                                  color: AsmitaPalette.deepNavy,
                                  size: 32,
                                ),
                              ),
                            )
                          : (_selectedTabIndex == 0
                              ? _buildInlineVisitList(context, waitingList, isAlertTab: false)
                              : _buildInlineVisitList(context, floorAlerts, isAlertTab: true)),
                    ),

                    // 5. Bottom clearance above floating curved nav bar
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

  Widget _buildDutyStatusBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (_isOnDuty
                            ? AsmitaPalette.successGreen
                            : AsmitaPalette.amberWarning)
                        .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isOnDuty
                    ? Icons.support_agent_rounded
                    : Icons.pause_circle_outline_rounded,
                color: _isOnDuty
                    ? AsmitaPalette.successGreen
                    : AsmitaPalette.amberWarning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _isOnDuty
                              ? AsmitaPalette.successGreen
                              : AsmitaPalette.amberWarning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isOnDuty ? 'RECEPTION ACTIVE' : 'DESK ON BREAK',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: _isOnDuty
                                ? AsmitaPalette.successGreen
                                : AsmitaPalette.amberWarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isOnDuty
                        ? 'Processing arrivals & visitor passes'
                        : 'Forwarding incoming guests to gate security',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _handleToggleDuty(!_isOnDuty),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isOnDuty
                      ? AsmitaPalette.successGreen.withValues(alpha: 0.12)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isOnDuty
                        ? AsmitaPalette.successGreen
                        : AsmitaPalette.textLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isOnDuty
                          ? Icons.check_circle_rounded
                          : Icons.power_settings_new_rounded,
                      size: 14,
                      color: _isOnDuty
                          ? AsmitaPalette.successGreen
                          : AsmitaPalette.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnDuty ? 'On Duty' : 'Away',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isOnDuty
                            ? AsmitaPalette.successGreen
                            : AsmitaPalette.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              context,
              icon: Icons.person_add_alt_1_rounded,
              label: 'New Walk-in',
              subtitle: 'Lobby guest',
              color: AsmitaPalette.deepNavy,
              onTap: () => _showNewVisitorModal(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionCard(
              context,
              icon: Icons.pin_rounded,
              label: 'Verify Code',
              subtitle: 'Pass check-in',
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuardPassCheckInScreen(gateId: 1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionCard(
              context,
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan QR',
              subtitle: 'Digital pass',
              color: const Color(0xFF059669),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuardQrScannerScreen(
                      isActive: true,
                      onScanComplete: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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

  Widget _buildSegmentedTabBar(
    BuildContext context,
    int waitingCount,
    int alertsCount,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabPill(
              context,
              index: 0,
              icon: Icons.people_alt_rounded,
              label: 'Lobby Waiting ($waitingCount)',
              isSelected: _selectedTabIndex == 0,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabPill(
              context,
              index: 1,
              icon: Icons.notifications_active_rounded,
              label: 'Floor Alerts ($alertsCount)',
              isSelected: _selectedTabIndex == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        if (_selectedTabIndex != index) {
          setState(() => _selectedTabIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AsmitaPalette.deepNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineVisitList(
    BuildContext context,
    List<IndustrialVisitModel> list, {
    required bool isAlertTab,
  }) {
    if (list.isEmpty) {
      return _buildEmptyState(context, isAlertTab: isAlertTab);
    }

    return Column(
      children: list.map((visit) => _buildVisitCard(context, visit)).toList(),
    );
  }

  Widget _buildVisitCard(BuildContext context, IndustrialVisitModel visit) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AsmitaPalette.deepNavy.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    visit.visitorName.isNotEmpty
                        ? visit.visitorName[0]
                        : 'V',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AsmitaPalette.deepNavy,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.visitorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Host: ${visit.hostName ?? "Unassigned"} • ${visit.departmentName ?? "Main HQ"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AsmitaPalette.textLight,
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
                    color: visit.status.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    visit.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: visit.status.badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (visit.cabinNumber != null) ...[
                  Text(
                    'Cabin: ${visit.cabinNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (visit.deskNumber != null) ...[
                  Text(
                    'Desk: ${visit.deskNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                Text(
                  'Ref: #${visit.requestNumber}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AsmitaPalette.textLight,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Reassign / Allocate Button
                OutlinedButton.icon(
                  onPressed: () {
                    ReceptionistReassignSheet.show(
                      context,
                      visit: visit,
                      onConfirmReassign: (assignedUser, cabin, desk) {
                        _handleReassign(
                          context,
                          visit.id,
                          assignedUser,
                          cabin,
                          desk,
                        );
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.edit_location_alt_outlined,
                    size: 14,
                    color: AsmitaPalette.deepNavy,
                  ),
                  label: const Text(
                    'Allocate Desk',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AsmitaPalette.deepNavy,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AsmitaPalette.deepNavy),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Quick Approve
                ElevatedButton(
                  onPressed: () =>
                      _handleDecide(context, visit.id, 'APPROVE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Approve Entry',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildEmptyState(BuildContext context, {required bool isAlertTab}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isAlertTab
                      ? AsmitaPalette.amberWarning
                      : AsmitaPalette.deepNavy)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAlertTab
                  ? Icons.notifications_off_outlined
                  : Icons.how_to_reg_rounded,
              size: 36,
              color: isAlertTab
                  ? AsmitaPalette.amberWarning
                  : AsmitaPalette.deepNavy,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isAlertTab ? 'No Active Floor Alerts' : 'Lobby is All Clear',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAlertTab
                ? 'No executive floor escalations or urgent visitor reassignments require attention right now.'
                : 'No visitors are currently waiting in the entrance lobby. New arrivals will appear here in real time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          if (!isAlertTab) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showNewVisitorModal(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Register Walk-in Guest',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
