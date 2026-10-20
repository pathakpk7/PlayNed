import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

class BingoResultDialog extends StatelessWidget {
  final String winnerName;
  final bool isWinnerLocalPlayer;
  final bool isTie;
  final String? patternName;
  final int numbersDrawn;
  final Duration matchDuration;
  final VoidCallback onRematch;
  final VoidCallback onBackToGames;
  final Color accentColor;

  const BingoResultDialog({
    super.key,
    required this.winnerName,
    this.isWinnerLocalPlayer = true,
    this.isTie = false,
    this.patternName,
    required this.numbersDrawn,
    required this.matchDuration,
    required this.onRematch,
    required this.onBackToGames,
    this.accentColor = PlayNedTokens.brandGold,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PlayNedTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        side: BorderSide(color: accentColor.withOpacity(0.8), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(PlayNedTokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: Icon(
                  isTie ? Icons.handshake_rounded : Icons.emoji_events_rounded,
                  size: 36,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: PlayNedTokens.space16),

              // Title: BINGO!
              Text(
                'BINGO!',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle Winner statement
              Text(
                isTie ? 'Simultaneous Bingo! Match Tied!' : '$winnerName Wins!',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PlayNedTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PlayNedTokens.space20),

              // Match Statistics Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PlayNedTokens.space16),
                decoration: BoxDecoration(
                  color: PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                  border: Border.all(color: PlayNedTokens.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildStatRow('PATTERN', patternName ?? 'Classic'),
                    const Divider(color: PlayNedTokens.borderSubtle, height: 16),
                    _buildStatRow('NUMBERS DRAWN', '$numbersDrawn / 75'),
                    const Divider(color: PlayNedTokens.borderSubtle, height: 16),
                    _buildStatRow('MATCH TIME', _formatDuration(matchDuration)),
                  ],
                ),
              ),
              const SizedBox(height: PlayNedTokens.space24),

              // Action Buttons: Rematch & Back to Games
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PlayNedTokens.textSecondary,
                        side: const BorderSide(color: PlayNedTokens.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                        ),
                      ),
                      onPressed: onBackToGames,
                      child: Text(
                        'BACK TO HUB',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: PlayNedTokens.space12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: PlayNedTokens.textInverse,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onRematch,
                      child: Text(
                        'REMATCH',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: PlayNedTokens.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: PlayNedTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}
