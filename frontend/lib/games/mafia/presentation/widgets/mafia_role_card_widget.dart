import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Classified Role Card displaying secret role, faction badge, and night instructions.
class MafiaRoleCardWidget extends StatefulWidget {
  final String roleName;
  final bool isAlive;
  final List<String> mafiaTeammates;
  final Map<String, String> playerNames;
  final VoidCallback? onOpenInvestigations;
  final bool hasInvestigations;

  const MafiaRoleCardWidget({
    super.key,
    required this.roleName,
    this.isAlive = true,
    this.mafiaTeammates = const [],
    this.playerNames = const {},
    this.onOpenInvestigations,
    this.hasInvestigations = false,
  });

  @override
  State<MafiaRoleCardWidget> createState() => _MafiaRoleCardWidgetState();
}

class _MafiaRoleCardWidgetState extends State<MafiaRoleCardWidget> {
  bool _concealed = false;

  Color _getRoleAccent() {
    switch (widget.roleName.toLowerCase()) {
      case 'mafia':
      case 'werewolf':
        return const Color(0xFFDC2626); // Crimson Red
      case 'doctor':
        return const Color(0xFF10B981); // Emerald Green
      case 'detective':
        return const Color(0xFF3B82F6); // Electric Blue
      case 'bodyguard':
        return const Color(0xFFF59E0B); // Amber Gold
      case 'jester':
        return const Color(0xFF8B5CF6); // Royal Violet
      case 'villager':
      default:
        return PlayNedTokens.brandGold;
    }
  }

  IconData _getRoleIcon() {
    switch (widget.roleName.toLowerCase()) {
      case 'mafia':
      case 'werewolf':
        return Icons.masks;
      case 'doctor':
        return Icons.medical_services_outlined;
      case 'detective':
        return Icons.search;
      case 'bodyguard':
        return Icons.shield;
      case 'jester':
        return Icons.theater_comedy;
      case 'villager':
      default:
        return Icons.people_outline;
    }
  }

  String _getRoleDescription() {
    switch (widget.roleName.toLowerCase()) {
      case 'mafia':
      case 'werewolf':
        return 'You belong to the Mafia syndicate. Coordinate with your fellow members each night to eliminate town citizens.';
      case 'doctor':
        return 'You are the town physician. Each night, choose one citizen to heal and protect from Mafia attacks.';
      case 'detective':
        return 'You are the town investigator. Each night, inspect one suspect to privately uncover if they belong to the Mafia.';
      case 'bodyguard':
        return 'You guard a fellow citizen each night, intercepting fatal attacks.';
      case 'jester':
        return 'You belong to no faction. Win the game by acting suspicious enough to get exiled during the daytime vote!';
      case 'villager':
      default:
        return 'You are an innocent citizen. You have no night abilities—use daytime discussion and your vote to root out the Mafia.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _getRoleAccent();
    final roleTitle = widget.roleName.toUpperCase();

    return Container(
      constraints: const BoxConstraints(maxWidth: 540),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(
          color: accent.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(PlayNedTokens.radiusMd - 1)),
              border: Border(bottom: BorderSide(color: accent.withOpacity(0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getRoleIcon(), size: 16, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'TOP SECRET // CLASSIFIED ROLE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => setState(() => _concealed = !_concealed),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          _concealed ? Icons.visibility : Icons.visibility_off,
                          size: 14,
                          color: PlayNedTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _concealed ? 'REVEAL' : 'HIDE',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PlayNedTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: _concealed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock, size: 36, color: PlayNedTokens.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            'ROLE CONCEALED',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PlayNedTokens.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "REVEAL" to view your identity',
                            style: PlayNedTokens.metadata.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: accent),
                            ),
                            child: Icon(_getRoleIcon(), size: 28, color: accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        widget.roleName.toLowerCase() == 'mafia' ? 'MAFIA FACTION' : 'TOWN FACTION',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (!widget.isAlive) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: PlayNedTokens.surfaceHover,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          'DECEASED',
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: PlayNedTokens.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  roleTitle,
                                  style: GoogleFonts.syne(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: PlayNedTokens.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _getRoleDescription(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          height: 1.45,
                          color: PlayNedTokens.textSecondary,
                        ),
                      ),

                      // Mafia Teammate Reveal
                      if (widget.roleName.toLowerCase() == 'mafia' && widget.mafiaTeammates.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PlayNedTokens.background,
                            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                            border: Border.all(color: accent.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FELLOW MAFIA SYNDICATE:',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: widget.mafiaTeammates.map((mPid) {
                                  final mName = widget.playerNames[mPid] ?? mPid;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      mName,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: PlayNedTokens.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Detective Case Log Shortcut
                      if (widget.hasInvestigations && widget.onOpenInvestigations != null) ...[
                        const SizedBox(height: 12),
                        PlayNedButton(
                          label: 'VIEW INVESTIGATION DOSSIER',
                          icon: Icons.folder_open,
                          variant: PlayNedButtonVariant.secondary,
                          customAccent: const Color(0xFF3B82F6),
                          onPressed: widget.onOpenInvestigations,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
