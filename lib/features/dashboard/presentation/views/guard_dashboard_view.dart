import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/design_system.dart';
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
          Text(
            'Name: ${(invite['visitor_name'] == null || invite['visitor_name'].toString().isEmpty) ? (invite['title'] ?? 'Unknown') : invite['visitor_name']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AsmitaPalette.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Type: ${invite['invite_type'] ?? 'Guest'}',
            style: const TextStyle(fontSize: 14, color: AsmitaPalette.textLight),
          ),
          if (invite['tower_name'] != null && invite['flat_number'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Unit: ${invite['tower_name']} - ${invite['flat_number']}',
              style: const TextStyle(fontSize: 14, color: AsmitaPalette.textDark, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 12),
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
      return const Center(child: CircularProgressIndicator(color: AsmitaPalette.deepNavy));
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: AsmitaPalette.systemBG,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildInviteIcon(invite),
            title: Text(
              _getInviteTitle(invite),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _getInviteSubtitle(invite),
              style: const TextStyle(height: 1.4),
            ),
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

  Widget _buildInviteIcon(Map<String, dynamic> invite) {
    final companyName = invite['company_name']?.toString();
    final isDelivery = invite['invite_type']?.toString().toLowerCase() == 'delivery';

    if (companyName != null && companyName.isNotEmpty) {
      // Basic mapping to filename based on common keys
      final fileName = companyName.toLowerCase().replaceAll(' ', (companyName.contains(' ') && !['amazon prime now', 'apollo 24-7', 'bharat gas', 'big basket', 'blue dart', 'country delight', 'india post', 'eat club', 'ecom express', 'fresh menu', 'fresh to home', 'hdfc bank', 'hp gas', 'milk basket', 'natures basket', 'pizza hut', 'professional courier', 'swiggy instamart', 'tata 1mg', 'tata play', 'urban company'].contains(companyName.toLowerCase())) ? '' : ' ');
      // The frontend uses specific file names, but if it doesn't match, errorBuilder will catch it.
      // E.g. "Zomato" -> "zomato.png"
      return CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Image.asset(
          'assets/images/logos/$fileName.png',
          errorBuilder: (context, error, stackTrace) => _defaultIcon(isDelivery),
        ),
      );
    }
    return _defaultIcon(isDelivery);
  }

  Widget _defaultIcon(bool isDelivery) {
    return CircleAvatar(
      backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
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

  String _getInviteSubtitle(Map<String, dynamic> invite) {
    String sub = 'Type: ${invite['invite_type'] ?? 'Guest'} • Valid Till: ${invite['valid_to']?.substring(0, 10) ?? 'N/A'}';
    if (invite['tower_name'] != null && invite['flat_number'] != null) {
      sub += '\nUnit: ${invite['tower_name']} - ${invite['flat_number']}';
    }
    return sub;
  }
}
