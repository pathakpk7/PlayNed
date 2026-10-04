import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Design Tokens for the PlayNed 2D Game Platform
class PlayNedTokens {
  // Base Palette
  static const Color background = Color(0xFF0E0E0C);
  static const Color surface = Color(0xFF161614);
  static const Color surfaceElevated = Color(0xFF1E1E1B);
  static const Color surfaceHover = Color(0xFF252521);
  static const Color border = Color(0xFF2A2A26);
  static const Color borderSubtle = Color(0xFF1F1F1C);
  static const Color borderBright = Color(0xFF3D3D36);

  // Typography Palette
  static const Color textPrimary = Color(0xFFF1EBDD);
  static const Color textSecondary = Color(0xFFA9A396);
  static const Color textMuted = Color(0xFF6E695F);
  static const Color textInverse = Color(0xFF0E0E0C);

  // Brand Palette
  static const Color brandGold = Color(0xFFD5A84B);
  static const Color brandGoldBright = Color(0xFFE5BA5C);
  static const Color brandGoldMuted = Color(0xFF8A6C2E);
  static const Color terracotta = Color(0xFFB95745);
  static const Color sageGreen = Color(0xFF879873);

  // Game-Specific Controlled Accents
  static const Color accentHangman = Color(0xFFD5A84B); // Amber Gold
  static const Color accentDots = Color(0xFF3B82F6);    // Electric Blue
  static const Color accentQuoridor = Color(0xFFE06C54); // Coral Red
  static const Color accentPentago = Color(0xFF10B981);  // Emerald
  static const Color accentShutTheBox = Color(0xFFE5A93C); // Warm Bronze / Amber
  static const Color accentCricket = Color(0xFF22C55E);  // Deep Field Green
  static const Color accentReversi = Color(0xFF10B981);  // Tactile Emerald Green

  static Color getGameAccent(String gameId) {
    switch (gameId.toLowerCase()) {
      case 'hangman':
        return accentHangman;
      case 'dots_and_boxes':
        return accentDots;
      case 'quoridor':
        return accentQuoridor;
      case 'pentago':
        return accentPentago;
      case 'shut_the_box':
        return accentShutTheBox;
      case 'cricket':
        return accentCricket;
      case 'reversi':
      case 'othello':
        return accentReversi;
      default:
        return brandGold;
    }
  }

  // Spacing System
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Border Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusPill = 999.0;

  // Animation Timings
  static const Duration animMicro = Duration(milliseconds: 140);
  static const Duration animFast = Duration(milliseconds: 180);
  static const Duration animStandard = Duration(milliseconds: 220);
  static const Duration animPage = Duration(milliseconds: 320);
  static const Curve animCurve = Curves.easeOutCubic;

  // Breakpoints
  static const double bpMobile = 600.0;
  static const double bpTablet = 960.0;
  static const double bpDesktop = 1200.0;
  static const double breakpointSm = 600.0;
  static const double breakpointMd = 768.0;
  static const double breakpointLg = 1024.0;

  // Typography Styles
  static TextStyle get heroDisplay => GoogleFonts.dmSerifDisplay(
        fontSize: 36,
        color: textPrimary,
        height: 1.15,
        letterSpacing: 0.5,
      );

  static TextStyle get heroTitle => heroDisplay;

  static TextStyle get sectionHeading => GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        color: textPrimary,
        letterSpacing: 0.3,
      );

  static TextStyle get gameTitle => GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        color: textPrimary,
        letterSpacing: 0.4,
      );

  static TextStyle get cardTitle => GoogleFonts.dmSerifDisplay(
        fontSize: 17,
        color: textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        color: textPrimary,
        height: 1.45,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 13,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get metadata => GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: textSecondary,
      );

  static TextStyle get buttonLabel => GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      );
}
