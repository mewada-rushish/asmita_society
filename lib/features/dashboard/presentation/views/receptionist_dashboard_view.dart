import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/presentation/widgets/receptionist_reassign_sheet.dart';

/// Receptionist Role Dashboard:
/// - Dual Tab Interface: "Ground Waiting List" vs "Floor Alerts"
/// - On-Duty toggle (is_on_duty) with instant server synchronization
/// - Cabin and Desk reassignment sheet integration
class ReceptionistDashboardView extends StatefulWidget {
  final List<IndustrialVisitModel> visits;
  final bool initialIsOnDuty;
  final ValueChanged<bool>? onToggleDuty;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId, int? assignedUserId, int? cabinId, int? deskId)? onReassignVisit;

  const ReceptionistDashboardView({
    super.key,
    this.visits = const [],
    this.initialIsOnDuty = true,
    this.onToggleDuty,
    this.onDecideVisit,
    this.onReassignVisit,
  });

  @override
  State<ReceptionistDashboardView> createState() => _ReceptionistDashboardViewState();
}

class _ReceptionistDashboardViewState extends State<ReceptionistDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isOnDuty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isOnDuty = widget.initialIsOnDuty;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tab 1: Ground Waiting List (Awaiting Host or inside lobby)
    final waitingList = widget.visits.where((v) => v.isPending).toList();

    // Tab 2: Floor Alerts (Escalated visits, Director visits, unassigned desks)
    final floorAlerts = widget.visits.where((v) => v.status == IndustrialVisitStatus.awaitingHost || v.departmentName == 'Executive Office').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AsmitaPalette.deepNavy,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reception Desk Operations',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Ground & Floor Visitor Coordination',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // On-Duty Switch
          Row(
            children: [
              Text(
                _isOnDuty ? 'On Duty' : 'Away',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Switch(
                value: _isOnDuty,
                activeThumbColor: AsmitaPalette.successGreen,
                onChanged: (val) {
                  setState(() => _isOnDuty = val);
                  widget.onToggleDuty?.call(val);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Waiting List (${waitingList.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notification_important_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('Floor Alerts (${floorAlerts.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Ground Waiting List
          _buildVisitList(context, waitingList, isAlertTab: false),

          // Tab 2: Floor Alerts
          _buildVisitList(context, floorAlerts, isAlertTab: true),
        ],
      ),
    );
  }

  Widget _buildVisitList(BuildContext context, List<IndustrialVisitModel> list, {required bool isAlertTab}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AsmitaPalette.textLight.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              isAlertTab ? 'No escalated floor alerts at this time.' : 'No visitors currently waiting in lobby.',
              style: const TextStyle(color: AsmitaPalette.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final visit = list[index];
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
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Host: ${visit.hostName ?? "Unassigned"} • ${visit.departmentName ?? "HQ"}',
                            style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
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
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: visit.status.badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (visit.cabinNumber != null) ...[
                      Text('Cabin: ${visit.cabinNumber}  ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                    if (visit.deskNumber != null) ...[
                      Text('Desk: ${visit.deskNumber}  ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                    Text(
                      'Request: ${visit.requestNumber}',
                      style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
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
                            widget.onReassignVisit?.call(visit.id, assignedUser, cabin, desk);
                          },
                        );
                      },
                      icon: const Icon(Icons.edit_location_alt_outlined, size: 14, color: AsmitaPalette.deepNavy),
                      label: const Text('Reassign / Allocate', style: TextStyle(fontSize: 11, color: AsmitaPalette.deepNavy)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AsmitaPalette.deepNavy),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick Approve
                    ElevatedButton(
                      onPressed: () => widget.onDecideVisit?.call(visit.id, 'APPROVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                      child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
