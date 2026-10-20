import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/presentation/widgets/acknowledge_action_button.dart';

/// Director Role Dashboard:
/// - Executive overview and visitor KPI metrics
/// - Personal VIP visitor log
/// - Quick direct contact button to floor receptionist
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

  void _handleDecide(BuildContext context, int visitId, String action) {
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
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Floor Support Hotline',
                      style: Theme.of(bottomSheetContext).textTheme.titleMedium?.copyWith(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            color: AsmitaPalette.deepNavy,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AsmitaPalette.deepNavy,
                    child: Icon(Icons.support_agent_rounded, color: Colors.white),
                  ),
                  title: const Text('Main Reception Desk', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Ext: 101 • Ground Floor Lobby'),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);
                      AsmitaToast.show(
                        context,
                        message: 'Calling Main Reception (Ext 101)...',
                        type: AsmitaToastType.info,
                      );
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AsmitaPalette.deepNavy,
                    child: Icon(Icons.shield_outlined, color: Colors.white),
                  ),
                  title: const Text('Gate 1 Security Control', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Ext: 104 • Pedestrian Gate'),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);
                      AsmitaToast.show(
                        context,
                        message: 'Calling Gate 1 Control (Ext 104)...',
                        type: AsmitaToastType.info,
                      );
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Executive Office',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                        color: AsmitaPalette.deepNavy,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Director Operations & VIP Gateways',
                                  style: TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quick Call to Floor Receptionist
                          ElevatedButton.icon(
                            onPressed: () => _handleContactReceptionist(context),
                            icon: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
                            label: const Text('Receptionist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AsmitaPalette.deepNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // KPI Row
                      Row(
                        children: [
                          _kpiCard(context, 'Pending', pendingCount.toString(), AsmitaPalette.actionRed, Icons.hourglass_top),
                          const SizedBox(width: 10),
                          _kpiCard(context, 'Approved', approvedCount.toString(), AsmitaPalette.successGreen, Icons.verified_user),
                          const SizedBox(width: 10),
                          _kpiCard(context, 'Inside HQ', checkedInCount.toString(), AsmitaPalette.deepNavy, Icons.business),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Executive Visitor History / Feed Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Executive Visitors',
                            style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${visits.length} Total Visits',
                            style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (visits.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.person_pin_outlined, size: 48, color: AsmitaPalette.textLight.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text('No pending executive visitor appointments.', style: TextStyle(color: AsmitaPalette.textLight)),
                            ],
                          ),
                        )
                      else
                        ...visits.map((visit) => _visitorCard(context, visit)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _kpiCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _visitorCard(BuildContext context, IndustrialVisitModel visit) {
    final isAck = _acknowledgedIds.contains(visit.id);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                  backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                  child: Text(
                    visit.visitorName.isNotEmpty ? visit.visitorName[0] : 'V',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AsmitaPalette.deepNavy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.visitorName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${visit.departmentName ?? "Executive Office"} • ${visit.requestNumber}',
                        style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            if (visit.purpose != null && visit.purpose!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Purpose: ${visit.purpose}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            if (visit.isPending) ...[
              const Divider(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AcknowledgeActionButton(
                    onAcknowledge: () => _handleAcknowledge(context, visit.id),
                    isAcknowledged: isAck,
                  ),
                  OutlinedButton(
                    onPressed: () => _handleDecide(context, visit.id, 'REJECT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AsmitaPalette.actionRed,
                      side: const BorderSide(color: AsmitaPalette.actionRed),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleDecide(context, visit.id, 'APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
