import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _errorMessage;
  int _pageNumber = 1;
  int _pageCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            AsmitaSubHeader(
              title: widget.title.isNotEmpty ? widget.title : 'Document Viewer',
              trailing: IconButton(
                icon: Icon(Icons.share_rounded, color: theme.colorScheme.primary),
                tooltip: 'Share Document',
                onPressed: _shareDocument,
              ),
            ),
            if (_pageCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page $_pageNumber of $_pageCount',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_in, size: 20),
                          tooltip: 'Zoom In',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                          },
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.zoom_out, size: 20),
                          tooltip: 'Zoom Out',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  if (widget.pdfUrl.isNotEmpty)
                    SfPdfViewer.network(
                      widget.pdfUrl,
                      controller: _pdfViewerController,
                      canShowScrollHead: true,
                      canShowScrollStatus: true,
                      enableDoubleTapZooming: true,
                      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                            _pageCount = details.document.pages.count;
                          });
                        }
                      },
                      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = details.description;
                          });
                        }
                      },
                      onPageChanged: (PdfPageChangedDetails details) {
                        if (mounted) {
                          setState(() {
                            _pageNumber = details.newPageNumber;
                          });
                        }
                      },
                    )
                  else
                    const Center(child: Text('Invalid document URL')),
                  if (_isLoading)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AsmitaLoadingIndicator(color: theme.colorScheme.primary, size: 36),
                          const SizedBox(height: 12),
                          Text('Loading document...', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load document',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareDocument() async {
    try {
      if (widget.pdfUrl.isEmpty) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing file to share...'), duration: Duration(seconds: 1)),
      );

      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = widget.title.replaceAll(RegExp(r'[^\w\s\-]'), '_').trim();
      final filePath = '${tempDir.path}/${sanitizedTitle.isNotEmpty ? sanitizedTitle : "document"}.pdf';

      final file = File(filePath);
      if (!await file.exists()) {
        await Dio().download(widget.pdfUrl, filePath);
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: widget.title,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share document: $e')),
        );
      }
    }
  }
}
