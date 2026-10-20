import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Modal dialog for voting on an active accusation.
class SpyfallVotingDialog extends StatelessWidget {
  final String accusedName;
  final String accuserName;
  final String currentVoterName;
  final ValueChanged<String> onVote; // 'guilty' or 'innocent'

  const SpyfallVotingDialog({
    super.key,
    required this.accusedName,
    required this.accuserName,
    required this.currentVoterName,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PlayNedTokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        side: BorderSide(color: PlayNedTokens.accentSpyfall.withOpacity(0.5), width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: PlayNedTokens.accentSpyfall, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ACCUSATION IN PROGRESS',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: PlayNedTokens.accentSpyfall,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PlayNedTokens.background,
                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                border: Border.all(color: PlayNedTokens.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: PlayNedTokens.textPrimary,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: accuserName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' has accused '),
                        TextSpan(
                          text: accusedName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: PlayNedTokens.accentSpyfall,
                          ),
                        ),
                        const TextSpan(text: ' of being the SPY!'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'VOTER: $currentVoterName',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: PlayNedTokens.brandGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A strict majority (>50%) is required to convict.',
                    style: PlayNedTokens.metadata.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PlayNedButton(
                    label: 'INNOCENT',
                    icon: Icons.shield_outlined,
                    variant: PlayNedButtonVariant.secondary,
                    onPressed: () => onVote('innocent'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PlayNedButton(
                    label: 'GUILTY',
                    icon: Icons.fingerprint,
                    variant: PlayNedButtonVariant.primary,
                    accentColor: PlayNedTokens.accentSpyfall,
                    onPressed: () => onVote('guilty'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
