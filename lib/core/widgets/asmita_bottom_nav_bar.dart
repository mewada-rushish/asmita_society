import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';

class AsmitaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? userRole;

  const AsmitaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    const double barHeight = 64.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            height: barHeight + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: isDark 
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.65) 
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _getVisibleIndices().map((index) {
            final isSelected = currentIndex == index;
            return _buildNavigationItem(context, index, isSelected);
          }).toList(),
        ),
          ),
        ),
      ),
    );
  }

  List<int> _getVisibleIndices() {
    if (userRole?.toLowerCase() == 'guard') {
      return [0, 6, 3, 5, 4]; // Home, Checked In, History, Scan, Menu
    }
    return [0, 1, 2, 3, 4]; // All tabs
  }

  Widget _buildNavigationItem(BuildContext context, int index, bool isSelected) {
    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 56,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // We use Opacity to handle the active/inactive state.
            // This prevents the ColorFilter from destroying your layered SVG strokes.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.4,
              child: _buildCustomScaledIcon(context, index),
            ),
            Positioned(
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 22,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomScaledIcon(BuildContext context, int index) {
    final iconColor = Theme.of(context).iconTheme.color ?? Colors.white;
    final colorFilter = ColorFilter.mode(iconColor, BlendMode.srcIn);

    switch (index) {
      case 0:
        return SvgPicture.asset('assets/icons/home.svg', width: 24, height: 24, colorFilter: colorFilter);
      case 1:
        return SvgPicture.asset('assets/icons/services.svg', width: 32, height: 32, colorFilter: colorFilter);
      case 2:
        return SvgPicture.asset('assets/icons/community.svg', width: 32, height: 32, colorFilter: colorFilter);
      case 3:
        return SvgPicture.asset('assets/icons/history.svg', width: 32, height: 32, colorFilter: colorFilter);
      case 5:
        return Icon(Icons.qr_code_scanner_rounded, size: 30, color: iconColor);
      case 6:
        return Icon(Icons.how_to_reg, size: 30, color: iconColor);
      case 4:
      default:
        return Icon(Icons.more_horiz_rounded, size: 32, color: iconColor);
    }
  }
}