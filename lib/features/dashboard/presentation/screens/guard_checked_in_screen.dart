import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../visitor_management/bloc/guard_gate_bloc.dart';
import '../../../visitor_management/bloc/guard_gate_event.dart';
import '../../../visitor_management/bloc/guard_gate_state.dart';

class GuardCheckedInScreen extends StatefulWidget {
  const GuardCheckedInScreen({super.key});

  @override
  State<GuardCheckedInScreen> createState() => _GuardCheckedInScreenState();
}

class _GuardCheckedInScreenState extends State<GuardCheckedInScreen> {
  @override
  void initState() {
    super.initState();
    _loadCheckedIn();
  }

  void _loadCheckedIn() {
    context.read<GuardGateBloc>().add(LoadCheckedInVisitors());
  }

  String _formatTime(String? dateStr, String? timeStr) {
    if (dateStr == null && timeStr == null) return '--:--';
    try {
      DateTime dt;
      if (dateStr != null && timeStr == null) {
        dt = DateTime.parse(dateStr).toLocal();
      } else if (dateStr != null && timeStr != null) {
        dt = DateTime.parse('${dateStr.split('T')[0]}T$timeStr').toLocal();
      } else {
        return timeStr ?? '--:--';
      }
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--:--';
    }
  }

  void _handleCheckOut(BuildContext context, Map<String, dynamic> item) {
    final name = item['visitor_name'] ?? item['title'] ?? 'Unknown';
    AsmitaDialog.show(
      context: context,
      title: 'Confirm Check-Out',
      content: Text(
        'Are you sure you want to check out $name?',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AsmitaPalette.deepNavy,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            final isPreApproved = item['record_type'] == 'PRE_APPROVED';
            final inviteId = item['invite_id']?.toString();
            final id = isPreApproved ? (inviteId ?? item['id'].toString()) : item['id'].toString();
            final inviteGuestId = item['invite_guest_id']?.toString();
            context.read<GuardGateBloc>().add(CheckOutVisitor(
              id: id, 
              isPreApproved: isPreApproved,
              inviteGuestId: inviteGuestId,
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.actionRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Check-Out'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            subtitleOverride: 'Checked In Visitors',
            allowPropertySwitching: false,
            onProfilePressed: () {},
            trailingActions: const SizedBox(),
          ),
          Expanded(
            child: BlocConsumer<GuardGateBloc, GuardGateState>(
              listener: (context, state) {
                if (state.status == GuardGateStatus.error && state.errorMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.errorMessage!,
                    type: AsmitaToastType.error,
                  );
                } else if (state.status == GuardGateStatus.success && state.successMessage != null) {
                  AsmitaToast.show(
                    context,
                    message: state.successMessage!,
                    type: AsmitaToastType.success,
                  );
                }
              },
              builder: (context, state) {
                if (state.status == GuardGateStatus.loading && state.checkedInVisitors.isEmpty) {
                  return const Center(
                    child: AsmitaLoadingIndicator(color: AsmitaPalette.actionRed, size: 28),
                  );
                }

                if (state.status == GuardGateStatus.error && state.checkedInVisitors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage ?? 'Failed to load checked in visitors',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCheckedIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.deepNavy,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state.checkedInVisitors.isEmpty) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          _loadCheckedIn();
                          await Future.delayed(const Duration(seconds: 1));
                        },
                      ),
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No active visitors inside.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    AsmitaAnimatedRefresh(
                      onRefresh: () async {
                        _loadCheckedIn();
                        await Future.delayed(const Duration(seconds: 1));
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                      sliver: SliverList.builder(
                        itemCount: state.checkedInVisitors.length,
                        itemBuilder: (context, index) {
                          final item = state.checkedInVisitors[index] as Map<String, dynamic>;
                          
                          final isPreApproved = item['record_type'] == 'PRE_APPROVED';
                          final name = item['visitor_name'] ?? item['title'] ?? 'Unknown';
                          final purpose = item['purpose'] ?? item['company_name'] ?? 'Visitor';
                          final category = isPreApproved ? (item['invite_type'] ?? 'Invite') : 'Walk-in';
                          
                          final dateStr = item['created_at'] ?? item['valid_from'];
                          final entryTimeStr = item['checkin_at'] ?? item['start_time'];
                          
                          final entryTime = _formatTime(dateStr, entryTimeStr);

                          IconData iconData = Icons.person;
                          Color brandColor = AsmitaPalette.deepNavy;

                          if (category.toString().toUpperCase() == 'DELIVERY') {
                            iconData = Icons.local_shipping;
                            brandColor = Colors.orange;
                          } else if (category.toString().toUpperCase() == 'CAB') {
                            iconData = Icons.local_taxi;
                            brandColor = Colors.green;
                          } else if (isPreApproved) {
                            iconData = Icons.check_circle_outline;
                            brandColor = AsmitaPalette.actionRed;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: brandColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconData, color: brandColor, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AsmitaPalette.deepNavy,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$purpose • In: $entryTime',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: AsmitaPalette.textLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                state.isSubmitting && state.submittingVisitorId == item['id'].toString()
                                    ? const SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Center(
                                          child: AsmitaLoadingIndicator(
                                            color: AsmitaPalette.actionRed,
                                            size: 20,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: () => _handleCheckOut(context, item),
                                        icon: const Icon(Icons.exit_to_app, color: AsmitaPalette.actionRed),
                                        tooltip: 'Check Out',
                                      ),
                              ],
                            ),
                          );
                        },
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
}
