import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/society_provider.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final rulesState = ref.watch(rulesProvider);

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Rules & Regulations'),
            Expanded(
              child: rulesState.when(
                data: (rules) {
                  if (rules.isEmpty) {
                    return Center(
                      child: Text('No rules found.', style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight)),
                    );
                  }
                  return ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      // Use a generic icon if title doesn't match predefined ones
                      IconData icon = Icons.rule_rounded;
                      if (rule.title.toLowerCase().contains('parking')) icon = Icons.directions_car_rounded;
                      if (rule.title.toLowerCase().contains('pet')) icon = Icons.pets_rounded;
                      if (rule.title.toLowerCase().contains('noise')) icon = Icons.volume_off_rounded;
                      if (rule.title.toLowerCase().contains('club')) icon = Icons.sports_tennis_rounded;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRuleCard(textTheme, icon, rule.title, rule.description),
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

  Widget _buildRuleCard(TextTheme textTheme, IconData icon, String title, String description) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AsmitaPalette.deepNavy, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight, height: 1.5),
          ),
        ],
      ),
    );
  }
}
