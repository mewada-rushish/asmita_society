import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/design_system.dart';
import 'asmita_loading_indicator.dart';

/// A premium, globally reusable animated pull-to-refresh sliver.
/// Utilizes native Cupertino physics with haptic feedback and custom branded visuals.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBrandColor = widget.color ?? (isDark ? const Color(0xFFEF4444) : AsmitaPalette.actionRed);

    return CupertinoSliverRefreshControl(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await widget.onRefresh();
      },
      refreshTriggerPullDistance: 70.0,
      refreshIndicatorExtent: 56.0,
      builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
        final double percentageComplete = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

        // Fire single light haptic feedback once threshold is armed
        if (refreshState == RefreshIndicatorMode.armed && !_hasArmedHapticFired) {
          _hasArmedHapticFired = true;
          HapticFeedback.selectionClick();
        } else if (refreshState == RefreshIndicatorMode.drag || refreshState == RefreshIndicatorMode.inactive) {
          _hasArmedHapticFired = false;
        }

        final isRefreshing = refreshState == RefreshIndicatorMode.armed || refreshState == RefreshIndicatorMode.refresh;

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(
                color: isRefreshing
                    ? primaryBrandColor.withValues(alpha: 0.35)
                    : theme.dividerColor.withValues(alpha: (percentageComplete * 0.7).clamp(0.1, 0.7)),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : primaryBrandColor.withValues(alpha: (isRefreshing ? 0.18 : (percentageComplete * 0.12))),
                  blurRadius: isRefreshing ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Pulling State: Spins and scales proportionally with user gesture
                if (!isRefreshing)
                  Transform.rotate(
                    angle: percentageComplete * 6.283185307179586,
                    child: Opacity(
                      opacity: (percentageComplete * 1.3).clamp(0.2, 1.0),
                      child: Icon(
                        Icons.blur_on_rounded, // Branded dotted icon
                        color: primaryBrandColor,
                        size: 24 * (0.65 + (0.35 * percentageComplete)),
                      ),
                    ),
                  ),

                // 2. Armed & Refreshing State: Continuous spinning branded preloader
                if (isRefreshing)
                  AsmitaLoadingIndicator(
                    color: primaryBrandColor,
                    size: 24,
                  ),
              ],
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