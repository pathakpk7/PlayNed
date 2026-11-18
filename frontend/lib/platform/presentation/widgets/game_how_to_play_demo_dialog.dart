import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/game_model.dart';
import '../../registry/game_registry.dart';
import '../theme/playned_design_tokens.dart';

class GameDemoStep {
  final String title;
  final String description;
  final IconData icon;
  final String? diagramType; // e.g. 'uttt_macro', 'uttt_routing', 'uttt_free', etc.
  final List<String> bulletPoints;
  final String? proTip;

  const GameDemoStep({
    required this.title,
    required this.description,
    required this.icon,
    this.diagramType,
    required this.bulletPoints,
    this.proTip,
  });
}

class GameDemoData {
  final String gameId;
  final String gameName;
  final String tagline;
  final Color accentColor;
  final List<GameDemoStep> steps;

  const GameDemoData({
    required this.gameId,
    required this.gameName,
    required this.tagline,
    required this.accentColor,
    required this.steps,
  });
}

class GameHowToPlayDemoDialog extends StatefulWidget {
  final String gameId;
  final VoidCallback? onPlayFreelyToggled;

  const GameHowToPlayDemoDialog({
    super.key,
    required this.gameId,
    this.onPlayFreelyToggled,
  });

  @override
  State<GameHowToPlayDemoDialog> createState() => _GameHowToPlayDemoDialogState();
}

class _GameHowToPlayDemoDialogState extends State<GameHowToPlayDemoDialog> {
  int _currentStep = 0;
  late GameDemoData _demoData;

  @override
  void initState() {
    super.initState();
    _demoData = _getDemoData(widget.gameId);
  }

