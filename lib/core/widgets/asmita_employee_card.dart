import 'package:flutter/material.dart';
import '../constants/design_system.dart';

/// Reusable Global Employee Identity Card
class AsmitaEmployeeCard extends StatelessWidget {
  final String name;
  final String? designation;
  final String? departmentName;
  final String? cabinNumber;
  final String? deskNumber;
  final bool isActive;
  final VoidCallback? onTap;
  final IconData? icon;

  const AsmitaEmployeeCard({
    super.key,
    required this.name,
    this.designation,
    this.departmentName,
    this.cabinNumber,
    this.deskNumber,
    this.isActive = true,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanName = name.trim().isEmpty ? 'Employee' : name.trim();
    final cleanDesignation = designation?.trim();
    final cleanDept = _cleanValue(departmentName, fallback: 'Department');
    final cleanCabin = _cleanValue(cabinNumber, fallback: 'N/A');
    final cleanDesk = _cleanValue(deskNumber, fallback: 'N/A');

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B);
    final insetBg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.65)
        : const Color(0xFFF8FAFC);
    final insetBorder = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);
    final avatarBg = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.5)
        : const Color(0xFFF1F5F9);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0x0A0F172A),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Subtle Squircle Avatar Container (Neutral)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: insetBorder,
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon ?? Icons.badge_outlined,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cleanName,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cleanDesignation != null &&
                            cleanDesignation.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            cleanDesignation,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Status capsule: Active / Inactive
                  _buildStatusPill(isActive),
                ],
              ),

              const SizedBox(height: 14),

              // Subtle horizontal divider
              Container(
                height: 1,
                color: borderColor,
              ),

              const SizedBox(height: 14),

              // Bottom Metric Boxes (3 Equal Columns: Department, Cabin, Desk)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      context,
                      icon: Icons.apartment_rounded,
                      headerLabel: 'DEPART...',
                      value: cleanDept,
                      insetBg: insetBg,
                      insetBorder: insetBorder,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricBox(
                      context,
                      icon: Icons.meeting_room_outlined,
                      headerLabel: 'CABIN',
                      value: cleanCabin,
                      insetBg: insetBg,
                      insetBorder: insetBorder,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricBox(
                      context,
                      icon: Icons.chair_outlined,
                      headerLabel: 'DESK',
                      value: cleanDesk,
                      insetBg: insetBg,
                      insetBorder: insetBorder,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool active) {
    const activeColor = Color(0xFF10B981);
    const inactiveColor = Color(0xFF94A3B8);
    final color = active ? activeColor : inactiveColor;
    final label = active ? 'Active' : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required IconData icon,
    required String headerLabel,
    required String value,
    required Color insetBg,
    required Color insetBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: insetBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insetBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header icon + label
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  headerLabel,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Value text
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _cleanValue(String? raw, {required String fallback}) {
    if (raw == null) return fallback;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed;
  }
}
