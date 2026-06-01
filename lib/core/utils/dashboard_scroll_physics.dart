import 'package:flutter/material.dart';
import 'package:asmita_society/core/utils/clamp_bottom_scroll_physics.dart';

class DashboardScrollPhysics extends ClampBottomScrollPhysics {
  final double junctionOffset;

  const DashboardScrollPhysics({
    super.parent,
    required this.junctionOffset,
  });

  @override
  DashboardScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return DashboardScrollPhysics(
      parent: buildParent(ancestor),
      junctionOffset: junctionOffset,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Free scroll zone when reading the feed below the boundary line
    if (position.pixels > junctionOffset) {
      return super.applyPhysicsToUserOffset(position, offset);
    }

    // Free scroll zone while the sheet moves until the entry module is fully exposed at the bottom edge
    if (position.pixels > 200.0) {
      return super.applyPhysicsToUserOffset(position, offset);
    }

    // Heavy friction applies only near the absolute open/close limits
    return super.applyPhysicsToUserOffset(position, offset) * 0.12;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange) return super.createBallisticSimulation(position, velocity);

    if (position.pixels > 0.0 && position.pixels < junctionOffset) {
      final double target;
      if (velocity.abs() > 300.0) {
        target = velocity > 0 ? junctionOffset : 0.0;
      } else {
        target = position.pixels > 200.0 ? junctionOffset : 0.0;
      }
      return ScrollSpringSimulation(
        spring, position.pixels, target, velocity, tolerance: toleranceFor(position),
      );
    }

    return super.createBallisticSimulation(position, velocity);
  }
}