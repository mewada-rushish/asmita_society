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
      refreshTriggerPullDistance: 65.0,
      refreshIndicatorExtent: 50.0,
      builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
        // Calculate the pull percentage to drive the custom animations
        final double percentageComplete = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Pulling State: Spins and fades in the brand icon as user pulls down
                if (refreshState == RefreshIndicatorMode.drag)
                  Transform.rotate(
                    angle: percentageComplete * 6.283185307179586,
                    child: Icon(
                      Icons.blur_on_rounded, // Branded dotted squircle
                      color: AsmitaPalette.actionRed.withValues(alpha: (percentageComplete * 1.2).clamp(0.2, 1.0)),
                      size: 28 * (0.6 + (0.4 * percentageComplete)),
                    ),
                  ),

                // 2. Armed & Refreshing State: Smooth continuous branded spinning animation
                if (refreshState == RefreshIndicatorMode.armed || refreshState == RefreshIndicatorMode.refresh)
                  const AsmitaLoadingIndicator(
                    color: AsmitaPalette.actionRed,
                    size: 28,
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