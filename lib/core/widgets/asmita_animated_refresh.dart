import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/design_system.dart';
import 'asmita_loading_indicator.dart';

/// A premium, globally reusable animated pull-to-refresh sliver.
/// Utilizes native Cupertino physics for a buttery-smooth inline stretch effect.
class AsmitaAnimatedRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const AsmitaAnimatedRefresh({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      refreshTriggerPullDistance: 30.0,
      refreshIndicatorExtent: 30.0,
      builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
        // Calculate the pull percentage to drive the custom animations
        final double percentageComplete = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Pulling State: Spins and fades in the brand icon
              if (refreshState == RefreshIndicatorMode.drag || refreshState == RefreshIndicatorMode.armed)
                Transform.rotate(
                  angle: percentageComplete * 6.28, // Full 360 rotation as they pull
                  child: Icon(
                    Icons.blur_on_rounded, // Brand Icon Placeholder
                    color: AsmitaPalette.actionRed.withValues(alpha: percentageComplete),
                    size: 28 * percentageComplete,
                  ),
                ),
              
              // 2. Loading State: Branded spinning indicator
              if (refreshState == RefreshIndicatorMode.refresh)
                const AsmitaLoadingIndicator(
                  color: AsmitaPalette.actionRed,
                  size: 28,
                ),
            ],
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