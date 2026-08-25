import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/society_provider.dart';

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
                  return ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildMemberCard(textTheme, member.name, member.role, member.phone ?? ''),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(TextTheme textTheme, String name, String role, String phone) {
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
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AsmitaPalette.deepNavy,
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?', 
                  style: textTheme.titleLarge?.copyWith(color: Colors.white)
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(role, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.actionRed, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AsmitaPalette.borderGrey),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(textTheme, Icons.call_rounded, 'Call'),
              Container(width: 1, height: 24, color: AsmitaPalette.borderGrey),
              _buildActionButton(textTheme, Icons.email_rounded, 'Email'),
              Container(width: 1, height: 24, color: AsmitaPalette.borderGrey),
              _buildActionButton(textTheme, Icons.message_rounded, 'Chat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(TextTheme textTheme, IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 18, color: AsmitaPalette.textLight),
          const SizedBox(width: 8),
          Text(label, style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
