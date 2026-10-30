import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/historyrequest_bloc.dart';
import '../../bloc/historyrequest_event.dart';
import '../../bloc/historyrequest_state.dart';
import '../../data/models/history_request_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class HistoryRequestsScreen extends StatelessWidget {
  const HistoryRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Access Requests'),
        centerTitle: true,
      ),
      body: BlocBuilder<HistoryRequestBloc, HistoryRequestState>(
        builder: (context, state) {
          if (state is HistoryRequestLoading) {
            return Center(child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28));
          } else if (state is HistoryRequestError) {
            return Center(child: Text('Error: ${state.message}', style: textTheme.bodyLarge?.copyWith(color: Colors.red)));
          } else if (state is HistoryRequestLoaded) {
            final requests = state.items;
            if (requests.isEmpty) {
              return const Center(child: Text('No access requests found.'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HistoryRequestBloc>().add(const LoadHistoryRequest());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return _buildRequestCard(context, textTheme, req);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, TextTheme textTheme, HistoryRequestModel request) {
    final isPending = request.status == 'PENDING';
    final formatter = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${request.ownerName} requests access to visitor history',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status,
                    style: textTheme.labelSmall?.copyWith(
                      color: isPending ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Requested on: ${formatter.format(request.createdAt)}',
              style: textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showApproveDialog(context, request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Approve Access', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, HistoryRequestModel request) {
    DateTimeRange? selectedRange;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Date Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select the timeframe for which you want to share visitor records.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(selectedRange != null 
                        ? '${DateFormat('MMM d').format(selectedRange!.start)} - ${DateFormat('MMM d').format(selectedRange!.end)}'
                        : 'Choose Date Range'),
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (range != null) {
                        setState(() => selectedRange = range);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRange == null ? null : () {
                    Navigator.pop(context);
                    context.read<HistoryRequestBloc>().add(ApproveRequest(
                      id: request.id, 
                      startDate: selectedRange!.start, 
                      endDate: selectedRange!.end
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Access approval request submitted')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  child: Text('Approve', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
                ),
              ],
            );
          },
        );
      }
    );
  }
}
