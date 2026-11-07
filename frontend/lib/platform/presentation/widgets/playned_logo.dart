import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Art-Directed PlayNed Identity Mark
class PlayNedLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double? fontSize;
  final VoidCallback? onTap;

  const PlayNedLogo({
    super.key,
    this.size = 30,
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
        SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/icons/playned_icon.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: PlayNedTokens.brandGold, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    "P",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: size * 0.55,
                      fontWeight: FontWeight.w800,
                      color: PlayNedTokens.brandGold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            "PlayNed",
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize ?? (size * 0.52).clamp(15.0, 24.0),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: PlayNedTokens.textPrimary,
            ),
          ),
        ],
      ],
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
