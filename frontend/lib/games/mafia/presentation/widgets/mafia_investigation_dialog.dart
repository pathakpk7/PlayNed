import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

import '../../models/mafia_models.dart';

/// Modal dialog displaying the Detective's confidential investigation notebook / case log.
class MafiaInvestigationDialog extends StatelessWidget {
  final List<InvestigationResult> investigations;
  final VoidCallback onClose;

  const MafiaInvestigationDialog({
    super.key,
    required this.investigations,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const accent = PlayNedTokens.accentDots;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.manage_search, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DETECTIVE CASE DOSSIER',
                        style: GoogleFonts.cinzel(
                          color: PlayNedTokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confidential Intel gathered under interrogation.',
                        style: GoogleFonts.spaceMono(
                          color: PlayNedTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: PlayNedTokens.border, height: 1),
            const SizedBox(height: 14),

            // Logs
            Flexible(
              child: investigations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: PlayNedTokens.textMuted, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'No investigations logged yet.\nCheck suspects during Night phase.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceMono(
                              color: PlayNedTokens.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: investigations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = investigations[index];
                        final isMafia = item.isMafia;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PlayNedTokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isMafia
                                  ? PlayNedTokens.accentMafia.withValues(alpha: 0.5)
                                  : PlayNedTokens.sageGreen.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: PlayNedTokens.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'R${item.round}',
                                  style: GoogleFonts.spaceMono(
                                    color: PlayNedTokens.brandGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.targetName,
                                      style: GoogleFonts.spaceMono(
                                        color: PlayNedTokens.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Target ID: ${item.targetId}',
                                      style: GoogleFonts.spaceMono(
                                        color: PlayNedTokens.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isMafia
                                      ? PlayNedTokens.accentMafia.withValues(alpha: 0.2)
                                      : PlayNedTokens.sageGreen.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isMafia ? PlayNedTokens.accentMafia : PlayNedTokens.sageGreen,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isMafia ? Icons.warning_rounded : Icons.verified_user,
                                      color: isMafia ? PlayNedTokens.accentMafia : PlayNedTokens.sageGreen,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isMafia ? 'MAFIA' : 'NOT MAFIA',
                                      style: GoogleFonts.spaceMono(
                                        color: isMafia ? PlayNedTokens.accentMafia : PlayNedTokens.sageGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            const Divider(color: PlayNedTokens.border, height: 1),
            const SizedBox(height: 14),

            // Close Button
            PlayNedButton(
              label: 'Close Dossier',
              onPressed: onClose,
              variant: PlayNedButtonVariant.primary,
              customAccent: accent,
            ),
          ],
        ),
      ),
    );
  }
}
