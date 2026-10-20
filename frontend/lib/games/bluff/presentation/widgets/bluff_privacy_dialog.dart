import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

class BluffPrivacyDialog extends StatelessWidget {
  final String nextPlayerName;
  final VoidCallback onReveal;

  const BluffPrivacyDialog({
    super.key,
    required this.nextPlayerName,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(PlayNedTokens.space16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(PlayNedTokens.space24),
        decoration: BoxDecoration(
          color: const Color(0xFF13101E),
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.5),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.screen_lock_portrait,
                size: 38,
                color: Color(0xFFA78BFA),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PASS THE DEVICE',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFA78BFA),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nextPlayerName,
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: PlayNedTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Keep the screen hidden from opponents.\nOnly $nextPlayerName should look at this hand.',
              textAlign: TextAlign.center,
              style: PlayNedTokens.bodyMuted.copyWith(
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: Text(
                  'I AM $nextPlayerName — REVEAL HAND',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                  ),
                ),
                onPressed: onReveal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
