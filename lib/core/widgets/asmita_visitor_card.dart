import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/env_config.dart';
import '../constants/design_system.dart';
import 'asmita_toast.dart';
import '../../features/visitor_management/data/models/industrial_visit_model.dart';

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
      passCode: (visit.passCode != null && visit.passCode!.isNotEmpty)
          ? visit.passCode
          : visit.requestNumber,
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
    final List<Color> gradientColors = avatarGradient ?? _determineAvatarGradient();

    final statusConfig = _resolveStatusConfig(
      rawStatus: statusLabel,
      isDark: isDark,
      overrideFill: statusFillColor,
      overrideText: statusTextColor,
      overrideIcon: statusIcon,
    );

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

                // 2. Inset Executive Meta Matrix (2 Rows)
                Container(
                  margin: const EdgeInsets.only(top: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Time & Date (Left) | Vehicle / Department / Gate (Right)
                      Row(
                        children: [
                          // Cell 1: Time & Date
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
                                        (timeAndDate != null && timeAndDate!.isNotEmpty) ? timeAndDate! : 'Pending Arrival',
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

                          // Vertical Divider
                          Container(
                            width: 1,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),

                          // Cell 2: Meta Location / Vehicle / Gate
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
                                        (metaValue != null && metaValue!.isNotEmpty) ? metaValue! : 'Main Gate',
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
                      ),

                      // Horizontal Hairline Divider between Row 1 and Row 2
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.5)
                            : const Color(0xFFE2E8F0),
                      ),

                      // Row 2: Security Pass Code Key (Left) | Status Cell (Right)
                      Row(
                        children: [
                          // Cell 3: Security Pass Code Key
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: hasPass
                                    ? () {
                                        Clipboard.setData(ClipboardData(text: passCode!));
                                        HapticFeedback.selectionClick();
                                        AsmitaToast.show(
                                          context,
                                          message: 'Pass code #$passCode copied to clipboard',
                                          type: AsmitaToastType.success,
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.vpn_key_rounded,
                                      size: 14,
                                      color: isDark ? const Color(0xFF93C5FD) : AsmitaPalette.deepNavy,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'SECURITY KEY',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (hasPass) ...[
                                                Text(
                                                  '#',
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.4,
                                                    color: isDark ? const Color(0xFF93C5FD) : AsmitaPalette.deepNavy,
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    passCode!,
                                                    style: TextStyle(
                                                      fontFamily: 'Montserrat',
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.4,
                                                      color: isDark ? const Color(0xFF93C5FD) : AsmitaPalette.deepNavy,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.copy_rounded,
                                                  size: 10,
                                                  color: isDark
                                                      ? const Color(0xFF93C5FD).withValues(alpha: 0.7)
                                                      : AsmitaPalette.deepNavy.withValues(alpha: 0.6),
                                                ),
                                              ] else ...[
                                                Text(
                                                  'PASS PENDING',
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Vertical Divider
                          Container(
                            width: 1,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),

                          // Cell 4: Status Cell (Dynamic Icon, BG color, Text color)
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'STATUS',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusConfig.bgColor,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: statusConfig.borderColor,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              statusConfig.icon,
                                              size: 11,
                                              color: statusConfig.textColor,
                                            ),
                                            const SizedBox(width: 4.5),
                                            Flexible(
                                              child: Text(
                                                statusConfig.label,
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: statusConfig.textColor,
                                                  letterSpacing: 0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Unified Executive Action Bar (Single Sleek Row)
                if (onApprove != null || onDeny != null || onAcknowledge != null) ...[
                  const SizedBox(height: 12),
                  _buildActionBar(context, isDark),
                ],

                // 4. Custom Bottom Actions slot
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

    final trimmedPhoto = photoUrl?.trim();
    if (trimmedPhoto != null && trimmedPhoto.isNotEmpty) {
      if (trimmedPhoto.startsWith('data:image')) {
        try {
          final commaIndex = trimmedPhoto.indexOf(',');
          final base64Str = commaIndex != -1 ? trimmedPhoto.substring(commaIndex + 1) : trimmedPhoto;
          final bytes = base64Decode(base64Str);
          avatarContent = ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorBuilder: (_, _, _) => _buildAvatarFallback(),
            ),
          );
        } catch (_) {
          avatarContent = _buildAvatarFallback();
        }
      } else {
        String fullUrl = trimmedPhoto;
        if (trimmedPhoto.startsWith('/')) {
          fullUrl = '${EnvConfig.baseUrl}$trimmedPhoto';
        }
        avatarContent = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: fullUrl,
            fit: BoxFit.cover,
            width: 48,
            height: 48,
            placeholder: (context, url) => Container(
              width: 48,
              height: 48,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            errorWidget: (context, url, error) => _buildAvatarFallback(),
          ),
        );
      }
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

    if (isPreApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.35)
              : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? const Color(0xFFB45309).withValues(alpha: 0.5)
                : const Color(0xFFFDE68A),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 12, color: Color(0xFFD97706)),
            const SizedBox(width: 3.5),
            Text(
              'VIP',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }

    if (onTap != null) {
      return Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionBar(BuildContext context, bool isDark) {
    final hasDeny = onDeny != null;
    final hasAck = onAcknowledge != null;
    final hasApprove = onApprove != null;

    final actionCount = (hasDeny ? 1 : 0) + (hasAck ? 1 : 0) + (hasApprove ? 1 : 0);
    if (actionCount == 0) return const SizedBox.shrink();

    return Row(
      children: [
        // 1. Destructive Deny Action
        if (hasDeny) ...[
          Expanded(
            flex: actionCount == 3 ? 10 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('visit_card_destructive_action'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDeny!();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4C0519).withValues(alpha: 0.35)
                        : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFE2E8F0).withValues(alpha: 0.3)
                          : const Color(0xFFFECDD3),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AsmitaPalette.actionRed,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          denyLabel ?? (actionCount == 3 ? 'Deny' : 'Deny Entry'),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AsmitaPalette.actionRed,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // Spacing
        if (hasDeny && (hasAck || hasApprove)) const SizedBox(width: 8),

        // 2. Secondary Acknowledge Action
        if (hasAck) ...[
          Expanded(
            flex: actionCount == 3 ? 10 : 1,
            child: isAcknowledged
                ? Container(
                    height: 40,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF059669).withValues(alpha: 0.4)
                            : const Color(0xFFA7F3D0),
                        width: 1.0,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Color(0xFF047857),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "Ack'd",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF047857),
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const ValueKey('visit_card_secondary_action'),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onAcknowledge!();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 15,
                              color: isDark
                                  ? const Color(0xFF93C5FD)
                                  : AsmitaPalette.deepNavy,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                actionCount == 3 ? 'Acknowledge' : 'Acknowledge Visit',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF93C5FD)
                                      : AsmitaPalette.deepNavy,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],

        // Spacing
        if (hasAck && hasApprove) const SizedBox(width: 8),

        // 3. Primary Approve Action (Hero Luxury Navy Gradient)
        if (hasApprove) ...[
          Expanded(
            flex: actionCount == 3 ? 13 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('visit_card_primary_action'),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onApprove!();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF27347B),
                        Color(0xFF1A2352),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF27347B).withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          approveLabel ?? (actionCount == 3 ? 'Approve' : 'Approve Entry'),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  _StatusThemeConfig _resolveStatusConfig({
    required String? rawStatus,
    required bool isDark,
    Color? overrideFill,
    Color? overrideText,
    IconData? overrideIcon,
  }) {
    final clean = (rawStatus ?? 'PENDING').trim().toUpperCase();

    // 1. Pending / Awaiting Host / Escalated / Submitted
    if (clean.contains('PENDING') ||
        clean.contains('AWAIT') ||
        clean.contains('WAIT') ||
        clean.contains('SUBMIT')) {
      return _StatusThemeConfig(
        label: rawStatus ?? 'Awaiting Host',
        icon: Icons.hourglass_top_rounded,
        bgColor: isDark
            ? const Color(0xFF451A03).withValues(alpha: 0.5)
            : const Color(0xFFFEF3C7),
        borderColor: isDark
            ? const Color(0xFFD97706).withValues(alpha: 0.4)
            : const Color(0xFFFDE68A),
        textColor: isDark ? const Color(0xFFFDE047) : const Color(0xFFB45309),
      );
    }

    // 2. Approved / Pre-Approved / Allow In
    if (clean.contains('APPROV') ||
        clean.contains('ALLOW') ||
        clean.contains('PRE_')) {
      return _StatusThemeConfig(
        label: rawStatus ?? 'Approved',
        icon: Icons.check_circle_rounded,
        bgColor: isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.5)
            : const Color(0xFFECFDF5),
        borderColor: isDark
            ? const Color(0xFF059669).withValues(alpha: 0.4)
            : const Color(0xFFA7F3D0),
        textColor: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
      );
    }

    // 3. Checked In / Active on Premises / Inside
    if (clean.contains('CHECKED_IN') ||
        clean.contains('CHECKED IN') ||
        clean.contains('INSIDE')) {
      return _StatusThemeConfig(
        label: rawStatus ?? 'Checked In',
        icon: Icons.sensor_door_rounded,
        bgColor: isDark
            ? const Color(0xFF134E4A).withValues(alpha: 0.5)
            : const Color(0xFFF0FDFA),
        borderColor: isDark
            ? const Color(0xFF0D9488).withValues(alpha: 0.4)
            : const Color(0xFF99F6E4),
        textColor: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
      );
    }

    // 4. Checked Out / Completed / Exited
    if (clean.contains('OUT') ||
        clean.contains('EXIT') ||
        clean.contains('COMPLET')) {
      return _StatusThemeConfig(
        label: rawStatus ?? 'Checked Out',
        icon: Icons.logout_rounded,
        bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      );
    }

    // 5. Denied / Rejected / Revoked / Blocked
    if (clean.contains('REJECT') ||
        clean.contains('DENI') ||
        clean.contains('REVOK') ||
        clean.contains('BLOCK')) {
      return _StatusThemeConfig(
        label: rawStatus ?? 'Denied',
        icon: Icons.cancel_rounded,
        bgColor: isDark
            ? const Color(0xFF4C0519).withValues(alpha: 0.5)
            : const Color(0xFFFFF1F2),
        borderColor: isDark
            ? const Color(0xFFE11D48).withValues(alpha: 0.3)
            : const Color(0xFFFECDD3),
        textColor: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C),
      );
    }

    // 6. Expired / Overstay
    if (clean.contains('EXPIR') || clean.contains('OVERSTAY')) {
      return _StatusThemeConfig(
        label: rawStatus ?? 'Expired',
        icon: Icons.timer_off_rounded,
        bgColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        textColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      );
    }

    // 7. Assigned / Host Acknowledged
    if (clean.contains('ASSIGN') || clean.contains('HOST_ACK')) {
      return _StatusThemeConfig(
        label: rawStatus ?? 'Assigned',
        icon: Icons.person_add_alt_1_rounded,
        bgColor: isDark
            ? const Color(0xFF2E1065).withValues(alpha: 0.5)
            : const Color(0xFFEDE9FE),
        borderColor: isDark
            ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
            : const Color(0xFFDDD6FE),
        textColor: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF5B21B6),
      );
    }

    // Explicit override fallback
    if (overrideFill != null && overrideText != null) {
      return _StatusThemeConfig(
        label: rawStatus ?? 'Active',
        icon: overrideIcon ?? Icons.info_outline_rounded,
        bgColor: overrideFill,
        borderColor: overrideText.withValues(alpha: 0.25),
        textColor: overrideText,
      );
    }

    // Default neutral fallback
    return _StatusThemeConfig(
      label: rawStatus ?? 'Active',
      icon: overrideIcon ?? Icons.info_outline_rounded,
      bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      textColor: isDark ? Colors.white70 : AsmitaPalette.textDark,
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

class _StatusThemeConfig {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _StatusThemeConfig({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}
