import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import '../../../visitor_management/bloc/guard_gate_bloc.dart';
import '../../../visitor_management/bloc/guard_gate_event.dart';
import '../../../visitor_management/bloc/guard_gate_state.dart';

class GuardHistoryScreen extends StatefulWidget {
  const GuardHistoryScreen({super.key});

  @override
  State<GuardHistoryScreen> createState() => _GuardHistoryScreenState();
}

class _GuardHistoryScreenState extends State<GuardHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    context.read<GuardGateBloc>().add(LoadGuardHistory());
  }

  String _formatTime(String? dateStr, String? timeStr) {
    if (dateStr == null && timeStr == null) return '--:--';
    try {
      DateTime dt;
      if (timeStr != null && (timeStr.contains('T') || timeStr.contains(' '))) {
        dt = DateTime.parse(timeStr).toLocal();
      } else if (dateStr != null && timeStr == null) {
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today';
      }
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            subtitleOverride: 'Gate History',
            showBackButton: true,
            allowPropertySwitching: false,
          ),
          Expanded(
            child: BlocBuilder<GuardGateBloc, GuardGateState>(
              builder: (context, state) {
                if (state.status == GuardGateStatus.loading && state.historyRecords.isEmpty) {
                  return _buildHistorySkeleton(context);
                }

                if (state.status == GuardGateStatus.error && state.historyRecords.isEmpty) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: isDark ? AsmitaPalette.textDarkModeMuted : Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage ?? 'Failed to load history',
                          style: TextStyle(color: isDark ? AsmitaPalette.textDarkModeMuted : Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state.historyRecords.isEmpty) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          _loadHistory();
                          await Future.delayed(const Duration(seconds: 1));
                        },
                      ),
                      SliverFillRemaining(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Center(
                            child: Text(
                              'No visitor records found.',
                              style: TextStyle(color: isDark ? AsmitaPalette.textDarkModeMuted : Colors.grey),
                            ),
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
                        _loadHistory();
                        await Future.delayed(const Duration(seconds: 1));
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 180),
                      sliver: SliverList.builder(
                        itemCount: state.historyRecords.length,
                        itemBuilder: (context, index) {
                          final item = state.historyRecords[index] as Map<String, dynamic>;
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          
                          final isPreApproved = item['record_type'] == 'PRE_APPROVED';
                          final name = item['visitor_name'] ?? item['title'] ?? 'Unknown';
                          final category = isPreApproved ? (item['invite_type'] ?? 'Invite') : 'Walk-in';
                          
                          final rawPurpose = item['purpose']?.toString().trim();
                          final rawCompany = item['company_name']?.toString().trim();
                          final purpose = (rawPurpose != null && rawPurpose.isNotEmpty) ? rawPurpose : ((rawCompany != null && rawCompany.isNotEmpty) ? rawCompany : category.toString());
                          
                          final dateStr = item['created_at'] ?? item['valid_from'];
                          final entryTimeStr = item['checkin_at'] ?? item['start_time'];
                          
                          final date = _formatDate(dateStr);
                          final entryTime = _formatTime(dateStr, entryTimeStr);
                          final exitTimeStr = item['checkout_at'];
                          final exitTime = exitTimeStr != null ? _formatTime(dateStr, exitTimeStr) : '--:--';

                          IconData iconData = Icons.person;
                          Color brandColor = isDark ? const Color(0xFF60A5FA) : Theme.of(context).colorScheme.primary;

                          if (category.toString().toUpperCase() == 'DELIVERY') {
                            iconData = Icons.local_shipping;
                            brandColor = Colors.orange;
                          } else if (category.toString().toUpperCase() == 'CAB') {
                            iconData = Icons.local_taxi;
                            brandColor = Colors.green;
                          } else if (isPreApproved) {
                            iconData = Icons.check_circle_outline;
                            brandColor = Theme.of(context).colorScheme.error;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AsmitaPalette.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AsmitaPalette.borderGreyDark : Colors.grey.withValues(alpha: 0.1),
                              ),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
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
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AsmitaPalette.textDarkModeMain : Theme.of(context).colorScheme.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: brandColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                purpose,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  color: brandColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.circle, 
                                            size: 4, 
                                            color: isDark ? AsmitaPalette.textDarkModeMuted : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            date,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              color: isDark ? AsmitaPalette.textDarkModeMuted : Theme.of(context).textTheme.bodySmall?.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.login, 
                                          size: 12, 
                                          color: isDark ? const Color(0xFF60A5FA) : Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          entryTime,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF60A5FA) : Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.logout, 
                                          size: 12, 
                                          color: isDark ? const Color(0xFFF87171) : Theme.of(context).colorScheme.error,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          exitTime,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFF87171) : Theme.of(context).colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildHistorySkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AsmitaSkeleton(
      isLoading: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16).copyWith(bottom: 180),
        itemCount: 6,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AsmitaPalette.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AsmitaPalette.borderGreyDark : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                AsmitaSkeleton.circle(size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AsmitaSkeleton.text(width: 130, height: 15, borderRadius: 4),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AsmitaSkeleton.pill(width: 70, height: 20),
                          const SizedBox(width: 8),
                          AsmitaSkeleton.circle(size: 4),
                          const SizedBox(width: 8),
                          AsmitaSkeleton.text(width: 65, height: 12, borderRadius: 3),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AsmitaSkeleton.bone(width: 12, height: 12, borderRadius: 2),
                        const SizedBox(width: 4),
                        AsmitaSkeleton.text(width: 50, height: 12, borderRadius: 3),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AsmitaSkeleton.bone(width: 12, height: 12, borderRadius: 2),
                        const SizedBox(width: 4),
                        AsmitaSkeleton.text(width: 50, height: 12, borderRadius: 3),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
