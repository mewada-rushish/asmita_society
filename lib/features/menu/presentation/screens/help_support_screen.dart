import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/bloc/support_bloc.dart';
import 'package:asmita_society/features/menu/data/repositories/support_repository.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/features/menu/bloc/support_event.dart';
import 'package:asmita_society/features/menu/bloc/support_state.dart';
import '../widgets/ticket_conversation_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_select_field.dart';
import 'package:asmita_society/features/menu/presentation/screens/all_tickets_screen.dart';
import 'package:asmita_society/features/bbps/presentation/widgets/bbps_support_modals.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        SupportBloc? existingBloc;
        try {
          existingBloc = ctx.read<SupportBloc>();
        } catch (_) {}

        if (existingBloc != null) {
          return const _HelpSupportContent();
        }

        return BlocProvider<SupportBloc>(
          create: (_) {
            final dio = AsmitaDioClient(SecureStorageService()).dio;
            final repository = SupportRepository(dio: dio);
            return SupportBloc(repository: repository)..add(const LoadSupport());
          },
          child: const _HelpSupportContent(),
        );
      },
    );
  }
}

class _HelpSupportContent extends StatelessWidget {
  const _HelpSupportContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                      context.read<SupportBloc>().add(const LoadSupport());
                    },
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.list(
                      children: [
                        _buildRaiseTicketSection(context, textTheme),
                        const SizedBox(height: 18),
                        _buildBbpsSupportSection(context, textTheme),
                        const SizedBox(height: 24),
                  BlocBuilder<SupportBloc, SupportState>(
                    builder: (context, state) {
                      if (state is SupportLoading) {
                        return _buildSkeletonTickets(context);
                      } else if (state is SupportError) {
                        return Text('Error: ${state.message}');
                      } else if (state is SupportLoaded) {
                        final tickets = state.items;
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
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<SupportBloc>(), child: const AllTicketsScreen())));
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
                      }
                      return const SizedBox.shrink();
                    },
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


  Widget _buildBbpsSupportSection(BuildContext context, TextTheme textTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Text(
                'Bharat BillPay (BBPS) Support',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NPCI',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => BbpsSupportModals.showTransactionHistoryModal(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 18, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text(
                        'History & Receipts',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => BbpsSupportModals.showComplaintModal(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Text(
                        'Raise Complaint',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRaiseTicketSection(BuildContext context, TextTheme textTheme) {
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
                  onPressed: () => _showRaiseTicketSheet(context),
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

  void _showRaiseTicketSheet(BuildContext context) {
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
                  AsmitaSelectField<String>(
                    label: 'Category',
                    hint: 'Select issue category',
                    value: category,
                    prefixIcon: Icons.category_outlined,
                    sheetTitle: 'Select Issue Category',
                    sheetSubtitle: 'Choose the area most relevant to your ticket',
                    items: [
                      const AsmitaSelectItem(
                        value: 'Bug Report',
                        label: 'Bug Report',
                        subtitle: 'App glitch, crash, or unexpected behavior',
                        icon: Icons.bug_report_outlined,
                        iconColor: AsmitaPalette.actionRed,
                      ),
                      AsmitaSelectItem(
                        value: 'Account Issue',
                        label: 'Account Issue',
                        subtitle: 'Login, permissions, or profile details',
                        icon: Icons.person_outline_rounded,
                        iconColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF60A5FA)
                            : AsmitaPalette.deepNavy,
                      ),
                      const AsmitaSelectItem(
                        value: 'Feature Request',
                        label: 'Feature Request',
                        subtitle: 'Suggest a new feature or improvement',
                        icon: Icons.lightbulb_outline_rounded,
                        iconColor: Colors.amber,
                      ),
                      const AsmitaSelectItem(
                        value: 'Billing',
                        label: 'Billing',
                        subtitle: 'Maintenance dues, receipts, or payments',
                        icon: Icons.receipt_long_outlined,
                        iconColor: AsmitaPalette.successGreen,
                      ),
                      const AsmitaSelectItem(
                        value: 'Other',
                        label: 'Other',
                        subtitle: 'General inquiries or uncategorized support',
                        icon: Icons.help_outline_rounded,
                        iconColor: AsmitaPalette.textLight,
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issue Title',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AsmitaPalette.textDarkModeMuted
                              : AsmitaPalette.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Cannot download gate pass PDF',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AsmitaPalette.textLight.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? AsmitaPalette.surfaceDark
                              : AsmitaPalette.systemBG,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AsmitaPalette.borderGreyDark
                                  : AsmitaPalette.borderGrey,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AsmitaPalette.borderGreyDark
                                  : AsmitaPalette.borderGrey,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF60A5FA)
                                  : AsmitaPalette.deepNavy,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AsmitaPalette.textDarkModeMuted
                              : AsmitaPalette.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Provide details on what happened or what you need...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AsmitaPalette.textLight.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? AsmitaPalette.surfaceDark
                              : AsmitaPalette.systemBG,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AsmitaPalette.borderGreyDark
                                  : AsmitaPalette.borderGrey,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AsmitaPalette.borderGreyDark
                                  : AsmitaPalette.borderGrey,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF60A5FA)
                                  : AsmitaPalette.deepNavy,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
                        context.read<SupportBloc>().add(CreateSupportTicket(
                          subject: titleCtrl.text,
                          message: descCtrl.text,
                          category: category,
                          priority: 'MEDIUM',
                        ));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Ticket raised successfully'),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2563EB)
                                  : AsmitaPalette.deepNavy,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2563EB)
                            : AsmitaPalette.deepNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Submit Ticket',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
      customHeader: TicketConversationHeader(ticket: ticket),
      contentPadding: EdgeInsets.zero,
      child: TicketConversationBottomSheet(ticket: ticket),
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
                                style: widget.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AsmitaPalette.textDarkModeMuted
                                      : AsmitaPalette.textLight,
                                ),
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
