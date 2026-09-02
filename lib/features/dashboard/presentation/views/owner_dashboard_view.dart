import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import 'package:asmita_society/core/utils/dashboard_scroll_physics.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_pre_approve_wizard.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_security_wizard.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_raise_alert_wizard.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/services/bloc/amenities_bloc.dart';
import 'package:asmita_society/features/services/bloc/amenities_state.dart';
import 'package:asmita_society/features/services/presentation/widgets/asmita_facility_booking_wizard.dart';
import 'package:asmita_society/features/community/presentation/widgets/community_post_item.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_bloc.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_state.dart';
import 'package:asmita_society/features/dashboard/data/models/quick_action_registry.dart';
import 'package:asmita_society/features/dashboard/presentation/screens/customise_quick_actions_sheet.dart';
import 'package:asmita_society/features/community/presentation/attachments/create_poll_dialog.dart';
import 'package:asmita_society/features/menu/presentation/screens/vehicles_screen.dart';

class OwnerDashboardView extends StatefulWidget {
  final VoidCallback? onNavigateToCommunity; 
  final VoidCallback? onNavigateToHistory; 
  final VoidCallback? onNavigateToViewMore; 
  final VoidCallback? onNavigateToServices;
  final VoidCallback? onNavigateToDailyHelp;
  final VoidCallback? onNavigateToAllNotices;
  final VoidCallback? onNavigateToSearch;

