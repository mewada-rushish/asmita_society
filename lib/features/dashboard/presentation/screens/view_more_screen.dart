import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
// import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_pre_approve_wizard.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_security_wizard.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_raise_alert_wizard.dart';
import 'package:asmita_society/features/menu/presentation/screens/vehicles_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/visitor_history_screen.dart';
import 'package:asmita_society/features/community/presentation/attachments/create_poll_dialog.dart';

/// A utility function to show the ViewMore content in a bottom sheet.
void showViewMoreSheet(
  BuildContext context, {
  Function(int)? onNavigationItemSelected,
  VoidCallback? onNavigateToPosts,
}) {
  showAsmitaBottomSheet(
    context: context,
    title: 'Quick Actions',
    child: ViewMoreScreen(
      onNavigationItemSelected: onNavigationItemSelected,
      onNavigateToPosts: onNavigateToPosts,
    ),
  );
}

class ViewMoreScreen extends StatelessWidget {
  final Function(int)? onNavigationItemSelected;
  final VoidCallback? onNavigateToPosts;

  const ViewMoreScreen({
    super.key,
    this.onNavigationItemSelected,
    this.onNavigateToPosts,
  });

  void _showPreApproveModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Pre-Approve Visitor',
        content: AsmitaPreApproveWizard(),
      ),
    );
  }

  void _showSecurityModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Security Hub',
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
    return BlocBuilder<CommunityPostBloc, CommunityPostState>(
      builder: (context, postState) {
        final postsCount = postState.activePosts.length;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
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
                    {
                      'label': 'Maintenance',
                      'icon': Icons.request_quote_rounded,
                      'color': AsmitaPalette.deepNavy,
                    },
                    {
                      'label': 'My Vehicles',
                      'icon': Icons.directions_car_rounded,
                      'color': AsmitaPalette.deepNavy,
                      'onTap': () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehiclesScreen(
                              onNavigateToTab: onNavigationItemSelected,
                            ),
                          ),
                        );
                      },
                    },
                  ],
                ),
                const SizedBox(height: 24),
                _buildServiceSection(
                  context,
                  title: 'Communication',
                  items: [
                    {
                      'label': 'Posts',
                      'icon': Icons.dynamic_feed_rounded,
                      'color': AsmitaPalette.deepNavy,
                      'badgeCount':
                          postsCount, // Dynamically sourced from CommunityPostBloc
                      'onTap': () {
                        Navigator.pop(context);
                        if (onNavigateToPosts != null) onNavigateToPosts!();
                      },
                    },
                    {
                      'label': 'Complaints',
                      'icon': Icons.report_problem_rounded,
                      'color': AsmitaPalette.actionRed,
                    },
                    {
                      'label': 'Management',
                      'icon': Icons.admin_panel_settings_rounded,
                      'color': AsmitaPalette.deepNavy,
                    },
                    {
                      'label': 'Opinion Poll',
                      'icon': Icons.poll_rounded,
                      'color': AsmitaPalette.deepNavy,
                      'onTap': () {
                        final nav = Navigator.of(context);
                        nav.pop();
                        if (onNavigationItemSelected != null) {
                          onNavigationItemSelected!(2);
                        }
                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (nav.mounted) {
                            // ignore: use_build_context_synchronously
                            showModalBottomSheet(
                              context: nav.context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const CreatePollDialog(),
                            );
                          }
                        });
                      },
                    },
                  ],
                ),
                const SizedBox(height: 24),
                _buildServiceSection(
                  context,
                  title: 'Services & Operations',
                  items: [
                    {
                      'label': 'Utility Pay',
                      'icon': Icons.receipt_long_rounded,
                      'color': AsmitaPalette.deepNavy,
                    },
                    {
                      'label': 'Deliveries',
                      'icon': Icons.local_shipping_rounded,
                      'color': AsmitaPalette.deepNavy,
                      'onTap': () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisitorHistoryScreen(
                              filterCategory: 'delivery',
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                    },
                    {
                      'label': 'Amenities',
                      'icon': Icons.sports_tennis_rounded,
                      'color': AsmitaPalette.deepNavy,
                    },
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
        );
      },
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AsmitaPalette.deepNavy,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20, bottom: 8, left: 8, right: 8),
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
              childAspectRatio: 1.0,
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
                badgeCount: (item['badgeCount'] as int?) ?? 0,
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
    int badgeCount = 0,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AsmitaPalette.actionRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
