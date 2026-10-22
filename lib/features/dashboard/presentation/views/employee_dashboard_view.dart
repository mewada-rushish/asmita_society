import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../visitor_management/data/models/industrial_visit_model.dart';
import '../../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../../visitor_management/bloc/industrial_visit_event.dart';
import '../../../visitor_management/bloc/industrial_visit_state.dart';
import '../../../visitor_management/presentation/widgets/acknowledge_action_button.dart';
import '../../../visitor_management/presentation/widgets/delivery_action_sheet.dart';

/// Employee Role Dashboard:
/// - Approvals feed for assigned / hosted visitors
/// - Cabin and Desk location display
/// - Delegation toggle / management button
/// - 1-tap Host Acknowledgment & Decision actions
class EmployeeDashboardView extends StatefulWidget {
  final String employeeName;
  final String departmentName;
  final String cabinNumber;
  final String deskNumber;
  final List<IndustrialVisitModel>? visits;
  final VoidCallback onOpenDelegation;
  final Function(int visitId, String action)? onDecideVisit;
  final Function(int visitId)? onAcknowledgeVisit;

  const EmployeeDashboardView({
    super.key,
    this.employeeName = 'Aditi Sharma',
    this.departmentName = 'Accounts',
    this.cabinNumber = '104',
    this.deskNumber = '2',
    this.visits,
    required this.onOpenDelegation,
    this.onDecideVisit,
    this.onAcknowledgeVisit,
  });

  @override
  State<EmployeeDashboardView> createState() => _EmployeeDashboardViewState();
}

class _EmployeeDashboardViewState extends State<EmployeeDashboardView> {
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
                child: RefreshIndicator(
                  color: AsmitaPalette.deepNavy,
                  onRefresh: () async {
                    context.read<IndustrialVisitBloc>().add(const LoadIndustrialVisits());
                  },
                  child: isLoading
                      ? const Center(
                          child: AsmitaLoadingIndicator(
                            color: AsmitaPalette.deepNavy,
                            size: 32,
                          ),
                        )
                      : _buildScrollBody(context, state.visits, isLoading: state.status == IndustrialVisitBlocStatus.loading),
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Employee Profile & Location Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AsmitaPalette.deepNavy, Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.employeeName,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delegation Button
                    OutlinedButton.icon(
                      onPressed: widget.onOpenDelegation,
                      icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                      label: const Text('Delegation', style: TextStyle(color: Colors.white, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.departmentName} Department',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _locationBadge(Icons.meeting_room_outlined, 'Cabin ${widget.cabinNumber}'),
                    const SizedBox(width: 8),
                    _locationBadge(Icons.desk_outlined, 'Desk ${widget.deskNumber}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pending Approvals Feed Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Approvals',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AsmitaPalette.actionRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pendingVisits.length} Action Needed',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AsmitaPalette.actionRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (pendingVisits.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: AsmitaPalette.successGreen.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  const Text('You are all caught up! No pending visitors.', style: TextStyle(color: AsmitaPalette.textLight)),
                ],
              ),
            )
          else
            ...pendingVisits.map((v) => _approvalCard(context, v)),
        ],
      ),
    );
  }

  Widget _locationBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _approvalCard(BuildContext context, IndustrialVisitModel visit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x0A0F172A),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Squircle Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: visit.isDelivery
                          ? const [Color(0xFFD97706), Color(0xFFF59E0B)]
                          : const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: (visit.isDelivery ? const Color(0xFFF59E0B) : const Color(0xFF2563EB))
                            .withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      visit.isDelivery ? Icons.local_shipping_rounded : Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.isDelivery ? '${visit.deliveryCompany} Delivery' : visit.visitorName,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        visit.isDelivery ? 'Package Dropoff' : (visit.purpose ?? 'Guest Meeting'),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: visit.status.fillColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: visit.status.textColor(isDark).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    visit.status.label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: visit.status.textColor(isDark),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),

            // Inset meta row
            Container(
              margin: const EdgeInsets.only(top: 13),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tag_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    visit.requestNumber,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  if (visit.passCode != null && visit.passCode!.isNotEmpty)
                    Text(
                      'PASS: #${visit.passCode}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (visit.isDelivery) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      DeliveryActionSheet.show(
                        context,
                        visit: visit,
                        onActionSelected: (action) => _handleDecide(context, visit.id, action),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                  ),
                ] else ...[
                  AcknowledgeActionButton(
                    onAcknowledge: () => _handleAcknowledge(context, visit.id),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _handleDecide(context, visit.id, 'REJECT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AsmitaPalette.actionRed,
                      side: BorderSide(
                        color: AsmitaPalette.actionRed.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _handleDecide(context, visit.id, 'APPROVE'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text(
                      'Approve',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
