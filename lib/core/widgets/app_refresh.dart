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

  Widget _buildRadialRefreshControl(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radialColor = widget.color ?? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy);

    return CupertinoSliverRefreshControl(
      onRefresh: _handleRefresh,
      refreshTriggerPullDistance: 70.0,
      refreshIndicatorExtent: 52.0,
      builder: (
        BuildContext context,
        RefreshIndicatorMode refreshState,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        final double percentageComplete = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
        final isRefreshing = refreshState == RefreshIndicatorMode.armed ||
            refreshState == RefreshIndicatorMode.refresh;
        final isDone = refreshState == RefreshIndicatorMode.done ||
            refreshState == RefreshIndicatorMode.inactive;

        if (isDone || (!isRefreshing && percentageComplete < 0.2)) {
          return const SizedBox.shrink();
        }

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: 22,
              height: 22,
              child: isRefreshing
                  ? CircularProgressIndicator(
                      strokeWidth: 2.4,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(radialColor),
                    )
                  : CircularProgressIndicator(
                      value: percentageComplete,
                      strokeWidth: 2.4,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(radialColor),
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSliver) {
      return _buildRadialRefreshControl(context);
    }

    final body = widget.padding != null
        ? Padding(padding: widget.padding!, child: widget.child!)
        : widget.child!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _buildRadialRefreshControl(context),
        SliverToBoxAdapter(
          child: body,
        ),
      ],
    );
  }
}

