import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Interactive & Tactile 2D Visuals for Game Cards in PlayNed
class GameCardVisual extends StatelessWidget {
  final String gameId;
  final Color accentColor;
  final bool isHovered;

  const GameCardVisual({
    super.key,
    required this.gameId,
    required this.accentColor,
    this.isHovered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: PlayNedTokens.background.withOpacity(0.6),
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
        border: Border.all(
          color: isHovered ? accentColor.withOpacity(0.4) : PlayNedTokens.borderSubtle,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
        child: _buildVisualContent(),
      ),
    );
  }

  Widget _buildVisualContent() {
    switch (gameId.toLowerCase()) {
      case 'hangman':
        return _HangmanVisual(accentColor: accentColor, isHovered: isHovered);
      case 'dots_and_boxes':
        return _DotsAndBoxesVisual(accentColor: accentColor, isHovered: isHovered);
      case 'quoridor':
        return _QuoridorVisual(accentColor: accentColor, isHovered: isHovered);
      case 'pentago':
        return _PentagoVisual(accentColor: accentColor, isHovered: isHovered);
      case 'shut_the_box':
        return _ShutTheBoxVisual(accentColor: accentColor, isHovered: isHovered);
      case 'cricket':
        return _CricketVisual(accentColor: accentColor, isHovered: isHovered);
      case 'reversi':
      case 'othello':
        return _ReversiVisual(accentColor: accentColor, isHovered: isHovered);
      default:
        return Center(
          child: Icon(Icons.sports_esports, size: 36, color: accentColor.withOpacity(0.5)),
        );
    }
  }
}

/// 1. Hangman Card Visual: Gallows + Letter tiles
class _HangmanVisual extends StatelessWidget {
  final Color accentColor;
  final bool isHovered;

