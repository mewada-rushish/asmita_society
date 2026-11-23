import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/app_refresh.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/asmita_bottom_nav_bar.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_visitor_card.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';
import '../../bloc/industrial_visit_bloc.dart';
import '../../bloc/industrial_visit_event.dart';
import '../../bloc/industrial_visit_state.dart';
import '../../data/models/industrial_visit_model.dart';
import '../widgets/delivery_action_sheet.dart';
import '../widgets/receptionist_reassign_sheet.dart';

/// Dedicated screen for Gate/Property Receptionists to review Lobby Waiting and Floor Alerts.
/// Accessible via the Quick Action bar on the main Receptionist Dashboard.
class ReceptionistLobbyUpdatesScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId, int? assignedUserId, int? cabinId, int? deskId)? onReassignVisit;

  const ReceptionistLobbyUpdatesScreen({
    super.key,
    this.onNavigateToTab,
    this.onDecideVisit,
    this.onReassignVisit,
  });

  static Future<int?> open(
    BuildContext context, {
    ValueChanged<int>? onNavigateToTab,
    Function(int visitId, String action)? onDecideVisit,
    Function(int visitId, int? assignedUserId, int? cabinId, int? deskId)? onReassignVisit,
  }) {
    return Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ReceptionistLobbyUpdatesScreen(
          onNavigateToTab: onNavigateToTab,
          onDecideVisit: onDecideVisit,
          onReassignVisit: onReassignVisit,
        ),
      ),
    );
  }

  @override
  State<ReceptionistLobbyUpdatesScreen> createState() =>
      _ReceptionistLobbyUpdatesScreenState();
}

class _ReceptionistLobbyUpdatesScreenState
    extends State<ReceptionistLobbyUpdatesScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
        } catch (_) {}
      }
    });
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
    if (mounted) {
      context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          Navigator.pop(context, index);
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(index);
          }
        },
      ),
      body: Column(
        children: [
          const AsmitaPrimaryHeader(
            subtitleOverride: 'Lobby & Floor Updates',
            showBackButton: true,
            allowPropertySwitching: false,
            bottomPadding: 12.0,
          ),
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
                final isLoading = state.status == IndustrialVisitBlocStatus.loading;
                final visits = state.visits.where((v) => v.isForToday).toList();
                final waitingList = visits.where((v) => v.isPending).toList();
                final floorAlerts = visits
                    .where(
                      (v) =>
                          v.status == IndustrialVisitStatus.awaitingHost ||
                          v.departmentName == 'Executive Office',
                    )
                    .toList();

                return AppRefresh(
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
                      const SizedBox(height: 12),
                      _buildSegmentedTabBar(
                        context,
                        waitingCount: waitingList.length,
                        alertsCount: floorAlerts.length,
                        isDark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: isLoading
                            ? _buildListSkeleton(context)
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
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabBar(
    BuildContext context, {
    required int waitingCount,
    required int alertsCount,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              ],

              if (!visit.isDelivery &&
                  visit.status == IndustrialVisitStatus.approved &&
                  !visit.isCheckedIn) ...[
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<IndustrialVisitBloc>().add(
                          CheckInPassEvent(visitId: visit.id, gateId: 1),
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
                              Color(0xFF059669),
                              Color(0xFF047857),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login_rounded, size: 16, color: Colors.white),
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

              if (!visit.isDelivery &&
                  visit.status != IndustrialVisitStatus.approved &&
                  !visit.isCheckedIn) ...[
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
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 16,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Reassign',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
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
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildListSkeleton(BuildContext context) {
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
}
