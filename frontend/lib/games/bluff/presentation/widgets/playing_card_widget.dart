import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/bluff_models.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard? card; // If null, renders face-down back
  final bool isFaceUp;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool isCompact;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.isFaceUp = true,
    this.isSelected = false,
    this.onTap,
    this.width = 64,
    this.height = 92,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFaceUp = isFaceUp && card != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, isSelected ? -10 : 0, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: effectiveFaceUp ? const Color(0xFF1E1E24) : const Color(0xFF19122C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : (effectiveFaceUp
                      ? PlayNedTokens.borderBright.withOpacity(0.7)
                      : const Color(0xFF7C3AED).withOpacity(0.5)),
              width: isSelected ? 2.2 : 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.45),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: effectiveFaceUp ? _buildFaceUp(card!) : _buildFaceDown(),
          ),
        ),
      ),
    );
  }

  Widget _buildFaceUp(PlayingCard card) {
    final rankSize = isCompact ? 11.0 : (width < 60 ? 12.0 : 15.0);
    final suitSize = isCompact ? 9.0 : (width < 60 ? 10.0 : 13.0);
    final centerSuitSize = isCompact ? 20.0 : (width < 60 ? 22.0 : 28.0);

    return Stack(
      children: [
        // Subtle background gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF262630),
                  const Color(0xFF181820),
                ],
              ),
            ),
          ),
        ),

        // Corner Top-Left
        Positioned(
          top: 4,
          left: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.rank,
                style: GoogleFonts.spaceMono(
                  fontSize: rankSize,
                  fontWeight: FontWeight.w800,
                  color: card.suitColor,
                  height: 1.0,
                ),
              ),
              Text(
                card.suitSymbol,
                style: TextStyle(
                  fontSize: suitSize,
                  color: card.suitColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),

        // Center Large Suit
        Center(
          child: Text(
            card.suitSymbol,
            style: TextStyle(
              fontSize: centerSuitSize,
              color: card.suitColor.withOpacity(0.85),
            ),
          ),
        ),

        // Corner Bottom-Right (Rotated 180)
        Positioned(
          bottom: 4,
          right: 5,
          child: RotatedBox(
            quarterTurns: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.rank,
                  style: GoogleFonts.spaceMono(
                    fontSize: rankSize,
                    fontWeight: FontWeight.w800,
                    color: card.suitColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    fontSize: suitSize,
                    color: card.suitColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selected Indicator Overlay
        if (isSelected)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildFaceDown() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E1065), // Deep Violet
            Color(0xFF1E1B4B), // Indigo Navy
          ],
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFFA78BFA).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.shield,
              size: isCompact ? 16 : (width < 60 ? 18 : 22),
              color: const Color(0xFFA78BFA).withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
