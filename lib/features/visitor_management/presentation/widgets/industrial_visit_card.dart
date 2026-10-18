import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../data/models/industrial_visit_model.dart';

/// Shared Industrial Visit Card Component
/// Enforces exact content hierarchy:
/// 1. Visitor Photo / Avatar
/// 2. Full Name
/// 3. Status Badge (with WCAG AA compliant colors and icon)
/// 4. Department
/// 5. Host Name
/// 6. Destination Cabin & Desk
/// 7. Purpose
/// 8. Vehicle Tag
///
/// Action Button Order strictly enforced:
/// [Primary] (Approve / Check In) -> [Secondary] (Acknowledge / Reassign) -> [Destructive] (Reject / Revoke)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final badgeFill = visit.status.fillColor(isDark);
    final badgeText = visit.status.textColor(isDark);

    final hasActions = onPrimaryAction != null ||
        onSecondaryAction != null ||
        onDestructiveAction != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.2 : 0.8),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Photo + Name + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visitor Photo / Avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: visit.visitorPhotoUrl != null && visit.visitorPhotoUrl!.isNotEmpty
                        ? Image.network(
                            visit.visitorPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _fallbackAvatar(),
                          )
                        : _fallbackAvatar(),
                  ),
                  const SizedBox(width: 12),
                  // Full Name & Request Number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.isDelivery
                              ? '${visit.deliveryCompany ?? "Courier"} Delivery'
                              : visit.visitorName,
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          visit.requestNumber,
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : AsmitaPalette.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge with WCAG AA Colors
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: badgeText.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(visit.status.iconData, size: 12, color: badgeText),
                        const SizedBox(width: 5),
                        Text(
                          visit.status.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Department & Host Name
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 14,
                    color: isDark ? Colors.grey[400] : AsmitaPalette.textLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    visit.departmentName ?? 'General Operations',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[200] : AsmitaPalette.deepNavy,
                    ),
                  ),
                  if (visit.hostName != null && visit.hostName!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: isDark ? Colors.grey[500] : AsmitaPalette.textLight),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: isDark ? Colors.grey[400] : AsmitaPalette.textLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        visit.hostName!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : AsmitaPalette.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // 3. Destination Cabin & Desk
              Row(
                children: [
                  _destinationPill(
                    icon: Icons.meeting_room_outlined,
                    label: visit.cabinNumber != null ? 'Cabin: ${visit.cabinNumber}' : 'Cabin: TBD',
                    color: const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _destinationPill(
                    icon: Icons.computer_outlined,
                    label: visit.deskNumber != null ? 'Desk: ${visit.deskNumber}' : 'Desk: TBD',
                    color: const Color(0xFF4F46E5),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 4. Purpose
              if (visit.purpose != null && visit.purpose!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 14,
                        color: isDark ? Colors.grey[400] : AsmitaPalette.textLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          visit.purpose!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : AsmitaPalette.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // 5. Vehicle Tag
              if (visit.vehicleNumber != null && visit.vehicleNumber!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car, size: 13, color: Color(0xFF0284C7)),
                      const SizedBox(width: 5),
                      Text(
                        '[Vehicle: ${visit.vehicleNumber}]',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),

              // Strict Action Button Hierarchy:
              // [Primary] -> [Secondary] -> [Destructive]
              if (hasActions) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Primary Action (Approve / Check In)
                    if (onPrimaryAction != null)
                      ElevatedButton.icon(
                        key: const ValueKey('visit_card_primary_action'),
                        onPressed: onPrimaryAction,
                        icon: Icon(
                          primaryActionIcon ?? Icons.check_circle_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          primaryActionLabel ?? 'Approve',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AsmitaPalette.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                    // Secondary Action (Acknowledge / Reassign)
                    if (onSecondaryAction != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        key: const ValueKey('visit_card_secondary_action'),
                        onPressed: onSecondaryAction,
                        icon: Icon(
                          secondaryActionIcon ?? Icons.access_time,
                          size: 16,
                          color: const Color(0xFFD97706),
                        ),
                        label: Text(
                          secondaryActionLabel ?? 'Acknowledge',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],

                    // Destructive Action (Reject / Revoke)
                    if (onDestructiveAction != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        key: const ValueKey('visit_card_destructive_action'),
                        onPressed: onDestructiveAction,
                        icon: Icon(
                          destructiveActionIcon ?? Icons.cancel_outlined,
                          size: 16,
                          color: AsmitaPalette.actionRed,
                        ),
                        label: Text(
                          destructiveActionLabel ?? 'Reject',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AsmitaPalette.actionRed,
                          side: const BorderSide(color: AsmitaPalette.actionRed),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Center(
      child: Icon(
        visit.isDelivery ? Icons.local_shipping_outlined : Icons.person_outline,
        size: 24,
        color: AsmitaPalette.deepNavy,
      ),
    );
  }

  Widget _destinationPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.4 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
