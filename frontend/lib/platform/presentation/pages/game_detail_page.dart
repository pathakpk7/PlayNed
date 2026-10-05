import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../models/game_model.dart';
import '../../registry/game_registry.dart';
import '../../services/platform_api_service.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../widgets/game_card_visuals.dart';
import '../widgets/platform_app_bar.dart';
import '../widgets/playned_components.dart';

class GameDetailPage extends ConsumerStatefulWidget {
  final String gameId;

  const GameDetailPage({
    super.key,
    required this.gameId,
  });

  @override
  ConsumerState<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends ConsumerState<GameDetailPage> {
  GameMetadata? _game;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _game = PlayNedGameRegistry.getGame(widget.gameId);
  }

  void _startLocalPlay() {
    if (_game == null) return;
    if (_game!.id == 'hangman') {
      _showHangmanModeSelector();
    } else if (_game!.id == 'dots_and_boxes') {
      context.push('/games/dots_and_boxes/play?mode=local');
    } else if (_game!.id == 'quoridor') {
      context.push('/games/quoridor/play?mode=local');
    } else if (_game!.id == 'pentago') {
      context.push('/games/pentago/play?mode=local');
    } else if (_game!.id == 'shut_the_box') {
      context.push('/games/shut_the_box/play?mode=local');
    } else if (_game!.id == 'cricket') {
      _showCricketModeSelector();
    } else if (_game!.id == 'reversi') {
      context.push('/games/reversi/hub');
    } else if (_game!.id == 'ultimate_tic_tac_toe' || _game!.id == 'ultimate-tic-tac-toe') {
      _showUltimateTicTacToeModeSelector();
    }
  }

