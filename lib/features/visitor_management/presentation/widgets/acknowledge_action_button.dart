import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';

/// Quick acknowledge action on approval cards.
/// Provides visual feedback and extends the active escalation timer by ack_grace_minutes.
class AcknowledgeActionButton extends StatelessWidget {
  final VoidCallback onAcknowledge;
  final bool isAcknowledged;

  const AcknowledgeActionButton({
    super.key,
    required this.onAcknowledge,
    this.isAcknowledged = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isAcknowledged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AsmitaPalette.successGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AsmitaPalette.successGreen),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: AsmitaPalette.successGreen),
            SizedBox(width: 6),
            Text(
              'Acknowledged',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AsmitaPalette.successGreen,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onAcknowledge,
      icon: const Icon(Icons.touch_app_outlined, size: 16, color: AsmitaPalette.deepNavy),
      label: const Text(
        'Acknowledge',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AsmitaPalette.deepNavy,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AsmitaPalette.deepNavy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }
}
