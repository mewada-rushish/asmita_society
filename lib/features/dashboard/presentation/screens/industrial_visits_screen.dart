import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../widgets/asmita_pre_approve_wizard.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/presentation/widgets/acknowledge_action_button.dart';

class IndustrialVisitsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const IndustrialVisitsScreen({super.key, this.onBack});

  @override
  State<IndustrialVisitsScreen> createState() => _IndustrialVisitsScreenState();
}

class _IndustrialVisitsScreenState extends State<IndustrialVisitsScreen> {
  String _selectedFilter = 'ALL';
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

  void _showPreApproveModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AsmitaDialog(
        title: 'Schedule Visitor',
        content: AsmitaPreApproveWizard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 16;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
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
                    return matchName || matchOrg || matchDept;
                  }
                  return true;
                }).toList();

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: topPadding),
                    ),
                    AsmitaAnimatedRefresh(
                      onRefresh: () async {
                        context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
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
                                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                decoration: const InputDecoration(
                                  hintText: 'Search visitors, organization, dept...',
                                  hintStyle: TextStyle(fontSize: 13, color: AsmitaPalette.textLight),
                                  prefixIcon: Icon(Icons.search, size: 20, color: AsmitaPalette.textLight),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _filterChip('ALL', 'All Visits (${state.visits.length})'),
                                  const SizedBox(width: 8),
                                  _filterChip('PENDING', 'Pending (${state.visits.where((v) => v.isPending).length})'),
                                  const SizedBox(width: 8),
                                  _filterChip('APPROVED', 'Approved'),
                                  const SizedBox(width: 8),
                                  _filterChip('INSIDE', 'Inside Campus'),
                                  const SizedBox(width: 8),
                                  _filterChip('COMPLETED', 'Completed'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    if (filteredVisits.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.badge_outlined,
                                    size: 48,
                                    color: AsmitaPalette.deepNavy,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Visitors Found',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'There are no visitor records matching your filter criteria.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AsmitaPalette.textLight),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => _showPreApproveModal(context),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Schedule Visitor'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AsmitaPalette.deepNavy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AsmitaPrimaryHeader(
              subtitleOverride: 'Visits & Approvals',
              allowPropertySwitching: false,
              trailingActions: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 20, color: AsmitaPalette.deepNavy),
                ),
                onPressed: () => _showPreApproveModal(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String code, String label) {
    final isSelected = _selectedFilter == code;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = code),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AsmitaPalette.deepNavy : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AsmitaPalette.deepNavy : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildVisitItem(BuildContext context, IndustrialVisitModel visit) {
    final isPending = visit.isPending;
    final isAck = _acknowledgedIds.contains(visit.id);

    final Color statusColor;
    final String statusText;
    if (isPending) {
      statusColor = AsmitaPalette.actionRed;
      statusText = 'Pending Approval';
    } else {
      statusColor = visit.status.badgeColor;
      statusText = visit.status.label;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AsmitaPalette.actionRed.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                child: Text(
                  visit.visitorName.isNotEmpty ? visit.visitorName[0].toUpperCase() : 'V',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    color: AsmitaPalette.deepNavy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.visitorName,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.deliveryCompany ?? visit.purpose ?? visit.departmentName ?? 'Guest Visitor',
                      style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AsmitaPalette.textLight),
                  const SizedBox(width: 4),
                  Text(
                    visit.createdAt != null
                        ? '${visit.createdAt!.hour.toString().padLeft(2, '0')}:${visit.createdAt!.minute.toString().padLeft(2, '0')}'
                        : 'Scheduled Visit',
                    style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                  ),
                ],
              ),
              if (visit.passCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PASS: ${visit.passCode}',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),

          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<IndustrialVisitBloc>().add(
                            DecideVisitEvent(visitId: visit.id, action: 'DENY'),
                          );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AsmitaPalette.actionRed,
                      side: const BorderSide(color: AsmitaPalette.actionRed),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Deny Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<IndustrialVisitBloc>().add(
                            DecideVisitEvent(visitId: visit.id, action: 'APPROVE'),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Approve Entry', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}