  const _HangmanVisual({required this.accentColor, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final letters = ['W', 'O', 'R', 'D', 'S'];
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minimal 2D Gallows Icon
          CustomPaint(
            size: const Size(40, 50),
            painter: _MinimalGallowsPainter(accentColor: accentColor),
          ),
          const SizedBox(width: 16),
          // Letter tiles
          Row(
            children: List.generate(letters.length, (i) {
              final revealed = isHovered ? true : (i < 3);
              return AnimatedContainer(
                duration: Duration(milliseconds: 100 + i * 40),
                curve: PlayNedTokens.animCurve,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 24,
                height: 30,
                decoration: BoxDecoration(
                  color: revealed ? accentColor.withOpacity(0.18) : PlayNedTokens.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: revealed ? accentColor : PlayNedTokens.border,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  revealed ? letters[i] : "_",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: revealed ? PlayNedTokens.textPrimary : PlayNedTokens.textMuted,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MinimalGallowsPainter extends CustomPainter {
  final Color accentColor;
  const _MinimalGallowsPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Base
    canvas.drawLine(Offset(4, size.height - 4), Offset(size.width - 4, size.height - 4), paint);
    // Pole
    canvas.drawLine(Offset(10, size.height - 4), const Offset(10, 6), paint);
    // Beam
    canvas.drawLine(const Offset(10, 6), Offset(size.width - 10, 6), paint);
    // Rope
    canvas.drawLine(Offset(size.width - 10, 6), Offset(size.width - 10, 16), paint);
    // Head circle
    canvas.drawCircle(Offset(size.width - 10, 22), 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Dots & Boxes Visual: Miniature dot grid + line preview
class _DotsAndBoxesVisual extends StatelessWidget {
  final Color accentColor;
  final bool isHovered;

  const _DotsAndBoxesVisual({required this.accentColor, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(130, 65),
        painter: _DotsGridPainter(accentColor: accentColor, isHovered: isHovered),
      ),
    );
  }
}

class _DotsGridPainter extends CustomPainter {
  final Color accentColor;
  final bool isHovered;

  const _DotsGridPainter({required this.accentColor, required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = PlayNedTokens.textSecondary.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final completedBoxPaint = Paint()
      ..color = accentColor.withOpacity(isHovered ? 0.35 : 0.2)
      ..style = PaintingStyle.fill;

    const rows = 3;
    const cols = 5;
    final cellWidth = size.width / (cols - 1);
    final cellHeight = size.height / (rows - 1);

    // Completed Box 1 (0,1)
    canvas.drawRect(
      Rect.fromLTWH(cellWidth, 0, cellWidth, cellHeight),
      completedBoxPaint,
    );

    // Completed Box Lines
    canvas.drawLine(Offset(cellWidth, 0), Offset(cellWidth * 2, 0), linePaint);
    canvas.drawLine(Offset(cellWidth, cellHeight), Offset(cellWidth * 2, cellHeight), linePaint);
    canvas.drawLine(Offset(cellWidth, 0), Offset(cellWidth, cellHeight), linePaint);
    canvas.drawLine(Offset(cellWidth * 2, 0), Offset(cellWidth * 2, cellHeight), linePaint);

    // Additional active line if hovered
    if (isHovered) {
      final activePaint = Paint()
        ..color = PlayNedTokens.brandGold
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cellWidth * 2, cellHeight), Offset(cellWidth * 3, cellHeight), activePaint);
    }

    // Draw Dots
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(Offset(c * cellWidth, r * cellHeight), 3.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsGridPainter oldDelegate) =>
      oldDelegate.isHovered != isHovered || oldDelegate.accentColor != accentColor;
}

/// 3. Quoridor Visual: 2D labyrinth walls & pawns
class _QuoridorVisual extends StatelessWidget {
  final Color accentColor;
  final bool isHovered;

  const _QuoridorVisual({required this.accentColor, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(100, 70),
        painter: _QuoridorMiniPainter(accentColor: accentColor, isHovered: isHovered),
      ),
    );
  }
}

class _QuoridorMiniPainter extends CustomPainter {
  final Color accentColor;
  final bool isHovered;

  const _QuoridorMiniPainter({required this.accentColor, required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = PlayNedTokens.borderSubtle
      ..strokeWidth = 1.0;

    const gridSize = 5;
    final stepX = size.width / gridSize;
    final stepY = size.height / gridSize;

    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(Offset(i * stepX, 0), Offset(i * stepX, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * stepY), Offset(size.width, i * stepY), gridPaint);
    }

    // Wooden Barricade Wall
    final wallPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset(stepX, stepY * 2), Offset(stepX * 3, stepY * 2), wallPaint);
    canvas.drawLine(Offset(stepX * 3, stepY * 3), Offset(stepX * 3, stepY * 5), wallPaint);

    // Pawns
    final p1Paint = Paint()..color = PlayNedTokens.brandGold;
    final p2Paint = Paint()..color = PlayNedTokens.terracotta;

    canvas.drawCircle(Offset(stepX * 2.5, isHovered ? stepY * 1.5 : stepY * 0.5), 4.5, p1Paint);
    canvas.drawCircle(Offset(stepX * 2.5, stepY * 4.5), 4.5, p2Paint);
  }

  @override
  bool shouldRepaint(covariant _QuoridorMiniPainter oldDelegate) => oldDelegate.isHovered != isHovered;
}

/// 4. Pentago Visual: 4 Quadrants & Marbles
class _PentagoVisual extends StatelessWidget {
  final Color accentColor;
  final bool isHovered;

  const _PentagoVisual({required this.accentColor, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(70, 70),
        painter: _PentagoMiniPainter(accentColor: accentColor, isHovered: isHovered),
      ),
    );
  }
}

class _PentagoMiniPainter extends CustomPainter {
  final Color accentColor;
  final bool isHovered;

  const _PentagoMiniPainter({required this.accentColor, required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    final quadBorder = Paint()
      ..color = PlayNedTokens.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final half = size.width / 2;

    // 4 Quadrants
    canvas.drawRect(Rect.fromLTWH(0, 0, half - 2, half - 2), quadBorder);
    canvas.drawRect(Rect.fromLTWH(half + 2, 0, half - 2, half - 2), quadBorder);
    canvas.drawRect(Rect.fromLTWH(0, half + 2, half - 2, half - 2), quadBorder);
    canvas.drawRect(Rect.fromLTWH(half + 2, half + 2, half - 2, half - 2), quadBorder);

    // Marbles (White & Emerald)
    final mWhite = Paint()..color = PlayNedTokens.textPrimary;
    final mEmerald = Paint()..color = accentColor;

    canvas.drawCircle(const Offset(12, 12), 3.5, mWhite);
    canvas.drawCircle(const Offset(24, 24), 3.5, mWhite);
    canvas.drawCircle(const Offset(46, 12), 3.5, mEmerald);
    canvas.drawCircle(const Offset(58, 24), 3.5, mEmerald);
    canvas.drawCircle(const Offset(12, 46), 3.5, mEmerald);
    canvas.drawCircle(const Offset(46, 46), 3.5, mWhite);

    // Rotation Arc on top-right quadrant
    final arcPaint = Paint()
      ..color = isHovered ? accentColor : accentColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(half + 16, 16), radius: 10),
      0,
      pi * 1.3,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PentagoMiniPainter oldDelegate) => oldDelegate.isHovered != isHovered;
}

/// 5. Shut The Box Visual: 12 Numbered Tiles & Dice
class _ShutTheBoxVisual extends StatelessWidget {
  final Color accentColor;
  final bool isHovered;

  const _ShutTheBoxVisual({required this.accentColor, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: tiles.map((t) {
              final isShut = (t == 1 || t == 4 || t == 5 || (isHovered && (t == 3 || t == 6)));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 14,
                height: 24,
                decoration: BoxDecoration(
                  color: isShut ? accentColor.withOpacity(0.18) : PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isShut ? accentColor : PlayNedTokens.border,
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "$t",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isShut ? accentColor : PlayNedTokens.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniDie(3, accentColor),
              const SizedBox(width: 8),
              _buildMiniDie(5, accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDie(int val, Color accent) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withOpacity(0.6)),
      ),
      alignment: Alignment.center,
      child: Text(
        "$val",
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: PlayNedTokens.textPrimary),
      ),
    );
  }
}

/// 6. Cricket Visual: Mini Pitch, Wickets & Ball
class _CricketVisual extends StatelessWidget {
  final Color accentColor;
  final bool isHovered;

  const _CricketVisual({required this.accentColor, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mini Cricket Pitch Strip
          Container(
            width: 110,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF162B1D),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stumps
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: List.generate(
                        3,
                        (_) => Container(
                          width: 2,
                          height: 18,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: PlayNedTokens.brandGold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Pitch Crease Line & Ball
                Row(
                  children: [
                    Container(width: 1.5, height: 26, color: Colors.white24),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: PlayNedTokens.animStandard,
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isHovered ? const Color(0xFFE53E3E) : PlayNedTokens.brandGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isHovered ? const Color(0xFFE53E3E) : PlayNedTokens.brandGold).withOpacity(0.5),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                // Batsman Crease & Bat
                Icon(Icons.sports_cricket, size: 20, color: PlayNedTokens.brandGold),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Score Mini Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PlayNedTokens.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: PlayNedTokens.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("SUPER OVER", style: PlayNedTokens.metadata.copyWith(fontSize: 7.5, color: accentColor)),
                Text("24/0 (6b)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: PlayNedTokens.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 7. Reversi & Othello Visual: Tactile 8x8 Mini-Board, Flipping Discs & Corner Control
class _ReversiVisual extends StatelessWidget {
  final Color accentColor;
  final bool isHovered;

  const _ReversiVisual({required this.accentColor, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mini 8x8 Emerald Board
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3826),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withOpacity(0.6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 16,
              itemBuilder: (context, idx) {
                // 4x4 representation of center and corners
                // Top-left corner (0), center discs (5, 6, 9, 10)
                final isCorner = (idx == 0 || idx == 3 || idx == 12 || idx == 15);
                final isBlack = (idx == 5 || idx == 10 || (isHovered && idx == 6));
                final isWhite = (idx == 9 || (!isHovered && idx == 6));
                final isCandidate = (isHovered && idx == 1);

                return Container(
                  decoration: BoxDecoration(
                    color: isCorner
                        ? accentColor.withOpacity(0.25)
                        : const Color(0xFF134530),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: isBlack
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A18),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 2)],
                          ),
                        )
                      : isWhite
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1EBDD),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 2)],
                              ),
                            )
                          : isCandidate
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          // Score & Strategy Pill
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: PlayNedTokens.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1A1A18), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(isHovered ? "4" : "2", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: PlayNedTokens.textPrimary)),
                    const SizedBox(width: 6),
                    Text("vs", style: GoogleFonts.inter(fontSize: 9, color: PlayNedTokens.textMuted)),
                    const SizedBox(width: 6),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF1EBDD), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(isHovered ? "1" : "2", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: PlayNedTokens.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text("SANDWICH & FLIP", style: PlayNedTokens.metadata.copyWith(fontSize: 7.5, color: accentColor)),
              Text("CORNER CONTROL", style: PlayNedTokens.metadata.copyWith(fontSize: 7.5, color: PlayNedTokens.brandGold)),
            ],
          ),
        ],
      ),
    );
  }
}
