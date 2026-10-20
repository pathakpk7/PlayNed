import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Player list/grid supporting 5–12 players with targeting and status badges.
class MafiaPlayerListWidget extends StatelessWidget {
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final Map<String, bool> aliveStatus;
  final Map<String, String>? revealedRoles;
  final String? myPlayerId;
  final String? selectedTargetId;
  final List<String> votedPlayerIds;
  final bool isTargetingAllowed;
  final String actionLabel;
  final Color actionColor;
  final ValueChanged<String>? onTargetSelected;

  const MafiaPlayerListWidget({
    super.key,
    required this.playerIds,
    required this.playerNames,
    required this.aliveStatus,
    this.revealedRoles,
    this.myPlayerId,
    this.selectedTargetId,
    this.votedPlayerIds = const [],
    this.isTargetingAllowed = false,
    this.actionLabel = 'SELECT',
    this.actionColor = PlayNedTokens.brandGold,
    this.onTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 580;
        final crossAxisCount = isWide ? 4 : (constraints.maxWidth > 380 ? 3 : 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isWide ? 2.1 : 2.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: playerIds.length,
          itemBuilder: (context, index) {
            final pid = playerIds[index];
            final name = playerNames[pid] ?? pid;
            final isAlive = aliveStatus[pid] ?? true;
            final isMe = pid == myPlayerId;
            final isSelected = pid == selectedTargetId;
            final hasVoted = votedPlayerIds.contains(pid);
            final revealedRole = revealedRoles?[pid];

            Color border = PlayNedTokens.borderSubtle;
            Color bg = PlayNedTokens.surfaceElevated;

            if (!isAlive) {
              bg = PlayNedTokens.background.withOpacity(0.5);
              border = PlayNedTokens.borderSubtle.withOpacity(0.4);
            } else if (isSelected) {
              border = actionColor;
              bg = actionColor.withOpacity(0.15);
            } else if (isMe) {
              border = PlayNedTokens.brandGold.withOpacity(0.4);
            }

            final canTarget = isTargetingAllowed && isAlive && !isMe;

            return InkWell(
              onTap: canTarget ? () => onTargetSelected?.call(pid) : null,
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: border, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: !isAlive
                          ? PlayNedTokens.surfaceHover
                          : (isSelected
                              ? actionColor
                              : (isMe ? PlayNedTokens.brandGold : PlayNedTokens.surfaceHover)),
                      child: !isAlive
                          ? const Icon(Icons.close, size: 14, color: PlayNedTokens.textMuted)
                          : Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected || isMe ? Colors.black : PlayNedTokens.textPrimary,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    decoration: isAlive ? null : TextDecoration.lineThrough,
                                    color: isAlive ? PlayNedTokens.textPrimary : PlayNedTokens.textMuted,
                                  ),
                                ),
                              ),
                              if (isMe)
                                Text(
                                  ' *',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: PlayNedTokens.brandGold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (!isAlive) ...[
                                Text(
                                  revealedRole != null ? revealedRole.toUpperCase() : 'DEAD',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ] else if (hasVoted) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: PlayNedTokens.sageGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    'VOTED',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                      color: PlayNedTokens.sageGreen,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'ALIVE',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 8.5,
                                    color: PlayNedTokens.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (canTarget) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                        color: isSelected ? actionColor : PlayNedTokens.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
