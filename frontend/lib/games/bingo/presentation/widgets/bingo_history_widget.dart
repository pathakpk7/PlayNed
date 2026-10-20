import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../services/bingo_engine.dart';

class BingoHistoryWidget extends StatelessWidget {
  final List<int> drawnNumbers;
  final int? latestNumber;
  final Color accentColor;

  const BingoHistoryWidget({
    super.key,
    required this.drawnNumbers,
    this.latestNumber,
    this.accentColor = PlayNedTokens.brandGold,
  });

  @override
  Widget build(BuildContext context) {
    final drawnSet = drawnNumbers.toSet();

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(PlayNedTokens.space12),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CALLED NUMBERS BOARD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: PlayNedTokens.textSecondary,
                ),
              ),
              Text(
                '${drawnNumbers.length}/75 CALLED',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 5 Column Rows: B, I, N, G, O
          Column(
            children: List.generate(5, (colIdx) {
              final letter = BingoEngine.columnLetters[colIdx];
              final range = BingoEngine.columnRanges[colIdx]!;
              final minVal = range[0];
              final maxVal = range[1];
              final count = maxVal - minVal + 1;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    // Letter tag
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: accentColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        letter,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Numbers in this column
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(count, (offset) {
                            final numVal = minVal + offset;
                            final isCalled = drawnSet.contains(numVal);
                            final isLatest = latestNumber == numVal;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 21,
                              height: 21,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isLatest
                                    ? accentColor
                                    : (isCalled
                                        ? accentColor.withOpacity(0.25)
                                        : PlayNedTokens.surfaceElevated),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: isLatest
                                      ? accentColor
                                      : (isCalled
                                          ? accentColor.withOpacity(0.6)
                                          : PlayNedTokens.borderSubtle),
                                  width: isLatest ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                '$numVal',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  fontWeight: isCalled ? FontWeight.w800 : FontWeight.w500,
                                  color: isLatest
                                      ? PlayNedTokens.textInverse
                                      : (isCalled
                                          ? PlayNedTokens.textPrimary
                                          : PlayNedTokens.textMuted.withOpacity(0.5)),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
