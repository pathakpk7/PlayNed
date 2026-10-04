import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/game_model.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import 'game_card_visuals.dart';
import 'playned_components.dart';

/// Modernized Tactile 2D Game Card for PlayNed
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
        decoration: BoxDecoration(
          color: _isHovered ? PlayNedTokens.surfaceElevated : PlayNedTokens.surface,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
          border: Border.all(
            color: _isHovered ? accent.withOpacity(0.6) : PlayNedTokens.border,
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? accent.withOpacity(0.18)
                  : Colors.black.withOpacity(0.25),
              blurRadius: _isHovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            onTap: widget.onPlayPressed ?? () => context.push('/games/${game.id}'),
            child: Padding(
              padding: const EdgeInsets.all(PlayNedTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Top Metadata Row: Category & Players
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

                  const SizedBox(height: PlayNedTokens.space12),

                  // 2. Tactile 2D Game Visual Graphic
                  GameCardVisual(
                    gameId: game.id,
                    accentColor: accent,
                    isHovered: _isHovered,
                  ),

                  const SizedBox(height: PlayNedTokens.space12),

                  // 3. Game Title & Short Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: PlayNedTokens.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: PlayNedTokens.space4),
                      Text(
                        game.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: PlayNedTokens.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: PlayNedTokens.space14),

                  // 4. Footer Row: Mode/Time & Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          DurationBadge(minutes: game.estimatedDurationMinutes),
                          const SizedBox(width: PlayNedTokens.space8),
                          Text(
                            "•",
                            style: TextStyle(color: PlayNedTokens.textMuted, fontSize: 10),
                          ),
                          const SizedBox(width: PlayNedTokens.space8),
                          Text(
                            "LOCAL / ONLINE",
                            style: PlayNedTokens.metadata.copyWith(
                              fontSize: 9,
                              color: PlayNedTokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                      AnimatedContainer(
                        duration: PlayNedTokens.animMicro,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _isHovered ? accent : accent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                          border: Border.all(
                            color: accent,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "PLAY",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: _isHovered ? PlayNedTokens.textInverse : accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 13,
                              color: _isHovered ? PlayNedTokens.textInverse : accent,
                            ),
                          ],
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
