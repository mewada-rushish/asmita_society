import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Centralized Skeleton Module for AsmitA Society & Industrial.
///
/// Features:
/// - Theme-aware shimmer (derives colors from ColorScheme/AsmitaPalette)
/// - Respects `MediaQuery.accessibleNavigationOf(context)` (reduced motion -> static pulse/solid)
/// - Single semantic label "Loading content" with `ExcludeSemantics` on children
/// - Configured with consistent shimmer duration (~1200ms) and smooth transitions
class AsmitaSkeleton extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final bool ignoreContainers;
  final Color? baseColor;
  final Color? highlightColor;

  const AsmitaSkeleton({
    super.key,
    required this.child,
    this.isLoading = true,
    this.ignoreContainers = false,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prefersReducedMotion = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;

    final effectiveBase = baseColor ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final effectiveHighlight = highlightColor ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC));

    return Semantics(
      label: 'Loading content',
      child: ExcludeSemantics(
        child: Skeletonizer(
          enabled: true,
          ignoreContainers: ignoreContainers,
          effect: prefersReducedMotion
              ? SolidColorEffect(color: effectiveBase)
              : ShimmerEffect(
                  baseColor: effectiveBase,
                  highlightColor: effectiveHighlight,
                  duration: const Duration(milliseconds: 1200),
                ),
          child: child,
        ),
      ),
    );
  }

  /// Helper placeholder for list items with realistic sizing
  static Widget bone({
    double? width,
    required double height,
    dynamic borderRadius = 8.0,
    EdgeInsetsGeometry? margin,
  }) {
    BorderRadius effectiveRadius;
    if (borderRadius is BorderRadius) {
      effectiveRadius = borderRadius;
    } else if (borderRadius is num) {
      effectiveRadius = BorderRadius.circular(borderRadius.toDouble());
    } else {
      effectiveRadius = BorderRadius.circular(8.0);
    }
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: effectiveRadius,
      ),
    );
  }

  /// Circular bone for avatars, icon placeholders, buttons
  static Widget circle({
    required double size,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Text bar bone for typography placeholders
  static Widget text({
    double? width,
    required double height,
    double borderRadius = 4.0,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Pill badge bone for tags, categories, and status chips
  static Widget pill({
    required double width,
    required double height,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
