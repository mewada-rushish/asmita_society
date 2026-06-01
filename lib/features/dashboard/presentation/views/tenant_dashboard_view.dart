import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/utils/dashboard_scroll_physics.dart';

class TenantDashboardView extends StatefulWidget {
  const TenantDashboardView({super.key});

  @override
  State<TenantDashboardView> createState() => _TenantDashboardViewState();
}

class _TenantDashboardViewState extends State<TenantDashboardView> {
  // Starts perfectly offset to hide the top Quick Actions
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 426.0);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFixedHeader(context),
          Expanded(
            child: Container(
              color: AsmitaPalette.systemBG,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const DashboardScrollPhysics(
                  junctionOffset: 426.0,
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  AsmitaAnimatedRefresh(
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 1500));
                    },
                  ),
                  
                  // HIDDEN TOP SECTION (Revealed by pulling down)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildRentSummaryCard(context),
                        const SizedBox(height: 24),
                        _buildQuickActionsMatrix(context),
                        const SizedBox(height: 24),
                        _buildAdPlaceholder(context, typeLabel: 'Slim Bar Ad', height: 54, margin: const EdgeInsets.symmetric(horizontal: 16)),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  // DEFAULT VISIBLE SECTION (Scrolls continuously upward)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, icon: Icons.notifications_active_rounded, title: '2 Entry Updates'),
                        const SizedBox(height: 12),
                        _buildGateSyncModule(context),
                        const SizedBox(height: 24),
                        _buildAdPlaceholder(context, typeLabel: 'Card Ad', height: 80, margin: const EdgeInsets.symmetric(horizontal: 16)),
                        const SizedBox(height: 24),
                        _buildCommunityPostsHeader(context),
                        const SizedBox(height: 12),
                        _buildCommunityPostsModule(context),
                        const SizedBox(height: 24),
                        _buildServicesFooter(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- INTERNAL UTILITY COMPONENT CORES ---

  Widget _buildFixedHeader(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AsmitaPalette.systemBG,
      padding: EdgeInsets.only(top: topPadding > 0 ? topPadding + 8 : 24, bottom: 12, left: 16, right: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.blur_on_rounded, color: AsmitaPalette.actionRed, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Hello, Kavana', style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy.withValues(alpha: 0.8), size: 18),
                  ],
                ),
                Text('Flat B-105 • Tenant', style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.actionRed, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy, size: 24), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: AsmitaPalette.deepNavy, size: 22), onPressed: () {}),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 16,
            backgroundColor: AsmitaPalette.deepNavy,
            child: Text('KM', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildRentSummaryCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AsmitaPalette.deepNavy,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AsmitaPalette.deepNavy.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming Rent', style: textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                const Icon(Icons.home_work_rounded, color: Colors.white, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text('₹ 28,000.00', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Due: 05 Jun 2026', style: textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.actionRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  ),
                  child: Text('Pay Rent', style: textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required IconData icon, required String title}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: AsmitaPalette.deepNavy, size: 20),
          const SizedBox(width: 8),
          Text(title, style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCommunityPostsHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Community Posts", style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_note_rounded, size: 16, color: AsmitaPalette.actionRed),
            label: Text("New Post", style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.actionRed, fontSize: 12, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AsmitaPalette.actionRed,
              side: const BorderSide(color: AsmitaPalette.actionRed, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsMatrix(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick Actions', style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: AsmitaPalette.textLight),
                  const SizedBox(width: 4),
                  Text('Customise', style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItem(context, Icons.person_add_alt_1_rounded, 'Pre-Approve', badgeLabel: 'Safe mode'),
              _buildGridItem(context, Icons.support_agent_rounded, 'Raise Ticket'),
              _buildGridItem(context, Icons.handshake_rounded, 'Leases'),
              _buildGridItem(context, Icons.phone_in_talk_rounded, 'Contact Owner'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGateSyncModule(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Entry Updates", style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Text('View All', style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.actionRed, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Icon(Icons.chevron_right_rounded, color: AsmitaPalette.actionRed, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCircularAvatarHook(context, 'Shaikh Nisar', hasBadge: true),
                const SizedBox(width: 14),
                _buildCircularAvatarHook(context, 'Aaqib', hasBadge: true),
                const SizedBox(width: 14),
                _buildCircularActionHook(context, Icons.engineering_outlined, 'Daily Help'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityPostsModule(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AsmitaPalette.actionRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.assignment_outlined, color: AsmitaPalette.actionRed, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Notice", style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text("Water supply shutdown scheduled for maintenance this Thursday from 10:00 AM to 2:00 PM.", style: textTheme.bodyMedium?.copyWith(fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesFooter(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Services", style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
          Row(
            children: [
              Text('See All', style: textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdPlaceholder(BuildContext context, {required String typeLabel, required double height, required EdgeInsetsGeometry margin}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AsmitaPalette.borderGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      child: Center(
        child: Text('Ad {$typeLabel}', style: textTheme.titleLarge?.copyWith(color: AsmitaPalette.textLight, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String label, {String? badgeLabel, int? notificationCount, Color iconColor = AsmitaPalette.deepNavy, bool isUtilityButton = false}) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isUtilityButton ? Border.all(color: AsmitaPalette.borderGrey, width: 1.5) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Icon(icon, color: isUtilityButton ? AsmitaPalette.actionRed : iconColor, size: 24),
              ),
              if (badgeLabel != null)
                Positioned(top: -6, left: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF5E35B1), borderRadius: BorderRadius.circular(6)), child: Text(badgeLabel.toUpperCase(), style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 0.3)))),
              if (notificationCount != null)
                Positioned(top: -4, right: -4, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AsmitaPalette.actionRed, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text('$notificationCount', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.bodyLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildCircularAvatarHook(BuildContext context, String shortName, {bool hasBadge = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: AsmitaPalette.borderGrey, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Center(child: Icon(Icons.account_circle, color: AsmitaPalette.deepNavy, size: 36)),
            ),
            if (hasBadge)
              Positioned(top: -2, right: -2, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AsmitaPalette.actionRed, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 8))),
          ],
        ),
        const SizedBox(height: 6),
        Text(shortName, style: textTheme.bodyMedium?.copyWith(fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildCircularActionHook(BuildContext context, IconData icon, String label) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5)),
              child: Icon(icon, color: AsmitaPalette.deepNavy, size: 20),
            ),
            Positioned(top: 0, right: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: AsmitaPalette.actionRed, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 10))),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}