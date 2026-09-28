import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/design_system.dart';
<<<<<<< HEAD
=======
import 'asmita_loading_indicator.dart';
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df

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

<<<<<<< HEAD
        return Container(
          color: AsmitaPalette.systemBG, // Locks the top overscroll color seamlessly
          alignment: Alignment.center,
=======
        return Center(
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
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
              
<<<<<<< HEAD
              // 2. Loading State: Clean, native activity spinner
              if (refreshState == RefreshIndicatorMode.refresh || refreshState == RefreshIndicatorMode.done)
                const CupertinoActivityIndicator(
                  color: AsmitaPalette.actionRed,
                  radius: 14,
=======
              // 2. Loading State: Branded spinning indicator
              if (refreshState == RefreshIndicatorMode.refresh)
                const AsmitaLoadingIndicator(
                  color: AsmitaPalette.actionRed,
                  size: 28,
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
                ),
            ],
          ),
        );
      },
    );
  }
}