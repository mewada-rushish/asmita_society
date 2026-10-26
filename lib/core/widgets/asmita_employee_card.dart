import 'package:flutter/material.dart';

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
    final cleanName = name.trim().isEmpty ? 'Employee' : name.trim();
    final cleanDesignation = designation?.trim();
    final cleanDept = _cleanValue(departmentName, fallback: 'Department');
    final cleanCabin = _cleanValue(cabinNumber, fallback: 'N/A');
    final cleanDesk = _cleanValue(deskNumber, fallback: 'N/A');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101B56),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1033).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                  // Icon Squircle Box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon ?? Icons.badge_outlined,
                      color: Colors.white,
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
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
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
                              color: const Color(
                                0xFF94A3B8,
                              ).withValues(alpha: 0.95),
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
              Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),

              const SizedBox(height: 14),

              // Bottom Metric Boxes (3 Equal Columns: Department, Cabin, Desk)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      icon: Icons.apartment_rounded,
                      headerLabel: 'DEPART...',
                      value: cleanDept,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricBox(
                      icon: Icons.meeting_room_outlined,
                      headerLabel: 'CABIN',
                      value: cleanCabin,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricBox(
                      icon: Icons.chair_outlined,
                      headerLabel: 'DESK',
                      value: cleanDesk,
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

  Widget _buildMetricBox({
    required IconData icon,
    required String headerLabel,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.9,
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
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.65)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  headerLabel,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.65),
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
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
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
