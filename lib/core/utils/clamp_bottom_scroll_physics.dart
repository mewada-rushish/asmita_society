import 'package:flutter/material.dart';

/// Custom scroll physics that bounces at the top but stops at the bottom.
/// 
/// This allows pull-to-refresh at the top while preventing the bottom layout
/// from stretching and showing background color gaps above the navigation bar.
class ClampBottomScrollPhysics extends BouncingScrollPhysics {
  const ClampBottomScrollPhysics({super.parent});

  @override
  ClampBottomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ClampBottomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Stop the scroll immediately if trying to overscroll past the bottom edge.
    if (value > position.pixels && position.pixels >= position.maxScrollExtent) {
      return value - position.pixels; 
    }
    
    // Hard-stop the movement exactly at the bottom limit during fast scrolling.
    if (value > position.maxScrollExtent && position.pixels < position.maxScrollExtent) {
      return value - position.maxScrollExtent; 
    }
    
    // Use normal bouncing physics for everything else (like top overscroll).
    return 0.0;
  }
}