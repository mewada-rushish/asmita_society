import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../data/models/industrial_visit_model.dart';

/// Modal bottom sheet allowing recipient to choose delivery action:
/// 1. Collect at Gate (default)
/// 2. Allow In (drop desk)
/// 3. Reject
class DeliveryActionSheet extends StatelessWidget {
  final IndustrialVisitModel visit;
  final ValueChanged<String> onActionSelected; // 'COLLECT_AT_GATE', 'ALLOW_IN', 'REJECT'

  const DeliveryActionSheet({
    super.key,
    required this.visit,
    required this.onActionSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required IndustrialVisitModel visit,
    required ValueChanged<String> onActionSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (_) => DeliveryActionSheet(visit: visit, onActionSelected: onActionSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: AsmitaPalette.deepNavy, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Arrival',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                      ),
                      Text(
                        '${visit.deliveryCompany ?? "Courier"} • ${visit.requestNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AsmitaPalette.textLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'A delivery agent is waiting at Gate 1. How would you like to handle this delivery?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Primary: Collect at Gate
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onActionSelected('COLLECT_AT_GATE');
              },
              icon: const Icon(Icons.handshake_outlined, color: Colors.white),
              label: const Text('Collect at Gate (Recommended)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary: Allow In
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onActionSelected('ALLOW_IN');
              },
              icon: const Icon(Icons.meeting_room_outlined, color: AsmitaPalette.deepNavy),
              label: const Text('Allow In to Ground Drop Desk'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AsmitaPalette.deepNavy,
                side: const BorderSide(color: AsmitaPalette.deepNavy),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            // Destructive: Reject
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onActionSelected('REJECT');
              },
              icon: const Icon(Icons.cancel_outlined, color: AsmitaPalette.actionRed),
              label: const Text('Reject Delivery', style: TextStyle(color: AsmitaPalette.actionRed)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
