import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

import '../../models/mafia_models.dart';

/// Morning Announcement modal informing all players of night casualties or doctor saves.
class MafiaAnnouncementDialog extends StatelessWidget {
  final int roundNumber;
  final String? casualtyId;
  final String? casualtyName;
  final MafiaRoleType? casualtyRole;
  final bool revealRole;
  final VoidCallback onProceedToDiscussion;

  const MafiaAnnouncementDialog({
    super.key,
    required this.roundNumber,
    this.casualtyId,
    this.casualtyName,
    this.casualtyRole,
    this.revealRole = true,
    required this.onProceedToDiscussion,
  });

  @override
  Widget build(BuildContext context) {
    final bool someoneDied = casualtyId != null && casualtyId!.isNotEmpty;
    final accent = someoneDied ? PlayNedTokens.accentMafia : PlayNedTokens.sageGreen;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Morning Header
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: PlayNedTokens.brandGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PlayNedTokens.brandGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny, color: PlayNedTokens.brandGold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'DAYBREAK // ROUND $roundNumber',
                      style: GoogleFonts.spaceMono(
                        color: PlayNedTokens.brandGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
                ),
                child: Icon(
                  someoneDied ? Icons.sentiment_very_dissatisfied : Icons.health_and_safety,
                  color: accent,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Center(
              child: Text(
                someoneDied ? 'A CITIZEN HAS FALLEN' : 'PEACEFUL MORNING',
                style: GoogleFonts.cinzel(
                  color: PlayNedTokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Body
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PlayNedTokens.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PlayNedTokens.border),
              ),
              child: Column(
                children: [
                  Text(
                    someoneDied
                        ? 'Under the shroud of night, the Mafia claimed a life:'
                        : 'The sun rises over the town square. Miraculously, nobody died last night!\nThe Doctor arrived in the nick of time, or no shots were fired.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      color: PlayNedTokens.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (someoneDied) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: PlayNedTokens.accentMafia.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PlayNedTokens.accentMafia.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_off, color: PlayNedTokens.accentMafia, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            casualtyName ?? casualtyId ?? 'Unknown Citizen',
                            style: GoogleFonts.spaceMono(
                              color: PlayNedTokens.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (revealRole && casualtyRole != null) ...[
                            Text(
                              '  •  ${casualtyRole!.displayName}',
                              style: GoogleFonts.spaceMono(
                                color: PlayNedTokens.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Proceed Button
            PlayNedButton(
              label: 'Proceed to Discussion',
              onPressed: onProceedToDiscussion,
              variant: PlayNedButtonVariant.primary,
              customAccent: accent,
            ),
          ],
        ),
      ),
    );
  }
}
