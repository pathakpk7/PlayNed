import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Roster of 3 to 8 players in the Spyfall session.
class SpyfallPlayerRosterWidget extends StatelessWidget {
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final Map<String, int> scores;
  final String? myPlayerId;
  final String? activeAccusedId;
  final String? activeAccuserId;
  final Map<String, String>? currentVotes; // playerId -> 'guilty'/'innocent'
  final bool canAccuse;
  final ValueChanged<String>? onAccuse;

  const SpyfallPlayerRosterWidget({
    super.key,
    required this.playerIds,
    required this.playerNames,
    required this.scores,
    this.myPlayerId,
    this.activeAccusedId,
    this.activeAccuserId,
    this.currentVotes,
    this.canAccuse = false,
    this.onAccuse,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 550;
        final crossAxisCount = isWide ? 4 : (constraints.maxWidth > 340 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isWide ? 2.2 : 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: playerIds.length,
          itemBuilder: (context, index) {
            final pid = playerIds[index];
            final name = playerNames[pid] ?? pid;
            final score = scores[pid] ?? 0;
            final isMe = pid == myPlayerId;
            final isAccused = pid == activeAccusedId;
            final isAccuser = pid == activeAccuserId;
            final hasVoted = currentVotes != null && currentVotes!.containsKey(pid);

            Color borderColor = PlayNedTokens.borderSubtle;
            Color bgColor = PlayNedTokens.surfaceElevated;

            if (isAccused) {
              borderColor = PlayNedTokens.accentSpyfall;
              bgColor = PlayNedTokens.accentSpyfall.withOpacity(0.12);
            } else if (isMe) {
              borderColor = PlayNedTokens.brandGold.withOpacity(0.5);
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                border: Border.all(color: borderColor, width: isAccused ? 2 : 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isAccused
                        ? PlayNedTokens.accentSpyfall
                        : (isMe ? PlayNedTokens.brandGold : PlayNedTokens.surfaceHover),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (isAccused || isMe) ? Colors.black : PlayNedTokens.textPrimary,
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PlayNedTokens.textPrimary,
                                ),
                              ),
                            ),
                            if (isMe)
                              Text(
                                ' (YOU)',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: PlayNedTokens.brandGold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '$score PTS',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: PlayNedTokens.textSecondary,
                              ),
                            ),
                            if (isAccused) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: PlayNedTokens.accentSpyfall,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'ACCUSED',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ] else if (isAccuser) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: PlayNedTokens.surfaceHover,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'ACCUSER',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 8,
                                    color: PlayNedTokens.textSecondary,
                                  ),
                                ),
                              ),
                            ] else if (hasVoted) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.check_circle, size: 12, color: PlayNedTokens.sageGreen),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canAccuse && !isMe && activeAccusedId == null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.gavel, size: 16),
                      tooltip: 'Accuse $name',
                      color: PlayNedTokens.accentSpyfall,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => onAccuse?.call(pid),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
