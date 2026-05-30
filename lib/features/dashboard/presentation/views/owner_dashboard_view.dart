import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/utils/clamp_bottom_scroll_physics.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';

class OwnerDashboardView extends StatelessWidget {
  const OwnerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: Column(
        children: [
          _buildFixedHeader(context),
          Expanded(
            child: CustomScrollView(
              physics: const ClampBottomScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                AsmitaAnimatedRefresh(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 1500));
                  },
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: AsmitaPalette.systemBG,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildAdPlaceholder(
                          typeLabel: 'Slider Image Ad',
                          height: 150,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActionsMatrix(),
                        const SizedBox(height: 20),
                        _buildAdPlaceholder(
                          typeLabel: 'Slim Bar Ad',
                          height: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  fillOverscroll: true,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 16),
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AsmitaPalette.borderGrey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'You have no new updates',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AsmitaPalette.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGateSyncModule(),
                        const SizedBox(height: 16),
                        _buildAdPlaceholder(
                          typeLabel: 'Card Ad',
                          height: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        const SizedBox(height: 24),
                        _buildCommunityPostsModule(),
                        const SizedBox(height: 24),
                        _buildServicesFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    return Container(
      color: AsmitaPalette.systemBG,
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 8 : 24,
        bottom: 12,
        left: 16,
        right: 16,
      ),
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
                    const Text(
                      'Siddhi CHS 34',
                      style: TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.deepNavy, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy.withValues(alpha: 0.8), size: 18),
                  ],
                ),
                const Text(
                  'Premium Mode',
                  style: TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy, size: 24), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: AsmitaPalette.deepNavy, size: 22), onPressed: () {}),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AsmitaPalette.deepNavy,
            child: Text('RM', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsMatrix() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.deepNavy, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: AsmitaPalette.textLight),
                  const SizedBox(width: 4),
                  const Text('Customise', style: TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItem(Icons.person_add_alt_1_rounded, 'Pre-Approve', badgeLabel: 'Safe mode'),
              _buildGridItem(Icons.local_police_outlined, 'Security'),
              _buildGridItem(Icons.quiz_outlined, 'Ask Society'),
              _buildGridItem(Icons.dynamic_feed_rounded, 'Posts', notificationCount: 9),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItem(Icons.credit_card_rounded, 'Pay Bills'),
              _buildGridItem(Icons.face_retouching_natural_rounded, 'Find Daily Help'),
              _buildGridItem(Icons.gpp_bad_outlined, 'Raise Alert', iconColor: AsmitaPalette.actionRed),
              _buildGridItem(Icons.add_rounded, 'View More', isUtilityButton: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGateSyncModule() {
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
                const Text(
                  "Today's Entry Updates",
                  style: TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.deepNavy, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    const Text('View All', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF2196F3), fontSize: 13, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right_rounded, color: Colors.blue.shade600, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCircularActionHook(Icons.person_outline_rounded, 'Pre-approve'),
                const SizedBox(width: 16),
                _buildCircularActionHook(Icons.engineering_outlined, 'Daily Help'),
                const SizedBox(width: 16),
                Container(width: 1.5, height: 40, color: AsmitaPalette.borderGrey),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "You don't have any upcoming visitors.",
                    style: TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityPostsModule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Community Posts", style: TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.deepNavy, fontSize: 15, fontWeight: FontWeight.w700)),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF2196F3)),
                label: const Text("New Post", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2196F3),
                  side: BorderSide(color: Colors.blue.shade200, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AsmitaPalette.systemBG,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AsmitaPalette.borderGrey),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.assignment_outlined, color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Notice • Society Management", style: TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.deepNavy, fontSize: 13, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text("Water supply shutdown scheduled for maintenance this Thursday from 10:00 AM to 2:00 PM.", style: TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
                Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesFooter() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Services", style: TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.deepNavy, fontSize: 15, fontWeight: FontWeight.w700)),
          Row(
            children: [
              const Text('See All', style: TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight, fontSize: 13, fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdPlaceholder({required String typeLabel, required double height, required EdgeInsetsGeometry margin}) {
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
        child: Text(
          'Ad {$typeLabel}',
          style: const TextStyle(fontFamily: 'Montserrat', color: AsmitaPalette.textLight, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, {String? badgeLabel, int? notificationCount, Color iconColor = AsmitaPalette.deepNavy, bool isUtilityButton = false}) {
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
                  color: isUtilityButton ? const Color(0xFFFFEB3B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (badgeLabel != null)
                Positioned(
                  top: -6,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF5E35B1), borderRadius: BorderRadius.circular(6)),
                    child: Text(badgeLabel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800, fontFamily: 'Poppins', letterSpacing: 0.3)),
                  ),
                ),
              if (notificationCount != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AsmitaPalette.actionRed, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text('$notificationCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textDark, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildCircularActionHook(IconData icon, String label) {
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
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFF2196F3), shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white, size: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AsmitaPalette.textLight, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}