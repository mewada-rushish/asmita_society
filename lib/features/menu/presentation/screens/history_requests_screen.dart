import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import '../providers/history_request_provider.dart';
import '../../data/models/history_request_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class HistoryRequestsScreen extends ConsumerWidget {
  const HistoryRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsState = ref.watch(historyRequestProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      appBar: AppBar(
        title: const Text('Access Requests'),
        centerTitle: true,
      ),
      body: requestsState.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('No access requests found.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(historyRequestProvider.notifier).fetchRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildRequestCard(context, ref, textTheme, req);
              },
            ),
          );
        },
        loading: () => const Center(child: AsmitaLoadingIndicator(color: AsmitaPalette.actionRed, size: 28)),
        error: (err, stack) => Center(child: Text('Error: $err', style: textTheme.bodyLarge?.copyWith(color: Colors.red))),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, WidgetRef ref, TextTheme textTheme, HistoryRequestModel request) {
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
              style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showApproveDialog(context, ref, request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.actionRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Approve Access', style: TextStyle(color: Colors.white)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, WidgetRef ref, HistoryRequestModel request) {
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
                  onPressed: selectedRange == null ? null : () async {
                    Navigator.pop(context);
                    final success = await ref.read(historyRequestProvider.notifier).approveRequest(
                      request.id, 
                      selectedRange!.start, 
                      selectedRange!.end
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Access approved' : 'Failed to approve access')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.actionRed),
                  child: const Text('Approve', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    );
  }
}
