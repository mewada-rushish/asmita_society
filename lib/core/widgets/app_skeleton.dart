import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../constants/design_system.dart';

/// Centralized Skeleton Module for AsmitA Society & Industrial.
/// Strictly follows SAP Fiori iOS Skeleton Loading guidelines:
/// - Structural content placeholders (avatars, text bars, pills, card shells)
/// - Subtly contrasting shimmer effect (8-10% opacity difference)
/// - Cards and surfaces keep real containers, borders, and shadows (ignoreContainers: true)
/// - Respects `MediaQuery.accessibleNavigationOf(context)` (reduced motion -> static solid effect)
/// - Preserves spatial layout without cumulative layout shifts (CLS = 0)
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
    this.ignoreContainers = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prefersReducedMotion = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;

    // SAP Fiori iOS standard dual-theme shimmer colors:
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

  /// Helper placeholder for general bone with realistic sizing
  static Widget bone({
    double? width,
    required double height,
    dynamic borderRadius = 8.0,
    EdgeInsetsGeometry? margin,
  }) {
    BorderRadiusGeometry effectiveRadius;
    if (borderRadius is BorderRadiusGeometry) {
      effectiveRadius = borderRadius;
    } else if (borderRadius is num) {
      effectiveRadius = BorderRadius.circular(borderRadius.toDouble());
    } else {
      effectiveRadius = BorderRadius.circular(8.0);
    }
    final boneWidget = Bone(
      width: width,
      height: height,
      borderRadius: effectiveRadius,
    );
    if (margin != null) {
      return Padding(padding: margin, child: boneWidget);
    }
    return boneWidget;
  }

  /// Circular bone for avatars, icon placeholders, buttons
  static Widget circle({
    required double size,
    EdgeInsetsGeometry? margin,
  }) {
    final circleWidget = Bone.circle(size: size);
    if (margin != null) {
      return Padding(padding: margin, child: circleWidget);
    }
    return circleWidget;
  }

  /// Text bar bone for typography placeholders (SAP Fiori 4px corner radius)
  static Widget text({
    double? width,
    required double height,
    double borderRadius = 4.0,
    EdgeInsetsGeometry? margin,
  }) {
    final textWidget = Bone(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(borderRadius),
    );
    if (margin != null) {
      return Padding(padding: margin, child: textWidget);
    }
    return textWidget;
  }

  /// Pill badge bone for tags, categories, and status chips
  static Widget pill({
    required double width,
    required double height,
    EdgeInsetsGeometry? margin,
  }) {
    final pillWidget = Bone(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
    if (margin != null) {
      return Padding(padding: margin, child: pillWidget);
    }
    return pillWidget;
  }

  /// Standard SAP Fiori iOS card container shell with natural surface and subtle border
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double borderRadius = 16.0,
    Color? surfaceColor,
    Color? borderColor,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: surfaceColor ?? (isDark ? AsmitaPalette.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ??
                  (isDark ? AsmitaPalette.borderGreyDark : Colors.grey.withValues(alpha: 0.15)),
              width: 1.0,
            ),
          ),
          child: child,
        );
      },
    );
  }

  /// Standard SAP Fiori iOS list tile skeleton (avatar, title, subtitle, trailing badge)
  static Widget listTile({
    double avatarSize = 44.0,
    double titleWidth = 140.0,
    double titleHeight = 15.0,
    double subtitleWidth = 90.0,
    double subtitleHeight = 12.0,
    Widget? leading,
    Widget? trailing,
    EdgeInsetsGeometry? margin = const EdgeInsets.only(bottom: 12),
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    return card(
      margin: margin,
      padding: padding,
      child: Row(
        children: [
          leading ?? circle(size: avatarSize),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                text(width: titleWidth, height: titleHeight, borderRadius: 4),
                const SizedBox(height: 8),
                text(width: subtitleWidth, height: subtitleHeight, borderRadius: 3),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  /// SAP Fiori iOS Community Post / Notice Card Skeleton
  static Widget postCard({
    EdgeInsetsGeometry? margin = const EdgeInsets.only(bottom: 14),
  }) {
    return card(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              circle(size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text(width: 130, height: 14, borderRadius: 4),
                    const SizedBox(height: 6),
                    text(width: 80, height: 11, borderRadius: 3),
                  ],
                ),
              ),
              pill(width: 70, height: 22),
            ],
          ),
          const SizedBox(height: 14),
          text(width: double.infinity, height: 15, borderRadius: 4),
          const SizedBox(height: 8),
          text(width: 240, height: 13, borderRadius: 4),
          const SizedBox(height: 6),
          text(width: 160, height: 13, borderRadius: 4),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              pill(width: 80, height: 24),
              bone(width: 60, height: 20, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }

  /// SAP Fiori iOS Visitor Pass / Approval Queue Card Skeleton
  /// Accurately mirrors [AsmitaVisitorCard]:
  /// - Top row: Squircle avatar (48x48, r:16) + Name text line + Subtitle text line + Status Pill
  /// - Inset meta matrix box (2 rows with dividers: Time & Date, Location/Gate, Pass Code, Status)
  /// - Bottom action button pills
  static Widget visitorCard({
    EdgeInsetsGeometry? margin = const EdgeInsets.only(bottom: 12),
    bool showActions = true,
  }) {
    return card(
      margin: margin,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top row: Avatar + Title & Subtitle + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              bone(width: 48, height: 48, borderRadius: 16),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text(width: 140, height: 16, borderRadius: 4),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        pill(width: 70, height: 18),
                        const SizedBox(width: 6),
                        text(width: 80, height: 12, borderRadius: 3),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              pill(width: 68, height: 26),
            ],
          ),

          // 2. Inset Meta Matrix Box
          Container(
            margin: const EdgeInsets.only(top: 13),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(width: 55, height: 9, borderRadius: 2),
                          const SizedBox(height: 4),
                          text(width: 85, height: 12, borderRadius: 3),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(width: 65, height: 9, borderRadius: 2),
                          const SizedBox(height: 4),
                          text(width: 75, height: 12, borderRadius: 3),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(width: 50, height: 9, borderRadius: 2),
                          const SizedBox(height: 4),
                          text(width: 90, height: 12, borderRadius: 3),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(width: 40, height: 9, borderRadius: 2),
                          const SizedBox(height: 4),
                          text(width: 60, height: 12, borderRadius: 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Bottom Action Buttons
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: bone(height: 40, borderRadius: 12)),
                const SizedBox(width: 10),
                Expanded(child: bone(height: 40, borderRadius: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// SAP Fiori iOS KPI Metric Card Skeleton
  static Widget metricCard({
    double? width,
    double height = 80,
    EdgeInsetsGeometry? margin,
  }) {
    return card(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SizedBox(
        width: width,
        height: height - 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            text(width: 36, height: 22, borderRadius: 4),
            const SizedBox(height: 6),
            text(width: 64, height: 11, borderRadius: 3),
          ],
        ),
      ),
    );
  }

  /// SAP Fiori iOS Hero / Campus Banner Skeleton
  static Widget bannerCard({
    double height = 90,
    EdgeInsetsGeometry? margin,
  }) {
    return card(
      margin: margin,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                text(width: 140, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                text(width: 90, height: 12, borderRadius: 3),
              ],
            ),
          ),
          circle(size: 48),
        ],
      ),
    );
  }
}
