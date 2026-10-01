import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/support_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final supportState = ref.watch(supportProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Help & Support'),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.all(16),
                children: [
                  _buildEmergencySection(context, textTheme),
                  SizedBox(height: 24),
                  _buildRaiseTicketSection(context, ref, textTheme),
                  SizedBox(height: 24),
                  supportState.when(
                    data: (tickets) {
                      if (tickets.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'YOUR TICKETS',
                              style: textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...tickets.map((t) => Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(t.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: t.status.toLowerCase() == 'open' 
                                          ? Colors.orange.withValues(alpha: 0.1) 
                                          : Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(t.status, style: textTheme.bodySmall?.copyWith(
                                        color: t.status.toLowerCase() == 'open' ? Colors.orange : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      )),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(t.description, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                if (t.createdAt != null) ...[
                                  SizedBox(height: 12),
                                  Text(
                                    'Raised on ${AppDateFormatter.formatDate(t.createdAt!)}',
                                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  )
                                ]
                              ],
                            ),
                          )),
                          SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => Center(child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28)),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  _buildFAQSection(context, textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'EMERGENCY CONTACTS',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
          ),
          child: Column(
            children: [
              _buildContactRow(context, textTheme, Icons.local_police_rounded, 'Main Security Gate', 'Ext 101', true),
              _buildContactRow(context, textTheme, Icons.build_circle_rounded, 'Estate Manager', '+91 8888888888', true),
              _buildContactRow(context, textTheme, Icons.medical_services_rounded, 'Ambulance (Nearby)', '108', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(BuildContext context, TextTheme textTheme, IconData icon, String title, String number, bool showBorder) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder ? Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.call_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 4),
                Text(number, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaiseTicketSection(BuildContext context, WidgetRef ref, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Color(0xFF1E2F52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                Text('Facing an Issue?', style: textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Plumbing, Electrical, or others.', style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7))),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showRaiseTicketSheet(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Raise a Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Icon(Icons.support_agent_rounded, size: 64, color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.24)),
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
                  SizedBox(height: 16),
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
                  SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Issue Title', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 24),
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Submit Ticket', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildFAQSection(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
          ),
          child: Column(
            children: [
              _buildFAQItem(context, textTheme, 'How do I pay maintenance?', true),
              _buildFAQItem(context, textTheme, 'Where can I book the clubhouse?', true),
              _buildFAQItem(context, textTheme, 'How to add a family member?', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(BuildContext context, TextTheme textTheme, String question, bool showBorder) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder ? Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)) : null,
        ),
        child: Row(
          children: [
            Expanded(child: Text(question, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
            Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}
