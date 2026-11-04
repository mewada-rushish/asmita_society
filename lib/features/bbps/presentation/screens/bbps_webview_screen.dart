import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/design_system.dart';

/// Full-screen in-app WebView for Setu BillPay (Ethereal).
///
/// Opens the Setu session link inside the app so the user stays within the
/// AsmitA context instead of bouncing to an external browser.
/// Shows a branded progress bar while the page loads.
class BbpsWebViewScreen extends StatefulWidget {
  final String sessionUrl;
  final String? categoryTitle;

  const BbpsWebViewScreen({
    super.key,
    required this.sessionUrl,
    this.categoryTitle,
  });

  static Future<void> open(
    BuildContext context, {
    required String sessionUrl,
    String? categoryTitle,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BbpsWebViewScreen(
          sessionUrl: sessionUrl,
          categoryTitle: categoryTitle,
        ),
      ),
    );
  }

  @override
  State<BbpsWebViewScreen> createState() => _BbpsWebViewScreenState();
}

class _BbpsWebViewScreenState extends State<BbpsWebViewScreen> {
  late final WebViewController _controller;
  int _loadProgress = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadProgress = progress);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.sessionUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = widget.categoryTitle != null
        ? '${widget.categoryTitle} • BBPS'
        : 'Bill Payments (BBPS)';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Secured by NPCI • Bharat BillPay',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
            tooltip: 'Reload',
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadProgress < 100 ? _loadProgress / 100 : null,
                  backgroundColor: Colors.transparent,
                  color: AsmitaPalette.deepNavy,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: _hasError ? _buildErrorView() : WebViewWidget(controller: _controller),
    );
  }

  Widget _buildErrorView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not connect to\nBharat BillPay Gateway',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your network connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _controller.reload();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
