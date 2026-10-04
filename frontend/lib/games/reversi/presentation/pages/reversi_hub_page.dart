import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/presentation/widgets/platform_app_bar.dart';
import '../../../../platform/services/platform_api_service.dart';
import '../../../../platform/theme/playned_design_tokens.dart';
import '../../models/reversi_game_state.dart';
import '../widgets/reversi_strategy_dialog.dart';

class ReversiHubPage extends ConsumerStatefulWidget {
  const ReversiHubPage({super.key});

  @override
  ConsumerState<ReversiHubPage> createState() => _ReversiHubPageState();
}

class _ReversiHubPageState extends ConsumerState<ReversiHubPage> {
  ReversiVariant _selectedVariant = ReversiVariant.othello;
  ReversiDifficulty _selectedDifficulty = ReversiDifficulty.grandmaster;
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isCreatingRoom = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _openStrategyAcademy() {
    showDialog(
      context: context,
      builder: (ctx) => const ReversiStrategyDialog(),
    );
  }

  void _startAiMatch() {
    final variantStr = _selectedVariant == ReversiVariant.othello ? 'othello' : 'reversi_classic';
    final diffStr = _selectedDifficulty.name;
    context.push('/games/reversi/play?mode=ai&difficulty=$diffStr&variant=$variantStr');
  }

  void _startLocalMatch() {
    final variantStr = _selectedVariant == ReversiVariant.othello ? 'othello' : 'reversi_classic';
    context.push('/games/reversi/play?mode=local&variant=$variantStr');
  }

