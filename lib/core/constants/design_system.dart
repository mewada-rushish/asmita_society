import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AsmitaPalette {
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color actionRed = Color(0xFFE21F26);
  static const Color deepNavy = Color(0xFF27347B);
  static const Color amberWarning = Color(0xFFD97706);
  
  // Light Mode Colors
  static const Color systemBG = Color(0xFFF8F8FB);
  static const Color surfaceLight = Colors.white;
  static const Color textDark = Color(0xFF1E2022); // Used for dark text on light bg
  static const Color textLight = Color(0xFF676E76); // Muted text on light bg
  static const Color borderGrey = Color(0xFFE5E8ED);

  // Dark Mode Colors (Apple HIG Aligned with Asmita Deep Navy undertones)
  // Level 1: Deep Midnight Slate with subtle Navy undertone instead of harsh dead black
  static const Color systemBGDark = Color(0xFF0D121F); 
  // Level 2: Elevated card & container surface
  static const Color surfaceDark = Color(0xFF172033); 
  // Level 3: Modal dialogs, popup sheets & elevated tiles
  static const Color surfaceElevatedDark = Color(0xFF1F2B45); 
  
  // Brand / Interactive: Luminous, high-contrast Navy-Blue tuned for dark mode
  static const Color deepNavyDark = Color(0xFF7B96EC); 
  
  // Semantic Text tokens matching Apple HIG dark mode label hierarchy
  static const Color textDarkModeMain = Color(0xFFF1F5F9); // Primary label (prevents glare/halation)
  static const Color textDarkModeMuted = Color(0xFF94A3B8); // Secondary label (accessible slate)
  static const Color textDarkModeTertiary = Color(0xFF64748B); // Tertiary subtle label
  static const Color textDarkModeQuaternary = Color(0xFF475569); // Quaternary subtle hint
  
  // Vibrant Semantic System Tints tuned for Dark Mode (Apple HIG compliant contrast)
  static const Color successGreenDark = Color(0xFF34D399); // Radiant Emerald (4.5:1+ contrast on dark)
  static const Color actionRedDark = Color(0xFFF87171); // Radiant Coral Red
  static const Color amberWarningDark = Color(0xFFFBBF24); // Radiant Gold Amber
  
  // Borders & Dividers
  static const Color borderGreyDark = Color(0xFF25334D); // Crisp subtle midnight-navy border

  // HIG-aligned dynamic color resolvers
  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? deepNavyDark : deepNavy;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textDarkModeMain : textDark;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textDarkModeMuted : textLight;

  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textDarkModeTertiary : const Color(0xFF94A3B8);

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color elevatedSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceElevatedDark : Colors.white;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderGreyDark : borderGrey;

  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? successGreenDark : successGreen;

  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? actionRedDark : actionRed;

  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? amberWarningDark : amberWarning;

  static Color subtleAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? deepNavyDark.withValues(alpha: 0.18)
          : deepNavy.withValues(alpha: 0.08);
}

class AsmitaTheme {
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AsmitaPalette.systemBG,
      dividerColor: AsmitaPalette.borderGrey,
      colorScheme: const ColorScheme.light(
        primary: AsmitaPalette.deepNavy,
        secondary: Color(0xFF3B4D9B),
        secondaryContainer: Color(0xFFE8ECF8),
        onSecondaryContainer: AsmitaPalette.deepNavy,
        error: AsmitaPalette.actionRed,
        surface: AsmitaPalette.surfaceLight,
        outline: AsmitaPalette.borderGrey,
      ),
      chipTheme: ChipThemeData(
        checkmarkColor: Colors.white,
        selectedColor: AsmitaPalette.deepNavy,
        secondarySelectedColor: AsmitaPalette.deepNavy,
        backgroundColor: AsmitaPalette.systemBG,
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AsmitaPalette.deepNavy;
          }
          return AsmitaPalette.systemBG;
        }),
        secondaryLabelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: AsmitaPalette.textLight),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AsmitaPalette.textDark),
        headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textDark),
        titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textDark),
        labelLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textLight),
        bodyLarge: GoogleFonts.poppins(fontWeight: FontWeight.normal, color: AsmitaPalette.textDark),
        bodyMedium: GoogleFonts.poppins(fontWeight: FontWeight.normal, color: AsmitaPalette.textLight),
        bodySmall: GoogleFonts.poppins(fontWeight: FontWeight.normal, color: AsmitaPalette.textLight),
      ),
      pageTransitionsTheme: _pageTransitions,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AsmitaPalette.systemBGDark,
      dividerColor: AsmitaPalette.borderGreyDark,
      cardColor: AsmitaPalette.surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AsmitaPalette.systemBGDark,
        foregroundColor: AsmitaPalette.textDarkModeMain,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AsmitaPalette.surfaceElevatedDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AsmitaPalette.borderGreyDark, width: 1.0),
        ),
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AsmitaPalette.textDarkModeMain,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AsmitaPalette.textDarkModeMuted,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AsmitaPalette.surfaceElevatedDark,
        modalBackgroundColor: AsmitaPalette.surfaceElevatedDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFF94A3B8);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AsmitaPalette.deepNavyDark;
          }
          return const Color(0xFF334155);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return const Color(0xFF475569);
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AsmitaPalette.surfaceElevatedDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AsmitaPalette.borderGreyDark, width: 1.0),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AsmitaPalette.textDarkModeMain,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AsmitaPalette.deepNavyDark,
        secondary: Color(0xFF5A75CD),
        secondaryContainer: Color(0xFF1E284A),
        onSecondaryContainer: Colors.white,
        error: AsmitaPalette.actionRedDark,
        surface: AsmitaPalette.surfaceDark,
        outline: AsmitaPalette.borderGreyDark,
      ),
      chipTheme: ChipThemeData(
        checkmarkColor: Colors.white,
        selectedColor: AsmitaPalette.deepNavyDark,
        secondarySelectedColor: AsmitaPalette.deepNavyDark,
        backgroundColor: AsmitaPalette.surfaceDark,
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AsmitaPalette.deepNavyDark;
          }
          return AsmitaPalette.surfaceDark;
        }),
        secondaryLabelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: AsmitaPalette.textDarkModeMuted),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AsmitaPalette.textDarkModeMain),
        headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textDarkModeMain),
        titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textDarkModeMain),
        labelLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textDarkModeMuted),
        bodyLarge: GoogleFonts.poppins(fontWeight: FontWeight.normal, color: AsmitaPalette.textDarkModeMain),
        bodyMedium: GoogleFonts.poppins(fontWeight: FontWeight.normal, color: AsmitaPalette.textDarkModeMuted),
        bodySmall: GoogleFonts.poppins(fontWeight: FontWeight.normal, color: AsmitaPalette.textDarkModeMuted),
      ),
      pageTransitionsTheme: _pageTransitions,
    );
  }
}

