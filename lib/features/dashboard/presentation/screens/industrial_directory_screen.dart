import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../../core/constants/design_system.dart';
import '../../../../core/utils/property_role_resolver.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';
import '../../../visitor_management/presentation/screens/department_delegation_screen.dart';

class IndustrialDirectoryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const IndustrialDirectoryScreen({super.key, this.onBack});

  @override
  State<IndustrialDirectoryScreen> createState() => _IndustrialDirectoryScreenState();
}

class _IndustrialDirectoryScreenState extends State<IndustrialDirectoryScreen> {
  bool _isDelegationActive = false;
  List<Map<String, dynamic>> _dynamicDepartments = [];
  bool _isLoadingDepartments = true;
  List<Map<String, dynamic>> _dynamicHotlines = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadHotlines();
  }

  int? _resolveSocietyId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.societyId;
    }
    return 114;
  }

  Future<void> _loadHotlines({bool forceRefresh = false}) async {
    final societyId = _resolveSocietyId();
    if (societyId == null) return;
    try {
      final hotlines = await AsmitaPreApproveWizard.loadSocietyHotlines(societyId);
      if (mounted && hotlines.isNotEmpty) {
        setState(() {
          _dynamicHotlines = hotlines;
        });
      }
    } catch (_) {}
  }

  IconData _iconForHotline(String title, String category) {
    final t = title.toLowerCase();
    final c = category.toUpperCase();
    if (c == 'EMERGENCY' || t.contains('emergency') || t.contains('fire') || t.contains('ambulance')) {
      return Icons.emergency_rounded;
    } else if (c == 'SECURITY' || t.contains('gate') || t.contains('guard') || t.contains('security')) {
      return Icons.shield_rounded;
    } else if (c == 'LOGISTICS' || t.contains('loading') || t.contains('bay') || t.contains('dock') || t.contains('delivery')) {
      return Icons.local_shipping_rounded;
    } else if (c == 'RECEPTION' || t.contains('desk') || t.contains('front') || t.contains('lobby')) {
      return Icons.support_agent_rounded;
    }
    return Icons.phone_in_talk_rounded;
  }

  Color _colorForHotline(String title, String category, bool isDark) {
    final t = title.toLowerCase();
    final c = category.toUpperCase();
    if (c == 'EMERGENCY' || t.contains('emergency')) {
      return isDark ? const Color(0xFFF87171) : AsmitaPalette.actionRed;
    } else if (c == 'SECURITY' || t.contains('gate')) {
      return isDark ? const Color(0xFF818CF8) : const Color(0xFF1E40AF);
    } else if (c == 'LOGISTICS' || t.contains('loading') || t.contains('bay')) {
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    } else if (c == 'RECEPTION' || t.contains('desk') || t.contains('front')) {
      return isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy;
    }
    return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  }

  Future<void> _loadDepartments({bool forceRefresh = false}) async {
    final societyId = _resolveSocietyId();
    if (societyId == null) {
      if (mounted) setState(() => _isLoadingDepartments = false);
      return;
    }

    try {
      final depts = await AsmitaPreApproveWizard.loadSocietyDepartments(societyId);
      if (mounted) {
        setState(() {
          _dynamicDepartments = depts;
          _isLoadingDepartments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDepartments = false);
    }
  }

  IconData _iconForDept(String name) {
    final n = name.toLowerCase();
    if (n.contains('tech') || n.contains('it') || n.contains('system')) {
      return Icons.memory_rounded;
    } else if (n.contains('finance') || n.contains('account')) {
      return Icons.account_balance_rounded;
    } else if (n.contains('security') || n.contains('guard') || n.contains('gate')) {
      return Icons.shield_rounded;
    } else if (n.contains('executive') || n.contains('board') || n.contains('hq')) {
      return Icons.workspace_premium_rounded;
    } else if (n.contains('hr') || n.contains('human') || n.contains('admin')) {
      return Icons.people_alt_rounded;
    } else if (n.contains('supply') || n.contains('logistic') || n.contains('facility')) {
      return Icons.inventory_2_rounded;
    } else if (n.contains('market')) {
      return Icons.campaign_rounded;
    } else if (n.contains('valet') || n.contains('park')) {
      return Icons.local_parking_rounded;
    }
    return Icons.domain_rounded;
  }

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
                await Future.wait([
                  _loadDepartments(forceRefresh: true),
                  _loadHotlines(forceRefresh: true),
                ]);
                if (mounted) setState(() {});
              },
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
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

                  // Grid of quick calls linked directly to contact numbers (4 Mandatory Defaults or Custom)
                  if (_dynamicHotlines.isNotEmpty) ...[
                    for (int i = 0; i < _dynamicHotlines.length; i += 2) ...[
                      Row(
                        children: [
                          _buildHotlineCard(
                            title: (_dynamicHotlines[i]['title'] ?? 'Hotline').toString(),
                            subtitle: (_dynamicHotlines[i]['subtitle'] ?? '').toString(),
                            contactNumber: (_dynamicHotlines[i]['contact_number'] ?? '').toString(),
                            extensionNumber: _dynamicHotlines[i]['extension']?.toString(),
                            icon: _iconForHotline(
                              (_dynamicHotlines[i]['title'] ?? '').toString(),
                              (_dynamicHotlines[i]['category'] ?? '').toString(),
                            ),
                            color: _colorForHotline(
                              (_dynamicHotlines[i]['title'] ?? '').toString(),
                              (_dynamicHotlines[i]['category'] ?? '').toString(),
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (i + 1 < _dynamicHotlines.length)
                            _buildHotlineCard(
                              title: (_dynamicHotlines[i + 1]['title'] ?? 'Hotline').toString(),
                              subtitle: (_dynamicHotlines[i + 1]['subtitle'] ?? '').toString(),
                              contactNumber: (_dynamicHotlines[i + 1]['contact_number'] ?? '').toString(),
                              extensionNumber: _dynamicHotlines[i + 1]['extension']?.toString(),
                              icon: _iconForHotline(
                                (_dynamicHotlines[i + 1]['title'] ?? '').toString(),
                                (_dynamicHotlines[i + 1]['category'] ?? '').toString(),
                              ),
                              color: _colorForHotline(
                                (_dynamicHotlines[i + 1]['title'] ?? '').toString(),
                                (_dynamicHotlines[i + 1]['category'] ?? '').toString(),
                                isDark,
                              ),
                            )
                          else
                            const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ] else ...[
                    // Fallback 4 Mandatory Campus Hotlines
                    Row(
                      children: [
                        _buildHotlineCard(
                          title: 'Front Desk',
                          subtitle: 'Receptionist • Lobby',
                          contactNumber: '+91 98201 10101',
                          extensionNumber: '101',
                          icon: Icons.support_agent_rounded,
                          color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                        ),
                        const SizedBox(width: 12),
                        _buildHotlineCard(
                          title: 'Main Gate 1',
                          subtitle: 'Security Post • Gate 1',
                          contactNumber: '+91 98201 10104',
                          extensionNumber: '104',
                          icon: Icons.shield_rounded,
                          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF1E40AF),
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
                          extensionNumber: '108',
                          icon: Icons.local_shipping_rounded,
                          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 12),
                        _buildHotlineCard(
                          title: 'Emergency',
                          subtitle: 'Safety & Rapid Response',
                          contactNumber: '+91 98201 10911',
                          extensionNumber: '911',
                          icon: Icons.emergency_rounded,
                          color: isDark ? const Color(0xFFF87171) : AsmitaPalette.actionRed,
                        ),
                      ],
                    ),
                  ],

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

                  if (_isLoadingDepartments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: AsmitaLoadingIndicator(
                          color: AsmitaPalette.deepNavy,
                          size: 24,
                        ),
                      ),
                    )
                  else if (_dynamicDepartments.isNotEmpty)
                    ..._dynamicDepartments.map((dept) {
                      final name = (dept['department_name'] ?? dept['name'] ?? 'Department').toString();
                      final floor = (dept['floor_number'] ?? dept['floor'] ?? 'General').toString();
                      final deptId = dept['id'] is int ? dept['id'] as int : int.tryParse(dept['id']?.toString() ?? '');
                      final floorLabel = floor.toLowerCase().contains('floor') ? floor : 'Floor $floor';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildDeptCard(
                          title: name,
                          floor: floorLabel,
                          cabins: 'Explore Staff',
                          icon: _iconForDept(name),
                          departmentId: deptId,
                        ),
                      );
                    })
                  else ...[
                    _buildDeptCard(
                      title: 'Executive Suite & Boardroom',
                      floor: 'Floor 4 • Executive Wing',
                      cabins: 'Cabins 401 - 406',
                      icon: Icons.workspace_premium_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildDeptCard(
                      title: 'Accounts & Finance',
                      floor: 'Floor 2 • East Wing',
                      cabins: 'Cabins 201 - 210',
                      icon: Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildDeptCard(
                      title: 'Technology & IT Operations',
                      floor: 'Floor 3 • Innovation Hub',
                      cabins: 'Workstations 301 - 340',
                      icon: Icons.memory_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildDeptCard(
                      title: 'Human Resources & Admin',
                      floor: 'Floor 1 • Main Lobby Wing',
                      cabins: 'Cabins 101 - 106',
                      icon: Icons.people_alt_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildDeptCard(
                      title: 'Supply Chain & Logistics',
                      floor: 'Ground Floor • Loading Dock B',
                      cabins: 'Bays 1 - 4',
                      icon: Icons.inventory_2_rounded,
                    ),
                  ],
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
    String? extensionNumber,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => _callContact(title, contactNumber),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : theme.dividerColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
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
                      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
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

              // Title with balanced line height & dark mode text color
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AsmitaPalette.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Subtitle/Role
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : AsmitaPalette.textLight,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Contact Number & Extension Badges Row
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (extensionNumber != null && extensionNumber.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.22 : 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ext $extensionNumber',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
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
    required IconData icon,
    int? departmentId,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showDepartmentEmployeesModal(title, floor, departmentId: departmentId),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : theme.dividerColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
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
                color: isDark
                    ? const Color(0xFF60A5FA).withValues(alpha: 0.15)
                    : AsmitaPalette.deepNavy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : AsmitaPalette.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    floor,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : AsmitaPalette.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.6)
                    : theme.dividerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cabins,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : AsmitaPalette.textLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? const Color(0xFF94A3B8) : AsmitaPalette.textLight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentEmployeesModal(String deptName, String floor, {int? departmentId}) {
    final societyId = _resolveSocietyId();
    showAsmitaBottomSheet(
      context: context,
      title: deptName,
      subtitle: floor,
      contentPadding: EdgeInsets.zero,
      child: _DepartmentEmployeesSheet(
        departmentName: deptName,
        floor: floor,
        departmentId: departmentId,
        societyId: societyId,
        onCall: _callContact,
      ),
    );
  }
}

class _DepartmentEmployeesSheet extends StatefulWidget {
  final String departmentName;
  final String floor;
  final int? departmentId;
  final int? societyId;
  final Future<void> Function(String title, String phone) onCall;

  const _DepartmentEmployeesSheet({
    required this.departmentName,
    required this.floor,
    this.departmentId,
    this.societyId,
    required this.onCall,
  });

  @override
  State<_DepartmentEmployeesSheet> createState() => _DepartmentEmployeesSheetState();
}

class _DepartmentEmployeesSheetState extends State<_DepartmentEmployeesSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final sId = widget.societyId ?? 114;
      final list = await AsmitaPreApproveWizard.loadSocietyEmployees(sId);
      if (!mounted) return;

      // Filter employees belonging to this department
      final normalizedDept = widget.departmentName.toLowerCase().trim();
      final filtered = list.where((emp) {
        // Direct department_id check
        if (widget.departmentId != null) {
          final empDeptId = emp['department_id'] is int
              ? emp['department_id'] as int
              : int.tryParse(emp['department_id']?.toString() ?? '');
          if (empDeptId == widget.departmentId) return true;
        }

        final empDept = (emp['department_name'] ?? emp['department'] ?? '').toString().toLowerCase().trim();
        final role = (emp['role'] ?? emp['primary_role'] ?? '').toString().toLowerCase().trim();
        final designation = (emp['designation'] ?? '').toString().toLowerCase().trim();

        // Exact or substring department match
        if (empDept.isNotEmpty && (empDept == normalizedDept || normalizedDept.contains(empDept) || empDept.contains(normalizedDept))) {
          return true;
        }

        // Specific category mappings
        if (normalizedDept.contains('it') || normalizedDept.contains('tech')) {
          return empDept.contains('tech') || empDept.contains('it') || role.contains('tech') || role.contains('developer') || designation.contains('it');
        } else if (normalizedDept.contains('finance') || normalizedDept.contains('account')) {
          return empDept.contains('account') || empDept.contains('finance') || role.contains('account') || designation.contains('finance');
        } else if (normalizedDept.contains('hr') || normalizedDept.contains('human')) {
          return empDept.contains('hr') || empDept.contains('human') || role.contains('hr') || designation.contains('hr');
        } else if (normalizedDept.contains('supply') || normalizedDept.contains('logistic') || normalizedDept.contains('facility')) {
          return empDept.contains('supply') || empDept.contains('logistic') || empDept.contains('facility') || role.contains('logistic');
        } else if (normalizedDept.contains('executive') || normalizedDept.contains('board')) {
          // Exclude security / guards from executive
          if (role.contains('security') || role.contains('guard') || empDept.contains('security')) {
            return false;
          }
          return empDept.contains('executive') || empDept.contains('board') || role.contains('director') || role.contains('executive') || designation.contains('director');
        } else if (normalizedDept.contains('security') || normalizedDept.contains('command') || normalizedDept.contains('gate')) {
          return empDept.contains('security') || role.contains('security') || role.contains('guard');
        } else if (normalizedDept.contains('market')) {
          return empDept.contains('market') || role.contains('market') || designation.contains('market');
        } else if (normalizedDept.contains('valet')) {
          return empDept.contains('valet') || role.contains('valet');
        }

        return false;
      }).toList();

      setState(() {
        _employees = filtered;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayed = _employees.where((emp) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final name = (emp['name'] ?? emp['full_name'] ?? '').toString().toLowerCase();
      final phone = (emp['phone'] ?? emp['mobile_number'] ?? '').toString();
      final ext = (emp['extension'] ?? emp['ext'] ?? '').toString();
      return name.contains(q) || phone.contains(q) || ext.contains(q);
    }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search within Department
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: AsmitaPalette.textLight),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _query = val.trim()),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search by employee name or extension...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AsmitaPalette.textLight,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(Icons.clear_rounded, size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: AsmitaLoadingIndicator(
                      color: AsmitaPalette.deepNavy,
                      size: 28,
                    ),
                  )
                : displayed.isEmpty
                    ? Center(
                        child: Text(
                          'No employees found in this department',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: displayed.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final emp = displayed[index];
                          final name = emp['name'] ?? emp['full_name'] ?? 'Staff Member';
                          final designation = emp['designation'] ?? emp['role'] ?? 'Team Member';
                          final phone = emp['phone'] ?? emp['mobile_number'] ?? '';
                          final extension = emp['extension'] ?? emp['ext'] ?? '10${index + 1}';
                          final desk = emp['desk_number'] ?? emp['desk_code'] ?? 'D-${201 + index}';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.dividerColor.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.12),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold,
                                      color: AsmitaPalette.deepNavy,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        designation,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: AsmitaPalette.textLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.dialer_sip_rounded, size: 10, color: AsmitaPalette.deepNavy),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Ext: $extension',
                                                  style: const TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AsmitaPalette.deepNavy,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.dividerColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.chair_outlined, size: 10, color: AsmitaPalette.textLight),
                                                const SizedBox(width: 4),
                                                Text(
                                                  desk,
                                                  style: const TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AsmitaPalette.textLight,
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
                                if (phone.isNotEmpty)
                                  IconButton(
                                    onPressed: () => widget.onCall(name, phone),
                                    icon: const Icon(
                                      Icons.phone_in_talk_rounded,
                                      size: 18,
                                      color: AsmitaPalette.successGreen,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AsmitaPalette.successGreen.withValues(alpha: 0.12),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
