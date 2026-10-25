import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants/design_system.dart';
import 'asmita_toast.dart';
import '../../features/visitor_management/data/models/industrial_visit_model.dart';
import '../../features/visitor_management/presentation/widgets/acknowledge_action_button.dart';

/// Global, reusable Executive Visitor Card component.
/// Standardized across Resident, Employee, Receptionist, Guard, and Director dashboards.
class AsmitaVisitorCard extends StatelessWidget {
  /// Primary visitor name or entity (e.g. "RUSHISH MEWADA" or "Amazon Courier")
  final String title;

  /// Secondary descriptive label (e.g. "Visiting IT Department" or "Pre-approved by John")
  final String? subtitle;

  /// Category name (e.g. "delivery", "cab", "visitor", "vip")
  final String? category;

  /// Company name (e.g. "Amazon", "Uber", "Swiggy")
  final String? company;

  /// Visitor photo URL if available
  final String? photoUrl;

  /// Leading icon override (defaults to person or delivery icon)
  final IconData? icon;

  /// Gradient colors for squircle avatar
  final List<Color>? avatarGradient;

  /// Whether this is a VIP / Pre-Approved visitor
  final bool isPreApproved;

  /// Whether the visit is outside authorized schedule
  final bool isOutsideSchedule;

  /// Formatted entry/scheduled time and date (e.g. "11:56 AM • 23 Oct 2026")
  final String? timeAndDate;

  /// Secondary meta block label (e.g. "DEPARTMENT", "ACCESS GATE", "VEHICLE", "SLOT")
  final String? metaLabel;

  /// Secondary meta block value (e.g. "IT Dept", "Main Gate", "MH01DD1878")
  final String? metaValue;

  /// Secondary meta block icon
  final IconData? metaIcon;

  /// Digital pass code (e.g. "PASS-2026-0009")
  final String? passCode;

  /// Whether a QR code token is available
  final bool hasQrCode;

  /// Status label (e.g. "PENDING", "APPROVED", "EXPIRED", "CHECKED IN")
  final String? statusLabel;

  /// Status badge background color
  final Color? statusFillColor;

  /// Status badge text/icon color
  final Color? statusTextColor;

  /// Status icon
  final IconData? statusIcon;

  /// Card tap callback
  final VoidCallback? onTap;

  /// Approve action callback
  final VoidCallback? onApprove;
  final String? approveLabel;

  /// Deny / Reject action callback
  final VoidCallback? onDeny;
  final String? denyLabel;

  /// Acknowledge action callback
  final VoidCallback? onAcknowledge;
  final bool isAcknowledged;

  /// Custom bottom actions or trailing widget
  final Widget? bottomActions;
  final Widget? trailing;

  const AsmitaVisitorCard({
    super.key,
    required this.title,
    this.subtitle,
    this.category,
    this.company,
    this.photoUrl,
    this.icon,
    this.avatarGradient,
    this.isPreApproved = false,
    this.isOutsideSchedule = false,
    this.timeAndDate,
    this.metaLabel,
    this.metaValue,
    this.metaIcon,
    this.passCode,
    this.hasQrCode = false,
    this.statusLabel,
    this.statusFillColor,
    this.statusTextColor,
    this.statusIcon,
    this.onTap,
    this.onApprove,
    this.approveLabel,
    this.onDeny,
    this.denyLabel,
    this.onAcknowledge,
    this.isAcknowledged = false,
    this.bottomActions,
    this.trailing,
  });

  /// Factory constructor to render directly from an [IndustrialVisitModel]
  factory AsmitaVisitorCard.fromIndustrialVisit({
    Key? key,
    required IndustrialVisitModel visit,
    BuildContext? context,
    VoidCallback? onTap,
    VoidCallback? onApprove,
    String? approveLabel,
    VoidCallback? onDeny,
    String? denyLabel,
    VoidCallback? onAcknowledge,
    bool isAcknowledged = false,
    Widget? bottomActions,
    Widget? trailing,
  }) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;

    final String title = visit.isDelivery
        ? '${visit.deliveryCompany ?? "Courier"} Delivery'
        : (visit.visitorName.isNotEmpty ? visit.visitorName : 'Guest Visitor');

    final String subtitle = visit.deliveryCompany ??
        visit.purpose ??
        (visit.isDelivery
            ? 'Package Delivery'
            : (visit.departmentName != null
                ? 'Visiting ${visit.departmentName}'
                : 'Guest Visit'));

    // Time & Date format
    final DateTime? dt = visit.checkInAt ?? visit.createdAt;
    final String timeAndDate = dt != null
        ? '${DateFormat('hh:mm a').format(dt)} • ${DateFormat('dd MMM yyyy').format(dt)}'
        : 'Scheduled Visit';

