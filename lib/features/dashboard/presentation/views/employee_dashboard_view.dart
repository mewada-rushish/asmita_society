import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_visitor_card.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/presentation/widgets/delivery_action_sheet.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';

/// Team Lead & HOD Role Dashboard:
/// - Real-time approval feed for assigned / department visitors
/// - Dynamic Cabin, Desk, and Department location badges
/// - Executive Delegation management & active status indicator
/// - Live operational metrics (Pending, On-Site, Expected, All)
/// - Multi-tab visitor management with search and instant filter
/// - 1-tap Host Acknowledgment, Pass Generation & Decision actions
class EmployeeDashboardView extends StatefulWidget {
  final String employeeName;
  final String departmentName;
  final String cabinNumber;
  final String deskNumber;
  final String designation;
  final List<IndustrialVisitModel>? visits;
  final VoidCallback onOpenDelegation;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId)? onAcknowledgeVisit;

  const EmployeeDashboardView({
    super.key,
    this.employeeName = 'IT HOD',
    this.departmentName = 'IT',
    this.cabinNumber = 'CAB-IT-01',
    this.deskNumber = 'Desk 1',
    this.designation = 'Head of Department (HOD)',
    this.visits,
    required this.onOpenDelegation,
    this.onDecideVisit,
    this.onAcknowledgeVisit,
  });

  @override
  State<EmployeeDashboardView> createState() => _EmployeeDashboardViewState();
}

class _EmployeeDashboardViewState extends State<EmployeeDashboardView> {
  int _selectedTab = 0; // 0: Pending, 1: On-Site, 2: Expected, 3: All
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    if (widget.visits == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleDecide(BuildContext context, int visitId, String action) {
    if (widget.onDecideVisit != null) {
      widget.onDecideVisit!(visitId, action);
    } else {
      context.read<IndustrialVisitBloc>().add(
            DecideVisitEvent(visitId: visitId, action: action),
          );
    }
  }

  void _handleAcknowledge(BuildContext context, int visitId) {
    if (widget.onAcknowledgeVisit != null) {
      widget.onAcknowledgeVisit!(visitId);
    } else {
      context.read<IndustrialVisitBloc>().add(
            AcknowledgeVisitEvent(visitId),
          );
    }
  }

  Future<void> _showPreApproveModal([BuildContext? ctx]) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => const AsmitaDialog(
        title: 'Pre-Approve Visitor',
        content: AsmitaPreApproveWizard(),
      ),
    );

