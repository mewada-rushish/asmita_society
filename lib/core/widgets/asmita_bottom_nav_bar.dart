import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/design_system.dart';

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: AsmitaPalette.deepNavy,
          height: barHeight + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _getVisibleIndices().map((index) {
              final isSelected = currentIndex == index;
              return _buildNavigationItem(index, isSelected);
            }).toList(),
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

  Widget _buildNavigationItem(int index, bool isSelected) {
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
              child: _buildCustomScaledIcon(index),
            ),
            Positioned(
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 22,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: AsmitaPalette.actionRed,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomScaledIcon(int index) {
    switch (index) {
      case 0:
        return SvgPicture.asset('assets/icons/home.svg', width: 24, height: 24);
      case 1:
        return SvgPicture.asset('assets/icons/services.svg', width: 32, height: 32);
      case 2:
        return SvgPicture.asset('assets/icons/community.svg', width: 32, height: 32);
      case 3:
        return SvgPicture.asset('assets/icons/history.svg', width: 32, height: 32);
      case 5:
        return const Icon(Icons.qr_code_scanner_rounded, size: 30, color: Colors.white);
      case 6:
        return const Icon(Icons.how_to_reg, size: 30, color: Colors.white);
      case 4:
      default:
        return const Icon(Icons.more_horiz_rounded, size: 32, color: Colors.white);
    }
  }
}