import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';

class ReversiStrategyDialog extends StatefulWidget {
  const ReversiStrategyDialog({super.key});

  @override
  State<ReversiStrategyDialog> createState() => _ReversiStrategyDialogState();
}

class _ReversiStrategyDialogState extends State<ReversiStrategyDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PlayNedTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        side: const BorderSide(color: PlayNedTokens.border, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(PlayNedTokens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(PlayNedTokens.space8),
                    decoration: BoxDecoration(
                      color: PlayNedTokens.accentReversi.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    ),
                    child: const Icon(Icons.school_outlined, color: PlayNedTokens.accentReversi, size: 22),
                  ),
                  const SizedBox(width: PlayNedTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("REVERSI & OTHELLO ACADEMY", style: PlayNedTokens.gameTitle),
                        Text("Rules, capturing mechanics, and grandmaster winning strategies",
                            style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: PlayNedTokens.space16),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: PlayNedTokens.background,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: PlayNedTokens.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: PlayNedTokens.accentReversi,
                  indicatorWeight: 3,
                  labelColor: PlayNedTokens.textPrimary,
                  unselectedLabelColor: PlayNedTokens.textMuted,
                  labelStyle: PlayNedTokens.buttonLabel.copyWith(fontSize: 11.5),
                  tabs: const [
                    Tab(text: "CAPTURING RULES"),
                    Tab(text: "WINNING STRATEGIES"),
                    Tab(text: "THE 2 VARIANTS"),
                  ],
                ),
              ),

              const SizedBox(height: PlayNedTokens.space16),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCapturingRulesTab(),
                    _buildWinningStrategiesTab(),
                    _buildVariantsTab(),
                  ],
                ),
              ),

              const SizedBox(height: PlayNedTokens.space16),

              // Footer Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlayNedButton(
                    label: "GOT IT, LET'S PLAY",
                    variant: PlayNedButtonVariant.primary,
                    customAccent: PlayNedTokens.accentReversi,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: CAPTURING RULES ---
  Widget _buildCapturingRulesTab() {
    return ListView(
      children: [
        _buildRuleCard(
          icon: Icons.compress,
          title: "The Sandwich Rule",
          description:
              "You capture opposing pieces by 'sandwiching' them between a piece you already have on the board and the new piece you just placed.",
        ),
        _buildRuleCard(
          icon: Icons.linear_scale,
          title: "Lines of Capture",
          description:
              "The sandwich can happen in any straight line—horizontally, vertically, or diagonally.",
        ),
        _buildRuleCard(
          icon: Icons.sync,
          title: "Flipping & Chain Reactions",
          description:
              "Once a valid move is made, all of the opponent's pieces trapped in continuous lines between your two pieces are flipped to your colour. If your move creates sandwiches in multiple directions simultaneously, you flip all trapped pieces!",
        ),
        _buildRuleCard(
          icon: Icons.block,
          title: "Mandatory Moves & Passing",
          description:
              "You can ONLY place a piece if it successfully traps and flips at least one opposing piece. If you cannot make any legal flips on your turn, you MUST pass. If neither player can move, the game ends immediately.",
        ),
      ],
    );
  }

  // --- TAB 2: WINNING STRATEGIES ---
  Widget _buildWinningStrategiesTab() {
    return ListView(
      children: [
        _buildStrategyCard(
          tag: "CRITICAL",
          tagColor: PlayNedTokens.brandGold,
          title: "1. Corner Control",
          subtitle: "Corners can NEVER be flipped",
          body:
              "Corners (a1, a8, h1, h8) are the supreme squares on the board. Once you occupy a corner, that disc can never be sandwiched or flipped back because it has no opposing side. Anchoring corners allows you to lock down whole edge rows (Stable Discs).",
        ),
        _buildStrategyCard(
          tag: "DANGER ZONE",
          tagColor: PlayNedTokens.terracotta,
          title: "2. Avoid the C-Squares and X-Squares",
          subtitle: "The deadly squares adjacent to corners",
          body:
              "• X-Squares (b2, b7, g2, g7): Diagonally adjacent to corners.\n• C-Squares (a2, b1, a7, b8, g1, h2, g8, h7): Orthogonally adjacent along edges.\n\nPlaying here early gives your opponent an immediate invitation to capture the adjacent corner! Only take a C-square if you already control the corner or have locked the edge.",
        ),
        _buildStrategyCard(
          tag: "COUNTERINTUITIVE",
          tagColor: PlayNedTokens.accentReversi,
          title: "3. Keep a Low Piece Count Early",
          subtitle: "Fewer pieces early = more freedom",
          body:
              "Counterintuitively, having FEWER pieces than your opponent during the opening and middle game is usually better. It leaves your opponent with fewer discs to anchor against, strictly limiting their options while maximizing your own flexibility.",
        ),
        _buildStrategyCard(
          tag: "TACTICAL",
          tagColor: PlayNedTokens.accentDots,
          title: "4. Mobility Optimization",
          subtitle: "Limit opponent options to force blunders",
          body:
              "Focus on limiting your opponent's legal moves while expanding your own. If you reduce your opponent to 1 or 2 terrible moves, they will be forced to play into an X-square or C-square, gifting you the corner and the game!",
        ),
      ],
    );
  }

  // --- TAB 3: THE 2 VARIANTS ---
  Widget _buildVariantsTab() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(PlayNedTokens.space16),
          decoration: BoxDecoration(
            color: PlayNedTokens.surfaceElevated,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            border: Border.all(color: PlayNedTokens.accentReversi.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PlayNedTokens.accentReversi,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text("STANDARD", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: PlayNedTokens.textInverse)),
                  ),
                  const SizedBox(width: PlayNedTokens.space8),
                  Text("Modern Othello", style: PlayNedTokens.gameTitle.copyWith(fontSize: 16)),
                ],
              ),
              const SizedBox(height: PlayNedTokens.space8),
              Text(
                "• Fixed Starting Setup: Begins with 4 central discs placed in a diagonal cross (Black at d5, e4; White at d4, e5).\n• Black always makes the first move.\n• Strict mandatory capture & passing rules.\n• Standard competitive tournament format worldwide.",
                style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: PlayNedTokens.space12),
        Container(
          padding: const EdgeInsets.all(PlayNedTokens.space16),
          decoration: BoxDecoration(
            color: PlayNedTokens.surfaceElevated,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            border: Border.all(color: PlayNedTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PlayNedTokens.brandGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text("CLASSIC 1883", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: PlayNedTokens.textInverse)),
                  ),
                  const SizedBox(width: PlayNedTokens.space8),
                  Text("Classic Reversi (English Variant)", style: PlayNedTokens.gameTitle.copyWith(fontSize: 16)),
                ],
              ),
              const SizedBox(height: PlayNedTokens.space8),
              Text(
                "• Disc Quota: Each player starts with exactly 32 discs in hand (64 total).\n• Flexible Center Opening: Players place 2 discs each into the center 4 squares in parallel or diagonal alignments.\n• If a player exhausts their 32-disc inventory, their turn passes automatically.",
                style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: PlayNedTokens.space10),
      padding: const EdgeInsets.all(PlayNedTokens.space14),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: PlayNedTokens.accentReversi.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: PlayNedTokens.accentReversi),
          ),
          const SizedBox(width: PlayNedTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PlayNedTokens.buttonLabel.copyWith(fontSize: 13, color: PlayNedTokens.textPrimary)),
                const SizedBox(height: PlayNedTokens.space4),
                Text(description, style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard({
    required String tag,
    required Color tagColor,
    required String title,
    required String subtitle,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: PlayNedTokens.space12),
      padding: const EdgeInsets.all(PlayNedTokens.space14),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: PlayNedTokens.buttonLabel.copyWith(fontSize: 13.5, color: PlayNedTokens.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusXs),
                  border: Border.all(color: tagColor.withOpacity(0.4)),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: tagColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: PlayNedTokens.space2),
          Text(subtitle, style: PlayNedTokens.metadata.copyWith(fontSize: 9.5, color: PlayNedTokens.brandGold)),
          const SizedBox(height: PlayNedTokens.space8),
          Text(body, style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}
