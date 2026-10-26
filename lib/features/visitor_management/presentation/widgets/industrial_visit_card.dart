import 'package:flutter/material.dart';
import '../../../../core/widgets/asmita_visitor_card.dart';
import '../../data/models/industrial_visit_model.dart';

export '../../../../core/widgets/asmita_visitor_card.dart';

/// Shared Industrial Visit Card Component
/// Standardized on the global [AsmitaVisitorCard] with identical executive aesthetics.
class IndustrialVisitCard extends StatelessWidget {
  final IndustrialVisitModel visit;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onDestructiveAction;
  final String? destructiveActionLabel;
  final IconData? destructiveActionIcon;
  final VoidCallback? onTap;

  const IndustrialVisitCard({
    super.key,
    required this.visit,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onDestructiveAction,
    this.destructiveActionLabel,
    this.destructiveActionIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget? bottomActions;
    if (onSecondaryAction != null) {
      bottomActions = Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: onSecondaryAction,
          icon: Icon(secondaryActionIcon ?? Icons.swap_horiz_rounded, size: 15),
          label: Text(
            secondaryActionLabel ?? 'Action',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return AsmitaVisitorCard.fromIndustrialVisit(
      visit: visit,
      context: context,
      onTap: onTap,
      onApprove: onPrimaryAction,
      approveLabel: primaryActionLabel,
      onDeny: onDestructiveAction,
      denyLabel: destructiveActionLabel,
      bottomActions: bottomActions,
    );
  }
}