/// Standard device breakpoints and responsive scaling system for AsmitA app.
///
/// Designed to:
/// 1. Maintain identical 1.0x layout on standard mobile reference devices (390dp width).
/// 2. Gracefully scale typography, gaps, and padding across small/compact phones (down to 320dp).
/// 3. Prevent stretched, distorted cards on tablets (>= 600dp) by providing bounded max-width canvases,
///    keeping layouts structured like a crisp document or PDF.
class AppResponsive {
  // Breakpoints
  static const double compactPhoneBreakpoint = 360.0;
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;

  // Reference baseline width (standard modern mobile, e.g. iPhone 14/15/16, modern Pixel emulator)
  static const double referencePhoneWidth = 390.0;

  /// Whether current device is a compact phone (< 360dp, e.g. small Androids or iPhone SE).
  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < compactPhoneBreakpoint;

  /// Whether current device is a tablet (>= 600dp, e.g. iPad, Android tablet, unfolded foldables).
  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Whether current device is desktop / wide screen (>= 1024dp).
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Device width
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Device height
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// Proportional scaling factor anchored at [referencePhoneWidth] (390dp).
  /// Clamped between [minScale] (0.88) and [maxScale] (1.15) for phones.
  /// On tablets, returns a controlled scale factor (1.05) to prevent oversized elements.
  static double scaleFactor(BuildContext context, {double minScale = 0.88, double maxScale = 1.15}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= tabletBreakpoint) {
      // Tablets use a bounded layout rather than continuous scalar inflation
      return 1.05;
    }
    return (w / referencePhoneWidth).clamp(minScale, maxScale);
  }

  /// Scales a base dimension proportionally based on device width.
  /// On reference 390dp screen, returns exactly [size].
  static double scale(BuildContext context, double size, {double minScale = 0.88, double maxScale = 1.15}) {
    return size * scaleFactor(context, minScale: minScale, maxScale: maxScale);
  }

  /// Scales font size safely.
  static double font(BuildContext context, double baseFontSize, {double minScale = 0.90, double maxScale = 1.12}) {
    final factor = scaleFactor(context, minScale: minScale, maxScale: maxScale);
    return (baseFontSize * factor).roundToDouble();
  }

  /// Scales horizontal/vertical padding proportionally (never dropping below [minPadding]).
  static double padding(BuildContext context, double basePadding, {double minPadding = 8.0}) {
    final scaled = scale(context, basePadding);
    return scaled < minPadding ? minPadding : scaled;
  }
}

/// Wraps content in a centered, bounded canvas on tablets and wide screens
/// so that cards, forms, and views do not stretch across wide displays
/// and remain intact like an executive PDF document.
class BoundedCanvas extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const BoundedCanvas({
    super.key,
    required this.child,
    this.maxWidth = 600.0,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppResponsive.isTablet(context)) {
      return child;
    }
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Convenience BuildContext extension for responsive utilities.
extension ResponsiveContext on BuildContext {
  bool get isCompact => AppResponsive.isCompact(this);
  bool get isTablet => AppResponsive.isTablet(this);
  bool get isDesktop => AppResponsive.isDesktop(this);
  double get screenWidth => AppResponsive.width(this);
  double get screenHeight => AppResponsive.height(this);
  double responsiveScale(double size) => AppResponsive.scale(this, size);
  double responsiveFont(double baseFontSize) => AppResponsive.font(this, baseFontSize);
  double responsivePadding(double basePadding) => AppResponsive.padding(this, basePadding);
}

/// Convenience BuildContext extension for Apple HIG-aligned theme tokens.
extension AsmitaThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get primaryColor => AsmitaPalette.primary(this);
  Color get textPrimary => AsmitaPalette.textPrimary(this);
  Color get textSecondary => AsmitaPalette.textSecondary(this);
  Color get textTertiary => AsmitaPalette.textTertiary(this);
  Color get surfaceColor => AsmitaPalette.surface(this);
  Color get elevatedSurfaceColor => AsmitaPalette.elevatedSurface(this);
  Color get borderColor => AsmitaPalette.border(this);
  Color get subtleAccentColor => AsmitaPalette.subtleAccent(this);
  Color get successColor => AsmitaPalette.success(this);
  Color get errorColor => AsmitaPalette.error(this);
  Color get warningColor => AsmitaPalette.warning(this);
}

