import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/bloc/society_bloc.dart';
import 'package:asmita_society/features/menu/bloc/society_state.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Rules & Regulations'),
            Expanded(
              child: BlocBuilder<SocietyBloc, SocietyState>(
                builder: (context, societyState) {
                  if (societyState is SocietyLoading || societyState is SocietyInitial) {
                    return Center(child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28));
                  } else if (societyState is SocietyError) {
                    return Center(child: Text('Error: ${societyState.message}', style: const TextStyle(color: Colors.red)));
                  } else if (societyState is SocietyLoaded) {
                    final rules = societyState.rules;
                    if (rules.isEmpty) {
                      return Center(
                        child: Text('No rules found.', style: textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
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
                          child: _buildRuleCard(context, textTheme, icon, rule.title, rule.description),
                        );
                      },
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

  Widget _buildRuleCard(BuildContext context, TextTheme textTheme, IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
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
            style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
          ),
        ],
      ),
    );
  }
}
