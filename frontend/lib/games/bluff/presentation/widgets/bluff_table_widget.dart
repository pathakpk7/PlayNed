import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/bluff_models.dart';
import 'playing_card_widget.dart';

class BluffTableWidget extends StatelessWidget {
  final BluffState state;
  final String activePerspectivePlayerId; // The player whose turn/device it is
  final VoidCallback? onChallengePressed;
  final VoidCallback? onPassPressed;
  final bool canChallenge;
  final bool canPass;

  const BluffTableWidget({
    super.key,
    required this.state,
    required this.activePerspectivePlayerId,
    this.onChallengePressed,
    this.onPassPressed,
    this.canChallenge = false,
    this.canPass = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13101E),
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle radial table felt styling
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    const Color(0xFF231B38),
                    const Color(0xFF110D1B),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(PlayNedTokens.space16),
            child: Column(
              children: [
                // 1. Opponents row across the top
                _buildOpponentsRow(),

                const Spacer(),

                // 2. Central Table Discard Pile & Callout Area
                _buildCentralPileArea(),

                const Spacer(),

                // 3. Challenge Window Actions (if phase is CHALLENGE)
                if (state.phase == BluffPhase.challenge)
                  _buildChallengeActionBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentsRow() {
    // Show all players other than the active perspective player
    final opponents = state.playerIds.where((pid) => pid != activePerspectivePlayerId).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: opponents.map((pid) {
          final isTurn = state.currentPlayerId == pid;
          final isLastPlayer = state.lastPlay?.playerId == pid;
          final cardCount = state.getPlayerCardCount(pid);
          final pName = state.getPlayerName(pid);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isTurn
                    ? const Color(0xFF8B5CF6).withOpacity(0.22)
                    : PlayNedTokens.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isTurn
                      ? const Color(0xFF8B5CF6)
                      : (isLastPlayer
                          ? const Color(0xFFEAB308)
                          : PlayNedTokens.borderSubtle),
                  width: isTurn ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isTurn
                        ? const Color(0xFF8B5CF6)
                        : PlayNedTokens.surfaceHover,
                    child: Text(
                      pName.isNotEmpty ? pName[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isTurn ? FontWeight.bold : FontWeight.w600,
                          color: isTurn ? Colors.white : PlayNedTokens.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.style, size: 10, color: Color(0xFFA78BFA)),
                          const SizedBox(width: 3),
                          Text(
                            '$cardCount card${cardCount == 1 ? '' : 's'}',
                            style: GoogleFonts.spaceMono(
                              fontSize: 9.5,
                              color: const Color(0xFFA78BFA),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCentralPileArea() {
    final lastPlay = state.lastPlay;
    final pileCount = state.pileCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Required Rank Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.18),
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.6),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radar, size: 14, color: Color(0xFFA78BFA)),
              const SizedBox(width: 6),
              Text(
                'CURRENT REQUIRED RANK: ',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PlayNedTokens.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${state.requiredRank}s',
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFC4B5FD),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Discard Pile Stack
        SizedBox(
          height: 96,
          width: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (pileCount == 0)
                Container(
                  width: 64,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PlayNedTokens.borderSubtle,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'EMPTY\nPILE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: PlayNedTokens.textMuted,
                      ),
                    ),
                  ),
                )
              else ...[
                // Stacked effect with slight offsets
                if (pileCount > 2)
                  Transform.translate(
                    offset: const Offset(-6, -4),
                    child: const PlayingCardWidget(isFaceUp: false, width: 62, height: 88),
                  ),
                if (pileCount > 1)
                  Transform.translate(
                    offset: const Offset(4, -2),
                    child: const PlayingCardWidget(isFaceUp: false, width: 62, height: 88),
                  ),
                const PlayingCardWidget(isFaceUp: false, width: 64, height: 90),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Pile Count Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: PlayNedTokens.surfaceElevated,
            borderRadius: BorderRadius.circular( PlayNedTokens.radiusPill),
            border: Border.all(color: PlayNedTokens.borderSubtle),
          ),
          child: Text(
            '$pileCount cards in center pile',
            style: GoogleFonts.spaceMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: PlayNedTokens.textSecondary,
            ),
          ),
        ),

        // Last Play Banner (if available)
        if (lastPlay != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B).withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_off_outlined, size: 14, color: Color(0xFF818CF8)),
                const SizedBox(width: 6),
                Text(
                  '${lastPlay.playerName} played ${lastPlay.cardCount} card${lastPlay.cardCount > 1 ? 's' : ''} claiming ${lastPlay.declaredRank}s',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE0E7FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChallengeActionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PlayNedTokens.space12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFFB7185)),
              const SizedBox(width: 6),
              Text(
                'CHALLENGE WINDOW OPEN',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFB7185),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (canChallenge)
                ElevatedButton.icon(
                  icon: const Icon(Icons.gavel, size: 15, color: Colors.white),
                  label: Text(
                    'CALL BLUFF!',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onChallengePressed,
                ),
              if (canChallenge && canPass) const SizedBox(width: 12),
              if (canPass)
                OutlinedButton.icon(
                  icon: const Icon(Icons.check, size: 15, color: Color(0xFFCBD5E1)),
                  label: Text(
                    'PASS / TRUST',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onPassPressed,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
