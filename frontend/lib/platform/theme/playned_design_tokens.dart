import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Art-Directed Design Tokens for PlayNed
/// Eliminates generic clichés in favor of architectural hierarchy,
/// intentional contrast, contemporary typography, and refined motion.
class PlayNedTokens {
  // --- Surface & Canvas System ---
  static const Color background = Color(0xFF090A0D);
  static const Color surface = Color(0xFF12141A);
  static const Color surfaceElevated = Color(0xFF191C24);
  static const Color surfaceHover = Color(0xFF222631);
  static const Color border = Color(0xFF242834);
  static const Color borderSubtle = Color(0xFF1A1D27);
  static const Color borderBright = Color(0xFF383E50);

  // --- Typography Palette ---
  static const Color textPrimary = Color(0xFFF5F6F8);
  static const Color textSecondary = Color(0xFF9DA2B3);
  static const Color textMuted = Color(0xFF64687A);
  static const Color textInverse = Color(0xFF090A0D);

  // --- Signature Brand Accents ---
  static const Color brandGold = Color(0xFFF59E0B);
  static const Color brandGoldBright = Color(0xFFFBBF24);
  static const Color brandGoldMuted = Color(0xFFB45309);
  static const Color brandElectric = Color(0xFF3B82F6);
  static const Color terracotta = Color(0xFFF43F5E);
  static const Color sageGreen = Color(0xFF10B981);

  // --- Game-Specific Cohesive Accents ---
  static const Color accentHangman = Color(0xFFF59E0B);
  static const Color accentDots = Color(0xFF3B82F6);
  static const Color accentQuoridor = Color(0xFFF43F5E);
  static const Color accentPentago = Color(0xFF10B981);
  static const Color accentShutTheBox = Color(0xFFD97706);
  static const Color accentCricket = Color(0xFF22C55E);
  static const Color accentReversi = Color(0xFF14B8A6);
  static const Color accentUltimateTicTacToe = Color(0xFFEAB308);
  static const Color accentBingo = Color(0xFFF97316);
  static const Color accentRajaMantri = Color(0xFFE11D48);
  static const Color accentBluff = Color(0xFF8B5CF6);
  static const Color accentSpyfall = Color(0xFFEC4899);
  static const Color accentMafia = Color(0xFFEF4444);
  static const Color accentHigherOrLower = Color(0xFF6366F1);

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
      case 'ultimate_tic_tac_toe':
      case 'ultimate-tic-tac-toe':
        return accentUltimateTicTacToe;
      case 'bingo':
        return accentBingo;
      case 'raja_mantri_chor_sipahi':
      case 'raja_mantri':
        return accentRajaMantri;
      case 'bluff':
      case 'bluff_cheat':
        return accentBluff;
      case 'spyfall':
        return accentSpyfall;
      case 'mafia':
      case 'werewolf':
        return accentMafia;
      case 'higher_or_lower':
      case 'higher_lower':
        return accentHigherOrLower;
      default:
        return brandGold;
    }
  }

  // --- Spatial Scale ---
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
  static const double space80 = 80.0;

  // --- Geometry Scale (No Squircles or Pill Clichés) ---
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 18.0;
  static const double radiusPill = 20.0;
  static const double radiusFull = 999.0;

  // --- Motion Design Principles ---
  static const Duration animMicro = Duration(milliseconds: 140);
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animStandard = Duration(milliseconds: 300);
  static const Duration animPage = Duration(milliseconds: 450);
  static const Curve animCurve = Curves.easeOutCubic;
  static const Curve animSpringCurve = Curves.easeOutQuart;

  // --- Breakpoints ---
  static const double bpMobile = 600.0;
  static const double bpTablet = 960.0;
  static const double bpDesktop = 1200.0;
  static const double breakpointSm = 600.0;
  static const double breakpointMd = 768.0;
  static const double breakpointLg = 1024.0;
  static const double breakpointXl = 1380.0;

  // --- Typography: Bold, Contemporary, Readable ---
  static TextStyle get heroDisplay => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        height: 1.08,
        letterSpacing: -1.0,
      );

  static TextStyle get heroTitle => heroDisplay;

  static TextStyle get sectionHeading => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get sectionHeader => sectionHeading;

  static TextStyle get gameTitle => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get gameTagline => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.45,
      );

  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.45,
      );

  static TextStyle get metadata => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonLabel => GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );
}
