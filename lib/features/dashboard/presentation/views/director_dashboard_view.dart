import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/presentation/widgets/acknowledge_action_button.dart';

/// Director Role Dashboard:
/// - Executive overview and visitor KPI metrics
/// - Personal VIP visitor log
/// - Quick direct contact button to floor receptionist
class DirectorDashboardView extends StatelessWidget {
  final List<IndustrialVisitModel> visits;
  final VoidCallback onContactReceptionist;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId)? onAcknowledgeVisit;

  const DirectorDashboardView({
    super.key,
    this.visits = const [],
    required this.onContactReceptionist,
    this.onDecideVisit,
    this.onAcknowledgeVisit,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = visits.where((v) => v.isPending).length;
    final approvedCount = visits.where((v) => v.status == IndustrialVisitStatus.approved).length;
    final checkedInCount = visits.where((v) => v.status == IndustrialVisitStatus.checkedIn).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                  // Quick Call to Floor Receptionist
                  ElevatedButton.icon(
                    onPressed: onContactReceptionist,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onDecideVisit?.call(visit.id, 'APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
