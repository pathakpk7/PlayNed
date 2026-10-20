import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

import '../../models/mafia_models.dart';

/// Grand Victory Dialog revealing all true player roles, winning faction, and rematch controls.
class MafiaMatchResultDialog extends StatelessWidget {
  final String winningFaction; // "town", "mafia", "jester"
  final List<String> winnerPlayerIds;
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final Map<String, String> roleAssignments; // pid -> role name
  final Map<String, bool> aliveStatus;
  final VoidCallback onRematch;
  final VoidCallback onLeave;

  const MafiaMatchResultDialog({
    super.key,
    required this.winningFaction,
    required this.winnerPlayerIds,
    required this.playerIds,
    required this.playerNames,
    required this.roleAssignments,
    required this.aliveStatus,
    required this.onRematch,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    Color factionAccent;
    String title;
    String subtitle;
    IconData victoryIcon;

    switch (winningFaction.toLowerCase()) {
      case 'mafia':
        factionAccent = PlayNedTokens.accentMafia;
        title = 'MAFIA VICTORY';
        subtitle = 'The Mafia has successfully taken control of the town! Crime rules supreme.';
        victoryIcon = Icons.groups_2_rounded;
        break;
      case 'jester':
        factionAccent = PlayNedTokens.brandGold;
        title = 'JESTER VICTORY';
        subtitle = 'The Jester manipulated the town into executing them and won alone!';
        victoryIcon = Icons.theater_comedy;
        break;
      case 'town':
      default:
        factionAccent = PlayNedTokens.sageGreen;
        title = 'TOWN VICTORY';
        subtitle = 'Justice has prevailed! All Mafia operatives have been identified and eliminated.';
        victoryIcon = Icons.verified_user;
        break;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        decoration: BoxDecoration(
          color: PlayNedTokens.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: factionAccent.withValues(alpha: 0.6), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: factionAccent.withValues(alpha: 0.25),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Victory Crest
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: factionAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: factionAccent, width: 2),
                ),
                child: Icon(victoryIcon, color: factionAccent, size: 36),
              ),
            ),
            const SizedBox(height: 16),

            // Victory Title
            Center(
              child: Text(
                title,
                style: GoogleFonts.cinzel(
                  color: PlayNedTokens.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 6),

            Center(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  color: PlayNedTokens.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: PlayNedTokens.border, height: 1),
            const SizedBox(height: 14),

            // Roster Role Reveal Header
            Row(
              children: [
                const Icon(Icons.badge, color: PlayNedTokens.textMuted, size: 16),
                const SizedBox(width: 8),
                Text(
                  'ALL PLAYER ROLES REVEALED',
                  style: GoogleFonts.spaceMono(
                    color: PlayNedTokens.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Roster List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: playerIds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pid = playerIds[index];
                  final name = playerNames[pid] ?? pid;
                  final rawRole = roleAssignments[pid] ?? 'villager';
                  final role = MafiaRoleType.fromString(rawRole);
                  final isAlive = aliveStatus[pid] ?? true;
                  final isWinner = winnerPlayerIds.contains(pid);

                  Color roleBadgeColor;
                  switch (role.faction) {
                    case MafiaFaction.mafia:
                      roleBadgeColor = PlayNedTokens.accentMafia;
                      break;
                    case MafiaFaction.neutral:
                      roleBadgeColor = PlayNedTokens.brandGold;
                      break;
                    case MafiaFaction.town:
                    default:
                      roleBadgeColor = PlayNedTokens.sageGreen;
                      break;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isWinner
                          ? roleBadgeColor.withValues(alpha: 0.1)
                          : PlayNedTokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isWinner
                            ? roleBadgeColor.withValues(alpha: 0.5)
                            : PlayNedTokens.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: roleBadgeColor.withValues(alpha: 0.2),
                          child: Icon(
                            role == MafiaRoleType.mafia
                                ? Icons.groups
                                : (role == MafiaRoleType.doctor
                                    ? Icons.healing
                                    : (role == MafiaRoleType.detective
                                        ? Icons.search
                                        : (role == MafiaRoleType.jester
                                            ? Icons.theater_comedy
                                            : Icons.person))),
                            color: roleBadgeColor,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.spaceMono(
                                      color: PlayNedTokens.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isWinner) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.star, color: PlayNedTokens.brandGold, size: 14),
                                  ],
                                ],
                              ),
                              Text(
                                isAlive ? 'Survived' : 'Eliminated',
                                style: GoogleFonts.spaceMono(
                                  color: isAlive ? PlayNedTokens.sageGreen : PlayNedTokens.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleBadgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: roleBadgeColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            role.displayName.toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              color: roleBadgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: PlayNedTokens.border, height: 1),
            const SizedBox(height: 16),

            // Controls
            Row(
              children: [
                Expanded(
                  child: PlayNedButton(
                    label: 'Exit to Lobby',
                    onPressed: onLeave,
                    variant: PlayNedButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PlayNedButton(
                    label: 'Play Again',
                    onPressed: onRematch,
                    variant: PlayNedButtonVariant.primary,
                    customAccent: factionAccent,
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
