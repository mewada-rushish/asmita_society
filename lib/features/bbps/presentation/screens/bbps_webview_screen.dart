import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_primary_header.dart';

/// Full-screen in-app WebView for Setu BillPay (Ethereal).
///
/// Features:
/// - Exact AsmitaPrimaryHeader component as-is (curved corners, branding, search, hotlines, avatar)
/// - Intercepts Setu's root "Pay bills" category screen and returns to native BBPS screen
/// - Smart back navigation: pops directly to native app from top-level biller list
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
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (_isRootCategoriesUrl(request.url)) {
              _exitToNativeBbps();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null && _isRootCategoriesUrl(change.url!)) {
              _exitToNativeBbps();
            }
          },
          onPageStarted: (url) {
            if (_isRootCategoriesUrl(url)) {
              _exitToNativeBbps();
              return;
            }
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

  /// Detects whether the URL points to Setu's root "Pay bills" category picker
  /// (e.g. `https://billpay.setu.co/{sessionId}` or `https://billpay.setu.co/{sessionId}/`).
  /// When true, we return to the app's native BBPS screen instead of loading Setu's category list.
  bool _isRootCategoriesUrl(String url) {
    if (widget.categoryTitle == null) return false;
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      // Setu category URLs have 3+ segments: /{sessionId}/billers/{category}
      // Root category screen has <= 1 segment: /{sessionId}
      if (segments.length <= 1) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _exitToNativeBbps() {
    if (_isExiting) return;
    _isExiting = true;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleBack() async {
    try {
      final currentUrl = await _controller.currentUrl();
      if (currentUrl != null) {
        final uri = Uri.parse(currentUrl);
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        // If user is on the top-level biller selection list (length <= 3, e.g. /{sessionId}/billers/{category}),
        // going back should return directly to our app's native BBPS screen!
        if (segments.length <= 3) {
          _exitToNativeBbps();
          return;
        }
      }
    } catch (_) {}

    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else {
      _exitToNativeBbps();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitle = widget.categoryTitle != null
        ? '${widget.categoryTitle} • BBPS'
        : 'Bill Payments (BBPS)';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        body: Stack(
          children: [
            // 1. WebView taking full screen underneath the floating header
            Positioned.fill(
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                bottom: true,
                child: _hasError
                    ? _buildErrorView()
                    : WebViewWidget(controller: _controller),
              ),
            ),

            // 2. Exact AsmitA Primary Header sitting directly on top of the webview
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AsmitaPrimaryHeader(
                    showBackButton: true,
                    onBackPressed: _handleBack,
                    subtitleOverride: subtitle,
                    allowPropertySwitching: false,
                    bottomPadding: 0.0,
                    isCurved: true,
                    backgroundColor: Colors.transparent,
                  ),

                  // Linear loading indicator during web navigation
                  if (_isLoading)
                    LinearProgressIndicator(
                      value: _loadProgress < 100 ? _loadProgress / 100 : null,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      color: AsmitaPalette.deepNavy,
                      minHeight: 2.5,
                    ),
                ],
              ),
            ),
          ],
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
