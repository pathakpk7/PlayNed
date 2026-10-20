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
    } else if (_game!.id == 'bingo') {
      _showBingoModeSelector();
    } else if (_game!.id == 'raja_mantri_chor_sipahi' || _game!.id == 'raja_mantri') {
      _showRajaMantriModeSelector();
    } else if (_game!.id == 'bluff' || _game!.id == 'bluff_cheat') {
      _showBluffModeSelector();
    } else if (_game!.id == 'spyfall') {
      _showSpyfallModeSelector();
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

  void _showBingoModeSelector() {
    String selectedPattern = 'classic';
    String selectedDifficulty = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
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
                            const Icon(Icons.grid_on, color: PlayNedTokens.brandGold, size: 22),
                            const SizedBox(width: 10),
                            Text("SELECT BINGO MODE", style: PlayNedTokens.gameTitle),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: PlayNedTokens.space12),

                    // Win Pattern Selector
                    Text(
                      "WINNING PATTERN",
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: PlayNedTokens.textSecondary, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPatternChoiceChip(
                            label: "Classic Line",
                            value: "classic",
                            selected: selectedPattern == "classic",
                            onSelected: (v) => setDialogState(() => selectedPattern = "classic"),
                          ),
                          const SizedBox(width: 6),
                          _buildPatternChoiceChip(
                            label: "Four Corners",
                            value: "fourCorners",
                            selected: selectedPattern == "fourCorners",
                            onSelected: (v) => setDialogState(() => selectedPattern = "fourCorners"),
                          ),
                          const SizedBox(width: 6),
                          _buildPatternChoiceChip(
                            label: "X Pattern",
                            value: "xPattern",
                            selected: selectedPattern == "xPattern",
                            onSelected: (v) => setDialogState(() => selectedPattern = "xPattern"),
                          ),
                          const SizedBox(width: 6),
                          _buildPatternChoiceChip(
                            label: "Blackout",
                            value: "blackout",
                            selected: selectedPattern == "blackout",
                            onSelected: (v) => setDialogState(() => selectedPattern = "blackout"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PlayNedTokens.space16),

                    // Mode 1: 1 vs Computer with Difficulty
                    Container(
                      padding: const EdgeInsets.all(PlayNedTokens.space12),
                      decoration: BoxDecoration(
                        color: PlayNedTokens.surfaceElevated,
                        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                        border: Border.all(color: PlayNedTokens.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.smart_toy_outlined, color: PlayNedTokens.brandGold, size: 20),
                                  const SizedBox(width: 8),
                                  Text("1 vs Computer", style: PlayNedTokens.buttonLabel.copyWith(color: PlayNedTokens.textPrimary)),
                                ],
                              ),
                              Row(
                                children: ["easy", "medium", "hard"].map((diff) {
                                  final isSel = selectedDifficulty == diff;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(4),
                                      onTap: () => setDialogState(() => selectedDifficulty = diff),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSel ? PlayNedTokens.brandGold : PlayNedTokens.surface,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: isSel ? PlayNedTokens.brandGold : PlayNedTokens.borderSubtle),
                                        ),
                                        child: Text(
                                          diff.toUpperCase(),
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isSel ? PlayNedTokens.textInverse : PlayNedTokens.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text("Play solo against an automated AI card player.", style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PlayNedTokens.brandGold,
                                foregroundColor: PlayNedTokens.textInverse,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push('/games/bingo/play?mode=ai&pattern=$selectedPattern&difficulty=$selectedDifficulty');
                              },
                              child: Text("PLAY VS CPU", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PlayNedTokens.space12),

                    // Mode 2: 1 vs 1 Local (Pass & Play)
                    _buildModeTile(
                      ctx: ctx,
                      icon: Icons.people_outline,
                      title: "1 vs 1 — Local (Pass & Play)",
                      subtitle: "Two players battle on the same device with synchronized draws",
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/games/bingo/play?mode=local&pattern=$selectedPattern');
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatternChoiceChip({
    required String label,
    required String value,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: selected ? PlayNedTokens.textInverse : PlayNedTokens.textSecondary,
      ),
      selected: selected,
      selectedColor: PlayNedTokens.brandGold,
      backgroundColor: PlayNedTokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
        side: BorderSide(color: selected ? PlayNedTokens.brandGold : PlayNedTokens.borderSubtle),
      ),
      onSelected: onSelected,
    );
  }

  void _showRajaMantriModeSelector() {
    int selectedRounds = 5;
    final p1Ctrl = TextEditingController(text: 'Player 1');
    final p2Ctrl = TextEditingController(text: 'Player 2');
    final p3Ctrl = TextEditingController(text: 'Player 3');
    final p4Ctrl = TextEditingController(text: 'Player 4');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: PlayNedTokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
              side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(PlayNedTokens.space24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.military_tech, color: Color(0xFFD97706), size: 22),
                              const SizedBox(width: 10),
                              Text("SETUP 4P LOCAL MATCH", style: PlayNedTokens.gameTitle),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: PlayNedTokens.space12),

                      Text(
                        "MATCH LENGTH",
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: PlayNedTokens.textSecondary, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [1, 5, 10].map((r) {
                          final isSel = selectedRounds == r;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('$r ${r == 1 ? "Round" : "Rounds"}'),
                              selected: isSel,
                              selectedColor: const Color(0xFFD97706),
                              backgroundColor: PlayNedTokens.surfaceElevated,
                              labelStyle: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSel ? PlayNedTokens.textInverse : PlayNedTokens.textPrimary,
                              ),
                              onSelected: (_) => setDialogState(() => selectedRounds = r),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "ENTER 4 PLAYER NAMES",
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: PlayNedTokens.textSecondary, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      ...[
                        {'ctrl': p1Ctrl, 'hint': 'Player 1'},
                        {'ctrl': p2Ctrl, 'hint': 'Player 2'},
                        {'ctrl': p3Ctrl, 'hint': 'Player 3'},
                        {'ctrl': p4Ctrl, 'hint': 'Player 4'},
                      ].map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextField(
                            controller: item['ctrl'] as TextEditingController,
                            style: GoogleFonts.inter(fontSize: 12, color: PlayNedTokens.textPrimary),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: PlayNedTokens.surfaceElevated,
                              hintText: item['hint'] as String,
                              hintStyle: GoogleFonts.inter(color: PlayNedTokens.textMuted, fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                borderSide: const BorderSide(color: PlayNedTokens.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: PlayNedTokens.textInverse,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final p1 = p1Ctrl.text.trim().isEmpty ? 'Player 1' : p1Ctrl.text.trim();
                            final p2 = p2Ctrl.text.trim().isEmpty ? 'Player 2' : p2Ctrl.text.trim();
                            final p3 = p3Ctrl.text.trim().isEmpty ? 'Player 3' : p3Ctrl.text.trim();
                            final p4 = p4Ctrl.text.trim().isEmpty ? 'Player 4' : p4Ctrl.text.trim();
                            context.push(
                              '/games/raja_mantri_chor_sipahi/play?mode=local&rounds=$selectedRounds&p1=${Uri.encodeComponent(p1)}&p2=${Uri.encodeComponent(p2)}&p3=${Uri.encodeComponent(p3)}&p4=${Uri.encodeComponent(p4)}',
                            );
                          },
                          child: Text(
                            "START 4P LOCAL MATCH",
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBluffModeSelector() {
    int selectedPlayerCount = 3;
    final controllers = List.generate(
      6,
      (i) => TextEditingController(text: 'Player ${i + 1}'),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: PlayNedTokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
              side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(PlayNedTokens.space24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.style, color: Color(0xFF8B5CF6), size: 22),
                              const SizedBox(width: 10),
                              Text("SETUP LOCAL BLUFF MATCH", style: PlayNedTokens.gameTitle),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: PlayNedTokens.space12),

                      Text(
                        "NUMBER OF PLAYERS (3–6)",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: PlayNedTokens.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [3, 4, 5, 6].map((count) {
                          final isSelected = selectedPlayerCount == count;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$count Players'),
                              labelStyle: GoogleFonts.spaceMono(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : PlayNedTokens.textSecondary,
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFF8B5CF6),
                              backgroundColor: PlayNedTokens.surfaceElevated,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF8B5CF6) : PlayNedTokens.borderSubtle,
                                ),
                              ),
                              onSelected: (_) {
                                setDialogState(() => selectedPlayerCount = count);
                              },
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: PlayNedTokens.space16),

                      Text(
                        "PLAYER NAMES",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: PlayNedTokens.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),

                      for (int i = 0; i < selectedPlayerCount; i++) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: controllers[i],
                            style: GoogleFonts.inter(fontSize: 12, color: PlayNedTokens.textPrimary),
                            decoration: InputDecoration(
                              labelText: "Player ${i + 1} Name",
                              labelStyle: GoogleFonts.inter(fontSize: 11, color: PlayNedTokens.textSecondary),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: PlayNedTokens.surfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                borderSide: const BorderSide(color: PlayNedTokens.borderSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: PlayNedTokens.space16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final qParams = <String, String>{
                              'mode': 'local',
                              'players': selectedPlayerCount.toString(),
                            };
                            for (int i = 0; i < selectedPlayerCount; i++) {
                              final name = controllers[i].text.trim().isEmpty
                                  ? 'Player ${i + 1}'
                                  : controllers[i].text.trim();
                              qParams['p${i + 1}'] = name;
                            }
                            final uri = Uri(
                              path: '/games/bluff/play',
                              queryParameters: qParams,
                            );
                            context.push(uri.toString());
                          },
                          child: Text(
                            "START $selectedPlayerCount-PLAYER MATCH",
                            style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSpyfallModeSelector() {
    int selectedPlayerCount = 4;
    int selectedDuration = 8;
    int selectedRounds = 3;
    final controllers = List.generate(
      8,
      (i) => TextEditingController(text: 'Agent ${i + 1}'),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: PlayNedTokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
              side: const BorderSide(color: PlayNedTokens.accentSpyfall, width: 1.5),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
              child: Padding(
                padding: const EdgeInsets.all(PlayNedTokens.space24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.fingerprint, color: PlayNedTokens.accentSpyfall, size: 24),
                              const SizedBox(width: PlayNedTokens.space10),
                              Text("SETUP LOCAL SPYFALL MISSION", style: PlayNedTokens.gameTitle.copyWith(fontSize: 16)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: PlayNedTokens.textSecondary, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: PlayNedTokens.space6),
                      Text(
                        "Pass-and-play social deduction for 3 to 8 agents on one device.",
                        style: PlayNedTokens.gameTagline,
                      ),
                      const SizedBox(height: PlayNedTokens.space16),

                      // Player Count Selection
                      Text("NUMBER OF AGENTS (3–8)", style: PlayNedTokens.sectionHeader.copyWith(fontSize: 12)),
                      const SizedBox(height: PlayNedTokens.space8),
                      Row(
                        children: [3, 4, 5, 6, 7, 8].map((count) {
                          final isSelected = selectedPlayerCount == count;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: InkWell(
                                onTap: () => setModalState(() => selectedPlayerCount = count),
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? PlayNedTokens.accentSpyfall : PlayNedTokens.surfaceElevated,
                                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                    border: Border.all(
                                      color: isSelected ? PlayNedTokens.accentSpyfall : PlayNedTokens.border,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$count",
                                    style: GoogleFonts.spaceMono(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isSelected ? Colors.white : PlayNedTokens.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: PlayNedTokens.space16),

                      // Discussion Timer Duration
                      Text("ROUND DURATION", style: PlayNedTokens.sectionHeader.copyWith(fontSize: 12)),
                      const SizedBox(height: PlayNedTokens.space8),
                      Row(
                        children: [5, 8, 10].map((mins) {
                          final isSelected = selectedDuration == mins;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () => setModalState(() => selectedDuration = mins),
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? PlayNedTokens.accentSpyfall.withOpacity(0.2) : PlayNedTokens.surfaceElevated,
                                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                    border: Border.all(
                                      color: isSelected ? PlayNedTokens.accentSpyfall : PlayNedTokens.border,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$mins MINS",
                                    style: GoogleFonts.spaceMono(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: isSelected ? PlayNedTokens.accentSpyfall : PlayNedTokens.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: PlayNedTokens.space16),

                      // Total Rounds
                      Text("TOTAL ROUNDS", style: PlayNedTokens.sectionHeader.copyWith(fontSize: 12)),
                      const SizedBox(height: PlayNedTokens.space8),
                      Row(
                        children: [1, 3, 5].map((rounds) {
                          final isSelected = selectedRounds == rounds;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () => setModalState(() => selectedRounds = rounds),
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? PlayNedTokens.accentSpyfall.withOpacity(0.2) : PlayNedTokens.surfaceElevated,
                                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                    border: Border.all(
                                      color: isSelected ? PlayNedTokens.accentSpyfall : PlayNedTokens.border,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$rounds ${rounds == 1 ? 'ROUND' : 'ROUNDS'}",
                                    style: GoogleFonts.spaceMono(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: isSelected ? PlayNedTokens.accentSpyfall : PlayNedTokens.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: PlayNedTokens.space16),

                      // Agent Names
                      Text("AGENT ALIASES", style: PlayNedTokens.sectionHeader.copyWith(fontSize: 12)),
                      const SizedBox(height: PlayNedTokens.space8),
                      for (int i = 0; i < selectedPlayerCount; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: PlayNedTokens.space8),
                          child: TextField(
                            controller: controllers[i],
                            style: GoogleFonts.spaceGrotesk(fontSize: 13, color: PlayNedTokens.textPrimary),
                            decoration: InputDecoration(
                              labelText: "Agent ${i + 1}",
                              labelStyle: GoogleFonts.spaceMono(fontSize: 11, color: PlayNedTokens.textMuted),
                              isDense: true,
                              filled: true,
                              fillColor: PlayNedTokens.surfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                borderSide: const BorderSide(color: PlayNedTokens.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                borderSide: const BorderSide(color: PlayNedTokens.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                                borderSide: const BorderSide(color: PlayNedTokens.accentSpyfall),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: PlayNedTokens.space16),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PlayNedTokens.accentSpyfall,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final qParams = <String, String>{
                              'mode': 'local',
                              'players': selectedPlayerCount.toString(),
                              'duration': selectedDuration.toString(),
                              'rounds': selectedRounds.toString(),
                            };
                            for (int i = 0; i < selectedPlayerCount; i++) {
                              final name = controllers[i].text.trim().isEmpty
                                  ? 'Agent ${i + 1}'
                                  : controllers[i].text.trim();
                              qParams['p${i + 1}'] = name;
                            }
                            final uri = Uri(
                              path: '/games/spyfall/play',
                              queryParameters: qParams,
                            );
                            context.push(uri.toString());
                          },
                          child: Text(
                            "START $selectedPlayerCount-AGENT MISSION",
                            style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
