import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

class BingoCallerWidget extends StatelessWidget {
  final int? currentNumber;
  final String? currentLetter;
  final int drawCount;
  final int totalPoolCount;
  final VoidCallback? onDrawPressed;
  final bool isAutoDrawing;
  final int autoDrawCountdown;
  final bool isGameOver;
  final Color accentColor;

  const BingoCallerWidget({
    super.key,
    required this.currentNumber,
    required this.currentLetter,
    required this.drawCount,
    required this.totalPoolCount,
    this.onDrawPressed,
    this.isAutoDrawing = false,
    this.autoDrawCountdown = 3,
    this.isGameOver = false,
    this.accentColor = PlayNedTokens.brandGold,
  });

  @override
  Widget build(BuildContext context) {
    final hasNumber = currentNumber != null && currentLetter != null;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(PlayNedTokens.space16),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info: CURRENT NUMBER & Draw Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NUMBER CALLER',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: PlayNedTokens.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
                  border: Border.all(color: PlayNedTokens.borderSubtle),
                ),
                child: Text(
                  'BALL $drawCount / $totalPoolCount',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PlayNedTokens.space12),

          // Central Prominent Ball Display
          AnimatedContainer(
            duration: PlayNedTokens.animFast,
            curve: PlayNedTokens.animCurve,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: PlayNedTokens.space16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasNumber
                    ? [
                        accentColor.withOpacity(0.20),
                        PlayNedTokens.surfaceElevated,
                      ]
                    : [
                        PlayNedTokens.surfaceElevated,
                        PlayNedTokens.surfaceElevated,
                      ],
              ),
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
              border: Border.all(
                color: hasNumber ? accentColor.withOpacity(0.5) : PlayNedTokens.borderSubtle,
                width: 1.5,
              ),
            ),
            child: hasNumber
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Letter badge (B, I, N, G, O)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                        ),
                        child: Text(
                          currentLetter!,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: PlayNedTokens.textInverse,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Number call
                      Text(
                        '$currentNumber',
                        style: GoogleFonts.spaceMono(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: PlayNedTokens.textPrimary,
                          letterSpacing: 2.0,
                          height: 1.0,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'PRESS DRAW TO START',
                        style: GoogleFonts.spaceMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PlayNedTokens.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: PlayNedTokens.space12),

          // Draw Controls / Auto-timer Countdown
          if (!isGameOver) ...[
            if (isAutoDrawing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: PlayNedTokens.borderSubtle),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NEXT DRAW IN $autoDrawCountdown S',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (onDrawPressed != null)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: PlayNedTokens.textInverse,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onDrawPressed,
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: Text(
                    hasNumber ? 'DRAW NEXT BALL' : 'DRAW FIRST NUMBER',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
