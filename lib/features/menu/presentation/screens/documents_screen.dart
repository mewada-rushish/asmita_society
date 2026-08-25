import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';
import 'package:asmita_society/features/menu/presentation/providers/society_provider.dart';
import 'package:intl/intl.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final docsState = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: SafeArea(
        child: Column(
          children: [
            const AsmitaSubHeader(title: 'Important Documents'),
            Expanded(
              child: docsState.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return Center(
                      child: Text('No documents found.', style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.textLight)),
                    );
                  }
                  return ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final dateStr = doc.uploadedAt != null 
                        ? DateFormat('dd MMM yyyy').format(doc.uploadedAt!)
                        : 'Unknown Date';
                        
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDocumentCard(textTheme, doc.title, 'Updated: $dateStr', 'Available'),
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

  Widget _buildDocumentCard(TextTheme textTheme, String title, String date, String size) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AsmitaPalette.actionRed, size: 28),
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
                    Text(date, style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight)),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: AsmitaPalette.borderGrey, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(size, style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AsmitaPalette.deepNavy),
            onPressed: () {
              // Open fileUrl logic
            },
          ),
        ],
      ),
    );
  }
}
