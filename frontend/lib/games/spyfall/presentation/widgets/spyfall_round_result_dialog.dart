import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Modal dialog displaying round results, true spy identity, true location, and score breakdown.
class SpyfallRoundResultDialog extends StatelessWidget {
  final String outcome;
  final String secretLocation;
  final String spyName;
  final String? accusedName;
  final String? spyGuess;
  final Map<String, int> roundPoints;
  final Map<String, int> totalScores;
  final Map<String, String> playerNames;
  final int currentRound;
  final int totalRounds;
  final bool isMatchOver;
  final bool isHost;
  final VoidCallback onNextRound;
  final VoidCallback onLeave;

  const SpyfallRoundResultDialog({
    super.key,
    required this.outcome,
    required this.secretLocation,
    required this.spyName,
    this.accusedName,
    this.spyGuess,
    required this.roundPoints,
    required this.totalScores,
    required this.playerNames,
    required this.currentRound,
    required this.totalRounds,
    required this.isMatchOver,
    this.isHost = true,
    required this.onNextRound,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isSpyWin = outcome == 'SPY_GUESSED_LOCATION' || outcome == 'SPY_ESCAPED';
    final accent = isSpyWin ? PlayNedTokens.accentSpyfall : PlayNedTokens.brandGold;

    String outcomeTitle;
    String outcomeDescription;
    IconData outcomeIcon;

    switch (outcome) {
      case 'SPY_GUESSED_LOCATION':
        outcomeTitle = 'SPY ESCAPED WITH INTEL!';
        outcomeDescription = '$spyName correctly guessed the secret location ($spyGuess)!';
        outcomeIcon = Icons.vpn_key;
        break;
      case 'SPY_GUESS_FAILED':
        outcomeTitle = 'SPY INTEL FAILED!';
        outcomeDescription = '$spyName guessed "$spyGuess", but the location was $secretLocation!';
        outcomeIcon = Icons.error_outline;
        break;
      case 'SPY_CONVICTED':
        outcomeTitle = 'SPY EXPOSED & CAPTURED!';
        outcomeDescription = 'The table correctly identified $spyName as the hidden Spy!';
        outcomeIcon = Icons.security;
        break;
      case 'INNOCENT_CONVICTED':
        outcomeTitle = 'INNOCENT AGENT CONVICTED!';
        outcomeDescription = 'The table falsely convicted $accusedName! $spyName was the true Spy.';
        outcomeIcon = Icons.warning_amber_rounded;
        break;
      case 'SPY_ESCAPED':
        outcomeTitle = 'TIME EXPIRED - SPY SURVIVED!';
        outcomeDescription = 'Discussion time ran out. $spyName successfully evaded detection!';
        outcomeIcon = Icons.timer_off;
        break;
      default:
        outcomeTitle = 'ROUND CONCLUDED';
        outcomeDescription = outcome;
        outcomeIcon = Icons.check_circle_outline;
    }

    final sortedPlayers = totalScores.keys.toList()
      ..sort((a, b) => (totalScores[b] ?? 0).compareTo(totalScores[a] ?? 0));

    return Dialog(
      backgroundColor: PlayNedTokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        side: BorderSide(color: accent.withOpacity(0.6), width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Outcome Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent),
                  ),
                  child: Icon(outcomeIcon, size: 36, color: accent),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                outcomeTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                outcomeDescription,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: PlayNedTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Reveal Dossier Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PlayNedTokens.background,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: PlayNedTokens.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SECRET LOCATION:',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PlayNedTokens.textMuted,
                          ),
                        ),
                        Text(
                          secretLocation.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: PlayNedTokens.brandGold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: PlayNedTokens.borderSubtle, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'THE SPY WAS:',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PlayNedTokens.textMuted,
                          ),
                        ),
                        Text(
                          spyName.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: PlayNedTokens.accentSpyfall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Standings
              Text(
                'STANDINGS & ROUND POINTS',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: PlayNedTokens.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: PlayNedTokens.background,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: PlayNedTokens.borderSubtle),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedPlayers.length,
                  separatorBuilder: (_, __) => const Divider(color: PlayNedTokens.borderSubtle, height: 1),
                  itemBuilder: (context, index) {
                    final pid = sortedPlayers[index];
                    final name = playerNames[pid] ?? pid;
                    final total = totalScores[pid] ?? 0;
                    final pts = roundPoints[pid] ?? 0;
                    final isSpy = name == spyName;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '#${index + 1}',
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: PlayNedTokens.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSpy ? PlayNedTokens.accentSpyfall : PlayNedTokens.textPrimary,
                                  ),
                                ),
                                if (isSpy) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: PlayNedTokens.accentSpyfall.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      'SPY',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: PlayNedTokens.accentSpyfall,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            pts > 0 ? '+$pts pts  ' : '0 pts  ',
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: pts > 0 ? PlayNedTokens.sageGreen : PlayNedTokens.textMuted,
                            ),
                          ),
                          Text(
                            '$total PTS',
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: PlayNedTokens.brandGold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              if (isMatchOver) ...[
                PlayNedButton(
                  label: 'MATCH COMPLETE - EXIT',
                  icon: Icons.exit_to_app,
                  variant: PlayNedButtonVariant.primary,
                  accentColor: PlayNedTokens.brandGold,
                  onPressed: onLeave,
                ),
              ] else ...[
                PlayNedButton(
                  label: isHost ? 'NEXT ROUND (${currentRound + 1}/$totalRounds)' : 'READY FOR NEXT ROUND',
                  icon: Icons.arrow_forward,
                  variant: PlayNedButtonVariant.primary,
                  accentColor: PlayNedTokens.brandGold,
                  onPressed: onNextRound,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
