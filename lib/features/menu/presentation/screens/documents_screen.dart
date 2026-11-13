import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:asmita_society/core/widgets/app_skeleton.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';
import 'package:asmita_society/features/menu/bloc/society_bloc.dart';
import 'package:asmita_society/features/menu/bloc/society_event.dart';
import 'package:asmita_society/features/menu/bloc/society_state.dart';
import 'package:asmita_society/features/menu/data/repositories/society_repository.dart';
import 'package:asmita_society/features/menu/data/models/society_document_model.dart';
import 'package:asmita_society/features/menu/presentation/screens/pdf_viewer_screen.dart';
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
              : SocietyRepository(
                  dio: AsmitaDioClient(SecureStorageService()).dio,
                );
          return BlocProvider<SocietyBloc>(
            create: (_) =>
                SocietyBloc(repository: repo)..add(const LoadSocietyData()),
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
                  if (societyState is SocietyLoading ||
                      societyState is SocietyInitial) {
                    return _buildDocumentsSkeleton(context);
                  } else if (societyState is SocietyError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${societyState.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<SocietyBloc>().add(
                              const LoadSocietyData(),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (societyState is SocietyLoaded) {
                    final docs = societyState.documents;
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        AsmitaAnimatedRefresh(
                          onRefresh: () async {
                            context.read<SocietyBloc>().add(
                              const LoadSocietyData(),
                            );
                            await Future.delayed(
                              const Duration(milliseconds: 600),
                            );
                          },
                        ),
                        if (docs.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 56,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No documents uploaded yet',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Policies and notices will appear here once published.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final doc = docs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _DocumentCard(doc: doc),
                                );
                              }, childCount: docs.length),
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

  Widget _buildDocumentsSkeleton(BuildContext context) {
    return AsmitaSkeleton(
      isLoading: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // PDF Badge Icon bone
                AsmitaSkeleton.bone(width: 48, height: 48, borderRadius: 12),
                const SizedBox(width: 14),
                // Title and Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AsmitaSkeleton.text(width: 160, height: 15, borderRadius: 4),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AsmitaSkeleton.circle(size: 13),
                          const SizedBox(width: 4),
                          AsmitaSkeleton.text(width: 110, height: 12, borderRadius: 3),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions (View pill + Download circle)
                AsmitaSkeleton.pill(width: 54, height: 28),
                const SizedBox(width: 8),
                AsmitaSkeleton.circle(size: 28),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final SocietyDocumentModel doc;

  const _DocumentCard({required this.doc});

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Recently Updated';
    try {
      final local = dt.toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(local);
    } catch (_) {
      return 'Recently Updated';
    }
  }

  void _openInAppViewer(BuildContext context) {
    if (doc.fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document file URL is not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(title: doc.title, pdfUrl: doc.fileUrl),
      ),
    );
  }

  Future<void> _downloadOrLaunch(BuildContext context) async {
    if (doc.fileUrl.isEmpty) return;
    final uri = Uri.tryParse(doc.fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final dateFormatted = _formatDateTime(doc.uploadedAt);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openInAppViewer(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF1E293B).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // PDF Badge Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFDC2626),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      doc.title.isNotEmpty ? doc.title : 'Untitled Document',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: textTheme.bodySmall?.color?.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateFormatted,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: textTheme.bodySmall?.color?.withValues(
                                alpha: 0.75,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Quick Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View In-App Pill Button
                  InkWell(
                    onTap: () => _openInAppViewer(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // External Download Button
                  IconButton(
                    icon: Icon(
                      Icons.download_rounded,
                      color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    tooltip: 'Download or Open in external app',
                    splashRadius: 18,
                    onPressed: () => _downloadOrLaunch(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
