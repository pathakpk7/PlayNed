import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/game_model.dart';

class PlayNedGameCard extends StatelessWidget {
  final GameMetadata game;
  final VoidCallback? onPlayPressed;

  const PlayNedGameCard({
    super.key,
    required this.game,
    this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: game.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: game.accentColor.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Background Artwork Graphic / Watermark
            Positioned(
              right: -14,
              bottom: -14,
              child: Icon(
                game.icon,
                size: 90,
                color: game.accentColor.withOpacity(0.08),
              ),
            ),

            // Card Body
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.push('/games/${game.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Category Badge & Player Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: game.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: game.accentColor.withOpacity(0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            game.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: game.accentColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              game.minPlayers == 1 ? Icons.person_outline : Icons.group_outlined,
                              size: 13,
                              color: const Color(0xFFA9A396),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              game.minPlayers == game.maxPlayers
                                  ? "${game.minPlayers}P"
                                  : "${game.minPlayers}–${game.maxPlayers} Players",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFFA9A396),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Game Title & Tagline
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 19,
                            color: const Color(0xFFF1EBDD),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.tagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFA9A396),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Bottom Action Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "~${game.estimatedDurationMinutes} MINS",
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: const Color(0xFFA9A396),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: game.accentColor,
                            foregroundColor: const Color(0xFF0F0F0D),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: onPlayPressed ?? () => context.push('/games/${game.id}'),
                          icon: const Icon(Icons.play_arrow, size: 14),
                          label: Text(
                            "PLAY",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
