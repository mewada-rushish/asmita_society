import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../widgets/asmita_toast.dart';

/// Centralized Error & Retry Handler for screens, refresh actions, and buttons.
///
/// Features:
/// - Extracts clean, user-friendly messages from Dio, Network, and Server exceptions
/// - Shows consistent, themed toasts (`AsmitaToastType.error`, `AsmitaToastType.warning`)
/// - Provides a standard scrollable error widget with a retry button for full screens
class AppErrorHandler {
  static String extractMessage(dynamic error, [String fallback = 'Something went wrong. Please try again.']) {
    if (error == null) return fallback;

    if (error is DioException) {
      if (error.error is SocketException ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'No internet connection. Please check your network.';
      }

      final response = error.response;
      if (response != null) {
        final statusCode = response.statusCode;
        if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
          return 'Server is momentarily restarting or updating. Please try again.';
        }
        if (statusCode == 401 || statusCode == 403) {
          return 'Session expired or access denied. Please login again.';
        }
        final data = response.data;
        if (data is Map) {
          final msg = data['error'] ?? data['message'] ?? data['msg'];
          if (msg != null && msg.toString().isNotEmpty) {
            return msg.toString();
          }
        }
      }
    }

    if (error is SocketException) {
      return 'Network unavailable. Please check your connection.';
    }

    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }

    return fallback;
  }

  static void showErrorToast(BuildContext context, dynamic error, [String? fallback]) {
    final message = extractMessage(error, fallback ?? 'Something went wrong.');
    AsmitaToast.show(
      context,
      message: message,
      type: AsmitaToastType.error,
    );
  }

  /// Builds a standard scrollable full-screen error state with a retry button.
  /// Allows pull-to-refresh even when in error state.
  static Widget buildErrorView({
    required BuildContext context,
    required dynamic error,
    required Future<void> Function() onRetry,
    String? title,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final message = extractMessage(error);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFFBE123C).withValues(alpha: 0.4) : const Color(0xFFFECDD3),
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE11D48),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Failed to Load Content',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

