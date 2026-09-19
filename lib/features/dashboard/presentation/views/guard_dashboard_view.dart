import 'package:flutter/material.dart';
import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/design_system.dart';
import '../../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_dialog.dart';
import '../../../../core/widgets/asmita_toast.dart';
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
    }
    if (code.length != 6) {
      AsmitaToast.show(
        context,
        message: 'Please enter a 6-digit access code',
        type: AsmitaToastType.error,
      );
      return;
    }
  }

  void _showCheckInDialog(Map<String, dynamic> invite) {
    AsmitaDialog.show(
      context: context,
      title: 'Verify Visitor',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (invite['company_name'] != null && invite['company_name'].toString().isNotEmpty) ...[
                _buildInviteIcon(invite),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  '${(invite['visitor_name'] == null || invite['visitor_name'].toString().isEmpty) ? (invite['title'] ?? 'Unknown') : invite['visitor_name']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AsmitaPalette.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final rows = <Widget>[];
              if (invite['tower_name'] != null && invite['flat_number'] != null) {
                rows.add(_buildDialogRow('Destination', '${invite['tower_name']} - ${invite['flat_number']}', highlight: true));
              }
              rows.add(_buildDialogRow('Type', (invite['invite_type']?.toString() ?? 'Guest').toUpperCase()));
              rows.add(_buildDialogRow('Valid From', invite['valid_from'] != null ? AppDateFormatter.formatDate(invite['valid_from']) : 'N/A'));
              rows.add(_buildDialogRow('Valid Till', invite['valid_to'] != null ? AppDateFormatter.formatDate(invite['valid_to']) : 'N/A'));

              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                  itemBuilder: (context, index) => rows[index],
                ),
              );
            }
          ),
          const SizedBox(height: 16),
          const Text(
            'Match the details with the visitor.', 
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<GuardGateBloc>().add(CheckInPreApprovedVisitor(invite['id'].toString()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.deepNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Confirm Check-in'),
        ),
      ],
    );
  }

  Widget _buildDialogRow(String label, String value, {bool highlight = false}) {
    return Container(
      color: highlight ? AsmitaPalette.deepNavy.withValues(alpha: 0.05) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AsmitaPalette.deepNavy, fontSize: 13, fontWeight: FontWeight.w600)),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
          Text(value, style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.w600, fontSize: highlight ? 15 : 13, color: highlight ? AsmitaPalette.deepNavy : AsmitaPalette.textDark)),
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
            allowPropertySwitching: false,
            onProfilePressed: widget.onNavigateToMenu,
            trailingActions: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history, color: AsmitaPalette.deepNavy),
                  onPressed: widget.onNavigateToHistory,
                ),
              ],
            ),
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
          } else if (state.searchResult != null) {
            _showCheckInDialog(state.searchResult!);
          } else if (state.status == GuardGateStatus.success && state.searchResult == null) {
            AsmitaToast.show(
              context,
              message: 'Check-in successful!',
              type: AsmitaToastType.success,
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expected Today', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildExpectedList(state),
                      ],
                    ),
                  ),
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
                    hintStyle: TextStyle(color: AsmitaPalette.textLight.withValues(alpha: 0.6), fontSize: 14),
                    prefixIcon: const Icon(Icons.numbers, color: AsmitaPalette.textLight, size: 20),
                    filled: true,
                    fillColor: AsmitaPalette.systemBG,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AsmitaPalette.deepNavy, width: 1.5),
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
                    ? const SizedBox(width: 24, height: 24, child: AsmitaLoadingIndicator(color: Colors.white, size: 24))
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
      return const Center(child: AsmitaLoadingIndicator(color: AsmitaPalette.deepNavy, size: 28));
    }
    
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final validInvites = state.expectedInvites.where((invite) {
      if (invite['valid_to'] != null) {
        try {
          final validTo = DateTime.parse(invite['valid_to']);
          if (validTo.isBefore(startOfToday)) return false;
        } catch (_) {}
      }
      return true;
    }).toList();

    if (validInvites.isEmpty) {
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
      padding: EdgeInsets.zero,
      itemCount: validInvites.length,
      itemBuilder: (context, index) {
        final invite = validInvites[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AsmitaPalette.systemBG,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildInviteIcon(invite),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _getInviteTitle(invite),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AsmitaPalette.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (invite['invite_type']?.toString() ?? 'Guest').toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AsmitaPalette.deepNavy),
                            ),
                          ),
                        ],
                      ),
                      _buildInviteSubtitle(invite),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: AsmitaPalette.deepNavy, size: 28),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _showCheckInDialog(invite);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInviteIcon(Map<String, dynamic> invite) {
    final companyName = invite['company_name']?.toString();
    final isDelivery = invite['invite_type']?.toString().toLowerCase() == 'delivery';

    if (companyName != null && companyName.isNotEmpty) {
      final fileName = companyName.toLowerCase().replaceAll(' ', (companyName.contains(' ') && !['amazon prime now', 'apollo 24-7', 'bharat gas', 'big basket', 'blue dart', 'country delight', 'india post', 'eat club', 'ecom express', 'fresh menu', 'fresh to home', 'hdfc bank', 'hp gas', 'milk basket', 'natures basket', 'pizza hut', 'professional courier', 'swiggy instamart', 'tata 1mg', 'tata play', 'urban company'].contains(companyName.toLowerCase())) ? '' : ' ');
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Image.asset(
          'assets/images/logos/$fileName.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _defaultIcon(isDelivery),
        ),
      );
    }
    return _defaultIcon(isDelivery);
  }

  Widget _defaultIcon(bool isDelivery) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(isDelivery ? Icons.local_shipping : Icons.person, color: AsmitaPalette.deepNavy),
    );
  }

  String _getInviteTitle(Map<String, dynamic> invite) {
    if (invite['visitor_name'] != null && invite['visitor_name'].toString().isNotEmpty) {
      return invite['visitor_name'];
    }
    if (invite['company_name'] != null && invite['company_name'].toString().isNotEmpty) {
      return invite['company_name'];
    }
    return invite['title'] ?? 'Unknown';
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $ampm';
    } catch (_) {
      return '';
    }
  }

  Widget _buildInviteSubtitle(Map<String, dynamic> invite) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invite['tower_name'] != null && invite['flat_number'] != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.meeting_room, size: 16, color: AsmitaPalette.deepNavy),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${invite['tower_name']} - ${invite['flat_number']}',
                  style: const TextStyle(
                    fontSize: 13, 
                    color: AsmitaPalette.deepNavy, 
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (invite['valid_to'] != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.watch_later, size: 14, color: AsmitaPalette.deepNavy),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${AppDateFormatter.formatDate(invite['valid_to'])} • ${_formatTime(invite['valid_to'])}',
                  style: const TextStyle(
                    fontSize: 12, 
                    color: AsmitaPalette.deepNavy, 
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
