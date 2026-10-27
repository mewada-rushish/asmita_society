import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Universal, Production-Safe Logger for AsmitA
/// 
/// In `kDebugMode`:
///   Outputs formatted, tagged diagnostics to developer console.
/// In `kReleaseMode`:
///   Completely silent — zero bytes written to system logs (logcat / syslog)
///   to prevent PII or sensitive operational data exposure.
class AsmitaLogger {
  AsmitaLogger._();

  /// Logs general informational diagnostic messages (Debug mode only)
  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$tag] $message');
    }
  }

  /// Logs non-sensitive operational success events (Debug mode only)
  static void success(String tag, String message) {
    if (kDebugMode) {
      debugPrint('✅ [$tag] $message');
    }
  }

  /// Logs warnings (Debug mode only)
  static void warn(String tag, String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [$tag] $message');
    }
  }

  /// Logs an error gracefully.
  /// 
  /// In debug mode: prints stack trace to console.
  /// In release mode: passes non-fatal error and non-PII diagnostic metadata to Crashlytics.
  static void error(
    String tag,
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    if (kDebugMode) {
      debugPrint('❌ [$tag] Error: $error ${reason != null ? '($reason)' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }

    // Forward to Firebase Crashlytics if available in release/production
    try {
      if (reason != null) {
        FirebaseCrashlytics.instance.log('[$tag] $reason: $error');
      }
      if (metadata != null) {
        metadata.forEach((key, value) {
          if (value != null) {
            FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
          }
        });
      }
      if (error is Exception || error is Error) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: '[$tag] ${reason ?? error.toString()}',
          fatal: false,
        );
      }
    } catch (_) {
      // Best-effort in test/mock environments where Crashlytics is not initialized
    }
  }

  /// Adds a non-PII operational breadcrumb to Crashlytics (e.g. "guard_gate_opened", "visitor_approved")
  static void breadcrumb(String action, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      debugPrint('📍 [Breadcrumb] $action ${params != null ? params.toString() : ''}');
    }
    try {
      final paramStr = params != null ? ' ${params.toString()}' : '';
      FirebaseCrashlytics.instance.log('$action$paramStr');
    } catch (_) {}
  }
}
