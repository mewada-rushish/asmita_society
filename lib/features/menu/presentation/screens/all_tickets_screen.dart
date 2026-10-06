import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/features/menu/bloc/support_bloc.dart';
import 'package:asmita_society/features/menu/bloc/support_state.dart';
import 'package:asmita_society/features/menu/bloc/support_event.dart';
import '../widgets/ticket_conversation_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';

class AllTicketsScreen extends StatelessWidget {
  const AllTicketsScreen({super.key});

  void _showTicketDetails(BuildContext context, dynamic ticket) {
    showAsmitaBottomSheet(
      context: context,
      customHeader: TicketConversationHeader(ticket: ticket),
      contentPadding: EdgeInsets.zero,
      child: TicketConversationBottomSheet(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('All Tickets'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: BlocBuilder<SupportBloc, SupportState>(
        builder: (context, supportState) {
          if (supportState is SupportLoading || supportState is SupportInitial) {
            return _buildSkeletonList(context);
          } else if (supportState is SupportError) {
            return Center(
              child: Text('Error: ${supportState.message}', style: TextStyle(color: Colors.red)),
            );
          } else if (supportState is SupportLoaded) {
            final tickets = supportState.items;
            if (tickets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No tickets found', style: textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SupportBloc>().add(const LoadSupport());
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tickets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = tickets[index];
                  return _buildTicketCard(context, t, textTheme);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, dynamic t, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => _showTicketDetails(context, t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        t.title, 
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.status.toLowerCase() == 'open' 
                          ? Colors.orange.withValues(alpha: 0.1) 
                          : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.status, 
                        style: textTheme.bodySmall?.copyWith(
                          color: t.status.toLowerCase() == 'open' ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            t.status.toLowerCase() == 'open' ? Icons.support_agent_rounded : Icons.check_circle_outline_rounded,
                            size: 16,
                            color: t.status.toLowerCase() == 'open' ? Colors.orange[700] : Colors.green[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t.status.toLowerCase() == 'open' ? 'Awaiting support reply' : t.status,
                              style: textTheme.bodySmall?.copyWith(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppDateFormatter.timeAgo(t.createdAt),
                      style: textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 1.5),
          ),
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 18,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
