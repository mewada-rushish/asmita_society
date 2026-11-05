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
  
  // Borders & Dividers
  static const Color borderGreyDark = Color(0xFF25334D); // Crisp subtle midnight-navy border
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
      colorScheme: const ColorScheme.dark(
        primary: AsmitaPalette.deepNavyDark,
        secondary: Color(0xFF5A75CD),
        secondaryContainer: Color(0xFF1E284A),
        onSecondaryContainer: Colors.white,
        error: AsmitaPalette.actionRed,
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