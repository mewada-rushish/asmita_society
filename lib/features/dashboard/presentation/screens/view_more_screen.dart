import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
// import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart'; 
import 'package:asmita_society/features/dashboard/widgets/asmita_pre_approve_wizard.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_security_wizard.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_raise_alert_wizard.dart';
import 'package:asmita_society/features/services/presentation/screens/daily_help_screen.dart';

class ViewMoreScreen extends StatelessWidget {
  final Function(int)? onNavigationItemSelected;

  const ViewMoreScreen({
    super.key,
    this.onNavigationItemSelected,
  });

  void _showPreApproveModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Pre-Approve Entry',
        content: AsmitaPreApproveWizard(),
      ),
    );
  }

  void _showSecurityModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Security Assistance',
        content: AsmitaSecurityWizard(),
      ),
    );
  }

  void _showRaiseAlertModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Emergency Broadcast',
        content: AsmitaRaiseAlertWizard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Premium Unified Top Header Block
          Container(
            padding: const EdgeInsets.only(top: 54, left: 20, right: 20, bottom: 20),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy, size: 20),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All Services',
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w700, 
                          color: AsmitaPalette.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Siddhi CHS 34 Directory',
                        style: const TextStyle(
                          fontSize: 12, 
                          color: AsmitaPalette.textLight, 
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Grid Area
          Expanded(
            child: Container(
              color: AsmitaPalette.systemBG,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildServiceSection(
                    context,
                    title: 'Society Utilities',
                    items: [
                      {
                        'label': 'Pre-Approve', 
                        'icon': Icons.person_add_alt_1_rounded, 
                        'color': AsmitaPalette.deepNavy,
                        'onTap': () => _showPreApproveModal(context),
                      },
                      {
                        'label': 'Security Hub', 
                        'icon': Icons.local_police_rounded, 
                        'color': AsmitaPalette.deepNavy,
                        'onTap': () => _showSecurityModal(context),
                      },
                      {'label': 'Pay Bills', 'icon': Icons.credit_card_rounded, 'color': AsmitaPalette.deepNavy},
                      {'label': 'My Vehicles', 'icon': Icons.directions_car_rounded, 'color': AsmitaPalette.deepNavy},
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildServiceSection(
                    context,
                    title: 'Community Interaction',
                    items: [
                      {'label': 'Ask Society', 'icon': Icons.quiz_outlined, 'color': AsmitaPalette.deepNavy},
                      {'label': 'Notice Board', 'icon': Icons.assignment_outlined, 'color': AsmitaPalette.deepNavy},
                      {'label': 'Social Feed', 'icon': Icons.dynamic_feed_rounded, 'color': AsmitaPalette.deepNavy},
                      {'label': 'Complaints', 'icon': Icons.report_problem_rounded, 'color': AsmitaPalette.actionRed},
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildServiceSection(
                    context,
                    title: 'Local Services',
                    items: [
                      {
                        'label': 'Daily Help', 
                        'icon': Icons.face_retouching_natural_rounded, 
                        'color': AsmitaPalette.deepNavy,
                        'onTap': () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DailyHelpScreen()),
                            ),
                      },
                      {'label': 'Deliveries', 'icon': Icons.local_shipping_rounded, 'color': AsmitaPalette.deepNavy},
                      {'label': 'Amenities', 'icon': Icons.sports_tennis_rounded, 'color': AsmitaPalette.deepNavy},
                      {
                        'label': 'Emergency', 
                        'icon': Icons.gpp_bad_outlined, 
                        'color': AsmitaPalette.actionRed,
                        'onTap': () => _showRaiseAlertModal(context),
                      },
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // // UPDATED: Now leveraging your reusable global navigation component
      // bottomNavigationBar: AsmitaBottomNavBar(
      //   currentIndex: 3, // hardcoded to index 3 so Services highlights as active
      //   onTap: (index) {
      //     if (index != 3) {
      //       Navigator.pop(context); // Safely clears route memory history stack
      //       onNavigationItemSelected?.call(index); // Syncs back into your main dashboard shell container
      //     }
      //   },
      // ),
    );
  }

  Widget _buildServiceSection(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 14, 
              fontWeight: FontWeight.w700, 
              color: AsmitaPalette.textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 4,
              childAspectRatio: 0.82,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildGridMenuItem(
                context,
                icon: item['icon'] as IconData,
                label: item['label'] as String,
                iconColor: item['color'] as Color,
                onTap: item['onTap'] as VoidCallback?,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AsmitaPalette.systemBG,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 11, 
                fontWeight: FontWeight.w600, 
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}