  void _createOnlineRoom() async {
    setState(() => _isCreatingRoom = true);
    try {
      final auth = ref.read(authProvider);
      final api = ref.read(platformApiServiceProvider);
      final hostName = auth.username ?? "Player 1";

      final room = await api.createRoom(
        gameId: 'reversi',
        playerName: hostName,
        playerId: auth.userId,
        maxPlayers: 2,
      );

      if (mounted) {
        context.push('/games/reversi/play?mode=online&room=${room.roomCode}&pid=${auth.userId ?? "p1"}&variant=${_selectedVariant == ReversiVariant.othello ? "othello" : "reversi_classic"}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create room: $e", style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingRoom = false);
    }
  }

  void _joinOnlineRoom() {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final auth = ref.read(authProvider);
    context.push('/games/reversi/play?mode=online&room=$code&pid=${auth.userId ?? "p2"}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: const PlatformAppBar(title: "REVERSI & OTHELLO"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                _buildHeaderBanner(),
                const SizedBox(height: 24),

                // Variant Selector Tabs
                _buildVariantSelector(),
                const SizedBox(height: 24),

                // Main Game Modes Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 700) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: _buildPlayModesSection()),
                          const SizedBox(width: 20),
                          Expanded(flex: 4, child: _buildStrategyAndRulesSideSection()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildPlayModesSection(),
                        const SizedBox(height: 20),
                        _buildStrategyAndRulesSideSection(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.accentReversi.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PlayNedTokens.surface,
            PlayNedTokens.accentReversi.withOpacity(0.08),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PlayNedTokens.background,
              border: Border.all(color: PlayNedTokens.accentReversi, width: 2),
            ),
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B231D), Color(0xFFF1EBDD)],
                    stops: [0.5, 0.5],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "REVERSI & OTHELLO",
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: PlayNedTokens.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: PlayNedTokens.accentReversi.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: PlayNedTokens.accentReversi.withOpacity(0.6)),
                      ),
                      child: Text(
                        "OFFICIAL",
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: PlayNedTokens.accentReversi,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "The timeless battle of tactical sandwich flips, corner control, and mobility dominance. One minute to learn, a lifetime to master.",
                  style: PlayNedTokens.bodyMuted.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SELECT GAME VARIANT",
          style: PlayNedTokens.metadata.copyWith(color: PlayNedTokens.textSecondary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildVariantCard(
                variant: ReversiVariant.othello,
                title: "Modern Othello",
                badge: "STANDARD TOURNAMENT",
                description: "Fixed 4-disc center opening (diagonal symmetry). Black plays first. Mandatory capture rule.",
                icon: Icons.grid_4x4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVariantCard(
                variant: ReversiVariant.reversiClassic,
                title: "Classic Reversi",
                badge: "HISTORICAL 1883",
                description: "32-disc quota per player. Flexible center opening placement followed by standard sandwich flips.",
                icon: Icons.history_edu,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariantCard({
    required ReversiVariant variant,
    required String title,
    required String badge,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedVariant == variant;
    return InkWell(
      onTap: () => setState(() => _selectedVariant = variant),
      borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? PlayNedTokens.accentReversi.withOpacity(0.12) : PlayNedTokens.surface,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
          border: Border.all(
            color: isSelected ? PlayNedTokens.accentReversi : PlayNedTokens.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isSelected ? PlayNedTokens.accentReversi : PlayNedTokens.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: PlayNedTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? PlayNedTokens.accentReversi : PlayNedTokens.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PlayNedTokens.accentReversi.withOpacity(0.25)
                        : PlayNedTokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.spaceMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? PlayNedTokens.accentReversi : PlayNedTokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayModesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PLAY MODES",
          style: PlayNedTokens.metadata.copyWith(color: PlayNedTokens.textSecondary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),

        // Mode 1: AI Battle
        _buildModeCard(
          title: "Player vs Strategic AI",
          subtitle: "Battle against tactical algorithms with depth search & positional weighting.",
          icon: Icons.smart_toy_outlined,
          color: PlayNedTokens.accentReversi,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                "AI DIFFICULTY LEVEL:",
                style: GoogleFonts.spaceMono(fontSize: 10, color: PlayNedTokens.textMuted, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDifficultyChip(ReversiDifficulty.novice, "Novice", "Random Legal"),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(ReversiDifficulty.tactician, "Tactician", "Greedy Max"),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(ReversiDifficulty.grandmaster, "Grandmaster", "Corner & Depth"),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startAiMatch,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text("PLAY VS ${_selectedDifficulty.name.toUpperCase()} AI"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PlayNedTokens.accentReversi,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd)),
                  textStyle: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mode 2: Pass & Play
        _buildModeCard(
          title: "Pass & Play (Local 2-Player)",
          subtitle: "Play on a single device screen with real-time turn transitions and move highlights.",
          icon: Icons.people_alt_outlined,
          color: PlayNedTokens.brandGold,
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: _startLocalMatch,
              icon: const Icon(Icons.tablet_android, size: 18),
              label: const Text("START LOCAL MATCH"),
              style: OutlinedButton.styleFrom(
                foregroundColor: PlayNedTokens.brandGold,
                side: const BorderSide(color: PlayNedTokens.brandGold),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd)),
                textStyle: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Mode 3: Online Multiplayer
        _buildModeCard(
          title: "Online Multiplayer",
          subtitle: "Create a private room code or join an opponent over real-time WebSockets.",
          icon: Icons.wifi_tethering_rounded,
          color: const Color(0xFF60A5FA),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCreatingRoom ? null : _createOnlineRoom,
                        icon: _isCreatingRoom
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_box_outlined, size: 18),
                        label: const Text("CREATE ROOM"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PlayNedTokens.surfaceElevated,
                          foregroundColor: PlayNedTokens.textPrimary,
                          side: const BorderSide(color: PlayNedTokens.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd)),
                          textStyle: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _roomCodeController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.spaceMono(fontSize: 13, color: PlayNedTokens.textPrimary),
                        decoration: InputDecoration(
                          hintText: "CODE (e.g. REV42)",
                          hintStyle: GoogleFonts.spaceMono(fontSize: 11, color: PlayNedTokens.textMuted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: PlayNedTokens.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                            borderSide: const BorderSide(color: PlayNedTokens.border),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.login, size: 18, color: PlayNedTokens.brandGold),
                            onPressed: _joinOnlineRoom,
                          ),
                        ),
                        onSubmitted: (_) => _joinOnlineRoom(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyChip(ReversiDifficulty diff, String title, String sub) {
    final isSel = _selectedDifficulty == diff;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDifficulty = diff),
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSel ? PlayNedTokens.accentReversi.withOpacity(0.2) : PlayNedTokens.surfaceElevated,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
            border: Border.all(
              color: isSel ? PlayNedTokens.accentReversi : PlayNedTokens.borderSubtle,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSel ? PlayNedTokens.accentReversi : PlayNedTokens.textPrimary,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.spaceMono(
                  fontSize: 8,
                  color: isSel ? PlayNedTokens.textPrimary : PlayNedTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: PlayNedTokens.body.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildStrategyAndRulesSideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STRATEGY ACADEMY",
          style: PlayNedTokens.metadata.copyWith(color: PlayNedTokens.textSecondary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),

        // Big Academy Banner Button
        InkWell(
          onTap: _openStrategyAcademy,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PlayNedTokens.surface,
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
              border: Border.all(color: PlayNedTokens.brandGold.withOpacity(0.4)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PlayNedTokens.surfaceElevated,
                  PlayNedTokens.brandGold.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PlayNedTokens.brandGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                      ),
                      child: const Icon(Icons.school_outlined, size: 22, color: PlayNedTokens.brandGold),
                    ),
                    Text(
                      "OPEN GUIDE",
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: PlayNedTokens.brandGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "HOW TO PLAY & WIN",
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PlayNedTokens.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Read our tactical masterclass: The Sandwich Rule, 8-way multi-chain flips, Corner Anchors, Danger of C & X squares, and Mobility Optimization.",
                  style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Principles Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PlayNedTokens.surface,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
            border: Border.all(color: PlayNedTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "KEY BOARD PRINCIPLES",
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: PlayNedTokens.accentReversi,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildRuleRow(
                icon: Icons.star,
                color: PlayNedTokens.brandGold,
                title: "Corner Control",
                desc: "Corners cannot be sandwiched. Seize them to build unflippable frontier walls.",
              ),
              const Divider(color: PlayNedTokens.borderSubtle, height: 20),
              _buildRuleRow(
                icon: Icons.warning_amber_rounded,
                color: Colors.amber,
                title: "Avoid C/X Squares Early",
                desc: "Playing diagonally adjacent to empty corners directly hands corners to your opponent.",
              ),
              const Divider(color: PlayNedTokens.borderSubtle, height: 20),
              _buildRuleRow(
                icon: Icons.compress_rounded,
                color: const Color(0xFF60A5FA),
                title: "Minimize Discs Early",
                desc: "Fewer discs early gives you maximum mobility and leaves opponent with no good moves.",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PlayNedTokens.body.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
