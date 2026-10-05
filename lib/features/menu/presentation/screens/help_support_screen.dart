import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/support_provider.dart';
import 'package:shimmer/shimmer.dart';

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
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  AsmitaAnimatedRefresh(
                    onRefresh: () async {
                      await ref.read(supportProvider.notifier).fetchTickets();
                    },
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.list(
                      children: [
                        _buildRaiseTicketSection(context, ref, textTheme),
                        SizedBox(height: 24),
                  supportState.when(
                    data: (tickets) {
                      if (tickets.isEmpty) return const SizedBox.shrink();
                      final displayTickets = tickets.take(3).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Your Tickets',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TicketCarousel(tickets: displayTickets, textTheme: textTheme),
                          if (tickets.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All Tickets screen coming soon')));
                                },
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                label: Text('View All Tickets', style: TextStyle(fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          ],
                          SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => _buildSkeletonTickets(context),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  _buildFAQSection(context, textTheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                Text('Need App Support?', style: textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Having trouble with the app or your account?', style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7))),
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
    String category = 'Bug Report';

    showAsmitaBottomSheet(
      context: context,
      title: 'Raise a Support Ticket',
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Bug Report', child: Text('Bug Report')),
                      DropdownMenuItem(value: 'Account Issue', child: Text('Account Issue')),
                      DropdownMenuItem(value: 'Feature Request', child: Text('Feature Request')),
                      DropdownMenuItem(value: 'Billing', child: Text('Billing')),
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
          },
        ),
    );
  }

  Widget _buildFAQSection(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Frequently Asked Questions',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 12),
        Material(
          color: Theme.of(context).colorScheme.surface,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
          ),
          child: Column(
            children: [
              _buildFAQItem(context, textTheme, 'How do I reset my password?', 'Go to the login screen, tap "Forgot Password", and follow the OTP instructions sent to your registered mobile number.', true),
              _buildFAQItem(context, textTheme, 'How do I update my profile details?', 'Navigate to the Profile tab in the bottom navigation bar, tap the edit icon, and save your changes.', true),
              _buildFAQItem(context, textTheme, 'The app is crashing, what should I do?', 'Please ensure you are on the latest version of the app. If the issue persists, raise a Bug Report ticket using the button above.', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(BuildContext context, TextTheme textTheme, String question, String answer, bool showBorder) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder ? Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)) : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: Text(question, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          iconColor: Theme.of(context).textTheme.bodyMedium?.color,
          collapsedIconColor: Theme.of(context).textTheme.bodyMedium?.color,
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Text(answer, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonTickets(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        ...List.generate(3, (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        )),
        SizedBox(height: 24),
      ],
    );
  }
}

class TicketCarousel extends StatefulWidget {
  final List<dynamic> tickets;
  final TextTheme textTheme;

  const TicketCarousel({super.key, required this.tickets, required this.textTheme});

  @override
  State<TicketCarousel> createState() => _TicketCarouselState();
}

class _TicketCarouselState extends State<TicketCarousel> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showTicketDetails(BuildContext context, dynamic ticket) {
    showAsmitaBottomSheet(
      context: context,
      title: 'Ticket Conversation',
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(ticket.title, style: widget.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ticket.status.toLowerCase() == 'open' 
                                ? Colors.orange.withValues(alpha: 0.1) 
                                : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(ticket.status, style: widget.textTheme.bodySmall?.copyWith(
                              color: ticket.status.toLowerCase() == 'open' ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(ticket.description, style: widget.textTheme.bodyMedium),
                      if (ticket.createdAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Raised ${AppDateFormatter.timeAgo(ticket.createdAt!)}',
                          style: widget.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        )
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Average reply time: < 2 hours',
                          style: widget.textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Text(
                      'No replies yet.',
                      style: widget.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type your reply...',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: _pageController,
            itemCount: widget.tickets.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final t = widget.tickets[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: Text(t.title, style: widget.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: t.status.toLowerCase() == 'open' 
                                    ? Colors.orange.withValues(alpha: 0.1) 
                                    : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(t.status, style: widget.textTheme.bodySmall?.copyWith(
                                  color: t.status.toLowerCase() == 'open' ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.bold,
                                )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      t.status.toLowerCase() == 'open' ? Icons.support_agent_rounded : Icons.check_circle_outline_rounded,
                                      size: 14,
                                      color: t.status.toLowerCase() == 'open' ? Colors.orange[700] : Colors.green[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        t.status.toLowerCase() == 'open' ? 'Awaiting support reply' : t.status,
                                        style: widget.textTheme.bodySmall?.copyWith(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w500),
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
                                style: widget.textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.tickets.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.tickets.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
