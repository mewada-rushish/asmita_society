import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/app_skeleton.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/menu/bloc/society_bloc.dart';
import 'package:asmita_society/features/menu/bloc/society_event.dart';
import 'package:asmita_society/features/menu/bloc/society_state.dart';
import 'package:asmita_society/features/menu/data/repositories/society_repository.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/core/di/injection_container.dart' as di;

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        bool hasBloc = false;
        try {
          ctx.read<SocietyBloc>();
          hasBloc = true;
        } catch (_) {}

        if (!hasBloc) {
          final repo = di.sl.isRegistered<SocietyRepository>()
              ? di.sl<SocietyRepository>()
              : SocietyRepository(dio: AsmitaDioClient(SecureStorageService()).dio);
          return BlocProvider<SocietyBloc>(
            create: (_) => SocietyBloc(repository: repo)..add(const LoadSocietyData()),
            child: const _RulesScreenBody(),
          );
        }

        if (ctx.read<SocietyBloc>().state is SocietyInitial) {
          ctx.read<SocietyBloc>().add(const LoadSocietyData());
        }

        return const _RulesScreenBody();
      },
    );
  }
}

class _RulesScreenBody extends StatelessWidget {
  const _RulesScreenBody();

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
                    return _buildRulesSkeleton(context);
                  } else if (societyState is SocietyError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${societyState.message}', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<SocietyBloc>().add(const LoadSocietyData()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (societyState is SocietyLoaded) {
                    final rules = societyState.rules;
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        AsmitaAnimatedRefresh(
                          onRefresh: () async {
                            context.read<SocietyBloc>().add(const LoadSocietyData());
                            await Future.delayed(const Duration(milliseconds: 600));
                          },
                        ),
                        if (rules.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No rules found.',
                                style: textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final rule = rules[index];
                                  IconData icon = Icons.rule_rounded;
                                  final lower = rule.title.toLowerCase();
                                  if (lower.contains('parking')) icon = Icons.directions_car_rounded;
                                  if (lower.contains('pet')) icon = Icons.pets_rounded;
                                  if (lower.contains('noise')) icon = Icons.volume_off_rounded;
                                  if (lower.contains('club')) icon = Icons.sports_tennis_rounded;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildRuleCard(context, textTheme, icon, rule.title, rule.description),
                                  );
                                },
                                childCount: rules.length,
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

  Widget _buildRulesSkeleton(BuildContext context) {
    return AsmitaSkeleton(
      isLoading: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                    AsmitaSkeleton.bone(width: 40, height: 40, borderRadius: 10),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AsmitaSkeleton.text(width: 160, height: 16, borderRadius: 4),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AsmitaSkeleton.text(width: double.infinity, height: 13, borderRadius: 3),
                const SizedBox(height: 6),
                AsmitaSkeleton.text(width: 200, height: 13, borderRadius: 3),
              ],
            ),
          );
        },
      ),
    );
  }
}
