import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../models/game_model.dart';
import '../../registry/game_registry.dart';
import '../../services/platform_api_service.dart';
import '../widgets/platform_app_bar.dart';

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
      context.push('/games/cricket/hub');
    }
  }

  void _showHangmanModeSelector() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141412),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A2A26), width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SELECT HANGMAN MODE",
                      style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFFA9A396)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ListTile(
                  tileColor: const Color(0xFF1B1B18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.play_circle_filled, color: Color(0xFFD5A84B)),
                  title: Text("Classic Mode (100 Levels)", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                  subtitle: Text("Level-based progression with 5 hearts, hints & Word DNA", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFA9A396)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/game/classic?level=1');
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: const Color(0xFF1B1B18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.timer_outlined, color: Color(0xFFD5A84B)),
                  title: Text("Timed Mode (60s Blitz)", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                  subtitle: Text("Fast-paced countdown deduction challenge", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFA9A396)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/game/timed?duration=60');
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: const Color(0xFF1B1B18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.hub_outlined, color: Color(0xFFD5A84B)),
                  title: Text("Hangman Mode Hub", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                  subtitle: Text("Explore Daily Challenge, 12 Categories, Level Map & Codex", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFA9A396)),
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
        appBar: const PlatformAppBar(title: "Game Not Found"),
        body: const Center(child: Text("Requested game does not exist on PlayNed.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0D),
      appBar: PlatformAppBar(title: game.name),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Artwork & Title Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: game.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: game.accentColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: game.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: game.accentColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              game.category.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: game.accentColor,
                              ),
                            ),
                          ),
                          Icon(game.icon, size: 36, color: game.accentColor.withOpacity(0.8)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        game.name,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 28,
                          color: const Color(0xFFF1EBDD),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.tagline,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: game.accentColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        game.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFA9A396),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Meta details row
                      Row(
                        children: [
                          _MetaBadge(
                            icon: Icons.group_outlined,
                            label: "${game.minPlayers}–${game.maxPlayers} Players",
                            color: game.accentColor,
                          ),
                          const SizedBox(width: 12),
                          _MetaBadge(
                            icon: Icons.timer_outlined,
                            label: "~${game.estimatedDurationMinutes} Mins",
                            color: game.accentColor,
                          ),
                          const SizedBox(width: 12),
                          _MetaBadge(
                            icon: Icons.devices,
                            label: "Local & Online",
                            color: game.accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Play Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: game.accentColor,
                          foregroundColor: const Color(0xFF0F0F0D),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _startLocalPlay,
                        icon: const Icon(Icons.play_circle_fill, size: 18),
                        label: Text(
                          "LOCAL PLAY",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF1EBDD),
                          side: const BorderSide(color: Color(0xFF2A2A26), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : _createOnlineRoom,
                        icon: const Icon(Icons.wifi, size: 18, color: Color(0xFFD5A84B)),
                        label: Text(
                          _isLoading ? "CREATING..." : "ONLINE ROOM",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // How to Play & Rules
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141412),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A26)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFFD5A84B)),
                          const SizedBox(width: 8),
                          Text(
                            "HOW TO PLAY & RULES",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: const Color(0xFFF1EBDD),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...game.rulesSummary.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4, right: 10),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: game.accentColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${entry.key + 1}",
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: game.accentColor,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFFA9A396),
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

                const SizedBox(height: 24),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF11110F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A2A26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF1EBDD),
            ),
          ),
        ],
      ),
    );
  }
}
