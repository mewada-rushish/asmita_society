import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/utils/dashboard_scroll_physics.dart';

class OwnerDashboardView extends StatefulWidget {
  const OwnerDashboardView({super.key});

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 440.0);

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
                  junctionOffset: 440.0,
                  parent: const AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  AsmitaAnimatedRefresh(
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 1500));
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildAdPlaceholder(context, typeLabel: 'Slider Image Ad', height: 140, margin: const EdgeInsets.symmetric(horizontal: 16)),
                        const SizedBox(height: 16),
                        _buildQuickActionsMatrix(context),
                        const SizedBox(height: 20),
                        _buildAdPlaceholder(context, typeLabel: 'Slim Bar Ad', height: 54, margin: const EdgeInsets.symmetric(horizontal: 16)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AsmitaPalette.borderGrey,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'You have no new updates',
                              style: textTheme.bodyLarge?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                    Text('Siddhi CHS 34', style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy.withValues(alpha: 0.8), size: 18),
                  ],
                ),
                Text('Premium Mode', style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy, size: 24), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: AsmitaPalette.deepNavy, size: 22), onPressed: () {}),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 16,
            backgroundColor: AsmitaPalette.deepNavy,
            child: Text('RM', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
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
              _buildGridItem(context, Icons.local_police_outlined, 'Security'),
              _buildGridItem(context, Icons.quiz_outlined, 'Ask Society'),
              _buildGridItem(context, Icons.dynamic_feed_rounded, 'Posts', notificationCount: 9),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItem(context, Icons.credit_card_rounded, 'Pay Bills'),
              _buildGridItem(context, Icons.face_retouching_natural_rounded, 'Find Daily Help'),
              _buildGridItem(context, Icons.gpp_bad_outlined, 'Raise Alert', iconColor: AsmitaPalette.actionRed),
              _buildGridItem(context, Icons.add_rounded, 'View More', isUtilityButton: true),
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