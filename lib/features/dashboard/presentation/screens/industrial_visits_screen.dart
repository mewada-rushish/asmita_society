import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../visitor_management/bloc/visitor_bloc.dart';
import '../../../visitor_management/bloc/visitor_event.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/presentation/widgets/acknowledge_action_button.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IndustrialVisitsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const IndustrialVisitsScreen({super.key, this.onBack});

  @override
  State<IndustrialVisitsScreen> createState() => _IndustrialVisitsScreenState();
}

class _IndustrialVisitsScreenState extends State<IndustrialVisitsScreen> {
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _acknowledgedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showPreApproveModal(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Schedule Visitor',
        content: AsmitaPreApproveWizard(),
      ),
    );

    if (!context.mounted) return;
    context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<VisitorBloc>().add(
        LoadMyHistory(residentId: authState.user.userId, isRefresh: true),
      );
    }
  }

  void _showVisitDetailsModal(BuildContext context, IndustrialVisitModel visit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = visit.isPending;
    final isAck = _acknowledgedIds.contains(visit.id);

    showAsmitaBottomSheet(
      context: context,
      title: 'Visitor Pass Details',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card with Pass Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AsmitaPalette.deepNavy, Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: Text(
                    visit.visitorName.isNotEmpty ? visit.visitorName[0].toUpperCase() : 'V',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.visitorName,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        visit.deliveryCompany ?? visit.purpose ?? 'Guest Visitor',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (visit.passCode != null)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: visit.passCode!));
                      HapticFeedback.lightImpact();
                      AsmitaToast.show(
                        context,
                        message: 'Pass code ${visit.passCode} copied!',
                        type: AsmitaToastType.success,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'PASS CODE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                visit.passCode!,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy, size: 12, color: Colors.white70),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail Grid
          _buildDetailRow(
            context,
            icon: Icons.flag_outlined,
            label: 'Current Status',
            value: visit.status.label,
            badgeColor: visit.status.textColor(isDark),
            badgeBg: visit.status.fillColor(isDark),
          ),
          _buildDetailRow(
            context,
            icon: Icons.business_rounded,
            label: 'Department',
            value: visit.departmentName ?? 'General Campus',
          ),
          if (visit.hostName != null && visit.hostName!.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.person_outline_rounded,
              label: 'Host Person',
              value: visit.hostName!,
            ),
          if (visit.visitorMobile != null && visit.visitorMobile!.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Visitor Contact',
              value: visit.visitorMobile!,
              trailing: IconButton(
                icon: const Icon(Icons.phone, size: 18, color: AsmitaPalette.successGreen),
                onPressed: () {
                  AsmitaToast.show(
                    context,
                    message: 'Connecting to ${visit.visitorMobile}...',
                    type: AsmitaToastType.info,
                  );
                },
              ),
            ),
          if (visit.vehicleNumber != null && visit.vehicleNumber!.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.directions_car_outlined,
              label: 'Vehicle Plate',
              value: visit.vehicleNumber!,
            ),
          _buildDetailRow(
            context,
            icon: Icons.access_time_rounded,
            label: 'Scheduled Time',
            value: visit.checkInAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(visit.checkInAt!)
                : (visit.createdAt != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(visit.createdAt!)
                    : 'Scheduled Visit'),
          ),

          if (visit.statusToken != null && visit.statusToken!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 170,
                height: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: visit.statusToken!,
                  version: QrVersions.auto,
                  size: 146.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AsmitaPalette.deepNavy),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AsmitaPalette.deepNavy),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<IndustrialVisitBloc>().add(
                            DecideVisitEvent(visitId: visit.id, action: 'DENY'),
                          );
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Deny Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AsmitaPalette.actionRed,
                      side: const BorderSide(color: AsmitaPalette.actionRed, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<IndustrialVisitBloc>().add(
                            DecideVisitEvent(visitId: visit.id, action: 'APPROVE'),
                          );
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (visit.status == IndustrialVisitStatus.approved && !isAck) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _acknowledgedIds.add(visit.id));
                context.read<IndustrialVisitBloc>().add(AcknowledgeVisitEvent(visit.id));
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Acknowledge Visitor Arrival', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
    Color? badgeBg,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AsmitaPalette.textLight),
          ),
          const Spacer(),
          if (badgeColor != null && badgeBg != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showPreApproveModal(context),
        backgroundColor: AsmitaPalette.deepNavy,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Schedule',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Unified Primary Asmita Header (Property Consistent)
          AsmitaPrimaryHeader(
            subtitleOverride: 'Visits & Passes',
            allowPropertySwitching: false,
            showBackButton: widget.onBack != null || Navigator.canPop(context),
            onBackPressed: widget.onBack,
          ),

          // 2. Scrollable Content Body with Bloc Consumer
          Expanded(
            child: BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
              listener: (context, state) {
                if (state.status == IndustrialVisitBlocStatus.actionSuccess &&
                    state.successMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.successMessage!,
                    type: AsmitaToastType.success,
                  );
                } else if (state.status == IndustrialVisitBlocStatus.error &&
                    state.errorMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.errorMessage!,
                    type: AsmitaToastType.error,
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state.status == IndustrialVisitBlocStatus.loading &&
                    state.visits.isEmpty;

                if (isLoading) {
                  return const Center(
                    child: AsmitaLoadingIndicator(
                      color: AsmitaPalette.deepNavy,
                      size: 32,
                    ),
                  );
                }

                final filteredVisits = state.visits.where((v) {
                  if (_selectedFilter == 'PENDING' && !v.isPending) {
                    return false;
                  }
                  if (_selectedFilter == 'APPROVED' &&
                      v.status != IndustrialVisitStatus.approved) {
                    return false;
                  }
                  if (_selectedFilter == 'INSIDE' &&
                      v.status != IndustrialVisitStatus.checkedIn) {
                    return false;
                  }
                  if (_selectedFilter == 'COMPLETED' &&
                      v.status != IndustrialVisitStatus.checkedOut) {
                    return false;
                  }

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final matchName = v.visitorName.toLowerCase().contains(q);
                    final org = v.deliveryCompany ?? v.purpose ?? '';
                    final matchOrg = org.toLowerCase().contains(q);
                    final matchDept = (v.departmentName ?? '').toLowerCase().contains(q);
                    final matchPass = (v.passCode ?? '').toLowerCase().contains(q);
                    final matchVehicle = (v.vehicleNumber ?? '').toLowerCase().contains(q);
                    return matchName || matchOrg || matchDept || matchPass || matchVehicle;
                  }
                  return true;
                }).toList();

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    AsmitaAnimatedRefresh(
                      onRefresh: () async {
                        context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
                      },
                    ),

                    // Search Box
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).dividerColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search visitor, company, pass code, vehicle...',
                              hintStyle: const TextStyle(fontSize: 13, color: AsmitaPalette.textLight),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AsmitaPalette.textLight),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18, color: AsmitaPalette.textLight),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top KPI Stat Metrics Cards (Interactive Filter Cards)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                        child: _buildKpiMetrics(context, state.visits),
                      ),
                    ),

                    // Visitor Items or Empty State
                    if (filteredVisits.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                          child: _buildEmptyState(context),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final visit = filteredVisits[index];
                              return _buildVisitItem(context, visit);
                            },
                            childCount: filteredVisits.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, List<IndustrialVisitModel> visits) {
    final pendingCount = visits.where((v) => v.isPending).length;
    final approvedCount = visits.where((v) => v.status == IndustrialVisitStatus.approved).length;
    final insideCount = visits.where((v) => v.status == IndustrialVisitStatus.checkedIn).length;
    final totalCount = visits.length;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Total',
            count: totalCount,
            icon: Icons.groups_rounded,
            accentColor: AsmitaPalette.deepNavy,
            filterKey: 'ALL',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Pending',
            count: pendingCount,
            icon: Icons.pending_actions_rounded,
            accentColor: AsmitaPalette.actionRed,
            filterKey: 'PENDING',
            showPulse: pendingCount > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Approved',
            count: approvedCount,
            icon: Icons.verified_rounded,
            accentColor: const Color(0xFF1E88E5),
            filterKey: 'APPROVED',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Inside',
            count: insideCount,
            icon: Icons.meeting_room_rounded,
            accentColor: AsmitaPalette.successGreen,
            filterKey: 'INSIDE',
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color accentColor,
    required String filterKey,
    bool showPulse = false,
  }) {
    final isSelected = _selectedFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = filterKey);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Squircle Icon Container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(alpha: isSelected ? 0.45 : 0.18),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: accentColor, size: 18),
                    if (showPulse)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? accentColor : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : AsmitaPalette.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    String emptyTitle = 'No Visitors Found';
    String emptySubtitle = 'There are no visitor records matching your filter criteria.';
    IconData emptyIcon = Icons.badge_outlined;

    if (_selectedFilter == 'PENDING') {
      emptyTitle = 'All Caught Up!';
      emptySubtitle = 'There are currently no visitors awaiting entry approval.';
      emptyIcon = Icons.done_all_rounded;
    } else if (_selectedFilter == 'INSIDE') {
      emptyTitle = 'Campus Clear';
      emptySubtitle = 'No active visitors are currently checked inside the premises.';
      emptyIcon = Icons.domain_verification_rounded;
    } else if (_selectedFilter == 'APPROVED') {
      emptyTitle = 'No Approved Passes';
      emptySubtitle = 'No upcoming approved passes found. Schedule a pass in seconds.';
      emptyIcon = Icons.event_available_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon,
                size: 42,
                color: AsmitaPalette.deepNavy,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              emptyTitle,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _showPreApproveModal(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Schedule Visitor',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitItem(BuildContext context, IndustrialVisitModel visit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = visit.isPending;
    final isAck = _acknowledgedIds.contains(visit.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? AsmitaPalette.actionRed.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isPending ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? AsmitaPalette.actionRed.withValues(alpha: isDark ? 0.15 : 0.08)
                : (isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0x0A0F172A)),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0x050F172A),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVisitDetailsModal(context, visit),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Identity/Type
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildVisitorAvatar(context, visit, isDark, isPending),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.visitorName.isNotEmpty ? visit.visitorName : 'Guest Visitor',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _buildVisitorCategoryBadge(context, visit, isDark),
                        ],
                      ),
                    ),
                  ],
                ),

                // Inset Executive Meta Data Table (Time, Location, Key, Status)
                _buildExecutiveFooter(context, visit, isDark, isPending),

                // Decision Actions for Pending Visits
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<IndustrialVisitBloc>().add(
                                  DecideVisitEvent(visitId: visit.id, action: 'DENY'),
                                );
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text(
                            'Deny Entry',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AsmitaPalette.actionRed,
                            side: BorderSide(
                              color: AsmitaPalette.actionRed.withValues(alpha: 0.8),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<IndustrialVisitBloc>().add(
                                  DecideVisitEvent(visitId: visit.id, action: 'APPROVE'),
                                );
                          },
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text(
                            'Approve Entry',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.deepNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Acknowledge Action Button
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AcknowledgeActionButton(
                    isAcknowledged: isAck,
                    onAcknowledge: () {
                      setState(() => _acknowledgedIds.add(visit.id));
                      context.read<IndustrialVisitBloc>().add(AcknowledgeVisitEvent(visit.id));
                      AsmitaToast.show(
                        context,
                        message: 'Visitor pass #${visit.passCode ?? visit.id} acknowledged',
                        type: AsmitaToastType.success,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorAvatar(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
    bool isPending,
  ) {
    if (visit.visitorPhotoUrl != null && visit.visitorPhotoUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.network(
            visit.visitorPhotoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildAvatarFallback(context, visit, isDark, isPending),
          ),
        ),
      );
    }
    return _buildAvatarFallback(context, visit, isDark, isPending);
  }

  Widget _buildAvatarFallback(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
    bool isPending,
  ) {
    List<Color> gradientColors;
    IconData? overlayIcon;
    bool showStarBadge = false;

    if (isPending) {
      gradientColors = const [Color(0xFF991B1B), Color(0xFFDC2626)];
    } else if (visit.isDelivery) {
      gradientColors = const [Color(0xFFD97706), Color(0xFFF59E0B)];
      overlayIcon = Icons.local_shipping_rounded;
    } else if (visit.isPreApproved) {
      gradientColors = const [Color(0xFF1E293B), Color(0xFF27347B)];
      showStarBadge = true;
    } else {
      gradientColors = const [Color(0xFF1E3A8A), Color(0xFF2563EB)];
    }

    final letter = visit.visitorName.isNotEmpty ? visit.visitorName[0].toUpperCase() : 'V';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: isDark ? 0.35 : 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: Center(
            child: overlayIcon != null
                ? Icon(overlayIcon, size: 22, color: Colors.white)
                : Text(
                    letter,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
          ),
        ),
        if (showStarBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVisitorCategoryBadge(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
  ) {
    if (visit.isPreApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.6) : const Color(0xFFFDE68A),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 11, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text(
              'VIP GUEST',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else if (visit.isDelivery) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 13,
            color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 4),
          Text(
            visit.deliveryCompany != null ? '${visit.deliveryCompany} Delivery' : 'Courier Dropoff',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
            ),
          ),
        ],
      );
    }

    final categoryText = visit.purpose ?? 'Campus Guest';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.badge_outlined,
          size: 13,
          color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Text(
          categoryText,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
    bool isPending,
  ) {
    Color bg;
    Color border;
    Color textColor;
    Color dotColor;
    String label;
    bool pulse = false;

    if (isPending) {
      bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
      border = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
      textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
      dotColor = const Color(0xFFEF4444);
      label = 'PENDING';
      pulse = true;
    } else if (visit.status == IndustrialVisitStatus.checkedIn) {
      bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
      border = isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0);
      textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
      dotColor = const Color(0xFF10B981);
      label = 'INSIDE HQ';
      pulse = true;
    } else if (visit.status == IndustrialVisitStatus.approved) {
      bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
      border = isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE);
      textColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
      dotColor = const Color(0xFF3B82F6);
      label = 'APPROVED';
    } else if (visit.status == IndustrialVisitStatus.checkedOut) {
      bg = isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5);
      border = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
      textColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
      dotColor = const Color(0xFF71717A);
      label = 'CHECKED OUT';
    } else {
      bg = visit.status.fillColor(isDark);
      border = visit.status.textColor(isDark).withValues(alpha: 0.3);
      textColor = visit.status.textColor(isDark);
      dotColor = textColor;
      label = visit.status.label.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: pulse
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5.5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveFooter(
    BuildContext context,
    IndustrialVisitModel visit,
    bool isDark,
    bool isPending,
  ) {
    final arrivalTime = visit.checkInAt != null
        ? DateFormat('hh:mm a').format(visit.checkInAt!)
        : (visit.createdAt != null
            ? DateFormat('hh:mm a').format(visit.createdAt!)
            : 'Scheduled');

    final destinationName = visit.departmentName ?? 'General Campus';
    final hasPassCode = visit.passCode != null && visit.passCode!.isNotEmpty;
    final hasVehicle = visit.vehicleNumber != null && visit.vehicleNumber!.isNotEmpty;

    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(top: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Row 1: Entered/Scheduled Time & Location/Vehicle
          Row(
            children: [
              // Time
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            visit.checkInAt != null ? 'ENTERED' : 'SCHEDULED',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: mutedColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            arrivalTime,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical Divider
              Container(
                width: 1,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: dividerColor,
              ),

              // Destination or Vehicle
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      hasVehicle ? Icons.directions_car_filled_rounded : Icons.apartment_rounded,
                      size: 14,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasVehicle ? 'VEHICLE' : 'LOCATION',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: mutedColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            hasVehicle ? visit.vehicleNumber! : destinationName,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Horizontal Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
            ),
          ),

          // Row 2: Access Key (Left) & Status (Right) in matching format
          Row(
            children: [
              // Access Key
              Expanded(
                child: InkWell(
                  onTap: hasPassCode
                      ? () {
                          Clipboard.setData(ClipboardData(text: visit.passCode!));
                          HapticFeedback.selectionClick();
                          AsmitaToast.show(
                            context,
                            message: 'Pass code #${visit.passCode} copied to clipboard',
                            type: AsmitaToastType.success,
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.vpn_key_rounded,
                        size: 14,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ACCESS KEY',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: mutedColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    hasPassCode ? '#${visit.passCode}' : 'N/A',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasPassCode) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 10,
                                    color: mutedColor,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Vertical Divider
              Container(
                width: 1,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: dividerColor,
              ),

              // Status
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isPending
                          ? Icons.pending_rounded
                          : (visit.status == IndustrialVisitStatus.checkedIn
                              ? Icons.meeting_room_rounded
                              : (visit.status == IndustrialVisitStatus.approved
                                  ? Icons.verified_rounded
                                  : Icons.info_outline_rounded)),
                      size: 14,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'STATUS',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: mutedColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _buildStatusBadge(context, visit, isDark, isPending),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