  const OwnerDashboardView({
    super.key, 
    this.onNavigateToCommunity, 
    this.onNavigateToHistory,
    this.onNavigateToViewMore, 
    this.onNavigateToServices,
    this.onNavigateToDailyHelp,
    this.onNavigateToAllNotices,
    this.onNavigateToSearch,
  });

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  final ScrollController _scrollController = ScrollController();
  int _currentPostSliderIndex = 0;

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
        title: 'Pre-Approve Entry',
        content: AsmitaPreApproveWizard(),
      ),
    );
  }

  void _showSecurityModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Security Alert',
        content: AsmitaSecurityWizard(),
      ),
    );
  }

  void _showRaiseAlertModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Raise an Alert',
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
          // FIXED: Removed 'const' so widget callback layers can bind dynamically
          AsmitaPrimaryHeader(
            userInitials: 'RM',
            onSearchPressed: widget.onNavigateToSearch,
            onChatPressed: widget.onNavigateToCommunity,
          ),
          Expanded(
            child: Container(
              color: AsmitaPalette.systemBG,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const DashboardScrollPhysics(
                  junctionOffset: 440.0,
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
                          _buildGateSyncModule(context),
                          const SizedBox(height: 24),
                          _buildAdPlaceholder(context, typeLabel: 'Card Ad', height: 80, margin: const EdgeInsets.symmetric(horizontal: 16)),
                          const SizedBox(height: 24),
                          _buildCommunityPostsHeader(context),
                          const SizedBox(height: 12),
                          _buildCommunityPostsModule(context),
                          const SizedBox(height: 24),
                          _buildServicesFooter(context),
                          const SizedBox(height: 12),
                          _buildFrequentServices(context),
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

  Widget _buildCommunityPostsHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Community Posts", style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: widget.onNavigateToAllNotices,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  children: [
                    Text('View All', style: textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600, size: 16),
                  ],
                ),
              ),
            ],
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
              InkWell(
                onTap: () {
                  showAsmitaBottomSheet(
                    context: context,
                    title: 'Customise Quick Actions',
                    subtitle: 'Select and hold to reorder up to 7 actions for your dashboard.',
                    isScrollControlled: true,
                    child: const CustomiseQuickActionsSheet(),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 14, color: AsmitaPalette.textLight),
                    const SizedBox(width: 4),
                    Text('Customise', style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<QuickActionsBloc, QuickActionsState>(
            builder: (context, state) {
              final selectedActions = state is QuickActionsLoaded 
                  ? state.selectedActions 
                  : QuickActionRegistry.defaultActions;
                  
              return GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: selectedActions.length + 1, // +1 for View More
                itemBuilder: (context, index) {
                  if (index == selectedActions.length) {
                    return _buildGridItem(
                      context, 
                      Icons.add_rounded, 
                      'View More', 
                      iconColor: Colors.white,
                      containerColor: AsmitaPalette.deepNavy,
                      hasBorder: true,
                      onTap: widget.onNavigateToViewMore,
                    );
                  }
                  
                  final type = selectedActions[index];
                  final meta = QuickActionRegistry.allActions[type]!;
                  
                  if (type == QuickActionType.posts) {
                    return BlocBuilder<CommunityPostBloc, CommunityPostState>(
                      builder: (context, postState) {
                        return _buildGridItem(
                          context, 
                          meta.icon, 
                          meta.label, 
                          iconColor: meta.iconColor,
                          containerColor: meta.containerColor,
                          isUtilityButton: meta.isUtilityButton,
                          notificationCount: postState.activePosts.isNotEmpty ? postState.activePosts.length : null,
                          onTap: widget.onNavigateToAllNotices,
                        );
                      },
                    );
                  }
                  
                  String? badgeLabel;
                  if (type == QuickActionType.preApprove) badgeLabel = 'Safe mode';
                  
                  return _buildGridItem(
                    context, 
                    meta.icon, 
                    meta.label,
                    iconColor: meta.iconColor,
                    containerColor: meta.containerColor,
                    isUtilityButton: meta.isUtilityButton,
                    badgeLabel: badgeLabel,
                    onTap: _getOnTapForAction(type, context),
                  );
                },
              );
            },
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Entry Updates", style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                InkWell(
                  onTap: () {
                    if (widget.onNavigateToHistory != null) {
                      widget.onNavigateToHistory!();
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
    return BlocBuilder<CommunityPostBloc, CommunityPostState>(
      builder: (context, state) {
        if (state.status == CommunityPostStatus.loading && state.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final activePosts = state.posts.where((p) {
          if (p.status != 'approved') return false;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          if (p.startDate != null) {
            final start = DateTime(p.startDate!.year, p.startDate!.month, p.startDate!.day);
            if (start.isAfter(today)) return false;
          }
          if (p.endDate != null) {
            final end = DateTime(p.endDate!.year, p.endDate!.month, p.endDate!.day);
            if (end.isBefore(today)) return false;
          }
          return true;
        }).toList();

        activePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final top3 = activePosts.take(3).toList();

        if (top3.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
              ),
              child: const Center(child: Text("No community posts yet.")),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 190,
              child: PageView.builder(
                itemCount: top3.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPostSliderIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CommunityPostItem(post: top3[index]),
                  );
                },
              ),
            ),
            if (top3.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  top3.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPostSliderIndex == index ? AsmitaPalette.deepNavy : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ]
          ],
        );
      },
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

  VoidCallback? _getOnTapForAction(QuickActionType type, BuildContext context) {
    switch (type) {
      case QuickActionType.preApprove: return () => _showPreApproveModal(context);
      case QuickActionType.security: return () => _showSecurityModal(context);
      case QuickActionType.askSociety: return widget.onNavigateToCommunity;
      case QuickActionType.posts: return widget.onNavigateToAllNotices;
      case QuickActionType.maintenance: return widget.onNavigateToServices;
      case QuickActionType.dailyHelp: return widget.onNavigateToDailyHelp;
      case QuickActionType.raiseAlert: return () => _showRaiseAlertModal(context);
      case QuickActionType.myVehicles: 
        return () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const VehiclesScreen()));
        };
      case QuickActionType.opinionPoll:
        return () {
           showAsmitaBottomSheet(
             context: context, 
             title: 'Create Opinion Poll',
             isScrollControlled: true,
             child: const CreatePollDialog()
           );
        };
      case QuickActionType.deliveries:
      case QuickActionType.complaints:
      case QuickActionType.management:
      case QuickActionType.utilityPay:
      case QuickActionType.amenities:
      case QuickActionType.emergency:
        return widget.onNavigateToViewMore;
    }
  }

  Widget _buildFrequentServices(BuildContext context) {
    return BlocBuilder<AmenitiesBloc, AmenitiesState>(
      builder: (context, state) {
        if (state.status == AmenitiesStatus.loading && state.amenities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count booking frequency by amenity ID
        final bookingCounts = <int, int>{};
        for (final booking in state.myBookings) {
          if (booking.amenity != null) {
            bookingCounts[booking.amenity!.amenityId] = (bookingCounts[booking.amenity!.amenityId] ?? 0) + 1;
          }
        }

        // Sort amenities by booking count (descending)
        final sortedAmenities = List.of(state.amenities)..sort((a, b) {
          final countA = bookingCounts[a.amenityId] ?? 0;
          final countB = bookingCounts[b.amenityId] ?? 0;
          return countB.compareTo(countA);
        });

        final topFacilities = sortedAmenities.take(4).toList();

        if (topFacilities.isEmpty) {
          return const SizedBox.shrink();
        }

        IconData getIconForFacility(String name) {
          final lower = name.toLowerCase();
          if (lower.contains('pool')) return Icons.pool_rounded;
          if (lower.contains('gym')) return Icons.fitness_center_rounded;
          if (lower.contains('yoga')) return Icons.self_improvement_rounded;
          if (lower.contains('banquet') || lower.contains('hall')) return Icons.celebration_rounded;
          return Icons.business_center_rounded;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topFacilities.map((fac) {
              return _buildGridItem(
                context, 
                getIconForFacility(fac.name), 
                fac.name,
                containerColor: AsmitaPalette.deepNavy,
                iconColor: Colors.white,
                onTap: () {
                  AsmitaDialog.show(
                    context: context,
                    title: '${fac.name} Booking',
                    content: AsmitaFacilityBookingWizard(initialAmenity: fac),
                  );
                }
              );
            }).toList(),
          ),
        );
      },
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

  Widget _buildGridItem(BuildContext context, IconData icon, String label, {String? badgeLabel, int? notificationCount, Color containerColor = AsmitaPalette.deepNavy, Color iconColor = Colors.white, bool isUtilityButton = false, bool hasBorder = false, VoidCallback? onTap}) {
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
                    color: isUtilityButton ? AsmitaPalette.actionRed : containerColor,
                    borderRadius: BorderRadius.circular(16),
                    border: hasBorder ? Border.all(color: AsmitaPalette.borderGrey, width: 1.5) : null,
                    boxShadow: hasBorder ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Icon(icon, color: isUtilityButton ? Colors.white : iconColor, size: 24),
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