import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/game_model.dart';
import '../../registry/game_registry.dart';
import '../../services/platform_api_service.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../widgets/game_card.dart';
import '../widgets/platform_app_bar.dart';
import '../widgets/playned_components.dart';
import '../widgets/playned_logo.dart';

class PlatformHomePage extends ConsumerStatefulWidget {
  const PlatformHomePage({super.key});

  @override
  ConsumerState<PlatformHomePage> createState() => _PlatformHomePageState();
}

class _PlatformHomePageState extends ConsumerState<PlatformHomePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _exploreKey = GlobalKey();
  final GlobalKey _quickPlayKey = GlobalKey();

  String _selectedCategory = 'ALL';
  List<GameMetadata> _games = PlayNedGameRegistry.allGames;
  bool _isLoading = false;

  final List<String> _categories = [
    'ALL',
    'BOARD',
    'STRATEGY',
    'WORD & PUZZLE',
    'SPORTS',
    'CASUAL',
  ];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(platformApiServiceProvider);
      final list = await api.fetchGames();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _games = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: PlayNedTokens.animCurve,
      );
    }
  }

  List<GameMetadata> _getFilteredGames() {
    if (_selectedCategory == 'ALL') return _games;
    return _games.where((g) {
      final cat = g.category.toUpperCase();
      switch (_selectedCategory) {
        case 'BOARD':
          return cat.contains('BOARD') || g.id == 'quoridor' || g.id == 'pentago' || g.id == 'dots_and_boxes';
        case 'STRATEGY':
          return cat.contains('STRAT') || g.id == 'quoridor' || g.id == 'pentago' || g.id == 'cricket';
        case 'WORD & PUZZLE':
          return cat.contains('WORD') || cat.contains('PUZZLE') || g.id == 'hangman';
        case 'SPORTS':
          return cat.contains('SPORT') || g.id == 'cricket';
        case 'CASUAL':
          return cat.contains('CASUAL') || g.id == 'shut_the_box' || g.id == 'dots_and_boxes';
        default:
          return cat.contains(_selectedCategory);
      }
    }).toList();
  }

  void _showJoinRoom() {
    showDialog(
      context: context,
      builder: (_) => const JoinRoomDialog(),
    );
  }

  void _showCreateRoom() {
    showDialog(
      context: context,
      builder: (_) => const CreateRoomDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _getFilteredGames();

    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: PlatformAppBar(
        onGamesClick: () => _scrollToKey(_exploreKey),
        onQuickPlayClick: () => _scrollToKey(_quickPlayKey),
      ),
      body: PlayNedBackgroundPattern(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PlayNedTokens.space20,
                  vertical: PlayNedTokens.space24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. HERO SECTION
                    _buildHeroSection(context),

                    const SizedBox(height: PlayNedTokens.space32),

                    // 2. QUICK PLAY LAUNCHER
                    _buildQuickPlaySection(context),

                    const SizedBox(height: PlayNedTokens.space40),

                    // 3. EXPLORE GAMES / CATALOG
                    _buildExploreSection(context, filteredGames),

                    const SizedBox(height: PlayNedTokens.space48),

                    // 4. MULTIPLAYER / PLAY WITH FRIENDS
                    _buildMultiplayerSection(context),

                    const SizedBox(height: PlayNedTokens.space48),

                    // 5. EDITORIAL FOOTER
                    _buildFooter(context),

                    const SizedBox(height: PlayNedTokens.space24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. HERO SECTION ---
  Widget _buildHeroSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= PlayNedTokens.breakpointMd;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(
          color: PlayNedTokens.brandGold.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background 2D Geometric Universe Elements
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
              child: CustomPaint(
                painter: _HeroUniversePainter(),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(isDesktop ? PlayNedTokens.space32 : PlayNedTokens.space20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag & Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: PlayNedTokens.brandGold,
                              borderRadius: BorderRadius.circular(PlayNedTokens.radiusXs),
                            ),
                            child: Text(
                              "PLAYNED V1.4.3",
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                color: PlayNedTokens.textInverse,
                              ),
                            ),
                          ),
                          const SizedBox(width: PlayNedTokens.space10),
                          Text(
                            "MODULAR 2D MULTIPLAYER",
                            style: PlayNedTokens.metadata.copyWith(
                              color: PlayNedTokens.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: PlayNedTokens.space16),

                      // Hero Headline
                      Text(
                        "ONE PLATFORM.\nMANY WAYS TO PLAY.",
                        style: isDesktop
                            ? PlayNedTokens.heroDisplay
                            : GoogleFonts.dmSerifDisplay(
                                fontSize: 28,
                                height: 1.15,
                                color: PlayNedTokens.textPrimary,
                                letterSpacing: 0.5,
                              ),
                      ),

                      const SizedBox(height: PlayNedTokens.space12),

                      // Supporting Copy
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 580),
                        child: Text(
                          "Board games, word games, strategy, sports, and quick competitive matches — play solo, pass the screen, or invite a friend with 6-character room codes.",
                          style: PlayNedTokens.bodyMuted.copyWith(
                            fontSize: isDesktop ? 14 : 12.5,
                            height: 1.45,
                          ),
                        ),
                      ),

                      const SizedBox(height: PlayNedTokens.space24),

                      // CTAs
                      Wrap(
                        spacing: PlayNedTokens.space12,
                        runSpacing: PlayNedTokens.space10,
                        children: [
                          PlayNedButton(
                            label: "EXPLORE GAMES",
                            icon: Icons.grid_view_rounded,
                            variant: PlayNedButtonVariant.primary,
                            onPressed: () => _scrollToKey(_exploreKey),
                          ),
                          PlayNedButton(
                            label: "JOIN A ROOM",
                            icon: Icons.meeting_room_outlined,
                            variant: PlayNedButtonVariant.outlined,
                            onPressed: _showJoinRoom,
                          ),
                          PlayNedButton(
                            label: "CREATE MATCH",
                            icon: Icons.add_circle_outline,
                            variant: PlayNedButtonVariant.secondary,
                            onPressed: _showCreateRoom,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isDesktop) ...[
                  const SizedBox(width: PlayNedTokens.space24),
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PlayNedTokens.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: PlayNedTokens.brandGold.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: PlayNedTokens.brandGold.withOpacity(0.18),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: PlayNedLogo(
                        size: 110,
                        showText: false,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. QUICK PLAY LAUNCHER STRIP ---
  Widget _buildQuickPlaySection(BuildContext context) {
    return Column(
      key: _quickPlayKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          tag: "INSTANT ACCESS",
          title: "QUICK PLAY",
          subtitle: "Jump straight into a match without setup",
        ),
        const SizedBox(height: PlayNedTokens.space14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _games.map((game) {
              return Padding(
                padding: const EdgeInsets.only(right: PlayNedTokens.space12),
                child: _QuickPlayCard(
                  game: game,
                  onTap: () => context.push('/games/${game.id}'),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- 3. EXPLORE GAMES & CATEGORIES ---
  Widget _buildExploreSection(BuildContext context, List<GameMetadata> filteredGames) {
    return Column(
      key: _exploreKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          tag: "CATALOG",
          title: "EXPLORE GAMES",
          subtitle: "Discover all ${_games.length} titles available on PlayNed",
          trailing: Text(
            "${filteredGames.length} OF ${_games.length} GAMES",
            style: PlayNedTokens.metadata.copyWith(fontSize: 10, color: PlayNedTokens.textMuted),
          ),
        ),

        const SizedBox(height: PlayNedTokens.space16),

        // Category Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: PlayNedTokens.space8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor: PlayNedTokens.brandGold.withOpacity(0.2),
                  backgroundColor: PlayNedTokens.surface,
                  side: BorderSide(
                    color: isSelected ? PlayNedTokens.brandGold : PlayNedTokens.border,
                    width: isSelected ? 1.2 : 0.8,
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 0.8,
                    color: isSelected ? PlayNedTokens.brandGold : PlayNedTokens.textSecondary,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: PlayNedTokens.space20),

        // Responsive Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= PlayNedTokens.breakpointMd;
            final crossAxisCount = isDesktop ? 2 : 1;
            final childAspectRatio = isDesktop ? 1.28 : 1.15;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGames.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: PlayNedTokens.space16,
                mainAxisSpacing: PlayNedTokens.space16,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final game = filteredGames[index];
                return PlayNedGameCard(game: game);
              },
            );
          },
        ),
      ],
    );
  }

  // --- 4. MULTIPLAYER / PLAY WITH FRIENDS ---
  Widget _buildMultiplayerSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= PlayNedTokens.breakpointMd;

    return Container(
      padding: EdgeInsets.all(isDesktop ? PlayNedTokens.space28 : PlayNedTokens.space20),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(PlayNedTokens.space10),
                decoration: BoxDecoration(
                  color: PlayNedTokens.brandGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_outlined, color: PlayNedTokens.brandGold, size: 22),
              ),
              const SizedBox(width: PlayNedTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PLAY WITH FRIENDS", style: PlayNedTokens.gameTitle),
                    Text("Zero installs, cross-platform multiplayer in 3 simple steps", style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: PlayNedTokens.space24),

          // 3-Step Flow Row
          LayoutBuilder(
            builder: (context, constraints) {
              final stepCards = [
                _buildStepItem("01", "CREATE ROOM", "Select your game and generate a private 6-character room code."),
                _buildStepItem("02", "SHARE CODE", "Send the code or link to your friends on mobile, desktop, or tablet."),
                _buildStepItem("03", "PLAY TOGETHER", "Real-time state sync with live turns and instant rematching."),
              ];

              if (constraints.maxWidth >= PlayNedTokens.breakpointMd) {
                return Row(
                  children: stepCards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
                );
              } else {
                return Column(
                  children: stepCards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
                );
              }
            },
          ),

          const SizedBox(height: PlayNedTokens.space24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PlayNedButton(
                label: "JOIN EXISTING ROOM",
                variant: PlayNedButtonVariant.outlined,
                onPressed: _showJoinRoom,
              ),
              const SizedBox(width: PlayNedTokens.space12),
              PlayNedButton(
                label: "START A NEW MATCH",
                variant: PlayNedButtonVariant.primary,
                onPressed: _showCreateRoom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(PlayNedTokens.space16),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: PlayNedTokens.brandGold,
            ),
          ),
          const SizedBox(height: PlayNedTokens.space6),
          Text(
            title,
            style: PlayNedTokens.buttonLabel.copyWith(fontSize: 12, color: PlayNedTokens.textPrimary),
          ),
          const SizedBox(height: PlayNedTokens.space4),
          Text(
            description,
            style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }

  // --- 5. FOOTER ---
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: PlayNedTokens.space24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PlayNedTokens.borderSubtle, width: 1.0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const PlayNedLogo(size: 22, showText: true, fontSize: 11),
                  const SizedBox(width: PlayNedTokens.space12),
                  Text(
                    "ONE PLATFORM. MANY WAYS TO PLAY.",
                    style: PlayNedTokens.metadata.copyWith(fontSize: 9.5, color: PlayNedTokens.textMuted),
                  ),
                ],
              ),
              Text(
                "VERSION 1.4.3",
                style: PlayNedTokens.metadata.copyWith(fontSize: 9.5, color: PlayNedTokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: PlayNedTokens.space12),
          Text(
            "Built with Flutter, Python FastAPI, WebSockets & Neon PostgreSQL.",
            style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Quick play horizontal mini card
class _QuickPlayCard extends StatefulWidget {
  final GameMetadata game;
  final VoidCallback onTap;

  const _QuickPlayCard({required this.game, required this.onTap});

  @override
  State<_QuickPlayCard> createState() => _QuickPlayCardState();
}

class _QuickPlayCardState extends State<_QuickPlayCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.game;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PlayNedTokens.animMicro,
          width: 155,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? PlayNedTokens.surfaceElevated : PlayNedTokens.surface,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            border: Border.all(
              color: _isHovered ? g.accentColor : PlayNedTokens.border,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(g.icon, size: 20, color: g.accentColor),
              const SizedBox(width: PlayNedTokens.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      g.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: PlayNedTokens.textPrimary,
                      ),
                    ),
                    Text(
                      "~${g.estimatedDurationMinutes} MIN",
                      style: PlayNedTokens.metadata.copyWith(fontSize: 8.5, color: PlayNedTokens.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2D geometric universe painter for Hero banner
class _HeroUniversePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = PlayNedTokens.brandGold.withOpacity(0.04)
      ..strokeWidth = 1.0;

    // Subtle isometric grid lines on top right
    final startX = size.width * 0.55;
    for (double x = startX; x < size.width + 100; x += 35) {
      canvas.drawLine(Offset(x, 0), Offset(x - 80, size.height), linePaint);
      canvas.drawLine(Offset(x, size.height), Offset(x - 80, 0), linePaint);
    }

    // Subtle abstract 2D dice/tile outlines in background
    final boxPaint = Paint()
      ..color = PlayNedTokens.brandGold.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (size.width > 500) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 120, 25, 45, 45), const Radius.circular(6)),
        boxPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 60, 60, 35, 35), const Radius.circular(6)),
        boxPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
