import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Animated discussion timer for Spyfall rounds.
class SpyfallTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalDurationSeconds;
  final bool isPaused;

  const SpyfallTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalDurationSeconds,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = remainingSeconds <= 60 && remainingSeconds > 0;
    final isExpired = remainingSeconds <= 0;

    final color = isExpired || isWarning
        ? PlayNedTokens.accentSpyfall
        : (isPaused ? PlayNedTokens.textSecondary : PlayNedTokens.brandGold);

    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusFull),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: isWarning
            ? [
                BoxShadow(
                  color: PlayNedTokens.accentSpyfall.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaused ? Icons.pause_circle_outline : (isWarning ? Icons.warning_amber_rounded : Icons.timer_outlined),
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isExpired ? '00:00 - TIME EXPIRED' : '$minutes:$seconds',
            style: GoogleFonts.spaceMono(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          if (isPaused) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PlayNedTokens.surfaceHover,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PAUSED',
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: PlayNedTokens.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
