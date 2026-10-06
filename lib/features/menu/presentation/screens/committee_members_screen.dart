import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/menu/bloc/society_bloc.dart';
import 'package:asmita_society/features/menu/bloc/society_state.dart';
import 'package:asmita_society/features/menu/bloc/society_event.dart';
import 'package:asmita_society/features/menu/data/models/committee_member_model.dart';

class CommitteeMembersScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onNavigateToCommunity;
  final VoidCallback? onNavigateToSearch;

  const CommitteeMembersScreen({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToCommunity,
    this.onNavigateToSearch,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          Navigator.pop(context);
          if (onNavigateToTab != null) {
            onNavigateToTab!(index);
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AsmitaPrimaryHeader(
              showBackButton: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottomPadding: 0.0,
              onSearchPressed: onNavigateToSearch,
              onChatPressed: onNavigateToCommunity,
            ),
            const AsmitaSubHeader(title: 'Committee Members'),
            Expanded(
              child: BlocBuilder<SocietyBloc, SocietyState>(
                builder: (context, societyState) {
                  if (societyState is SocietyLoading || societyState is SocietyInitial) {
                    return Center(child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28));
                  } else if (societyState is SocietyError) {
                    return Center(child: Text('Error: ${societyState.message}', style: TextStyle(color: Colors.red)));
                  } else if (societyState is SocietyLoaded) {
                    final members = societyState.committeeMembers;
                    if (members.isEmpty) {
                      return Center(
                        child: Text('No committee members found.', style: textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      );
                    }
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        AsmitaAnimatedRefresh(
                          onRefresh: () async {
                            context.read<SocietyBloc>().add(const LoadSocietyData());
                            await Future.delayed(const Duration(milliseconds: 1000));
                          },
                        ),
                        SliverPadding(
                          padding: EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 205,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final member = members[index];
                                return _buildMemberCard(context, textTheme, member);
                              },
                              childCount: members.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, TextTheme textTheme, CommitteeMemberModel member) {
    String formattedDate = '';
    if (member.createdAt != null && member.createdAt!.isNotEmpty) {
      try {
        final date = DateTime.parse(member.createdAt!);
        formattedDate = AppDateFormatter.formatDate(date);
      } catch (e) {
        formattedDate = member.createdAt!;
      }
    }

    final name = member.name;
    final role = member.role;
    final phone = member.phone ?? '';
    final email = member.email ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?', 
                    style: textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.surface)
                  ),
                ),
                SizedBox(height: 12),
                Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text(role, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (formattedDate.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text('Joined $formattedDate', style: textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  Icons.call_rounded, 
                  () => _launchUrl('tel:$phone'),
                ),
                Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                _buildActionButton(
                  context,
                  Icons.email_rounded, 
                  () => _launchUrl('mailto:$email'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Icon(icon, size: 22, color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      await url_launcher.launchUrl(uri);
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }
}
