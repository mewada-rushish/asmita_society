import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../visitor_management/bloc/guard_gate_bloc.dart';
import '../../../visitor_management/bloc/guard_gate_event.dart';
import '../../../visitor_management/bloc/guard_gate_state.dart';
import '../../../visitor_management/presentation/screens/guard_new_visitor_screen.dart';

class GuardDashboardView extends StatefulWidget {
  final VoidCallback onNavigateToMenu;
  final VoidCallback onNavigateToHistory;

  const GuardDashboardView({
    super.key,
    required this.onNavigateToMenu,
    required this.onNavigateToHistory,
  });

  @override
  State<GuardDashboardView> createState() => _GuardDashboardViewState();
}

class _GuardDashboardViewState extends State<GuardDashboardView> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<GuardGateBloc>().add(LoadExpectedInvites());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _searchCode() {
    final code = _codeController.text.trim();
    if (code.length == 6) {
      context.read<GuardGateBloc>().add(SearchInviteByCode(code));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit access code')),
      );
    }
  }

  void _showCheckInDialog(Map<String, dynamic> invite) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Visitor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${invite['visitor_name']}'),
            Text('Type: ${invite['visitor_type'] ?? 'Guest'}'),
            const SizedBox(height: 8),
            const Text('Match the details with the visitor.', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GuardGateBloc>().add(CheckInPreApprovedVisitor(invite['id'].toString()));
            },
            child: const Text('Confirm Check-in'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: Column(
        children: [
          AsmitaPrimaryHeader(
            subtitleOverride: 'Security Guard',
            trailingActions: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history, color: AsmitaPalette.deepNavy),
                  onPressed: widget.onNavigateToHistory,
                ),
                IconButton(
                  icon: const Icon(Icons.menu, color: AsmitaPalette.deepNavy),
                  onPressed: widget.onNavigateToMenu,
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<GuardGateBloc, GuardGateState>(
        listener: (context, state) {
          if (state.status == GuardGateStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          } else if (state.searchResult != null) {
            _showCheckInDialog(state.searchResult!);
          } else if (state.status == GuardGateStatus.success && state.searchResult == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Check-in successful!')),
            );
            _codeController.clear();
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<GuardGateBloc>().add(LoadExpectedInvites());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(state.isSubmitting),
                  const SizedBox(height: 24),
                  _buildNewVisitorAction(context),
                  const SizedBox(height: 24),
                  Text('Expected Today', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildExpectedList(state),
                ],
              ),
            ),
          );
        },
      ),
    ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scan or Enter Pass Code', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'e.g. 123456',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AsmitaPalette.deepNavy),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isSubmitting ? null : _searchCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AsmitaPalette.deepNavy,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewVisitorAction(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GuardNewVisitorScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AsmitaPalette.deepNavy.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AsmitaPalette.deepNavy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_add, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Walk-in Visitor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AsmitaPalette.textDark)),
                  Text('Record details for unannounced guests', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AsmitaPalette.deepNavy),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedList(GuardGateState state) {
    if (state.status == GuardGateStatus.loading && state.expectedInvites.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AsmitaPalette.deepNavy));
    }
    
    if (state.expectedInvites.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No expected visitors for today', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.expectedInvites.length,
      itemBuilder: (context, index) {
        final invite = state.expectedInvites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AsmitaPalette.deepNavy),
            ),
            title: Text(invite['visitor_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Type: ${invite['visitor_type'] ?? 'Guest'} • Valid Till: ${invite['valid_till'] ?? 'N/A'}'),
            trailing: IconButton(
              icon: const Icon(Icons.check_circle, color: AsmitaPalette.deepNavy),
              onPressed: () {
                _showCheckInDialog(invite);
              },
            ),
          ),
        );
      },
    );
  }
}
