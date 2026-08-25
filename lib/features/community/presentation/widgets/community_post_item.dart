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

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
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
                mainAxisSize: MainAxisSize.min,
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
                          title: '', // We will use a custom header in the child
                          isScrollControlled: true,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: _ScrollableQuillContent(
                              quillController: quillController,
                              post: post,
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
      ),
    );
  }
}

class _ScrollableQuillContent extends StatefulWidget {
  final QuillController quillController;
  final CommunityPostModel post;
  
  const _ScrollableQuillContent({
    required this.quillController,
    required this.post,
  });

  @override
  State<_ScrollableQuillContent> createState() => _ScrollableQuillContentState();
}

class _ScrollableQuillContentState extends State<_ScrollableQuillContent> {
  final ScrollController _scrollController = ScrollController();
  bool _showArrow = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollable() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.maxScrollExtent <= 0) {
        if (_showArrow) setState(() => _showArrow = false);
      } else {
        _onScroll();
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isAtBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 10;
    if (isAtBottom && _showArrow) {
      setState(() => _showArrow = false);
    } else if (!isAtBottom && !_showArrow) {
      setState(() => _showArrow = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Header inside the modal
            Text(
              widget.post.title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, size: 20, color: AsmitaPalette.actionRed),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.authorName,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      DateFormat('MMMM d, yyyy • hh:mm a').format(widget.post.createdAt),
                      style: textTheme.bodySmall?.copyWith(color: AsmitaPalette.textLight, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AsmitaPalette.borderGrey, height: 1),
            const SizedBox(height: 16),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 40), // Extra padding for the fade/arrow
                child: QuillEditor.basic(
                  controller: widget.quillController,
                  config: const QuillEditorConfig(
                    scrollable: false,
                    expands: false,
                    padding: EdgeInsets.zero,
                    showCursor: false,
                    autoFocus: false,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Premium Bottom Fade Effect
        if (_showArrow)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
        // Floating Scroll Down Indicator
        if (_showArrow)
          Positioned(
            bottom: 12,
            right: 0,
            left: 0,
            child: GestureDetector(
              onTap: () {
                if (_scrollController.hasClients) {
                  final target = (_scrollController.offset + 250).clamp(
                    0.0,
                    _scrollController.position.maxScrollExtent,
                  );
                  _scrollController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AsmitaPalette.borderGrey),
                    boxShadow: [
                      BoxShadow(
                        color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Read More',
                        style: textTheme.labelSmall?.copyWith(
                          color: AsmitaPalette.deepNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.deepNavy, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
