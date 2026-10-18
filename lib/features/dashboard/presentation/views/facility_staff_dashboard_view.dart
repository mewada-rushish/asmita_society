import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';

/// Facility Staff Role Dashboard:
/// - Operations work queue
/// - Building occupancy and active checked-in visitor count
/// - Facility tasks and service logs
class FacilityStaffDashboardView extends StatelessWidget {
  final List<IndustrialVisitModel> visits;
  final VoidCallback? onRefresh;

  const FacilityStaffDashboardView({
    super.key,
    this.visits = const [],
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final insideBuildingCount = visits.where((v) => v.status == IndustrialVisitStatus.checkedIn).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Facility & Operations HQ',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AsmitaPalette.deepNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Building Occupancy Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AsmitaPalette.deepNavy.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AsmitaPalette.deepNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apartment, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Building Occupancy Tracker',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$insideBuildingCount Visitors Currently Checked-In',
                          style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Operations Work Queue
            const Text(
              'Operations Work Queue',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _taskTile(
              context,
              title: 'HVAC Airflow Check - Floor 2 Executive Cabins',
              category: 'Climate & Power',
              priority: 'High Priority',
              priorityColor: AsmitaPalette.actionRed,
              isCompleted: false,
            ),
            _taskTile(
              context,
              title: 'Lobby Visitor Badge Dispenser Maintenance',
              category: 'Security Systems',
              priority: 'Normal',
              priorityColor: AsmitaPalette.deepNavy,
              isCompleted: true,
            ),
            _taskTile(
              context,
              title: 'Conference Room 101 Projector Calibration',
              category: 'AV & IT Facilities',
              priority: 'Scheduled',
              priorityColor: AsmitaPalette.successGreen,
              isCompleted: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskTile(
    BuildContext context, {
    required String title,
    required String category,
    required String priority,
    required Color priorityColor,
    required bool isCompleted,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? AsmitaPalette.successGreen : AsmitaPalette.textLight,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(category, style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            priority,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
          ),
        ),
      ),
    );
  }
}
