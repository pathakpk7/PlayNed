import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Official PlayNed Golden Logo & Icon Mark Widget
class PlayNedLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double? fontSize;
  final VoidCallback? onTap;

  const PlayNedLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Golden P-Game Controller Icon Mark
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
            boxShadow: [
              BoxShadow(
                color: PlayNedTokens.brandGold.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
            child: Image.asset(
              'assets/icons/playned_icon.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback elegant golden monogram
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: PlayNedTokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    border: Border.all(color: PlayNedTokens.brandGold, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      "P",
                      style: GoogleFonts.cinzel(
                        fontSize: size * 0.55,
                        fontWeight: FontWeight.w900,
                        color: PlayNedTokens.brandGold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            "PLAYNED",
            style: GoogleFonts.inter(
              fontSize: fontSize ?? (size * 0.45).clamp(13.0, 24.0),
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: PlayNedTokens.textPrimary,
            ),
          ),
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }
}
