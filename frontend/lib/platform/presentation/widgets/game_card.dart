import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/game_model.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import 'game_card_visuals.dart';
import 'playned_components.dart';

/// Art-Directed Game Card with fluid hover kinetics and architectural layout
class PlayNedGameCard extends StatefulWidget {
  final GameMetadata game;
  final VoidCallback? onPlayPressed;

  const PlayNedGameCard({
    super.key,
    required this.game,
    this.onPlayPressed,
  });

  @override
  State<PlayNedGameCard> createState() => _PlayNedGameCardState();
}

class _PlayNedGameCardState extends State<PlayNedGameCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final accent = game.accentColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: PlayNedTokens.animFast,
        curve: PlayNedTokens.animCurve,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: _isHovered ? PlayNedTokens.surfaceElevated : PlayNedTokens.surface,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
          border: Border.all(
            color: _isHovered ? accent.withOpacity(0.4) : PlayNedTokens.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? accent.withOpacity(0.08)
                  : Colors.black.withOpacity(0.25),
              blurRadius: _isHovered ? 24 : 8,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            onTap: widget.onPlayPressed ?? () => context.push('/games/${game.id}'),
            child: Padding(
              padding: const EdgeInsets.all(PlayNedTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Metadata: Category & Player count (no rounded pill containers)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GameCategoryBadge(
                        category: game.category,
                        accentColor: accent,
                      ),
                      PlayerCountBadge(
                        minPlayers: game.minPlayers,
                        maxPlayers: game.maxPlayers,
                      ),
                    ],
                  ),

                  const SizedBox(height: PlayNedTokens.space14),

                  // Tactile 2D Game Graphic
                  GameCardVisual(
                    gameId: game.id,
                    accentColor: accent,
                    isHovered: _isHovered,
                  ),

                  const SizedBox(height: PlayNedTokens.space14),

                  // Title & Tagline
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              game.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: PlayNedTokens.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            duration: PlayNedTokens.animFast,
                            opacity: _isHovered ? 1.0 : 0.0,
                            child: Icon(
                              Icons.arrow_outward,
                              size: 16,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        game.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: PlayNedTokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: PlayNedTokens.space16),

                  // Footer: Duration and Play Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DurationBadge(minutes: game.estimatedDurationMinutes),
                      AnimatedContainer(
                        duration: PlayNedTokens.animFast,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isHovered ? accent : PlayNedTokens.surfaceHover,
                          borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                        ),
                        child: Text(
                          "Play",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isHovered ? PlayNedTokens.textInverse : PlayNedTokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
