import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/design_system.dart';

/// Full-screen in-app WebView for Setu BillPay (Ethereal).
///
/// Features:
/// - Exact native AsmitA AppBar (edge-to-edge, no curved card corners)
/// - Unified typography (Montserrat title, Poppins subtitle)
/// - Integrated iOS-style chevron back, reload, and close actions
/// - Native AppBar elevation & subtle baseline divider
/// - Progress indicator during web navigation
/// - Safe area management for Android 3-button and gesture navigation
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

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : theme.colorScheme.primary;
    final title = widget.categoryTitle ?? 'Bill Payments';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          foregroundColor: primaryColor,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
              size: 20,
            ),
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Secured by NPCI • Bharat BillPay',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: primaryColor,
                size: 20,
              ),
              onPressed: () => _controller.reload(),
              tooltip: 'Reload',
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: primaryColor,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2.5),
            child: _isLoading
                ? LinearProgressIndicator(
                    value: _loadProgress < 100 ? _loadProgress / 100 : null,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    color: AsmitaPalette.deepNavy,
                    minHeight: 2.5,
                  )
                : Container(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    height: 1,
                  ),
          ),
        ),
        body: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: _hasError
              ? _buildErrorView()
              : WebViewWidget(controller: _controller),
        ),
      ),
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
              'Unable to Load Bharat BillPay',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _controller.reload();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
