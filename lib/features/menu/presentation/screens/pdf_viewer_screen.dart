import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:asmita_society/core/widgets/app_skeleton.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfViewerScreen({super.key, required this.title, required this.pdfUrl});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndPreparePdf();
  }

  Future<void> _downloadAndPreparePdf() async {
    if (widget.pdfUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = "Invalid document URL";
          _isLoading = false;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final tempDir = await getTemporaryDirectory();
      // Derive a deterministic filename based on url hash or basename
      final urlHash = widget.pdfUrl.hashCode.abs().toString();
      final sanitizedTitle = widget.title
          .replaceAll(RegExp(r'[^\w\s\-]'), '_')
          .trim();
      final baseName = sanitizedTitle.isNotEmpty ? sanitizedTitle : "document";
      final filePath = '${tempDir.path}/${baseName}_$urlHash.pdf';

      final file = File(filePath);
      if (!await file.exists() || await file.length() == 0) {
        await Dio().download(
          widget.pdfUrl,
          filePath,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _localFilePath = filePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load document: $e";
        });
      }
    }
  }

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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    tooltip: 'Share Document',
                    onPressed: _shareDocument,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.open_in_browser_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    tooltip: 'Open in Browser',
                    onPressed: _openInBrowser,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_localFilePath != null && _errorMessage == null)
                    PDFView(
                      filePath: _localFilePath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      defaultPage: _currentPage,
                      fitPolicy: FitPolicy.BOTH,
                      preventLinkNavigation: false,
                      onRender: (pages) {
                        if (mounted) {
                          setState(() {
                            _totalPages = pages ?? 0;
                            _isLoading = false;
                          });
                        }
                      },
                      onError: (error) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = error.toString();
                            _isLoading = false;
                          });
                        }
                      },
                      onPageError: (page, error) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = "Page $page error: $error";
                          });
                        }
                      },
                      onViewCreated: (PDFViewController vc) {},
                      onPageChanged: (int? page, int? total) {
                        if (mounted) {
                          setState(() {
                            _currentPage = page ?? 0;
                            _totalPages = total ?? 0;
                          });
                        }
                      },
                    ),

                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: theme.scaffoldBackgroundColor,
                        padding: const EdgeInsets.all(24),
                        child: AsmitaSkeleton(
                          isLoading: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AsmitaSkeleton.text(width: 220, height: 20),
                              const SizedBox(height: 16),
                              AsmitaSkeleton.text(width: double.infinity, height: 14),
                              const SizedBox(height: 8),
                              AsmitaSkeleton.text(width: double.infinity, height: 14),
                              const SizedBox(height: 8),
                              AsmitaSkeleton.text(width: 280, height: 14),
                              const SizedBox(height: 24),
                              Expanded(
                                child: AsmitaSkeleton.bone(
                                  width: double.infinity,
                                  height: double.infinity,
                                  borderRadius: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to display document preview',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                  onPressed: _downloadAndPreparePdf,
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.open_in_browser),
                                  label: const Text('Open Externally'),
                                  onPressed: _openInBrowser,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Floating page indicator
                  if (_totalPages > 0 && _errorMessage == null && !_isLoading)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentPage + 1} / $_totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.pdfUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareDocument() async {
    try {
      if (widget.pdfUrl.isEmpty) return;

      final filePath = _localFilePath;
      if (filePath != null && await File(filePath).exists()) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], text: widget.title),
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparing file to share...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = widget.title
          .replaceAll(RegExp(r'[^\w\s\-]'), '_')
          .trim();
      final downloadPath =
          '${tempDir.path}/${sanitizedTitle.isNotEmpty ? sanitizedTitle : "document"}.pdf';

      final file = File(downloadPath);
      if (!await file.exists()) {
        await Dio().download(widget.pdfUrl, downloadPath);
      }

      await SharePlus.instance.share(
        ShareParams(files: [XFile(downloadPath)], text: widget.title),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share document: $e')));
      }
    }
  }
}
