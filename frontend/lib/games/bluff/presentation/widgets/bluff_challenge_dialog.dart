import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/bluff_models.dart';
import 'playing_card_widget.dart';

class BluffChallengeDialog extends StatelessWidget {
  final BluffChallengeResult result;
  final VoidCallback onContinue;

  const BluffChallengeDialog({
    super.key,
    required this.result,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final wasBluff = result.wasBluff;
    final badgeColor = wasBluff ? const Color(0xFFE11D48) : const Color(0xFF10B981);
    final badgeIcon = wasBluff ? Icons.warning_rounded : Icons.verified;
    final title = wasBluff ? 'BLUFF CAUGHT!' : 'TRUTHFUL PLAY!';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(PlayNedTokens.space16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(PlayNedTokens.space24),
        decoration: BoxDecoration(
          color: const Color(0xFF140F22),
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          border: Border.all(color: badgeColor.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withOpacity(0.3),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
                border: Border.all(color: badgeColor.withOpacity(0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 16, color: badgeColor),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Confrontation text
            Text(
              '${result.challengerName} called BLUFF on ${result.blufferName}!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: PlayNedTokens.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Claimed: ${result.declaredRank}s',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: const Color(0xFFA78BFA),
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            // Actual Revealed Cards
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A152E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PlayNedTokens.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    'ACTUAL REVEALED CARDS',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: PlayNedTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: result.revealedCards.map((c) {
                      return PlayingCardWidget(
                        card: c,
                        isFaceUp: true,
                        width: 60,
                        height: 86,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pile pickup notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: PlayNedTokens.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PlayNedTokens.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFFCBD5E1)),
                  const SizedBox(width: 8),
                  Text(
                    '${result.pileCollectorName} collects all ${result.cardsCollectedCount} pile cards!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PlayNedTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                  ),
                ),
                onPressed: onContinue,
                child: Text(
                  'CONTINUE',
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
