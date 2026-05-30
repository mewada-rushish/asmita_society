import 'package:flutter/material.dart';
import '../constants/design_system.dart'; // Adjust import path as needed

class AsmitaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AsmitaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // The globally defined icons for the 4 core modules
  final List<IconData> _icons = const [
    Icons.home_work_outlined,
    Icons.domain_outlined,
    Icons.people_alt_outlined,
    Icons.more_horiz_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    // Read raw system insets unaffected by Scaffold padding injection
    // This ensures the bar sits perfectly above the system navigation buttons (pill/triangle)
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
            children: List.generate(_icons.length, (index) {
              final isSelected = currentIndex == index;
              return _buildNavigationItem(index, isSelected);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(int index, bool isSelected) {
    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 64,
        // Force the item to take the full height of the row so bottom: 0 is exactly at the edge
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Tab Icon
            Icon(
              _icons[index],
              color: isSelected 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.4),
              size: 26,
            ),
            
            // The precise bottom-anchored semi-circle indicator
            Positioned(
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 22, 
                  height: 11, // Exactly half the width to create a perfect semi-circle
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
}