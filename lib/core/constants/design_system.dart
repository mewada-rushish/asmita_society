import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AsmitaPalette {
  static const Color actionRed = Color(0xFFE21F26);
  static const Color deepNavy = Color(0xFF27347B);
  static const Color systemBG = Color(0xFFF8F8FB);
  
  static const Color textDark = Color(0xFF1E2022);
  static const Color textLight = Color(0xFF676E76);
  static const Color borderGrey = Color(0xFFE5E8ED);
}

class AsmitaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AsmitaPalette.systemBG,
      colorScheme: const ColorScheme.light(
        primary: AsmitaPalette.deepNavy,
        secondary: AsmitaPalette.actionRed,
        surface: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AsmitaPalette.textDark),
        headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textDark),
        titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textDark),
        labelLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AsmitaPalette.textLight),
        bodyLarge: GoogleFonts.poppins(fontWeight: FontWeight.normal, color: AsmitaPalette.textDark),
        bodyMedium: GoogleFonts.poppins(fontWeight: FontWeight.normal, color: AsmitaPalette.textLight),
      ),
    );
  }
}