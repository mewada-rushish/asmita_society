import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/presentation/widgets/acknowledge_action_button.dart';
import '../../../visitor_management/presentation/widgets/delivery_action_sheet.dart';

/// Employee Role Dashboard:
/// - Approvals feed for assigned / hosted visitors
/// - Cabin and Desk location display
/// - Delegation toggle / management button
class EmployeeDashboardView extends StatelessWidget {
  final String employeeName;
  final String departmentName;
  final String cabinNumber;
  final String deskNumber;
  final List<IndustrialVisitModel> visits;
  final VoidCallback onOpenDelegation;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId)? onAcknowledgeVisit;

  const EmployeeDashboardView({
    super.key,
    this.employeeName = 'Aditi Sharma',
    this.departmentName = 'Accounts',
    this.cabinNumber = '104',
    this.deskNumber = '2',
    this.visits = const [],
    required this.onOpenDelegation,
    this.onDecideVisit,
    this.onAcknowledgeVisit,
  });

  @override
  Widget build(BuildContext context) {
    final pendingVisits = visits.where((v) => v.isPending).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Employee Profile & Location Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AsmitaPalette.deepNavy, Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Delegation Button
                        OutlinedButton.icon(
                          onPressed: onOpenDelegation,
                          icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                          label: const Text('Delegation', style: TextStyle(color: Colors.white, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$departmentName Department',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _locationBadge(Icons.meeting_room_outlined, 'Cabin $cabinNumber'),
                        const SizedBox(width: 8),
                        _locationBadge(Icons.desk_outlined, 'Desk $deskNumber'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pending Approvals Feed Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pending Approvals',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AsmitaPalette.actionRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingVisits.length} Action Needed',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AsmitaPalette.actionRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (pendingVisits.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: AsmitaPalette.successGreen.withValues(alpha: 0.6)),
                      const SizedBox(height: 12),
                      const Text('You are all caught up! No pending visitors.', style: TextStyle(color: AsmitaPalette.textLight)),
                    ],
                  ),
                )
              else
                ...pendingVisits.map((v) => _approvalCard(context, v)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _approvalCard(BuildContext context, IndustrialVisitModel visit) {
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
                  child: Icon(
                    visit.isDelivery ? Icons.local_shipping_outlined : Icons.person_outline,
                    color: AsmitaPalette.deepNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.isDelivery ? '${visit.deliveryCompany} Delivery' : visit.visitorName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${visit.isDelivery ? "Package Delivery" : (visit.purpose ?? "Meeting")} • ${visit.requestNumber}',
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
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (visit.isDelivery) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      DeliveryActionSheet.show(
                        context,
                        visit: visit,
                        onActionSelected: (action) => onDecideVisit?.call(visit.id, action),
                      );
                    },
                    icon: const Icon(Icons.touch_app, size: 16, color: Colors.white),
                    label: const Text('Delivery Options'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ] else ...[
                  if (onAcknowledgeVisit != null)
                    AcknowledgeActionButton(
                      onAcknowledge: () => onAcknowledgeVisit!(visit.id),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => onDecideVisit?.call(visit.id, 'REJECT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AsmitaPalette.actionRed,
                      side: const BorderSide(color: AsmitaPalette.actionRed),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onDecideVisit?.call(visit.id, 'APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
