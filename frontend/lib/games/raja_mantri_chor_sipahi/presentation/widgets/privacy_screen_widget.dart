import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/raja_mantri_models.dart';
import 'role_card_widget.dart';

class LocalPassPrivacyWidget extends StatefulWidget {
  final int playerIndex; // 0..3
  final String playerName;
  final RajaMantriRole role;
  final VoidCallback onRoleHiddenAndPassed;

  const LocalPassPrivacyWidget({
    super.key,
    required this.playerIndex,
    required this.playerName,
    required this.role,
    required this.onRoleHiddenAndPassed,
  });

  @override
  State<LocalPassPrivacyWidget> createState() => _LocalPassPrivacyWidgetState();
}

class _LocalPassPrivacyWidgetState extends State<LocalPassPrivacyWidget> {
  bool _isRoleRevealed = false;

  void _revealRole() {
    setState(() {
      _isRoleRevealed = true;
    });
  }

  void _hideAndPass() {
    setState(() {
      _isRoleRevealed = false;
    });
    widget.onRoleHiddenAndPassed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Step pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: PlayNedTokens.brandGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
              border: Border.all(color: PlayNedTokens.brandGold.withOpacity(0.4)),
            ),
            child: Text(
              'PLAYER ${widget.playerIndex + 1} OF 4',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PlayNedTokens.brandGold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Player prompt
          Text(
            widget.playerName,
            style: GoogleFonts.cinzel(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: PlayNedTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            _isRoleRevealed
                ? 'Keep your role secret from other players!'
                : 'Pass the device to ${widget.playerName}. Only they should see this chit.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: PlayNedTokens.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Chit Display
          if (!_isRoleRevealed) ...[
            Container(
              width: 170,
              height: 230,
              decoration: BoxDecoration(
                color: PlayNedTokens.surfaceElevated,
                borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                border: Border.all(color: PlayNedTokens.borderBright, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security,
                    size: 42,
                    color: PlayNedTokens.brandGold,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SECRET CHIT',
                    style: GoogleFonts.cinzel(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: PlayNedTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hidden for privacy',
                    style: GoogleFonts.inter(fontSize: 11, color: PlayNedTokens.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: 220,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PlayNedTokens.brandGold,
                  foregroundColor: PlayNedTokens.textInverse,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
                ),
                onPressed: _revealRole,
                icon: const Icon(Icons.visibility, size: 18),
                label: Text(
                  'REVEAL MY CHIT',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ),
          ] else ...[
            RoleCardWidget(
              role: widget.role,
              isRevealed: true,
              playerName: widget.playerName,
              width: 170,
              height: 230,
              showPoints: true,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: 240,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.playerIndex < 3
                      ? PlayNedTokens.surfaceElevated
                      : PlayNedTokens.brandGold,
                  foregroundColor: widget.playerIndex < 3
                      ? PlayNedTokens.textPrimary
                      : PlayNedTokens.textInverse,
                  side: BorderSide(
                    color: widget.playerIndex < 3 ? PlayNedTokens.borderBright : PlayNedTokens.brandGold,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
                ),
                onPressed: _hideAndPass,
                icon: Icon(
                  widget.playerIndex < 3 ? Icons.lock_outline : Icons.check_circle_outline,
                  size: 18,
                ),
                label: Text(
                  widget.playerIndex < 3
                      ? 'HIDE ROLE & PASS DEVICE'
                      : 'ALL ROLES VIEWED — START',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
