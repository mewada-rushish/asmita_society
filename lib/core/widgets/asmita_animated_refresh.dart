import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/design_system.dart';

/// Centralized modern radial pull-to-refresh sliver for AsmitA Society.
/// Displays a smooth, clean radial arc loader upon pull and active refresh.
class AsmitaAnimatedRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Color? color;

  const AsmitaAnimatedRefresh({
    super.key,
    required this.onRefresh,
    this.color,
  });

  @override
  State<AsmitaAnimatedRefresh> createState() => _AsmitaAnimatedRefreshState();
}

class _AsmitaAnimatedRefreshState extends State<AsmitaAnimatedRefresh> {
  bool _hasArmedHapticFired = false;
  bool _isClosing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radialColor = widget.color ?? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy);

    return CupertinoSliverRefreshControl(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        try {
          await widget.onRefresh();
        } finally {
          if (mounted) {
            setState(() {
              _isClosing = true;
            });
          }
        }
      },
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

        if (refreshState == RefreshIndicatorMode.inactive ||
            (refreshState == RefreshIndicatorMode.drag && pulledExtent <= 0.0)) {
          _isClosing = false;
        }

        if (refreshState == RefreshIndicatorMode.armed && !_hasArmedHapticFired) {
          _hasArmedHapticFired = true;
          HapticFeedback.selectionClick();
        } else if (refreshState == RefreshIndicatorMode.drag ||
            refreshState == RefreshIndicatorMode.inactive) {
          _hasArmedHapticFired = false;
        }

        final isRefreshing = refreshState == RefreshIndicatorMode.armed ||
            refreshState == RefreshIndicatorMode.refresh;
        final isDone = refreshState == RefreshIndicatorMode.done ||
            refreshState == RefreshIndicatorMode.inactive;

        if (_isClosing || isDone || (!isRefreshing && percentageComplete < 0.2)) {
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
}

/// A global, easy-to-use pull-to-refresh wrapper that provides the signature
/// Asmita animated preloader to any non-sliver screen or widget hierarchy.
class AsmitaPullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const AsmitaPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: physics ?? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        AsmitaAnimatedRefresh(onRefresh: onRefresh),
        if (padding != null)
          SliverPadding(
            padding: padding!,
            sliver: SliverToBoxAdapter(child: child),
          )
        else
          SliverToBoxAdapter(child: child),
      ],
    );
  }
}

/// Convenient sliver list wrapper featuring the signature Asmita pull-to-refresh preloader.
class AsmitaRefreshableListView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const AsmitaRefreshableListView({
    super.key,
    required this.onRefresh,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: physics ?? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        AsmitaAnimatedRefresh(onRefresh: onRefresh),
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: separatorBuilder != null
              ? SliverList.separated(
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                  separatorBuilder: separatorBuilder!,
                )
              : SliverList.builder(
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                ),
        ),
      ],
    );
  }
}