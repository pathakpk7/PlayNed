import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

import '../../models/mafia_models.dart';

/// Modal dialog showing the results of the town's democratic voting / trial.
class MafiaVoteResultDialog extends StatelessWidget {
  final int roundNumber;
  final String? exiledId;
  final String? exiledName;
  final MafiaRoleType? exiledRole;
  final bool revealRole;
  final Map<String, String> votes; // voterId -> targetId
  final Map<String, String> playerNames;
  final bool isGameOver;
  final VoidCallback onProceed;

  const MafiaVoteResultDialog({
    super.key,
    required this.roundNumber,
    this.exiledId,
    this.exiledName,
    this.exiledRole,
    this.revealRole = true,
    required this.votes,
    required this.playerNames,
    this.isGameOver = false,
    required this.onProceed,
  });

  Map<String, int> get _voteCounts {
    final counts = <String, int>{};
    for (final targetId in votes.values) {
      counts[targetId] = (counts[targetId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final bool someoneExiled = exiledId != null && exiledId!.isNotEmpty;
    final bool isJester = exiledRole == MafiaRoleType.jester;
    final accent = isJester
        ? PlayNedTokens.brandGold
        : (someoneExiled ? PlayNedTokens.accentMafia : PlayNedTokens.sageGreen);

    final counts = _voteCounts;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        decoration: BoxDecoration(
          color: PlayNedTokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.2),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PlayNedTokens.border),
                ),
                child: Text(
                  'TRIAL VERDICT // ROUND $roundNumber',
                  style: GoogleFonts.spaceMono(
                    color: PlayNedTokens.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
                ),
                child: Icon(
                  isJester
                      ? Icons.theater_comedy
                      : (someoneExiled ? Icons.gavel : Icons.balance),
                  color: accent,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Verdict Title
            Center(
              child: Text(
                isJester
                    ? 'THE JESTER HAS WON!'
                    : (someoneExiled ? 'CITIZEN EXILED' : 'NO CITIZEN EXILED'),
                style: GoogleFonts.cinzel(
                  color: PlayNedTokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Verdict description
            Text(
              isJester
                  ? '${exiledName ?? exiledId} was secretly the Jester! By voting them out, the town fell directly into their trap.'
                  : (someoneExiled
                      ? 'By majority vote, the town has decided to eliminate ${exiledName ?? exiledId}.'
                      : 'The vote ended in a tie or all citizens abstained. Nobody was exiled today.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                color: PlayNedTokens.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            if (someoneExiled && revealRole && exiledRole != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'True Role: ${exiledRole!.displayName} (${exiledRole!.faction.name.toUpperCase()})',
                    style: GoogleFonts.spaceMono(
                      color: PlayNedTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(color: PlayNedTokens.border, height: 1),
            const SizedBox(height: 12),

            // Vote Tally
            Text(
              'VOTE TALLY',
              style: GoogleFonts.spaceMono(
                color: PlayNedTokens.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            Flexible(
              child: counts.isEmpty
                  ? Center(
                      child: Text(
                        'No votes were cast.',
                        style: GoogleFonts.spaceMono(
                          color: PlayNedTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: counts.entries.map((entry) {
                        final targetName = playerNames[entry.key] ?? entry.key;
                        final voteCount = entry.value;
                        final isWinner = entry.key == exiledId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isWinner
                                ? accent.withValues(alpha: 0.15)
                                : PlayNedTokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isWinner ? accent : PlayNedTokens.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  targetName,
                                  style: GoogleFonts.spaceMono(
                                    color: PlayNedTokens.textPrimary,
                                    fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isWinner ? accent : PlayNedTokens.surfaceHover,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$voteCount ${voteCount == 1 ? "vote" : "votes"}',
                                  style: GoogleFonts.spaceMono(
                                    color: isWinner ? Colors.black : PlayNedTokens.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
            const Divider(color: PlayNedTokens.border, height: 1),
            const SizedBox(height: 14),

            // Proceed Button
            PlayNedButton(
              label: isGameOver ? 'View Match Results' : 'Proceed to Night Phase',
              onPressed: onProceed,
              variant: PlayNedButtonVariant.primary,
              customAccent: accent,
            ),
          ],
        ),
      ),
    );
  }
}
