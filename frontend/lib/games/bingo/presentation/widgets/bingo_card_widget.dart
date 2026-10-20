import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/bingo_models.dart';
import '../../services/bingo_engine.dart';

class BingoCardWidget extends StatelessWidget {
  final BingoCard card;
  final String playerTitle;
  final bool isLocalPlayer;
  final Color accentColor;
  final List<int> winningCells;
  final int? lastCalledNumber;

  const BingoCardWidget({
    super.key,
    required this.card,
    required this.playerTitle,
    this.isLocalPlayer = true,
    this.accentColor = PlayNedTokens.brandGold,
    this.winningCells = const [],
    this.lastCalledNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(
          color: winningCells.isNotEmpty
              ? accentColor.withOpacity(0.8)
              : PlayNedTokens.border,
          width: winningCells.isNotEmpty ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: winningCells.isNotEmpty
                ? accentColor.withOpacity(0.25)
                : Colors.black.withOpacity(0.35),
            blurRadius: winningCells.isNotEmpty ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(PlayNedTokens.space12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player Card Title & Marked Counter
          Padding(
            padding: const EdgeInsets.only(bottom: PlayNedTokens.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      playerTitle.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: PlayNedTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PlayNedTokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
                    border: Border.all(color: PlayNedTokens.borderSubtle),
                  ),
                  child: Text(
                    '${card.markedCount}/25 MARKED',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // B-I-N-G-O Header Row
          Row(
            children: List.generate(5, (colIdx) {
              final letter = BingoEngine.columnLetters[colIdx];
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),

          // 5x5 Number Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1.0,
            ),
            itemCount: 25,
            itemBuilder: (context, idx) {
              return _buildCell(context, idx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, int index) {
    final isFree = card.isFree(index);
    final number = card.getNumber(index);
    final isMarked = card.isMarked(index);
    final isWinningCell = winningCells.contains(index);
    final isJustCalled = lastCalledNumber != null && number == lastCalledNumber;
    final letter = BingoEngine.columnLetters[index % 5];

    final semanticLabel = isFree
        ? 'Free space, automatically marked'
        : 'Bingo cell $letter$number, ${isMarked ? "marked" : "unmarked"}';

    // Cell background styling
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isWinningCell) {
      bgColor = accentColor.withOpacity(0.38);
      borderColor = accentColor;
      textColor = PlayNedTokens.textPrimary;
    } else if (isFree) {
      bgColor = accentColor.withOpacity(0.20);
      borderColor = accentColor.withOpacity(0.5);
      textColor = accentColor;
    } else if (isMarked) {
      bgColor = isJustCalled
          ? accentColor.withOpacity(0.32)
          : accentColor.withOpacity(0.22);
      borderColor = accentColor.withOpacity(0.65);
      textColor = PlayNedTokens.textPrimary;
    } else {
      bgColor = PlayNedTokens.surfaceElevated;
      borderColor = PlayNedTokens.borderSubtle;
      textColor = PlayNedTokens.textSecondary;
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: AnimatedContainer(
        duration: PlayNedTokens.animFast,
        curve: PlayNedTokens.animCurve,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
          border: Border.all(
            color: borderColor,
            width: isWinningCell ? 2.0 : (isMarked ? 1.5 : 1.0),
          ),
          boxShadow: isWinningCell
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Marked tactile check badge in top-right corner
            if (isMarked && !isFree)
              Positioned(
                top: 2,
                right: 3,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 10,
                  color: isWinningCell ? PlayNedTokens.textPrimary : accentColor,
                ),
              ),

            // Number or FREE Text
            if (isFree)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                  Text(
                    'FREE',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: accentColor,
                    ),
                  ),
                ],
              )
            else
              Text(
                '$number',
                style: GoogleFonts.spaceMono(
                  fontSize: 15,
                  fontWeight: isMarked ? FontWeight.w900 : FontWeight.w600,
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
