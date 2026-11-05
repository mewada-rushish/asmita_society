import '../constants/design_system.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../utils/property_role_resolver.dart';

class AsmitaBottomNavBar extends StatelessWidget {
  /// Standard bar height without bottom device padding
  static const double barHeight = 64.0;

  /// Dynamic bottom padding to apply to FloatingActionButton widgets inside
  /// screens rendered above the [AsmitaBottomNavBar] in [MainDashboardScreen].
  ///
  /// Since Flutter's [Scaffold] automatically offsets FABs by [kFloatingActionButtonMargin] (16px)
  /// and [MediaQuery.viewPaddingOf(context).bottom], adding exactly [barHeight] (+ optional [extraMargin])
  /// places the bottom edge of the FAB perfectly [kFloatingActionButtonMargin + extraMargin] (16px)
  /// Dynamic bottom padding to apply to FloatingActionButton widgets inside
  /// screens rendered above the [AsmitaBottomNavBar] in [MainDashboardScreen].
  ///
  /// Since the outer [Scaffold] in [MainDashboardScreen] uses `extendBody: true`, the body
  /// extends behind the [AsmitaBottomNavBar]. Flutter's inner [Scaffold] automatically offsets
  /// the FAB by [kFloatingActionButtonMargin] (16px) and device insets. Adding [barHeight] (64px)
  /// (+ optional [extraMargin]) ensures the FAB hovers cleanly 16-20px above the curved navigation bar
  /// on all screen sizes and device types without floating awkwardly high or being submerged.
  static double fabBottomPadding([BuildContext? context, double extraMargin = 0.0]) {
    return barHeight + extraMargin;
  }

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
    // Automatically resolve effective role from AuthBloc if not explicitly passed
    String? effectiveRole = userRole;
    if (effectiveRole == null || effectiveRole.trim().isEmpty) {
      try {
        final authState = context.watch<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          final user = authState.user;
          effectiveRole = authState.sessionRole.isNotEmpty == true
              ? authState.sessionRole
              : (user.systemRole?.isNotEmpty == true
                  ? user.systemRole
                  : user.primaryRole);
        }
      } catch (_) {}
    }

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.05);

    final navContent = Container(
      height: barHeight + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark 
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.65) 
            : Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark ? Border.all(color: borderColor, width: 1.0) : null,
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
        children: _getVisibleIndices(effectiveRole).map((index) {
          final isSelected = currentIndex == index;
          return _buildNavigationItem(context, index, isSelected, effectiveRole);
        }).toList(),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: isDark 
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: navContent,
            )
          : navContent,
      ),
    );
  }

  List<int> _getVisibleIndices(String? role) {
    if (PropertyRoleResolver.normalizeRole(role) == 'guard') {
      return [0, 6, 3, 5, 4]; // Home, Checked In, History, Scan, Menu
    }
    return [0, 1, 2, 3, 4]; // All tabs
  }

  Widget _buildNavigationItem(BuildContext context, int index, bool isSelected, String? role) {
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
              child: _buildCustomScaledIcon(context, index, role),
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
                    color: AsmitaPalette.actionRed,
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

  Widget _buildCustomScaledIcon(BuildContext context, int index, String? role) {
    const iconColor = Colors.white;
    const colorFilter = ColorFilter.mode(iconColor, BlendMode.srcIn);

    final normalized = PropertyRoleResolver.normalizeRole(role);
    final isIndustrial = normalized == 'director' ||
        normalized == 'employee' ||
        normalized == 'receptionist' ||
        normalized == 'facility';

    switch (index) {
      case 0:
        return SvgPicture.asset('assets/icons/home.svg', width: 24, height: 24, colorFilter: colorFilter);
      case 1:
        if (isIndustrial) {
          return const Icon(Icons.assignment_ind_rounded, size: 28, color: iconColor);
        }
        return SvgPicture.asset('assets/icons/services.svg', width: 32, height: 32, colorFilter: colorFilter);
      case 2:
        if (isIndustrial) {
          return const Icon(Icons.corporate_fare_rounded, size: 28, color: iconColor);
        }
        return SvgPicture.asset('assets/icons/community.svg', width: 32, height: 32, colorFilter: colorFilter);
      case 3:
        return SvgPicture.asset('assets/icons/history.svg', width: 32, height: 32, colorFilter: colorFilter);
      case 5:
        return const Icon(Icons.qr_code_scanner_rounded, size: 30, color: iconColor);
      case 6:
        return const Icon(Icons.how_to_reg, size: 30, color: iconColor);
      case 4:
      default:
        return const Icon(Icons.more_horiz_rounded, size: 32, color: iconColor);
    }
  }
}