    if (!mounted) return;
    context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visits != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: _buildScrollBody(context, widget.visits!, isLoading: false),
        ),
      );
    }

    return BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
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

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              const AsmitaPrimaryHeader(
                subtitleOverride: 'Host Desk',
                allowPropertySwitching: false,
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: AsmitaLoadingIndicator(
                          color: AsmitaPalette.deepNavy,
                          size: 32,
                        ),
                      )
                    : _buildScrollBody(
                        context,
                        state.visits,
                        isLoading: state.status == IndustrialVisitBlocStatus.loading,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollBody(
    BuildContext context,
    List<IndustrialVisitModel> allVisits, {
    required bool isLoading,
  }) {
    final pendingVisits = allVisits.where((v) => v.isPending).toList();
    final onSiteVisits = allVisits.where((v) => v.isCheckedIn).toList();
    final expectedVisits = allVisits.where((v) => v.isApproved && !v.isCheckedIn).toList();

    List<IndustrialVisitModel> currentList;
    switch (_selectedTab) {
      case 0:
        currentList = pendingVisits;
        break;
      case 1:
        currentList = onSiteVisits;
        break;
      case 2:
        currentList = expectedVisits;
        break;
      case 3:
      default:
        currentList = allVisits;
        break;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      currentList = currentList.where((v) {
        final name = v.visitorName.toLowerCase();
        final reqNum = v.requestNumber.toLowerCase();
        final pass = (v.passCode ?? '').toLowerCase();
        final car = (v.vehicleNumber ?? '').toLowerCase();
        final company = (v.deliveryCompany ?? '').toLowerCase();
        final purpose = (v.purpose ?? '').toLowerCase();
        return name.contains(q) ||
            reqNum.contains(q) ||
            pass.contains(q) ||
            car.contains(q) ||
            company.contains(q) ||
            purpose.contains(q);
      }).toList();
    }

    return AsmitaPullToRefresh(
      onRefresh: () async {
        context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
      },
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Executive Team Lead / HOD Hero Card
          _buildHeroCard(context),
          const SizedBox(height: 16),

          // 2. Executive Quick Action Bar
          _buildQuickActionBar(context),
          const SizedBox(height: 18),

          // 3. Operational KPI Overview Metrics (4 interactive cards)
          _buildMetricsOverview(
            context,
            pendingCount: pendingVisits.length,
            onSiteCount: onSiteVisits.length,
            expectedCount: expectedVisits.length,
            totalCount: allVisits.length,
          ),
          const SizedBox(height: 18),

          // 4. Search Bar (if opened or active)
          if (_showSearchBar) ...[
            _buildSearchField(context),
            const SizedBox(height: 14),
          ],

          // 5. Section Filter Segmented Pills
          _buildSegmentedFilterTabs(
            context,
            pendingCount: pendingVisits.length,
            onSiteCount: onSiteVisits.length,
            expectedCount: expectedVisits.length,
            totalCount: allVisits.length,
          ),
          const SizedBox(height: 14),

          // 6. Content Feed / Approval Cards
          if (currentList.isEmpty)
            _buildEmptyState(context, _selectedTab, _searchQuery.trim().isNotEmpty)
          else
            ...currentList.map((v) => _buildVisitCard(context, v)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. EXECUTIVE HERO CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AsmitaPalette.deepNavy,
            Color(0xFF1B2A6B),
            Color(0xFF142055),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: AsmitaPalette.deepNavy.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Name & Designation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employeeName,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981), // active green dot
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                widget.designation.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Department row
            Row(
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.departmentName} Department',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Location badges row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _locationBadge(Icons.meeting_room_outlined, 'Cabin ${widget.cabinNumber}'),
                _locationBadge(Icons.desk_outlined, 'Desk ${widget.deskNumber}'),
                _locationBadge(Icons.verified_user_outlined, 'Host Active', isAccent: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationBadge(IconData icon, String label, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccent
            ? const Color(0xFF10B981).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isAccent
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.22),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isAccent ? const Color(0xFF6EE7B7) : Colors.white,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isAccent ? const Color(0xFFE6FFFA) : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. QUICK ACTION BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Primary Action: Issue Guest Pass
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () => _showPreApproveModal(context),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: const Text(
              'Issue Guest Pass',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.deepNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Delegation Rules Action
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: widget.onOpenDelegation,
            icon: const Icon(Icons.sync_alt_rounded, size: 16),
            label: const Text(
              'Delegation',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : AsmitaPalette.deepNavy,
              side: BorderSide(
                color: isDark ? const Color(0xFF475569) : AsmitaPalette.deepNavy.withValues(alpha: 0.5),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Search toggle button
        Container(
          decoration: BoxDecoration(
            color: _showSearchBar
                ? AsmitaPalette.deepNavy
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: IconButton(
            tooltip: 'Search Visitors',
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            icon: Icon(
              _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
              size: 20,
              color: _showSearchBar
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. OPERATIONAL KPI METRICS (4 Interactive Cards)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMetricsOverview(
    BuildContext context, {
    required int pendingCount,
    required int onSiteCount,
    required int expectedCount,
    required int totalCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context,
                index: 0,
                title: 'Pending',
                count: pendingCount,
                subtitle: pendingCount > 0 ? '$pendingCount Action Required' : 'All Clear',
                icon: Icons.pending_actions_rounded,
                accentColor: pendingCount > 0 ? AsmitaPalette.actionRed : const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                context,
                index: 1,
                title: 'On-Site',
                count: onSiteCount,
                subtitle: onSiteCount > 0 ? '$onSiteCount In Department' : 'No Visitors Inside',
                icon: Icons.business_rounded,
                accentColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context,
                index: 2,
                title: 'Expected',
                count: expectedCount,
                subtitle: expectedCount > 0 ? '$expectedCount Scheduled' : 'None Scheduled',
                icon: Icons.event_available_rounded,
                accentColor: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                context,
                index: 3,
                title: 'All Visits',
                count: totalCount,
                subtitle: 'Total Department Logs',
                icon: Icons.history_rounded,
                accentColor: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required int index,
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? accentColor.withValues(alpha: 0.15)
                  : accentColor.withValues(alpha: 0.08))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: accentColor),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. SEARCH FIELD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by visitor, pass code, vehicle...',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. SEGMENTED FILTER TABS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedFilterTabs(
    BuildContext context, {
    required int pendingCount,
    required int onSiteCount,
    required int expectedCount,
    required int totalCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterPill(
            index: 0,
            label: 'Pending',
            count: pendingCount,
            badgeColor: pendingCount > 0 ? AsmitaPalette.actionRed : null,
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            index: 1,
            label: 'On-Site',
            count: onSiteCount,
            badgeColor: onSiteCount > 0 ? const Color(0xFF10B981) : null,
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            index: 2,
            label: 'Expected',
            count: expectedCount,
            badgeColor: expectedCount > 0 ? const Color(0xFF3B82F6) : null,
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            index: 3,
            label: 'All Logs',
            count: totalCount,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required int index,
    required String label,
    required int count,
    Color? badgeColor,
  }) {
    final isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AsmitaPalette.deepNavy
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AsmitaPalette.deepNavy
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (badgeColor?.withValues(alpha: 0.15) ??
                        (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (badgeColor ??
                          (isDark ? Colors.white70 : const Color(0xFF64748B))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. VISITOR CARD (Responsive, Overflow-Proof)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVisitCard(BuildContext context, IndustrialVisitModel visit) {
    final bool isPending = visit.isPending;

    Widget? bottomActions;
    if (isPending && visit.isDelivery) {
      bottomActions = Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () {
            DeliveryActionSheet.show(
              context,
              visit: visit,
              onActionSelected: (action) =>
                  _handleDecide(context, visit.id, action),
            );
          },
          icon: const Icon(Icons.touch_app_rounded, size: 16, color: Colors.white),
          label: const Text(
            'Delivery Options',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.deepNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
          ),
        ),
      );
    }

    return AsmitaVisitorCard.fromIndustrialVisit(
      visit: visit,
      context: context,
      onApprove: (isPending && !visit.isDelivery)
          ? () => _handleDecide(context, visit.id, 'APPROVE')
          : null,
      onDeny: (isPending && !visit.isDelivery)
          ? () => _handleDecide(context, visit.id, 'REJECT')
          : null,
      onAcknowledge: (isPending && !visit.isDelivery)
          ? () => _handleAcknowledge(context, visit.id)
          : null,
      bottomActions: bottomActions,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. RICH EMPTY STATE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, int tabIndex, bool isSearching) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;
    String buttonText;
    VoidCallback onButtonTap;

    if (isSearching) {
      icon = Icons.search_off_rounded;
      iconColor = const Color(0xFF94A3B8);
      title = 'No Matching Visitors';
      subtitle = 'No visits match "$_searchQuery". Check spelling or clear your filter.';
      buttonText = 'Clear Search';
      onButtonTap = () {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });
      };
    } else {
      switch (tabIndex) {
        case 1:
          icon = Icons.meeting_room_outlined;
          iconColor = const Color(0xFF10B981);
          title = 'No Visitors On-Site';
          subtitle = 'No guests are currently checked in or inside your department cabin.';
          buttonText = 'Issue Guest Pass';
          onButtonTap = () => _showPreApproveModal(context);
          break;
        case 2:
          icon = Icons.event_available_rounded;
          iconColor = const Color(0xFF3B82F6);
          title = 'No Expected Visitors';
          subtitle = 'No upcoming visitor appointments scheduled for today.';
          buttonText = 'Schedule Guest Visit';
          onButtonTap = () => _showPreApproveModal(context);
          break;
        case 3:
          icon = Icons.folder_open_rounded;
          iconColor = const Color(0xFF64748B);
          title = 'No Visit History';
          subtitle = 'No visitor logs recorded for your department today.';
          buttonText = 'Refresh Feed';
          onButtonTap = () {
            context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
          };
          break;
        case 0:
        default:
          icon = Icons.task_alt_rounded;
          iconColor = const Color(0xFF10B981);
          title = 'All Caught Up!';
          subtitle = 'There are no pending visitor approvals requiring your attention right now. When security registers a visitor, they will appear here instantly.';
          buttonText = '+ Issue Guest Pass';
          onButtonTap = () => _showPreApproveModal(context);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onButtonTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.deepNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
