import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_refresh.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_visitor_card.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/presentation/widgets/receptionist_reassign_sheet.dart';
import '../../../visitor_management/presentation/widgets/delivery_action_sheet.dart';
import '../../../visitor_management/presentation/screens/guard_qr_scanner_screen.dart';
import '../../../visitor_management/presentation/widgets/employee_registry_sheet.dart';
import 'employee_dashboard_view.dart';

class ReceptionistDashboardView extends StatefulWidget {
  final List<IndustrialVisitModel>? visits;
  final bool initialIsOnDuty;
  final ValueChanged<bool>? onToggleDuty;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId, int? assignedUserId, int? cabinId, int? deskId)?
  onReassignVisit;
  final ValueChanged<int>? onNavigateToTab;

  const ReceptionistDashboardView({
    super.key,
    this.visits,
    this.initialIsOnDuty = true,
    this.onToggleDuty,
    this.onDecideVisit,
    this.onReassignVisit,
    this.onNavigateToTab,
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
            AsmitaPreApproveWizard.loadSocietyEmployees(
              authState.user.societyId,
            );
            AsmitaPreApproveWizard.loadSocietyDepartments(
              authState.user.societyId,
            );
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
            AsmitaPreApproveWizard.loadSocietyEmployees(
              authState.user.societyId,
            );
            AsmitaPreApproveWizard.loadSocietyDepartments(
              authState.user.societyId,
            );
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

  Future<void> _showNewVisitorModal(BuildContext modalContext) async {
    await AsmitaPreApproveWizard.showAsModalSheet(
      modalContext,
      isGuardMode: true,
      title: 'New Walk-in Visitor',
      subtitle: 'Record lobby guest entry details',
    );
    if (!mounted) return;
    context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
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
        final isLoading = state.status == IndustrialVisitBlocStatus.loading;

        return _buildScaffold(context, state.visits, isLoading: isLoading);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<IndustrialVisitModel> rawVisits, {
    required bool isLoading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Today's entries only (resets at 00:00)
    final visits = rawVisits.where((v) => v.isForToday).toList();

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
            child: AppRefresh(
              onRefresh: () async {
                final bloc = context.read<IndustrialVisitBloc>();
                final future = bloc.stream
                    .firstWhere((s) => s.status != IndustrialVisitBlocStatus.loading)
                    .timeout(const Duration(seconds: 4), onTimeout: () => bloc.state);
                bloc.add(const LoadIndustrialVisits());
                await future;
              },
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: isLoading
                        ? _buildReceptionistListSkeleton(context)
                        : (_selectedTabIndex == 0
                              ? _buildInlineVisitList(
                                  context,
                                  waitingList,
                                  isAlertTab: false,
                                )
                              : _buildInlineVisitList(
                                  context,
                                  floorAlerts,
                                  isAlertTab: true,
                                )),
                  ),

                  // 5. Bottom clearance above floating curved nav bar
                  const SizedBox(height: 180),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyStatusBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                          _isOnDuty ? 'Reception Open' : 'Desk On Break',
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
                        ? 'Ready for visitors & passes'
                        : 'Forwarding guests to security',
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
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. New Walk-in
          Expanded(
            child: _buildSquareActionBox(
              context,
              icon: Icons.person_add_alt_1_rounded,
              label: 'New Walk-in',
              onTap: () => _showNewVisitorModal(context),
            ),
          ),
          // 2. Digital Pass (QR Scan & Check-in Code)
          Expanded(
            child: _buildSquareActionBox(
              context,
              icon: Icons.qr_code_scanner_rounded,
              label: 'Digital Pass',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuardQrScannerScreen(
                      isActive: true,
                      onScanComplete: () => Navigator.pop(context),
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
          ),
          // 3. Employee Registry (Check-in / Check-out)
          Expanded(
            child: _buildSquareActionBox(
              context,
              icon: Icons.badge_rounded,
              label: 'Staff Registry',
              onTap: () => EmployeeRegistrySheet.show(context),
            ),
          ),
          // 4. BBPS Bill Payments
          Expanded(
            child: _buildSquareActionBox(
              context,
              icon: Icons.receipt_long_rounded,
              label: 'BillPay',
              onTap: () => BbpsBillPaymentsSheet.show(context, onNavigateToTab: widget.onNavigateToTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareActionBox(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeBlue = isDark ? const Color(0xFF7B96EC) : AsmitaPalette.deepNavy;

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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: themeBlue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : themeBlue.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isDark ? Colors.black : Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceptionistListSkeleton(BuildContext context) {
    return AsmitaSkeleton(
      isLoading: true,
      child: Column(
        children: List.generate(
          3,
          (index) => AsmitaSkeleton.visitorCard(
            margin: const EdgeInsets.only(bottom: 12),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : AsmitaPalette.deepNavy)
              : Colors.transparent,
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
                  : Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
                      : Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isExpired = visit.status == IndustrialVisitStatus.expired ||
        (visit.passCodeExpiresAt != null && visit.passCodeExpiresAt!.isBefore(DateTime.now()));
    final isTerminal = isExpired ||
        visit.status == IndustrialVisitStatus.checkedOut ||
        visit.status == IndustrialVisitStatus.rejected ||
        visit.status == IndustrialVisitStatus.cancelled;

    final actions = isTerminal
        ? null
        : Row(
            children: [
              if (visit.isDelivery) ...[
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        DeliveryActionSheet.show(
                          context,
                          visit: visit,
                          onActionSelected: (action) =>
                              _handleDecide(context, visit.id, action),
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
                            Icon(
                              Icons.touch_app_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Delivery Options',
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
                const SizedBox(width: 8),
              ],
              // PTM update/assign button (Secondary Outlined Corporate Style)
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
                          _handleReassign(context, visit.id, assignedUser, cabin, desk);
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

              // 1. Forward (When APPROVED and floor has receptionist)
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

              // 2. Check In (When APPROVED without floor rec, or when Forwarded / Waiting on floor)
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

              // 3. Wait button (Available for Approved, Forwarded, or Checked In when not already waiting)
              if (visit.status != IndustrialVisitStatus.waitingToMeet &&
                  visit.status != IndustrialVisitStatus.checkedOut &&
                  (visit.status == IndustrialVisitStatus.approved ||
                   visit.status == IndustrialVisitStatus.onTheWay ||
                   visit.status == IndustrialVisitStatus.checkedIn)) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<IndustrialVisitBloc>().add(
                          DecideVisitEvent(
                            visitId: visit.id,
                            action: 'WAITING_TO_MEET',
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF78350F).withValues(alpha: 0.35)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFFB45309).withValues(alpha: 0.5)
                                : const Color(0xFFFDE68A),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_top_rounded, size: 15, color: Color(0xFFD97706)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Wait',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
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

              // 4. Check Out (When Checked In)
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

    return AsmitaVisitorCard.fromIndustrialVisit(
      visit: visit,
      context: context,
      bottomActions: actions,
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isAlertTab}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
              size: 24,
              color: isAlertTab
                  ? AsmitaPalette.amberWarning
                  : AsmitaPalette.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAlertTab ? 'No Active Floor Alerts' : 'Lobby is All Clear',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAlertTab
                ? 'No executive escalations or urgent visitor reassignments.'
                : 'No visitors waiting in lobby. New arrivals show here in real time.',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              height: 1.3,
            ),
          ),
          if (!isAlertTab) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showNewVisitorModal(context),
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text(
                'Register Walk-in Guest',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2563EB)
                    : AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
