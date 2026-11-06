import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfViewerScreen({super.key, required this.title, required this.pdfUrl});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    if (widget.pdfUrl.isEmpty) {
      _errorMessage = "Invalid document URL";
      _isLoading = false;
      return;
    }

    // Google Docs Viewer renders PDFs seamlessly without requiring native device_info or binary plugins
    final googleDocsViewerUrl =
        'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.pdfUrl)}';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(googleDocsViewerUrl));
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
                  if (_errorMessage == null)
                    WebViewWidget(controller: _webViewController),
                  if (_isLoading)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AsmitaLoadingIndicator(
                            color: theme.colorScheme.primary,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Rendering document...',
                            style: theme.textTheme.bodyMedium,
                          ),
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
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('Open in Browser'),
                              onPressed: _openInBrowser,
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

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.pdfUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareDocument() async {
    try {
      if (widget.pdfUrl.isEmpty) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing file to share...'),
          duration: Duration(seconds: 1),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = widget.title
          .replaceAll(RegExp(r'[^\w\s\-]'), '_')
          .trim();
      final filePath =
          '${tempDir.path}/${sanitizedTitle.isNotEmpty ? sanitizedTitle : "document"}.pdf';

      final file = File(filePath);
      if (!await file.exists()) {
        await Dio().download(widget.pdfUrl, filePath);
      }

      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: widget.title),
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
