import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AsmitaPalette {
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color actionRed = Color(0xFFE21F26);
  static const Color deepNavy = Color(0xFF27347B);
  
  // Light Mode Colors
  static const Color systemBG = Color(0xFFF8F8FB);
  static const Color surfaceLight = Colors.white;
  static const Color textDark = Color(0xFF1E2022); // Used for dark text on light bg
  static const Color textLight = Color(0xFF676E76); // Muted text on light bg
  static const Color borderGrey = Color(0xFFE5E8ED);

  // Dark Mode Colors
  static const Color systemBGDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF282828); // Lighter grey for cards
  static const Color deepNavyDark = Color(0xFF8A9CFF); // Much brighter blue for dark mode visibility (switches, text)
  static const Color textDarkModeMain = Color(0xFFFFFFFF); // White text on dark bg
  static const Color textDarkModeMuted = Color(0xFFA0A0A0); // Muted text on dark bg
  static const Color borderGreyDark = Color(0xFF404040); // Slightly lighter border for contrast
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
        secondary: AsmitaPalette.actionRed,
        surface: AsmitaPalette.surfaceLight,
        outline: AsmitaPalette.borderGrey,
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
        secondary: AsmitaPalette.actionRed,
        surface: AsmitaPalette.surfaceDark,
        outline: AsmitaPalette.borderGreyDark,
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