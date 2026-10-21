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

                final visits = state.visits;
                final pendingCount = visits.where((v) => v.isPending).length;
                final approvedCount = visits.where((v) => v.status == IndustrialVisitStatus.approved).length;
                final insideCount = visits.where((v) => v.status == IndustrialVisitStatus.checkedIn).length;

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

                    // Top KPI Stat Metrics Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: _buildKpiMetrics(context, state.visits),
                      ),
                    ),

                    // Search and Filter Row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Search Box
                            Container(
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
                            const SizedBox(height: 12),

                            // Fitted Segmented Filter Bar (Zero cropping, 100% responsive width)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Theme.of(context).dividerColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  _segmentedTab(
                                    'ALL',
                                    'All',
                                    count: visits.length,
                                  ),
                                  _segmentedTab(
                                    'PENDING',
                                    'Pending',
                                    count: pendingCount,
                                    alertColor: AsmitaPalette.actionRed,
                                  ),
                                  _segmentedTab(
                                    'APPROVED',
                                    'Approved',
                                    count: approvedCount,
                                    alertColor: const Color(0xFF1E88E5),
                                  ),
                                  _segmentedTab(
                                    'INSIDE',
                                    'Inside',
                                    count: insideCount,
                                    alertColor: AsmitaPalette.successGreen,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
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

  Widget _segmentedTab(
    String code,
    String label, {
    int? count,
    Color? alertColor,
  }) {
    final isSelected = _selectedFilter == code;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = alertColor ?? AsmitaPalette.deepNavy;
    final hasBadge = count != null && count > 0;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = code);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? highlight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: highlight.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AsmitaPalette.textDark),
                    ),
                  ),
                ),
              ),
              if (hasBadge) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : highlight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : highlight,
                    ),
                  ),
                ),
              ],
            ],
          ),
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

    final statusBgColor = visit.status.fillColor(isDark);
    final statusTextColor = visit.status.textColor(isDark);
    final statusLabel = isPending ? 'Pending Approval' : visit.status.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AsmitaPalette.actionRed.withValues(alpha: 0.45)
              : Theme.of(context).dividerColor,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? AsmitaPalette.actionRed.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVisitDetailsModal(context, visit),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Name + Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isPending
                          ? AsmitaPalette.actionRed.withValues(alpha: 0.12)
                          : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                      child: Text(
                        visit.visitorName.isNotEmpty ? visit.visitorName[0].toUpperCase() : 'V',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          color: isPending ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  visit.visitorName,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (visit.passCode != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${visit.passCode}',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AsmitaPalette.deepNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                visit.deliveryCompany != null
                                    ? Icons.local_shipping_outlined
                                    : Icons.business_outlined,
                                size: 13,
                                color: AsmitaPalette.textLight,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  visit.deliveryCompany ??
                                      visit.purpose ??
                                      visit.departmentName ??
                                      'Guest Visitor',
                                  style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AsmitaPalette.actionRed.withValues(alpha: 0.12)
                            : statusBgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPending
                              ? AsmitaPalette.actionRed.withValues(alpha: 0.35)
                              : statusTextColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPending ? Icons.warning_amber_rounded : visit.status.iconData,
                            size: 12,
                            color: isPending ? AsmitaPalette.actionRed : statusTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPending ? AsmitaPalette.actionRed : statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Info Meta Row: Department, Vehicle, Expected Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AsmitaPalette.textLight),
                        const SizedBox(width: 4),
                        Text(
                          visit.checkInAt != null
                              ? DateFormat('hh:mm a').format(visit.checkInAt!)
                              : (visit.createdAt != null
                                  ? DateFormat('hh:mm a').format(visit.createdAt!)
                                  : 'Scheduled'),
                          style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                        ),
                      ],
                    ),
                    if (visit.departmentName != null && visit.departmentName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.apartment_outlined, size: 14, color: AsmitaPalette.textLight),
                          const SizedBox(width: 4),
                          Text(
                            visit.departmentName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AsmitaPalette.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (visit.vehicleNumber != null && visit.vehicleNumber!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car_rounded, size: 11, color: AsmitaPalette.textLight),
                            const SizedBox(width: 4),
                            Text(
                              visit.vehicleNumber!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Actions if Pending or Approved
                if (isPending) ...[
                  const SizedBox(height: 14),
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
                          label: const Text('Deny Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AsmitaPalette.actionRed,
                            side: const BorderSide(color: AsmitaPalette.actionRed),
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
                          label: const Text('Approve Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (visit.status == IndustrialVisitStatus.approved && !isAck) ...[
                  const SizedBox(height: 12),
                  AcknowledgeActionButton(
                    isAcknowledged: isAck,
                    onAcknowledge: () {
                      setState(() => _acknowledgedIds.add(visit.id));
                      context.read<IndustrialVisitBloc>().add(AcknowledgeVisitEvent(visit.id));
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
