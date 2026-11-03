import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/menu/bloc/society_bloc.dart';
import 'package:asmita_society/features/menu/bloc/society_event.dart';
import 'package:asmita_society/features/menu/bloc/society_state.dart';
import 'package:asmita_society/features/menu/data/repositories/society_repository.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/core/di/injection_container.dart' as di;

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

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
            child: const _DocumentsScreenBody(),
          );
        }

        // Trigger load if still initial
        if (ctx.read<SocietyBloc>().state is SocietyInitial) {
          ctx.read<SocietyBloc>().add(const LoadSocietyData());
        }

        return const _DocumentsScreenBody();
      },
    );
  }
}

class _DocumentsScreenBody extends StatelessWidget {
  const _DocumentsScreenBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Important Documents'),
            Expanded(
              child: BlocBuilder<SocietyBloc, SocietyState>(
                builder: (context, societyState) {
                  if (societyState is SocietyLoading || societyState is SocietyInitial) {
                    return Center(child: AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.primary, size: 28));
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
                    final docs = societyState.documents;
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        AsmitaAnimatedRefresh(
                          onRefresh: () async {
                            context.read<SocietyBloc>().add(const LoadSocietyData());
                            await Future.delayed(const Duration(milliseconds: 600));
                          },
                        ),
                        if (docs.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No documents found.',
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
                                  final doc = docs[index];
                                  final dateStr = doc.uploadedAt != null
                                      ? AppDateFormatter.formatDate(doc.uploadedAt!)
                                      : 'Unknown Date';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildDocumentCard(context, textTheme, doc.title, 'Updated: $dateStr', 'Available'),
                                  );
                                },
                                childCount: docs.length,
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

  Widget _buildDocumentCard(BuildContext context, TextTheme textTheme, String title, String date, String size) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.picture_as_pdf_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(date, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(size, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download_rounded, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              // Open fileUrl logic
            },
          ),
        ],
      ),
    );
  }
}
