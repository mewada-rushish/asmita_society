import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../../core/constants/design_system.dart';
import '../../../../core/utils/property_role_resolver.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../visitor_management/presentation/screens/department_delegation_screen.dart';

class IndustrialDirectoryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const IndustrialDirectoryScreen({super.key, this.onBack});

  @override
  State<IndustrialDirectoryScreen> createState() => _IndustrialDirectoryScreenState();
}

class _IndustrialDirectoryScreenState extends State<IndustrialDirectoryScreen> {
  bool _isDelegationActive = false;

  Future<void> _callContact(String title, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await url_launcher.launchUrl(uri);
      if (!launched && mounted) {
        AsmitaToast.show(
          context,
          message: 'Calling $title: $phone',
          type: AsmitaToastType.info,
        );
      }
    } catch (_) {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Connecting to $title: $phone',
          type: AsmitaToastType.info,
        );
      }
    }
  }

  void _openDelegationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DepartmentDelegationScreen(
          departmentName: 'General HQ',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            subtitleOverride: 'Campus Directory & Support',
            propertyType: AsmitaPropertyType.industrial,
            showBackButton: widget.onBack != null || Navigator.canPop(context),
            onBackPressed: widget.onBack,
            allowPropertySwitching: false,
          ),
          Expanded(
            child: AsmitaPullToRefresh(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 700));
                if (mounted) setState(() {});
              },
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campus Hotline Section Header
                  Text(
                    'Campus Intercom & Hotlines',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AsmitaPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2x2 Grid of quick calls linked directly to contact numbers
                  Row(
                    children: [
                      _buildHotlineCard(
                        title: 'Front Desk',
                        subtitle: 'Receptionist • Lobby',
                        contactNumber: '+91 98201 10101',
                        icon: Icons.support_agent_rounded,
                        color: AsmitaPalette.deepNavy,
                      ),
                      const SizedBox(width: 12),
                      _buildHotlineCard(
                        title: 'Main Gate 1',
                        subtitle: 'Security Post • Gate 1',
                        contactNumber: '+91 98201 10104',
                        icon: Icons.shield_rounded,
                        color: const Color(0xFF1E40AF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildHotlineCard(
                        title: 'Loading Bay',
                        subtitle: 'Dock & Logistics • Bay 2',
                        contactNumber: '+91 98201 10108',
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 12),
                      _buildHotlineCard(
                        title: 'Emergency',
                        subtitle: 'Safety & Rapid Response',
                        contactNumber: '+91 98201 10911',
                        icon: Icons.emergency_rounded,
                        color: AsmitaPalette.actionRed,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Host Delegation Card (Compact Executive Bar)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AsmitaPalette.deepNavy,
                          Color(0xFF1B2D5A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AsmitaPalette.deepNavy.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _openDelegationScreen,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Visitor Approval Delegation',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (_isDelegationActive) ...[
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF34D399),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                        ],
                                        Flexible(
                                          child: Text(
                                            _isDelegationActive
                                                ? 'Active • Routing to department'
                                                : 'Tap to configure team routing',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              color: _isDelegationActive
                                                  ? const Color(0xFF34D399)
                                                  : Colors.white60,
                                              fontWeight: _isDelegationActive
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: _openDelegationScreen,
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                tooltip: 'Configure Members',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              Transform.scale(
                                scale: 0.82,
                                child: Switch(
                                  value: _isDelegationActive,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFFD97706),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) {
                                    setState(() => _isDelegationActive = val);
                                    AsmitaToast.show(
                                      context,
                                      message: val
                                          ? 'Delegation Active: Approvals routed to department team'
                                          : 'Delegation Deactivated: You receive direct notifications',
                                      type: val ? AsmitaToastType.success : AsmitaToastType.info,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Department Directory
                  Text(
                    'Campus Departments',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AsmitaPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildDeptCard(
                    title: 'Executive Suite & Boardroom',
                    floor: 'Floor 4 • Executive Wing',
                    cabins: 'Cabins 401 - 406',
                    contactNumber: '+91 98201 10401',
                    icon: Icons.workspace_premium_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDeptCard(
                    title: 'Accounts & Finance',
                    floor: 'Floor 2 • East Wing',
                    cabins: 'Cabins 201 - 210',
                    contactNumber: '+91 98201 10201',
                    icon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDeptCard(
                    title: 'Technology & IT Operations',
                    floor: 'Floor 3 • Innovation Hub',
                    cabins: 'Workstations 301 - 340',
                    contactNumber: '+91 98201 10301',
                    icon: Icons.memory_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDeptCard(
                    title: 'Human Resources & Admin',
                    floor: 'Floor 1 • Main Lobby Wing',
                    cabins: 'Cabins 101 - 106',
                    contactNumber: '+91 98201 10106',
                    icon: Icons.people_alt_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDeptCard(
                    title: 'Supply Chain & Logistics',
                    floor: 'Ground Floor • Loading Dock B',
                    cabins: 'Bays 1 - 4',
                    contactNumber: '+91 98201 10008',
                    icon: Icons.inventory_2_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineCard({
    required String title,
    required String subtitle,
    required String contactNumber,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _callContact(title, contactNumber),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Unit Icon + Quick Call Action Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.call_rounded, size: 11, color: color),
                        const SizedBox(width: 4),
                        Text(
                          'Call',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title with balanced line height
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4), // Generous label spacing

              // Subtitle/Role
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AsmitaPalette.textLight,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10), // Clean separation before contact number

              // Contact Number Row
              Row(
                children: [
                  Icon(
                    Icons.phone_iphone_rounded,
                    size: 13,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      contactNumber,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildDeptCard({
    required String title,
    required String floor,
    required String cabins,
    required String contactNumber,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _callContact(title, contactNumber),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AsmitaPalette.deepNavy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4), // Proper label spacing
                  Text(
                    floor,
                    style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 11, color: AsmitaPalette.deepNavy),
                      const SizedBox(width: 4),
                      Text(
                        contactNumber,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AsmitaPalette.deepNavy,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cabins,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AsmitaPalette.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
