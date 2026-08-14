import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import 'package:asmita_society/core/utils/dashboard_scroll_physics.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_pre_approve_wizard.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_raise_alert_wizard.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';

class TenantDashboardView extends StatefulWidget {
  final VoidCallback? onNavigateToCommunity; 
  final VoidCallback? onNavigateToHistory; 
  final VoidCallback? onNavigateToViewMore; 
  final VoidCallback? onNavigateToServices;
  final VoidCallback? onNavigateToDailyHelp;
  final VoidCallback? onNavigateToSearch;

  const TenantDashboardView({
    super.key, 
    this.onNavigateToCommunity, 
    this.onNavigateToHistory,
    this.onNavigateToViewMore, 
    this.onNavigateToServices,
    this.onNavigateToDailyHelp,
    this.onNavigateToSearch,
  });

  @override
  State<TenantDashboardView> createState() => _TenantDashboardViewState();
}

class _TenantDashboardViewState extends State<TenantDashboardView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      int residentId = 1;
      if (authState is AuthAuthenticated) {
        residentId = authState.user.userId;
      }
      context.read<VisitorBloc>().add(LoadMyHistory(residentId: residentId, isRefresh: true));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showPreApproveModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        content: AsmitaPreApproveWizard(), // Plugs in our dynamic wizard safely
      ),
    );
  }

  void _showRaiseAlertModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        content: AsmitaRaiseAlertWizard(),
      ),
    );
  } 

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            userInitials: 'KM',
            onSearchPressed: widget.onNavigateToSearch,
            onChatPressed: widget.onNavigateToCommunity,
          ),
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
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildRentSummaryCard(context),
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
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: AsmitaPalette.textLight),
                  const SizedBox(width: 4),
                  Text('Customise', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: () {
                  if (widget.onNavigateToViewMore != null) {
                    widget.onNavigateToViewMore!();
                  }
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  children: [
                    Text('View All', style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.actionRed, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Icon(Icons.chevron_right_rounded, color: AsmitaPalette.actionRed, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItem(context, Icons.support_agent_rounded, 'Raise Ticket', onTap: () => _showRaiseAlertModal(context)),
              _buildGridItem(context, Icons.handshake_rounded, 'Leases', onTap: () {
                AsmitaToast.show(context, message: 'Leases feature coming soon.', type: AsmitaToastType.info);
              }),
              _buildGridItem(context, Icons.phone_in_talk_rounded, 'Contact Owner', onTap: () {
                AsmitaToast.show(context, message: 'Contact Owner feature coming soon.', type: AsmitaToastType.info);
              }),
              _buildGridItem(context, Icons.person_add_alt_1_rounded, 'Pre-Approve', badgeLabel: 'Safe mode', onTap: () => _showPreApproveModal(context)),
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
            BlocBuilder<VisitorBloc, VisitorState>(
              builder: (context, state) {
                if (state is VisitorHistoryLoaded) {
                  final today = DateTime.now();
                  final todayEntries = state.history.where((rawItem) {
                    final item = rawItem is Map ? Map<String, dynamic>.from(rawItem) : <String, dynamic>{};
                    final dateStr = item['created_at'] ?? item['valid_from'];
                    if (dateStr == null) return false;
                    try {
                      final dt = DateTime.parse(dateStr).toLocal();
                      return dt.year == today.year && dt.month == today.month && dt.day == today.day;
                    } catch (_) {
                      return false;
                    }
                  }).take(10).toList();

                  if (todayEntries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text('You have no new updates', style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight)),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                      children: todayEntries.map((rawItem) {
                        final item = rawItem is Map ? Map<String, dynamic>.from(rawItem) : <String, dynamic>{};
                        final name = item['visitor_name'] ?? item['title'] ?? 'Unknown';
                        final company = item['company_name'] ?? item['purpose'] ?? 'Visitor';
                        final isPreApproved = item['record_type'] == 'PRE_APPROVED';
                        final category = (isPreApproved ? (item['invite_type'] ?? 'Invite') : 'Walk-in').toString().toLowerCase();
                        
                        final authState = context.read<AuthBloc>().state;
                        final currentUserId = authState is AuthAuthenticated ? authState.user.userId : null;
                        final isUnviewed = item['is_viewed'] == false;
                        final isForCurrentUser = item['resident_id'] == currentUserId;
                        final showBadge = isUnviewed && isForCurrentUser;
                        
                        String titleText = name;
                        if (category == 'delivery' || category == 'cab' || name.toLowerCase().contains('invite')) {
                          titleText = company;
                          if (titleText.toLowerCase().contains('invite')) {
                            titleText = titleText.replaceAll(RegExp(r' invite', caseSensitive: false), '').trim();
                          }
                        }
                        // fallback length
                        if (titleText.length > 15) {
                          titleText = '${titleText.substring(0, 12)}...';
                        }

                        IconData icon = Icons.person_rounded;
                        Color brandColor = AsmitaPalette.deepNavy;

                        if (category == 'delivery') {
                          icon = Icons.local_shipping_rounded;
                          if (company.toString().toLowerCase().contains('amazon')) {
                            brandColor = const Color(0xFFFF9900);
                          } else if (company.toString().toLowerCase().contains('zomato')) {
                            icon = Icons.fastfood_rounded;
                            brandColor = const Color(0xFFCB202D);
                          } else if (company.toString().toLowerCase().contains('swiggy')) {
                            icon = Icons.fastfood_rounded;
                            brandColor = const Color(0xFFFC8019);
                          }
                        } else if (company.toString().toLowerCase().contains('uber') || category.contains('cab')) {
                          icon = Icons.directions_car_rounded;
                          brandColor = Colors.black;
                        } else if (category == 'guest') {
                          icon = Icons.group_rounded;
                        } else if (category == 'daily help') {
                          icon = Icons.engineering_outlined;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 14, top: 2, bottom: 2),
                          child: _buildCircularActionHook(context, icon, titleText, hasBadge: showBadge, iconColor: brandColor),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              },
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
          InkWell(
            onTap: () {
              if (widget.onNavigateToServices != null) {
                widget.onNavigateToServices!();
              }
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Row(
              children: [
                Text('See All', style: textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600, size: 16),
              ],
            ),
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

  Widget _buildGridItem(BuildContext context, IconData icon, String label, {String? badgeLabel, int? notificationCount, Color iconColor = AsmitaPalette.deepNavy, bool isUtilityButton = false, VoidCallback? onTap}) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
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
      ),
    );
  }



  Widget _buildCircularActionHook(BuildContext context, IconData icon, String label, {bool hasBadge = false, Color iconColor = AsmitaPalette.deepNavy}) {
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
              child: Center(child: Icon(icon, color: iconColor, size: 22)),
            ),
            if (hasBadge)
              Positioned(top: -2, right: -2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: AsmitaPalette.actionRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}