import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/support_provider.dart';
import 'package:intl/intl.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final supportState = ref.watch(supportProvider);
    
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Help & Support'),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildEmergencySection(textTheme),
                  const SizedBox(height: 24),
                  _buildRaiseTicketSection(context, ref, textTheme),
                  const SizedBox(height: 24),
                  supportState.when(
                    data: (tickets) {
                      if (tickets.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'YOUR TICKETS',
                              style: textTheme.bodySmall?.copyWith(
                                color: AsmitaPalette.textLight,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...tickets.map((t) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(t.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: t.status.toLowerCase() == 'open' 
                                          ? Colors.orange.withValues(alpha: 0.1) 
                                          : AsmitaPalette.successGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(t.status, style: textTheme.bodySmall?.copyWith(
                                        color: t.status.toLowerCase() == 'open' ? Colors.orange : AsmitaPalette.successGreen,
                                        fontWeight: FontWeight.bold,
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(t.description, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight)),
                                if (t.createdAt != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Raised on ${DateFormat('MMM dd, yyyy').format(t.createdAt!)}',
                                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  )
                                ]
                              ],
                            ),
                          )),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  _buildFAQSection(textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'EMERGENCY CONTACTS',
            style: textTheme.bodySmall?.copyWith(
              color: AsmitaPalette.textLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          ),
          child: Column(
            children: [
              _buildContactRow(textTheme, Icons.local_police_rounded, 'Main Security Gate', 'Ext 101', true),
              _buildContactRow(textTheme, Icons.build_circle_rounded, 'Estate Manager', '+91 8888888888', true),
              _buildContactRow(textTheme, Icons.medical_services_rounded, 'Ambulance (Nearby)', '108', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(TextTheme textTheme, IconData icon, String title, String number, bool showBorder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 1)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AsmitaPalette.actionRed, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.call_rounded, size: 14, color: AsmitaPalette.deepNavy),
                const SizedBox(width: 4),
                Text(number, style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaiseTicketSection(BuildContext context, WidgetRef ref, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AsmitaPalette.deepNavy, Color(0xFF1E2F52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AsmitaPalette.deepNavy.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Facing an Issue?', style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Plumbing, Electrical, or others.', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showRaiseTicketSheet(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AsmitaPalette.deepNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Raise a Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Icon(Icons.support_agent_rounded, size: 64, color: Colors.white24),
        ],
      ),
    );
  }

  void _showRaiseTicketSheet(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Plumbing';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Raise a Support Ticket', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Plumbing', child: Text('Plumbing')),
                      DropdownMenuItem(value: 'Electrical', child: Text('Electrical')),
                      DropdownMenuItem(value: 'Cleaning', child: Text('Cleaning/Housekeeping')),
                      DropdownMenuItem(value: 'Security', child: Text('Security')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Issue Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
                        final success = await ref.read(supportProvider.notifier).createTicket(
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          category: category,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket raised successfully')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.deepNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Submit Ticket', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildFAQSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: textTheme.bodySmall?.copyWith(
              color: AsmitaPalette.textLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          ),
          child: Column(
            children: [
              _buildFAQItem(textTheme, 'How do I pay maintenance?', true),
              _buildFAQItem(textTheme, 'Where can I book the clubhouse?', true),
              _buildFAQItem(textTheme, 'How to add a family member?', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(TextTheme textTheme, String question, bool showBorder) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder ? const Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 1)) : null,
        ),
        child: Row(
          children: [
            Expanded(child: Text(question, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.textLight),
          ],
        ),
      ),
    );
  }
}
