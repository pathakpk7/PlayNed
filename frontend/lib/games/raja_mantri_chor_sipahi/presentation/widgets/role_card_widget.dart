import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/raja_mantri_models.dart';

class RoleCardWidget extends StatelessWidget {
  final RajaMantriRole? role;
  final bool isRevealed;
  final String? playerName;
  final String? subtitle;
  final bool isSelected;
  final bool isEligibleSuspect;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool showPoints;

  const RoleCardWidget({
    super.key,
    this.role,
    this.isRevealed = true,
    this.playerName,
    this.subtitle,
    this.isSelected = false,
    this.isEligibleSuspect = false,
    this.onTap,
    this.width = 150,
    this.height = 210,
    this.showPoints = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRevealed || role == null) {
      return _buildFaceDownCard();
    }
    return _buildRevealedCard();
  }

  Widget _buildFaceDownCard() {
    return Semantics(
      label: playerName != null
          ? '$playerName secret chit face down'
          : 'Secret role chit face down',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: PlayNedTokens.animFast,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isSelected
                ? PlayNedTokens.brandGold.withOpacity(0.15)
                : PlayNedTokens.surfaceElevated,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            border: Border.all(
              color: isSelected
                  ? PlayNedTokens.brandGold
                  : (isEligibleSuspect ? PlayNedTokens.brandGold.withOpacity(0.6) : PlayNedTokens.border),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? PlayNedTokens.brandGold.withOpacity(0.25)
                    : Colors.black.withOpacity(0.4),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PlayNedTokens.surface,
                  border: Border.all(
                    color: isEligibleSuspect
                        ? PlayNedTokens.brandGold
                        : PlayNedTokens.borderBright,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.markunread_mailbox_outlined,
                  size: 24,
                  color: isEligibleSuspect
                      ? PlayNedTokens.brandGold
                      : PlayNedTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'CHIT',
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: PlayNedTokens.textPrimary,
                ),
              ),
              if (playerName != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    playerName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PlayNedTokens.brandGold,
                    ),
                  ),
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: PlayNedTokens.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevealedCard() {
    final r = role!;
    final accent = r.color;

    return Semantics(
      label: '${r.displayName} (${r.englishTitle}), ${r.points} points. ${playerName ?? ""}',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: PlayNedTokens.surfaceElevated,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
          border: Border.all(
            color: accent.withOpacity(0.8),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.2),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ambient corner glow
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: English Title & Points Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(PlayNedTokens.radiusXs),
                        ),
                        child: Text(
                          r.englishTitle.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: accent,
                          ),
                        ),
                      ),
                      if (showPoints)
                        Text(
                          '${r.points} PTS',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: PlayNedTokens.textPrimary,
                          ),
                        ),
                    ],
                  ),

                  // Center: Role Icon & Primary Name
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.15),
                          border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
                        ),
                        child: Icon(r.icon, size: 28, color: accent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r.displayName.toUpperCase(),
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: PlayNedTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Bottom: Player Name
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (playerName != null)
                        Text(
                          playerName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: PlayNedTokens.textSecondary,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
