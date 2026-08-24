import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/community/data/models/community_post_model.dart';
import 'package:intl/intl.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';

class CommunityPostItem extends StatelessWidget {
  final CommunityPostModel post;

  const CommunityPostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    // Parse Quill document from JSON
    Document? doc;
    try {
      final decoded = jsonDecode(post.contentJson);
      doc = Document.fromJson(decoded);
    } catch (e) {
      doc = Document()..insert(0, post.contentJson);
    }

    final quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    final plainText = doc.toPlainText().trim();
    final isLong = plainText.length > 100 || plainText.split('\n').length > 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AsmitaPalette.actionRed.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(10)
            ),
            child: const Icon(Icons.assignment_outlined, color: AsmitaPalette.actionRed, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(post.title, style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      DateFormat('MMM d, hh:mm a').format(post.createdAt),
                      style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!isLong)
                  QuillEditor.basic(
                    controller: quillController,
                    config: const QuillEditorConfig(
                      scrollable: false,
                      expands: false,
                      padding: EdgeInsets.zero,
                      showCursor: false,
                      autoFocus: false,
                    ),
                  )
                else ...[
                  Text(
                    plainText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      showAsmitaBottomSheet(
                        context: context,
                        title: post.title,
                        isScrollControlled: true,
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: QuillEditor.basic(
                                  controller: quillController,
                                  config: const QuillEditorConfig(
                                    scrollable: true,
                                    expands: true,
                                    padding: EdgeInsets.all(16),
                                    showCursor: false,
                                    autoFocus: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Know More',
                      style: textTheme.bodySmall?.copyWith(
                        color: AsmitaPalette.deepNavy,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'By ${post.authorName}',
                  style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AsmitaPalette.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
