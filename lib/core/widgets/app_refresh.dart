import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/design_system.dart';

/// Centralized, standard pull-to-refresh wrapper for AsmitA Society.
///
/// Features:
/// - Built on `RefreshIndicator.adaptive`
/// - Forces `AlwaysScrollableScrollPhysics` so short lists, empty states, and errors can always be refreshed
/// - Awaits the real fetch with a `try/finally` block
/// - Enforces ~600ms minimum visibility to prevent jarring flash of indicator
/// - Debounces rapid triggers
/// - Provides a subtle haptic feedback (`HapticFeedback.lightImpact()`) upon trigger
class AppRefresh extends StatefulWidget {
  final Widget? child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;
  final EdgeInsetsGeometry? padding;
  final ScrollNotificationPredicate? notificationPredicate;
  final bool isSliver;

  const AppRefresh({
    super.key,
    required Widget this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.padding,
    this.notificationPredicate,
  }) : isSliver = false;

  const AppRefresh.sliver({
    super.key,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.padding,
    this.notificationPredicate,
  })  : child = null,
        isSliver = true;

  @override
  State<AppRefresh> createState() => _AppRefreshState();
}

class _AppRefreshState extends State<AppRefresh> {
  bool _isRefreshing = false;
  DateTime _lastRefreshTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _handleRefresh() async {
    final now = DateTime.now();
    // Debounce triggers within 600ms
    if (_isRefreshing || now.difference(_lastRefreshTime).inMilliseconds < 600) {
      return;
    }

    _isRefreshing = true;
    _lastRefreshTime = now;
    HapticFeedback.lightImpact();

    final stopwatch = Stopwatch()..start();
    try {
      await widget.onRefresh();
    } finally {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 600) {
        await Future.delayed(Duration(milliseconds: 600 - elapsed));
      }
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = widget.color ?? AsmitaPalette.deepNavy;
    final effectiveBg = widget.backgroundColor ??
        (isDark ? const Color(0xFF1E293B) : Colors.white);

    if (widget.isSliver) {
      return CupertinoSliverRefreshControl(
        onRefresh: _handleRefresh,
      );
    }

    final body = widget.padding != null
        ? Padding(padding: widget.padding!, child: widget.child!)
        : widget.child!;

    return RefreshIndicator.adaptive(
      onRefresh: _handleRefresh,
      color: effectiveColor,
      backgroundColor: effectiveBg,
      displacement: widget.displacement,
      edgeOffset: widget.edgeOffset,
      notificationPredicate: widget.notificationPredicate ?? defaultScrollNotificationPredicate,
      child: body is ScrollView
          ? body
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: body,
            ),
    );
  }
}