  void _showCricketModeSelector() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: PlayNedTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          side: const BorderSide(color: PlayNedTokens.brandGold, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(PlayNedTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_cricket, color: PlayNedTokens.brandGold, size: 22),
                        const SizedBox(width: 10),
                        Text("SELECT CRICKET MODE", style: PlayNedTokens.gameTitle),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: PlayNedTokens.space16),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.gavel,
                  title: "IPL Mini Auction (NEW & FEATURED)",
                  subtitle: "10-Franchise War Room, ₹120 Cr Purse, Marquee Icons & Live Bidding Wars",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/games/cricket/auction');
                  },
                ),
                const SizedBox(height: PlayNedTokens.space10),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.sports_cricket,
                  title: "Super Over Duel",
                  subtitle: "Tactical 6-ball innings with custom batter & bowler matchups",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/games/cricket/super-over?mode=local');
                  },
                ),
                const SizedBox(height: PlayNedTokens.space10),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.analytics_outlined,
                  title: "Stat Clash",
                  subtitle: "Draft a 5-player squad to reach statistical milestones without busting",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/games/cricket/stat-clash');
                  },
                ),
                const SizedBox(height: PlayNedTokens.space10),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.hub_outlined,
                  title: "Cricket Hub Arena",
                  subtitle: "Browse all cricket game modes, rules, and live leaderboards",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/games/cricket/hub');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUltimateTicTacToeModeSelector() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: PlayNedTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          side: const BorderSide(color: PlayNedTokens.border, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(PlayNedTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("SELECT MATCH MODE", style: PlayNedTokens.gameTitle),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: PlayNedTokens.space16),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.smart_toy_outlined,
                  title: "Solo vs Tactical AI",
                  subtitle: "Sharpen your routing strategy against an intelligent AI bot",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/games/ultimate_tic_tac_toe/play?mode=ai');
                  },
                ),
                const SizedBox(height: PlayNedTokens.space10),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.people_outline,
                  title: "Pass & Play (2 Players)",
                  subtitle: "Turn-based local match on the same screen",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/games/ultimate_tic_tac_toe/play?mode=local');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHangmanModeSelector() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: PlayNedTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          side: const BorderSide(color: PlayNedTokens.border, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(PlayNedTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("SELECT HANGMAN MODE", style: PlayNedTokens.gameTitle),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: PlayNedTokens.space16),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.play_circle_filled,
                  title: "Classic Mode (100 Levels)",
                  subtitle: "Level-based progression with 5 hearts, hints & Word DNA",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/game/classic?level=1');
                  },
                ),
                const SizedBox(height: PlayNedTokens.space10),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.timer_outlined,
                  title: "Timed Mode (60s Blitz)",
                  subtitle: "Fast-paced countdown deduction challenge",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/game/timed?duration=60');
                  },
                ),
                const SizedBox(height: PlayNedTokens.space10),
                _buildModeTile(
                  ctx: ctx,
                  icon: Icons.hub_outlined,
                  title: "Hangman Mode Hub",
                  subtitle: "Daily Challenge, 12 Categories, Level Map & Codex",
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/games/hangman/hub');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTile({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd)),
        leading: Icon(icon, color: PlayNedTokens.brandGold),
        title: Text(title, style: PlayNedTokens.buttonLabel.copyWith(fontSize: 13, color: PlayNedTokens.textPrimary)),
        subtitle: Text(subtitle, style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: PlayNedTokens.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _createOnlineRoom() async {
    if (_game == null) return;
    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      final api = ref.read(platformApiServiceProvider);
      final hostName = auth.username ?? "Host Player";

      final room = await api.createRoom(
        gameId: _game!.id,
        playerName: hostName,
        playerId: auth.userId,
        maxPlayers: _game!.maxPlayers,
      );

      if (mounted) {
        context.push('/room/${room.roomCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create room: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return Scaffold(
        backgroundColor: PlayNedTokens.background,
        appBar: const PlatformAppBar(title: "Game Not Found"),
        body: Center(
          child: Text("Requested game does not exist on PlayNed.", style: PlayNedTokens.bodyMuted),
        ),
      );
    }

    final accent = game.accentColor;

    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: PlatformAppBar(title: game.name),
      body: PlayNedBackgroundPattern(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: PlayNedTokens.space24,
                vertical: PlayNedTokens.space24,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWidescreen = constraints.maxWidth >= 880;

                  // 1. Hero Artwork & Details Card
                  final heroCard = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(PlayNedTokens.space24),
                    decoration: BoxDecoration(
                      color: PlayNedTokens.surface,
                      borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
                      border: Border.all(color: accent.withOpacity(0.5), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GameCategoryBadge(category: game.category, accentColor: accent),
                            PlayerCountBadge(minPlayers: game.minPlayers, maxPlayers: game.maxPlayers),
                          ],
                        ),

                        const SizedBox(height: PlayNedTokens.space16),

                        // Tactile 2D Visual Banner
                        GameCardVisual(
                          gameId: game.id,
                          accentColor: accent,
                          isHovered: true,
                        ),

                        const SizedBox(height: PlayNedTokens.space16),

                        // Title & Tagline
                        Text(game.name, style: PlayNedTokens.heroDisplay.copyWith(fontSize: 30)),
                        const SizedBox(height: PlayNedTokens.space4),
                        Text(
                          game.tagline,
                          style: PlayNedTokens.body.copyWith(
                            fontStyle: FontStyle.italic,
                            color: accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: PlayNedTokens.space12),
                        Text(
                          game.description,
                          style: PlayNedTokens.bodyMuted.copyWith(fontSize: 13.5, height: 1.45),
                        ),

                        const SizedBox(height: PlayNedTokens.space20),

                        // Meta Badges Row
                        Wrap(
                          spacing: PlayNedTokens.space12,
                          runSpacing: PlayNedTokens.space8,
                          children: [
                            _MetaBadge(
                              icon: Icons.group_outlined,
                              label: "${game.minPlayers}–${game.maxPlayers} PLAYERS",
                              color: accent,
                            ),
                            _MetaBadge(
                              icon: Icons.timer_outlined,
                              label: "~${game.estimatedDurationMinutes} MIN MATCH",
                              color: accent,
                            ),
                            _MetaBadge(
                              icon: Icons.devices,
                              label: "LOCAL & ONLINE MULTIPLAYER",
                              color: accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  // 2. Actions & Rules Right Panel
                  final actionsAndRulesPanel = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Play Actions
                      Row(
                        children: [
                          Expanded(
                            child: PlayNedButton(
                              label: "LOCAL PASS & PLAY",
                              icon: Icons.play_circle_fill,
                              variant: PlayNedButtonVariant.primary,
                              customAccent: accent,
                              padding: const EdgeInsets.symmetric(vertical: PlayNedTokens.space16),
                              onPressed: _startLocalPlay,
                            ),
                          ),
                          const SizedBox(width: PlayNedTokens.space12),
                          Expanded(
                            child: PlayNedButton(
                              label: "CREATE ONLINE ROOM",
                              icon: Icons.wifi,
                              variant: PlayNedButtonVariant.outlined,
                              customAccent: PlayNedTokens.brandGold,
                              isLoading: _isLoading,
                              padding: const EdgeInsets.symmetric(vertical: PlayNedTokens.space16),
                              onPressed: _createOnlineRoom,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: PlayNedTokens.space20),

                      // How to Play & Game Rules Card
                      PlayNedCard(
                        padding: const EdgeInsets.all(PlayNedTokens.space20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.menu_book_outlined, size: 18, color: PlayNedTokens.brandGold),
                                const SizedBox(width: PlayNedTokens.space8),
                                Text(
                                  "HOW TO PLAY & OFFICIAL RULES",
                                  style: PlayNedTokens.metadata.copyWith(
                                    fontSize: 11,
                                    color: PlayNedTokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: PlayNedTokens.space16),
                            ...game.rulesSummary.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: PlayNedTokens.space12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 2, right: PlayNedTokens.space12),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: accent.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: accent.withOpacity(0.5)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "${entry.key + 1}",
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: PlayNedTokens.bodyMuted.copyWith(
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (isWidescreen) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: heroCard),
                        const SizedBox(width: PlayNedTokens.space24),
                        Expanded(flex: 5, child: actionsAndRulesPanel),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heroCard,
                      const SizedBox(height: PlayNedTokens.space20),
                      actionsAndRulesPanel,
                      const SizedBox(height: PlayNedTokens.space24),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PlayNedTokens.space10, vertical: PlayNedTokens.space6),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: PlayNedTokens.space6),
          Text(
            label,
            style: PlayNedTokens.metadata.copyWith(
              fontSize: 10,
              color: PlayNedTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
