import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/reversi_game_state.dart';

class ReversiBoardWidget extends StatelessWidget {
  final ReversiGameState state;
  final Function(int r, int c) onCellTapped;
  final bool showHints;
  final bool isInteractive;

  const ReversiBoardWidget({
    super.key,
    required this.state,
    required this.onCellTapped,
    this.showHints = true,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final legalMoves = state.currentLegalMoves;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0C2418), // Deep Classic Emerald Felt
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
          border: Border.all(color: PlayNedTokens.accentReversi.withOpacity(0.6), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top column notation (a-h)
            _buildColumnLabels(),
            const SizedBox(height: 4),
            // Board grid + row notations
            Expanded(
              child: Row(
                children: [
                  _buildRowLabels(),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10402B),
                          border: Border.all(color: const Color(0xFF0A291B), width: 1.5),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            crossAxisSpacing: 1.5,
                            mainAxisSpacing: 1.5,
                          ),
                          itemCount: 64,
                          itemBuilder: (context, index) {
                            final r = index ~/ 8;
                            final c = index % 8;
                            final discVal = state.board[r][c];
                            final coord = ReversiCoord(r, c);
                            final isLegal = showHints && legalMoves.containsKey(coord);
                            final flipCount = isLegal ? legalMoves[coord]!.length : 0;
                            final isLastMove = state.lastMoveCoord == coord;
                            final squareType = ReversiGameState.classifySquare(r, c);

                            return _buildCell(
                              r: r,
                              c: c,
                              discVal: discVal,
                              isLegal: isLegal,
                              flipCount: flipCount,
                              isLastMove: isLastMove,
                              squareType: squareType,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell({
    required int r,
    required int c,
    required int discVal,
    required bool isLegal,
    required int flipCount,
    required bool isLastMove,
    required SquareType squareType,
  }) {
    Color cellBg = const Color(0xFF144D34);

    // Subtle tactical tints for corners & X/C squares
    if (discVal == 0) {
      if (squareType == SquareType.corner) {
        cellBg = const Color(0xFF1C6344);
      }
    }

    return GestureDetector(
      onTap: () {
        if (isInteractive && (isLegal || discVal == 0)) {
          onCellTapped(r, c);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          border: isLastMove
              ? Border.all(color: PlayNedTokens.brandGold, width: 2.0)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Corner Star Indicator
            if (squareType == SquareType.corner && discVal == 0)
              Positioned(
                top: 2,
                left: 2,
                child: Icon(Icons.star, size: 8, color: PlayNedTokens.brandGold.withOpacity(0.5)),
              ),

            // Discs with tactile flip animations
            if (discVal != 0)
              _buildDisc(discVal, isLastMove)
            // Legal Move Hint Marker
            else if (isLegal)
              _buildLegalMarker(flipCount),
          ],
        ),
      ),
    );
  }

  Widget _buildDisc(int discVal, bool isLastMove) {
    final isBlack = discVal == 1;

    return AnimatedContainer(
      duration: PlayNedTokens.animFast,
      curve: Curves.easeOutBack,
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isBlack ? const Color(0xFF161614) : const Color(0xFFF6F2E9),
        border: Border.all(
          color: isBlack ? const Color(0xFF333330) : const Color(0xFFDDD6C7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          if (isLastMove)
            BoxShadow(
              color: PlayNedTokens.brandGold.withOpacity(0.6),
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBlack ? const Color(0xFF282824) : const Color(0xFFE5DECE),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalMarker(int flipCount) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PlayNedTokens.accentReversi.withOpacity(0.35),
        border: Border.all(color: PlayNedTokens.accentReversi, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        "$flipCount",
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: PlayNedTokens.textPrimary,
        ),
      ),
    );
  }

  Widget _buildColumnLabels() {
    const cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    return Padding(
      padding: const EdgeInsets.only(left: 18.0),
      child: Row(
        children: cols.map((col) {
          return Expanded(
            child: Text(
              col,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: PlayNedTokens.accentReversi.withOpacity(0.8),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRowLabels() {
    const rows = ['1', '2', '3', '4', '5', '6', '7', '8'];
    return SizedBox(
      width: 14,
      child: Column(
        children: rows.map((row) {
          return Expanded(
            child: Center(
              child: Text(
                row,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: PlayNedTokens.accentReversi.withOpacity(0.8),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
