import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
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

  void _callExtension(String title, String ext) {
    AsmitaToast.show(
      context,
      message: 'Calling $title (Ext $ext)...',
      type: AsmitaToastType.info,
    );
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
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 16;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, topPadding, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campus Hotline Section Header
                  const Text(
                    'Campus Intercom & Hotlines',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2x2 Grid of quick calls
                  Row(
                    children: [
                      _buildHotlineCard(
                        title: 'Front Desk',
                        subtitle: 'Receptionist',
                        ext: '101',
                        icon: Icons.support_agent_rounded,
                        color: AsmitaPalette.deepNavy,
                      ),
                      const SizedBox(width: 12),
                      _buildHotlineCard(
                        title: 'Main Gate 1',
                        subtitle: 'Security Post',
                        ext: '104',
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
                        subtitle: 'Dock & Logistics',
                        ext: '108',
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 12),
                      _buildHotlineCard(
                        title: 'Emergency',
                        subtitle: 'Safety & First Aid',
                        ext: '911',
                        icon: Icons.emergency_rounded,
                        color: AsmitaPalette.actionRed,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Host Delegation Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AsmitaPalette.deepNavy,
                          const Color(0xFF1B2D5A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AsmitaPalette.deepNavy.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.swap_horiz_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Visitor Approval Delegation',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isDelegationActive,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFFD97706),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Route your incoming visitor requests to other department members when you are in meetings or away from your desk.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _openDelegationScreen,
                            icon: const Icon(Icons.settings, size: 14, color: Colors.white),
                            label: const Text(
                              'Configure Team Members',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Department Directory
                  const Text(
                    'Campus Departments',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

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
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: const AsmitaPrimaryHeader(
              subtitleOverride: 'Campus Directory & Support',
              showBackButton: true,
              allowPropertySwitching: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineCard({
    required String title,
    required String subtitle,
    required String ext,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _callExtension(title, ext),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ext $ext',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AsmitaPalette.textLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
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
  }) {
    return Container(
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
                const SizedBox(height: 2),
                Text(
                  floor,
                  style: const TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
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
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AsmitaPalette.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
