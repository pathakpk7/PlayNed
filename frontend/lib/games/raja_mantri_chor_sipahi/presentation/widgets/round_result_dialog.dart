import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/raja_mantri_models.dart';

class RajaMantriResultDialog extends StatelessWidget {
  final RajaMantriState state;
  final VoidCallback onNextRound;
  final VoidCallback? onRematch;
  final bool isHost;

  const RajaMantriResultDialog({
    super.key,
    required this.state,
    required this.onNextRound,
    this.onRematch,
    this.isHost = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMatchOver = state.phase == RajaMantriPhase.matchResults || state.isGameOver;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PlayNedTokens.surface,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          border: Border.all(color: PlayNedTokens.brandGold.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: PlayNedTokens.brandGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
                  border: Border.all(color: PlayNedTokens.brandGold.withOpacity(0.4)),
                ),
                child: Text(
                  isMatchOver
                      ? 'MATCH FINAL STANDINGS'
                      : 'ROUND ${state.currentRound} OF ${state.totalRounds} SUMMARY',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: PlayNedTokens.brandGold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title / Outcome
              Text(
                isMatchOver
                    ? (state.isTie ? 'MATCH TIED!' : 'CHAMPION DECLARED!')
                    : (state.guessCorrect == true ? 'CHOR CAUGHT!' : 'CHOR ESCAPED!'),
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isMatchOver
                      ? PlayNedTokens.brandGold
                      : (state.guessCorrect == true
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E)),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                state.lastAction,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: PlayNedTokens.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Round Roles & Points Breakdown
              Text(
                'ROLE ASSIGNMENTS & POINTS',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: PlayNedTokens.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                  border: Border.all(color: PlayNedTokens.border),
                ),
                child: Column(
                  children: state.playerIds.map((pid) {
                    final role = state.getPlayerRole(pid);
                    final name = state.getPlayerName(pid);
                    final roundPts = state.getPlayerRoundPoints(pid);
                    final totalPts = state.getPlayerScore(pid);
                    final roleColor = role?.color ?? PlayNedTokens.textSecondary;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: pid != state.playerIds.last
                                ? PlayNedTokens.borderSubtle
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(role?.icon ?? Icons.person, size: 20, color: roleColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PlayNedTokens.textPrimary,
                                  ),
                                ),
                                Text(
                                  role != null
                                      ? '${role.displayName} (${role.englishTitle})'
                                      : 'Hidden',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: roleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+$roundPts PTS',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: PlayNedTokens.brandGold,
                                ),
                              ),
                              Text(
                                'TOTAL: $totalPts',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  color: PlayNedTokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PlayNedTokens.textSecondary,
                        side: const BorderSide(color: PlayNedTokens.borderBright),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
                      ),
                      onPressed: () => context.go('/games/raja_mantri_chor_sipahi'),
                      child: Text(
                        'EXIT TO HUB',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PlayNedTokens.brandGold,
                        foregroundColor: PlayNedTokens.textInverse,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
                      ),
                      onPressed: isMatchOver ? onRematch : onNextRound,
                      child: Text(
                        isMatchOver
                            ? 'PLAY AGAIN'
                            : 'NEXT ROUND',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
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
}
