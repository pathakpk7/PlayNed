import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Sophisticated Carbon & Obsidian Palette
  static const Color darkBackground = Color(0xFF090A0D);
  static const Color darkSurface = Color(0xFF12141A);
  static const Color darkSurfaceElevated = Color(0xFF191C24);
  static const Color darkBorder = Color(0xFF242834);
  
  static const Color paperText = Color(0xFFF5F6F8);
  static const Color mutedInk = Color(0xFF9DA2B3);
  
  static const Color goldAccent = Color(0xFFF59E0B);
  static const Color terracottaAccent = Color(0xFFF43F5E);
  static const Color sageSuccess = Color(0xFF10B981);

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: terracottaAccent,
        surface: darkSurface,
        error: terracottaAccent,
        onSurface: paperText,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: paperText,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: paperText,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          color: paperText,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: paperText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: paperText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        bodyLarge: GoogleFonts.inter(
          color: paperText,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: mutedInk,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          color: paperText,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: paperText, fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
