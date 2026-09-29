import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/menu/presentation/providers/society_provider.dart';
import 'package:asmita_society/features/menu/data/models/committee_member_model.dart';

class CommitteeMembersScreen extends ConsumerWidget {
  const CommitteeMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final committeeState = ref.watch(committeeProvider);
    
    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Committee Members'),
            Expanded(
              child: committeeState.when(
                data: (members) {
                  if (members.isEmpty) {
                    return Center(
                      child: Text('No committee members found.', style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight)),
                    );
                  }
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      AsmitaAnimatedRefresh(
                        onRefresh: () async {
                          ref.invalidate(committeeProvider);
                          await Future.delayed(const Duration(milliseconds: 1000));
                        },
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 200,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final member = members[index];
                              return _buildMemberCard(textTheme, member);
                            },
                            childCount: members.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: AsmitaLoadingIndicator(color: AsmitaPalette.actionRed, size: 28)),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(TextTheme textTheme, CommitteeMemberModel member) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AsmitaPalette.deepNavy,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?', 
              style: textTheme.titleLarge?.copyWith(color: Colors.white)
            ),
          ),
          const SizedBox(height: 12),
          Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(role, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.actionRed, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Joined $formattedDate', style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const Spacer(),
          const Divider(height: 1, color: AsmitaPalette.borderGrey),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                Icons.call_rounded, 
                () => _launchUrl('tel:$phone'),
              ),
              Container(width: 1, height: 24, color: AsmitaPalette.borderGrey),
              _buildActionButton(
                Icons.email_rounded, 
                () => _launchUrl('mailto:$email'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(icon, size: 22, color: AsmitaPalette.textLight),
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