    // Meta cell logic
    final bool hasVehicle = visit.vehicleNumber != null && visit.vehicleNumber!.trim().isNotEmpty;
    final String metaLabel = hasVehicle
        ? 'VEHICLE'
        : (visit.departmentName != null && visit.departmentName!.trim().isNotEmpty
            ? 'DEPARTMENT'
            : 'ACCESS GATE');
    final String metaValue = hasVehicle
        ? visit.vehicleNumber!
        : (visit.departmentName ?? 'General Campus');
    final IconData metaIcon = hasVehicle
        ? Icons.directions_car_filled_rounded
        : (visit.departmentName != null ? Icons.business_rounded : Icons.meeting_room_rounded);

    return AsmitaVisitorCard(
      key: key,
      title: title,
      subtitle: subtitle,
      category: visit.isDelivery ? 'delivery' : (hasVehicle ? 'cab' : 'visitor'),
      company: visit.deliveryCompany,
      photoUrl: visit.visitorPhotoUrl,
      icon: visit.isDelivery
          ? Icons.local_shipping_rounded
          : (visit.isCheckedIn
              ? Icons.how_to_reg_rounded
              : Icons.person_rounded),
      isPreApproved: visit.isPreApproved,
      timeAndDate: timeAndDate,
      metaLabel: metaLabel,
      metaValue: metaValue,
      metaIcon: metaIcon,
      passCode: visit.passCode,
      hasQrCode: visit.statusToken != null && visit.statusToken!.isNotEmpty,
      statusLabel: visit.status.label,
      statusFillColor: visit.status.fillColor(isDark),
      statusTextColor: visit.status.textColor(isDark),
      statusIcon: visit.status.iconData,
      onTap: onTap,
      onApprove: onApprove,
      approveLabel: approveLabel,
      onDeny: onDeny,
      denyLabel: denyLabel,
      onAcknowledge: onAcknowledge,
      isAcknowledged: isAcknowledged,
      bottomActions: bottomActions,
      trailing: trailing,
    );
  }

  /// Factory constructor to render directly from a Visitor History map [item]
  factory AsmitaVisitorCard.fromMap({
    Key? key,
    required Map<String, dynamic> item,
    VoidCallback? onTap,
    Widget? bottomActions,
    Widget? trailing,
  }) {
    final passCode = item['passCode']?.toString();
    final qrCode = item['qrCode']?.toString();
    final bool hasQr = qrCode != null && qrCode.isNotEmpty;

    // Time & Date format
    final entryTime = item['entryTime'] as String? ?? '';
    final date = item['date'] as String? ?? '';
    final timeAndDate = entryTime.isNotEmpty && date.isNotEmpty
        ? '$entryTime • $date'
        : (entryTime.isNotEmpty ? entryTime : date);

    // Slot vs Vehicle vs Gate
    final bool isFrequent = item['inviteSubType'] == 'FREQUENT' &&
        item['startTime'] != null &&
        item['endTime'] != null;
    final bool hasVehicle = item['vehicleNumber'] != null &&
        item['vehicleNumber'].toString().trim().isNotEmpty;

    final String metaLabel = isFrequent
        ? 'SLOT'
        : (hasVehicle ? 'VEHICLE' : 'ACCESS GATE');

    final String metaValue = isFrequent
        ? '${_formatSlotTime(item['startTime'])} - ${_formatSlotTime(item['endTime'])}'
        : (hasVehicle
            ? item['vehicleNumber'].toString()
            : (item['gate'] as String? ?? 'Main Gate'));

    final IconData metaIcon = isFrequent
        ? Icons.timelapse_rounded
        : (hasVehicle
            ? Icons.directions_car_filled_rounded
            : Icons.meeting_room_rounded);

    return AsmitaVisitorCard(
      key: key,
      title: item['titleText'] as String? ?? item['name'] as String? ?? 'Visitor',
      subtitle: item['subtitleText'] as String?,
      category: item['category']?.toString(),
      company: item['company']?.toString(),
      icon: item['icon'] as IconData?,
      isPreApproved: item['isPreApproved'] == true,
      isOutsideSchedule: item['isOutsideSchedule'] == true,
      timeAndDate: timeAndDate,
      metaLabel: metaLabel,
      metaValue: metaValue,
      metaIcon: metaIcon,
      passCode: passCode,
      hasQrCode: hasQr,
      statusLabel: item['status'] as String?,
      onTap: onTap,
      bottomActions: bottomActions,
      trailing: trailing,
    );
  }

  static String _formatSlotTime(dynamic rawTime) {
    if (rawTime == null) return '--';
    String timeStr = rawTime.toString();
    try {
      if (timeStr.contains('T')) {
        timeStr = timeStr.split('T')[1];
      }
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;
        final time = TimeOfDay(hour: hour, minute: minute);
        final now = DateTime.now();
        return DateFormat.jm().format(
          DateTime(now.year, now.month, now.day, time.hour, time.minute),
        );
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPass = passCode != null && passCode!.trim().isNotEmpty;

    // Squircle gradient selection matching visitor history aesthetics
    final List<Color> gradientColors = avatarGradient ?? _determineAvatarGradient();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOutsideSchedule
              ? AsmitaPalette.actionRed.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isOutsideSchedule ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOutsideSchedule
                ? AsmitaPalette.actionRed.withValues(alpha: isDark ? 0.15 : 0.08)
                : (isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0x0A0F172A)),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0x050F172A),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Row: Avatar + Title & Subtitle + Status / Action
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Squircle Avatar
                    _buildAvatar(context, isDark, gradientColors),
                    const SizedBox(width: 14),

                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (isPreApproved) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF78350F).withValues(alpha: 0.35)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFFB45309).withValues(alpha: 0.6)
                                          : const Color(0xFFFDE68A),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 10, color: Color(0xFFD97706)),
                                      const SizedBox(width: 3),
                                      Text(
                                        'VIP PASS',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? const Color(0xFFFDE68A)
                                              : const Color(0xFFB45309),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (subtitle != null && subtitle!.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    subtitle!,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AsmitaPalette.textDarkModeMuted
                                          : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          if (isOutsideSchedule) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF450A0A)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF7F1D1D)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: const Text(
                                '⚠️ Outside Schedule',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Right Affordance: Status pill, QR button, trailing widget, or chevron
                    _buildRightAffordance(context, isDark),
                  ],
                ),

                // 2. Inset Executive Meta Footer
                Container(
                  margin: const EdgeInsets.only(top: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.6)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cell 1: Time & Date
                      if (timeAndDate != null && timeAndDate!.isNotEmpty) ...[
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'TIME & DATE',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    Text(
                                      timeAndDate!,
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ],

                      // Cell 2: Meta Location / Vehicle / Gate
                      if (metaValue != null && metaValue!.isNotEmpty) ...[
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                metaIcon ?? Icons.meeting_room_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      metaLabel ?? 'ACCESS GATE',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    Text(
                                      metaValue!,
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Cell 3: Security Pass Code Ticket
                      if (hasPass) ...[
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: passCode!));
                              HapticFeedback.selectionClick();
                              AsmitaToast.show(
                                context,
                                message: 'Pass code #$passCode copied to clipboard',
                                type: AsmitaToastType.success,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.vpn_key_rounded,
                                    size: 11,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '#$passCode',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 3. Optional Bottom Decision Actions (e.g. Approve/Deny buttons)
                if (onApprove != null || onDeny != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (onDeny != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDeny,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: Text(
                              denyLabel ?? 'Deny Entry',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AsmitaPalette.actionRed,
                              side: BorderSide(
                                color: AsmitaPalette.actionRed.withValues(alpha: 0.8),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      if (onApprove != null && onDeny != null)
                        const SizedBox(width: 10),
                      if (onApprove != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onApprove,
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                              approveLabel ?? 'Approve Entry',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AsmitaPalette.deepNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // 4. Optional Acknowledge Action Button
                if (onAcknowledge != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: AcknowledgeActionButton(
                      isAcknowledged: isAcknowledged,
                      onAcknowledge: onAcknowledge!,
                    ),
                  ),
                ],

                // 5. Custom Bottom Actions slot
                if (bottomActions != null) ...[
                  const SizedBox(height: 12),
                  bottomActions!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isDark, List<Color> gradientColors) {
    Widget avatarContent;

    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      avatarContent = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          photoUrl!.trim(),
          fit: BoxFit.cover,
          width: 48,
          height: 48,
          errorBuilder: (_, _, _) => _buildAvatarFallback(),
        ),
      );
    } else {
      avatarContent = _buildAvatarFallback();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: isDark ? 0.35 : 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: Center(child: avatarContent),
        ),
        if (isPreApproved)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    if (icon != null) {
      return Icon(icon, color: Colors.white, size: 22);
    }
    final initial = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'V';
    return Text(
      initial,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRightAffordance(BuildContext context, bool isDark) {
    if (trailing != null) return trailing!;

    if (statusLabel != null && statusLabel!.isNotEmpty) {
      final fill = statusFillColor ?? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
      final textC = statusTextColor ?? (isDark ? Colors.white70 : AsmitaPalette.textDark);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textC.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusIcon != null) ...[
              Icon(statusIcon, size: 12, color: textC),
              const SizedBox(width: 4),
            ],
            Text(
              statusLabel!,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: textC,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    if (hasQrCode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: 16,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
            ),
            const SizedBox(width: 4),
            Text(
              'QR',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: 13,
      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
    );
  }

  List<Color> _determineAvatarGradient() {
    final cat = (category ?? '').toLowerCase();
    final comp = (company ?? '').toLowerCase();

    if (cat == 'delivery') {
      return const [Color(0xFFD97706), Color(0xFFF59E0B)];
    } else if (comp.contains('uber') || cat.contains('cab')) {
      return const [Color(0xFF334155), Color(0xFF1E293B)];
    } else if (isPreApproved) {
      return const [Color(0xFF1E293B), Color(0xFF27347B)];
    } else {
      return const [Color(0xFF1E3A8A), Color(0xFF2563EB)];
    }
  }
}
