import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

import '../../models/mafia_models.dart';

/// Modal dialog for performing private night actions (Kill, Heal, Investigate, Guard).
class MafiaNightActionDialog extends StatefulWidget {
  final MafiaRoleType role;
  final String myPlayerId;
  final List<String> livingPlayerIds;
  final Map<String, String> playerNames;
  final List<String> mafiaTeammates;
  final bool allowSelfHeal;
  final String? initialSelectedTarget;
  final ValueChanged<String> onConfirmTarget;
  final VoidCallback onSkip;

  const MafiaNightActionDialog({
    super.key,
    required this.role,
    required this.myPlayerId,
    required this.livingPlayerIds,
    required this.playerNames,
    this.mafiaTeammates = const [],
    this.allowSelfHeal = false,
    this.initialSelectedTarget,
    required this.onConfirmTarget,
    required this.onSkip,
  });

  @override
  State<MafiaNightActionDialog> createState() => _MafiaNightActionDialogState();
}

class _MafiaNightActionDialogState extends State<MafiaNightActionDialog> {
  String? _selectedTarget;

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialSelectedTarget;
  }

  List<String> get _validCandidates {
    return widget.livingPlayerIds.where((pid) {
      if (widget.role == MafiaRoleType.doctor && !widget.allowSelfHeal) {
        if (pid == widget.myPlayerId) return false;
      }
      if (widget.role == MafiaRoleType.detective) {
        if (pid == widget.myPlayerId) return false;
      }
      return true;
    }).toList();
  }

  String get _actionTitle {
    switch (widget.role) {
      case MafiaRoleType.mafia:
        return 'MAFIA HIT TARGET';
      case MafiaRoleType.doctor:
        return 'SELECT PATIENT TO HEAL';
      case MafiaRoleType.detective:
        return 'SELECT SUSPECT TO INVESTIGATE';
      case MafiaRoleType.bodyguard:
        return 'SELECT VIP TO GUARD';
      default:
        return 'NIGHT ACTION';
    }
  }

  String get _actionSubtitle {
    switch (widget.role) {
      case MafiaRoleType.mafia:
        return 'Choose a townsperson to eliminate tonight under cover of darkness.';
      case MafiaRoleType.doctor:
        return widget.allowSelfHeal
            ? 'Choose any player to protect against Mafia attacks tonight.'
            : 'Choose another player to protect. (Self-heal is disabled)';
      case MafiaRoleType.detective:
        return 'Interrogate a suspect to uncover whether they belong to the Mafia.';
      case MafiaRoleType.bodyguard:
        return 'Sacrifice your guard to shield a fellow citizen tonight.';
      default:
        return 'Choose a target.';
    }
  }

  Color get _accentColor {
    switch (widget.role) {
      case MafiaRoleType.mafia:
        return PlayNedTokens.accentMafia;
      case MafiaRoleType.doctor:
        return PlayNedTokens.sageGreen;
      case MafiaRoleType.detective:
        return PlayNedTokens.accentDots;
      case MafiaRoleType.bodyguard:
        return PlayNedTokens.brandGold;
      default:
        return PlayNedTokens.brandGold;
    }
  }

  IconData get _actionIcon {
    switch (widget.role) {
      case MafiaRoleType.mafia:
        return Icons.gps_fixed;
      case MafiaRoleType.doctor:
        return Icons.healing;
      case MafiaRoleType.detective:
        return Icons.search;
      case MafiaRoleType.bodyguard:
        return Icons.shield;
      default:
        return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context) {
    final validTargets = _validCandidates;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        decoration: BoxDecoration(
          color: PlayNedTokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.2),
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
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(_actionIcon, color: _accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _actionTitle,
                        style: GoogleFonts.cinzel(
                          color: PlayNedTokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _actionSubtitle,
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

            // Target Candidate List
            Flexible(
              child: validTargets.isEmpty
                  ? Center(
                      child: Text(
                        'No eligible targets available.',
                        style: GoogleFonts.spaceMono(
                          color: PlayNedTokens.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: validTargets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final pid = validTargets[index];
                        final name = widget.playerNames[pid] ?? pid;
                        final isSelected = _selectedTarget == pid;
                        final isTeammate = widget.mafiaTeammates.contains(pid);
                        final isSelf = pid == widget.myPlayerId;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTarget = pid;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _accentColor.withValues(alpha: 0.15)
                                    : PlayNedTokens.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? _accentColor : PlayNedTokens.border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isSelected
                                        ? _accentColor
                                        : PlayNedTokens.surfaceHover,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: GoogleFonts.spaceMono(
                                        color: isSelected ? Colors.black : PlayNedTokens.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.spaceMono(
                                            color: PlayNedTokens.textPrimary,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (isSelf)
                                          Text(
                                            'Yourself',
                                            style: GoogleFonts.spaceMono(
                                              color: PlayNedTokens.sageGreen,
                                              fontSize: 10,
                                            ),
                                          )
                                        else if (isTeammate)
                                          Text(
                                            'Fellow Mafia Teammate',
                                            style: GoogleFonts.spaceMono(
                                              color: PlayNedTokens.accentMafia,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: _accentColor, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            const Divider(color: PlayNedTokens.border, height: 1),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: PlayNedButton(
                    label: 'Skip / No Target',
                    onPressed: widget.onSkip,
                    variant: PlayNedButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PlayNedButton(
                    label: 'Confirm Target',
                    onPressed: _selectedTarget != null
                        ? () => widget.onConfirmTarget(_selectedTarget!)
                        : null,
                    variant: PlayNedButtonVariant.primary,
                    customAccent: _accentColor,
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
