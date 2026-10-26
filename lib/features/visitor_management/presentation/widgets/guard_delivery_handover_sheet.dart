import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../data/models/industrial_visit_model.dart';

/// Modal sheet for gate security guard to confirm recipient package handover.
/// Moves delivery status from APPROVED to COLLECTED with verified_on_site: true.
class GuardDeliveryHandoverSheet extends StatelessWidget {
  final IndustrialVisitModel visit;
  final VoidCallback onConfirmHandover;

  const GuardDeliveryHandoverSheet({
    super.key,
    required this.visit,
    required this.onConfirmHandover,
  });

  static Future<void> show(
    BuildContext context, {
    required IndustrialVisitModel visit,
    required VoidCallback onConfirmHandover,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (_) => GuardDeliveryHandoverSheet(
        visit: visit,
        onConfirmHandover: onConfirmHandover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.successGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AsmitaPalette.successGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Package Handover',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                      ),
                      Text(
                        'Pass: ${visit.passCode ?? "N/A"} • ${visit.requestNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AsmitaPalette.textLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  _infoRow('Courier Company', visit.deliveryCompany ?? 'Courier Partner'),
                  const Divider(height: 12),
                  _infoRow('Intended Recipient', visit.hostName ?? 'HQ Employee'),
                  const Divider(height: 12),
                  _infoRow('Package Status', 'Awaiting Pickup at Gate'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onConfirmHandover();
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Confirm Handover to Recipient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AsmitaPalette.textLight)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
