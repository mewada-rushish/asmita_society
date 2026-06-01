import 'package:flutter/material.dart';

/// A custom [ScrollPhysics] that permits bouncing at the top edge 
/// while strictly clamping scroll forces at the bottom boundary.
class ClampBottomScrollPhysics extends BouncingScrollPhysics {
  const ClampBottomScrollPhysics({super.parent});

  @override
  ClampBottomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ClampBottomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Absorb 100% of the structural overscroll delta at the bottom boundary
    if (value > position.pixels && position.pixels >= position.maxScrollExtent) {
      return value - position.pixels; 
    }
    if (value > position.maxScrollExtent && position.pixels < position.maxScrollExtent) {
      return value - position.maxScrollExtent; 
    }
    return 0.0;
  }
}