  static void show(BuildContext context, String gameId, {VoidCallback? onPlayFreelyToggled}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => GameHowToPlayDemoDialog(
        gameId: gameId,
        onPlayFreelyToggled: onPlayFreelyToggled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _demoData.steps[_currentStep];
    final isLast = _currentStep == _demoData.steps.length - 1;

    return Dialog(
      backgroundColor: const Color(0xFF141822),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        side: BorderSide(color: _demoData.accentColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _demoData.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _demoData.accentColor.withValues(alpha: 0.4)),
                        ),
                        child: Icon(step.icon, color: _demoData.accentColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_demoData.gameName.toUpperCase()} • HOW TO PLAY",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: _demoData.accentColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Step ${_currentStep + 1} of ${_demoData.steps.length}: ${step.title}",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    tooltip: "Close Demo",
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Area
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Visual interactive demo diagram card
                      _buildDiagramCard(step, _demoData.accentColor),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        step.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFE2E8F0),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Bullet Points
                      ...step.bulletPoints.map((bp) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, right: 10),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _demoData.accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    bp,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFFCBD5E1),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      // Pro Tip Callout
                      if (step.proTip != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline, color: Color(0xFF38BDF8), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.proTip!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFBAE6FD),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Navigation & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step Dots
                  Row(
                    children: List.generate(_demoData.steps.length, (idx) {
                      final isActive = idx == _currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? _demoData.accentColor : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: () => setState(() => _currentStep--),
                          child: Text(
                            "Previous",
                            style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _demoData.accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          if (isLast) {
                            Navigator.of(context).pop();
                          } else {
                            setState(() => _currentStep++);
                          }
                        },
                        child: Text(
                          isLast ? "Got It, Let's Play!" : "Next Step ->",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagramCard(GameDemoStep step, Color accent) {
    if (step.diagramType == 'uttt_routing') {
      return Container(
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F121C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Micro board with mark
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("You play in Cell (1, 1)", style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(9, (i) {
                        return Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
                          child: Center(
                            child: i == 4
                                ? const Text("X", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold))
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Color(0xFFF59E0B), size: 28),
            // Macro grid pointing to center board
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Opponent sent to Center Block!", style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(9, (i) {
                        final isTarget = i == 4;
                        return Container(
                          decoration: BoxDecoration(
                            color: isTarget ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : null,
                            border: Border.all(color: isTarget ? const Color(0xFFF59E0B) : Colors.white10),
                          ),
                          child: Center(
                            child: isTarget ? const Icon(Icons.my_location, size: 14, color: Color(0xFFF59E0B)) : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (step.diagramType == 'uttt_freedom') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lock_open_rounded, color: Color(0xFF38BDF8), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Play Freely Option Available Anytime!",
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Prefer unconstrained play? You can toggle 'Free Choice Mode' directly at the top of the board to place marks in ANY open block on every turn without restriction!",
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
            ),
          ],
        ),
      );
    }

    // Default icon banner
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Icon(step.icon, size: 44, color: accent.withValues(alpha: 0.8)),
      ),
    );
  }

  static GameDemoData _getDemoData(String gameId) {
    switch (gameId) {
      case 'ultimate_tic_tac_toe':
      case 'ultimate-tic-tac-toe':
        return const GameDemoData(
          gameId: 'ultimate_tic_tac_toe',
          gameName: 'Ultimate Tic-Tac-Toe',
          tagline: 'Recursive strategy: every move dictates where your opponent plays next.',
          accentColor: Color(0xFFF59E0B),
          steps: [
            GameDemoStep(
              title: "The 9x9 Macro Grid Layout",
              description: "Ultimate Tic-Tac-Toe consists of 1 giant Macro 3x3 board containing 9 smaller Micro 3x3 boards (81 cells total).",
              icon: Icons.grid_4x4_rounded,
              bulletPoints: [
                "You play as either X (Blue) or O (Amber).",
                "Winning a 3-in-a-row inside any small board claims that entire macro board.",
                "Forming a 3-in-a-row across the large macro grid wins the ultimate match!",
              ],
              proTip: "Think two moves ahead! Sacrificing a small board to send your opponent to a dead corner is often a winning maneuver.",
            ),
            GameDemoStep(
              title: "Target Board Routing Rule",
              description: "In Classic Rules, the cell position you select dictates which board your opponent must play in next.",
              icon: Icons.alt_route_rounded,
              diagramType: 'uttt_routing',
              bulletPoints: [
                "Placing your mark in the top-right cell of any board forces your opponent to play in the top-right board.",
                "Placing your mark in the center cell sends your opponent to the center board.",
                "The board lights up with an amber pulse indicating your active target block.",
              ],
              proTip: "Never blindly take an easy cell if it sends your opponent directly into a board where they have a winning line!",
            ),
            GameDemoStep(
              title: "Free Move Rule & Free Play Mode",
              description: "What if you are sent to a board that is already won or full? You receive a FREE MOVE!",
              icon: Icons.lock_open_rounded,
              diagramType: 'uttt_freedom',
              bulletPoints: [
                "⭐ Free Move: When routed to an already completed board, you can place your mark in ANY open board on the entire grid.",
                "🚀 Play Freely Toggle: You can also toggle 'Free Choice Mode' at any time from the top bar if you prefer playing anywhere without block restrictions!",
              ],
              proTip: "Sending an opponent into a completed board gives them a powerful Free Move — avoid doing this unless deliberate!",
            ),
            GameDemoStep(
              title: "Ultimate Victory Condition",
              description: "Win 3 macro boards in a row (horizontal, vertical, or diagonal) to achieve Ultimate Victory!",
              icon: Icons.emoji_events_rounded,
              bulletPoints: [
                "Claiming a small board locks that board for the macro calculation.",
                "If no player connects 3 macro boards and all boards fill up, the player with the most small boards claimed wins, or ends in a draw.",
              ],
              proTip: "Control the corners and the center macro boards early to maximize your line-completion angles.",
            ),
          ],
        );

      case 'dots_and_boxes':
        return const GameDemoData(
          gameId: 'dots_and_boxes',
          gameName: 'Dots & Boxes',
          tagline: 'Territorial line-drawing strategy and chain capture.',
          accentColor: Color(0xFF4E89FF),
          steps: [
            GameDemoStep(
              title: "Drawing Lines",
              description: "Players take turns connecting two adjacent dots with a single horizontal or vertical line.",
              icon: Icons.timeline,
              bulletPoints: [
                "Tap on any dashed line between dots to draw your wall.",
                "Walls can be placed anywhere on the grid.",
                "Turns alternate between players until a box is completed.",
              ],
            ),
            GameDemoStep(
              title: "Capturing Boxes & Bonus Turns",
              description: "When you place the 4th closing line of a 1x1 box, you capture it and score 1 point!",
              icon: Icons.check_box_outlined,
              bulletPoints: [
                "The completed box fills with your color and initial.",
                "⭐ Critical Rule: Closing a box gives you an IMMEDIATE BONUS TURN!",
                "You can chain multiple box captures together in a single turn.",
              ],
              proTip: "Beware of creating '3-sided boxes' that your opponent can capture on their next turn!",
            ),
            GameDemoStep(
              title: "Winning the Match",
              description: "When all dots are connected and every box is captured, the player with the highest score wins.",
              icon: Icons.emoji_events_outlined,
              bulletPoints: [
                "In 2-player mode, the first to secure more than half the total boxes guarantees victory.",
                "Long chain reactions in the end-game often decide the entire match.",
              ],
            ),
          ],
        );

      case 'quoridor':
        return const GameDemoData(
          gameId: 'quoridor',
          gameName: 'Quoridor',
          tagline: 'Mensa-awarded maze race and tactical wall blocking.',
          accentColor: Color(0xFFE57373),
          steps: [
            GameDemoStep(
              title: "The Goal: Cross the Board",
              description: "Guide your pawn from your baseline to any square on the opponent's opposite side of the 9x9 board.",
              icon: Icons.directions_run_outlined,
              bulletPoints: [
                "Pawns move 1 square orthogonally (forward, backward, left, or right).",
                "If two pawns face each other, you can jump over your opponent!",
                "First player to touch the opposite baseline wins immediately.",
              ],
            ),
            GameDemoStep(
              title: "Placing Walls & The Golden Rule",
              description: "Instead of moving your pawn, you can place a 2-tile wall to block your opponent's path.",
              icon: Icons.view_column_outlined,
              bulletPoints: [
                "Walls can be placed horizontally or vertically between grid cells.",
                "Each player starts with a limited supply of 10 walls.",
                "⚠️ THE GOLDEN RULE: You may NEVER completely seal off an opponent's path to their goal. At least one open path must always remain!",
              ],
              proTip: "Use walls to build long serpentine corridors that multiply your opponent's required steps.",
            ),
          ],
        );

      case 'pentago':
        return const GameDemoData(
          gameId: 'pentago',
          gameName: 'Pentago',
          tagline: '5-in-a-row with a rotating twist.',
          accentColor: Color(0xFF48BB78),
          steps: [
            GameDemoStep(
              title: "Phase 1: Place a Marble",
              description: "Played on a 6x6 board composed of four independent 3x3 quadrants.",
              icon: Icons.circle_outlined,
              bulletPoints: [
                "On your turn, place a marble into any empty cell on the entire 6x6 grid.",
                "Player 1 plays White/Green marbles, Player 2 plays Black/Orange marbles.",
              ],
            ),
            GameDemoStep(
              title: "Phase 2: Twist a Quadrant",
              description: "After placing your marble, you MUST rotate any one of the four quadrants 90 degrees.",
              icon: Icons.rotate_right_rounded,
              bulletPoints: [
                "Choose any quadrant (even one you didn't place a marble in).",
                "Twist it 90° clockwise or counter-clockwise.",
                "The rotation alters the board geometry and shifts alignments dynamically!",
              ],
              proTip: "You can use the twist to disrupt an opponent's incoming 5-in-a-row or instantly complete your own!",
            ),
            GameDemoStep(
              title: "Form 5-in-a-Row to Win",
              description: "Align 5 of your marbles horizontally, vertically, or diagonally.",
              icon: Icons.stars_rounded,
              bulletPoints: [
                "Lines can span across multiple quadrants.",
                "A win can be formed on placement OR after the rotation.",
                "If a twist creates 5-in-a-row for both players simultaneously, the game ends in a Draw.",
              ],
            ),
          ],
        );

      case 'shut_the_box':
        return const GameDemoData(
          gameId: 'shut_the_box',
          gameName: 'Shut the Box',
          tagline: 'Roll dice, flip tiles, and aim for 0 penalty points.',
          accentColor: Color(0xFFE5A93C),
          steps: [
            GameDemoStep(
              title: "Rolling the Dice",
              description: "Numbered tiles from 1 to 9 (or 12) start upright. On your turn, roll the dice to get a target sum.",
              icon: Icons.casino_outlined,
              bulletPoints: [
                "Roll 2 dice to get a total (e.g., 3 + 5 = 8).",
                "If the sum of remaining open tiles is 6 or less, you can choose to roll only 1 single die!",
              ],
            ),
            GameDemoStep(
              title: "Flipping Matching Tiles",
              description: "Flip down any combination of open tiles that add up exactly to your dice sum.",
              icon: Icons.filter_9_plus_outlined,
              bulletPoints: [
                "For a dice roll of 8, you could flip: [8], or [1, 7], or [2, 6], or [3, 5], or [1, 2, 5].",
                "Flipped tiles remain shut for the rest of your turn.",
                "Keep rolling as long as you can legally match your dice sum.",
              ],
              proTip: "Shut higher numbers (7, 8, 9) early to drastically lower your potential penalty points!",
            ),
            GameDemoStep(
              title: "Scoring & The Grand Slam",
              description: "When no open tiles match your roll, your turn ends. Penalty = sum of open tiles.",
              icon: Icons.military_tech_outlined,
              bulletPoints: [
                "The player with the lowest penalty score wins the round.",
                "⭐ Grand Slam: If you successfully shut ALL 9 tiles, your score is 0 (Instant Victory)!",
              ],
            ),
          ],
        );

      case 'reversi':
        return const GameDemoData(
          gameId: 'reversi',
          gameName: 'Reversi & Othello',
          tagline: 'A minute to learn, a lifetime to master.',
          accentColor: Color(0xFF10B981),
          steps: [
            GameDemoStep(
              title: "The Sandwich Rule",
              description: "Place a disc on an empty square to trap one or more opponent discs between your new disc and another disc of your color.",
              icon: Icons.adjust_rounded,
              bulletPoints: [
                "Sandwiches can occur in any straight line: horizontal, vertical, or diagonal.",
                "All trapped opponent discs in all 8 directions flip to your color simultaneously!",
                "You may ONLY place a disc if it flips at least one opposing disc.",
              ],
            ),
            GameDemoStep(
              title: "Corner Supremacy",
              description: "Corner squares are the most valuable tactical positions on the board.",
              icon: Icons.crop_square_rounded,
              bulletPoints: [
                "Once captured, a corner disc can NEVER be flipped by your opponent.",
                "Corners allow you to build permanently protected edge anchors.",
                "⚠️ Avoid placing discs in squares adjacent to open corners ('C' and 'X' squares)!",
              ],
              proTip: "Early in the game, having fewer discs is often better because it limits your opponent's mobility.",
            ),
          ],
        );

      case 'bingo':
        return const GameDemoData(
          gameId: 'bingo',
          gameName: 'Bingo',
          tagline: 'Mark your numbers, complete the pattern, and call Bingo!',
          accentColor: Color(0xFFF59E0B),
          steps: [
            GameDemoStep(
              title: "The 5x5 Card",
              description: "Each player receives a 5x5 Bingo grid with columns B (1-15), I (16-30), N (31-45), G (46-60), and O (61-75).",
              icon: Icons.grid_view_rounded,
              bulletPoints: [
                "The center square (N3) is a FREE space that starts permanently marked.",
                "Numbers are drawn randomly from the hopper one by one.",
                "Called numbers light up and get automatically marked on your card.",
              ],
            ),
            GameDemoStep(
              title: "Winning Patterns",
              description: "Complete the designated winning pattern before your opponent to achieve BINGO!",
              icon: Icons.pattern_rounded,
              bulletPoints: [
                "Classic Line: Any full horizontal row, vertical column, or diagonal.",
                "Four Corners: Mark all 4 outer corner numbers.",
                "X Pattern: Mark both full diagonal lines.",
                "Blackout: Cover every single number on your entire card!",
              ],
            ),
          ],
        );

      case 'higher_or_lower':
        return const GameDemoData(
          gameId: 'higher_or_lower',
          gameName: 'Higher or Lower',
          tagline: 'High-stakes rank prediction and streak management.',
          accentColor: Color(0xFF6366F1),
          steps: [
            GameDemoStep(
              title: "Predict the Next Value",
              description: "A number or card is displayed on the board. Predict whether the next revealed value will be HIGHER or LOWER.",
              icon: Icons.unfold_more_rounded,
              bulletPoints: [
                "Tap 'HIGHER' if you think the next card is greater.",
                "Tap 'LOWER' if you think the next card is smaller.",
                "Numbers range from 1 to 100 (or Card ranks 2 through Ace).",
              ],
            ),
            GameDemoStep(
              title: "Streaks & Point Multipliers",
              description: "Every consecutive correct guess increases your streak multiplier!",
              icon: Icons.bolt_rounded,
              bulletPoints: [
                "A streak of 3x or 5x dramatically boosts your round score.",
                "An incorrect prediction breaks your streak.",
                "Compete across 20 rounds or race to reach the target score first!",
              ],
              proTip: "If the current value is below 50, predicting Higher gives statistically favorable odds!",
            ),
          ],
        );

      case 'cricket':
        return const GameDemoData(
          gameId: 'cricket',
          gameName: 'Cricket Hub',
          tagline: 'Super Over duels, Stat Clashes, and IPL Mini-Auction.',
          accentColor: Color(0xFFE5A93C),
          steps: [
            GameDemoStep(
              title: "Super Over Duel",
              description: "A high-octane 6-ball innings duel between batter and bowler.",
              icon: Icons.sports_cricket,
              bulletPoints: [
                "Pick 2 batsmen and 1 bowler to take into the clash.",
                "Batter selects a shot: Defend, Normal, Attack, or Lofted.",
                "Bowler selects a delivery: Yorker, Bouncer, Good Length, Full, or Slower.",
                "Outcomes are determined by realistic tactical matchup probabilities!",
              ],
            ),
            GameDemoStep(
              title: "Stat Clash & IPL Auction",
              description: "Draft squads to hit statistical milestones or bid in live 10-franchise auctions.",
              icon: Icons.analytics_outlined,
              bulletPoints: [
                "Stat Clash: Select 5 legends to get as close to target stats without busting.",
                "Mini Auction: Manage ₹120 Cr budget and build a championship XI against smart AI bidders.",
              ],
            ),
          ],
        );

      case 'hangman':
        return const GameDemoData(
          gameId: 'hangman',
          gameName: 'Hangman Reimagined',
          tagline: 'Strategic word discovery with Word DNA analytics.',
          accentColor: Color(0xFFD5A84B),
          steps: [
            GameDemoStep(
              title: "Guessing Hidden Letters",
              description: "Decipher the mystery word letter-by-letter before your hearts run out.",
              icon: Icons.spellcheck,
              bulletPoints: [
                "You have 5 hearts. Each wrong letter guess deducts 1 heart.",
                "Correct guesses reveal letter positions and increase your combo multiplier.",
                "Inspect Word DNA clues (length, vowel count, repeated patterns) to deduce difficult words.",
              ],
            ),
          ],
        );

      default:
        // Generic fallback for party / classic games
        final game = PlayNedGameRegistry.getGame(gameId);
        return GameDemoData(
          gameId: gameId,
          gameName: game?.name ?? 'PlayNed Game',
          tagline: game?.tagline ?? 'Play together locally or online with friends.',
          accentColor: game?.accentColor ?? PlayNedTokens.brandGold,
          steps: [
            GameDemoStep(
              title: "Objective & Rules",
              description: game?.description ?? "Enjoy real-time strategic multiplayer on PlayNed.",
              icon: game?.icon ?? Icons.sports_esports_outlined,
              bulletPoints: game?.rulesSummary ?? [
                "Follow turn-based instructions on screen.",
                "Take actions on your turn and anticipate opponent moves.",
                "Achieve the victory condition to win!",
              ],
            ),
          ],
        );
    }
  }
}
