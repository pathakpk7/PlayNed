import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  String _selectedCategory = 'All';
  List<GameMetadata> _games = PlayNedGameRegistry.allGames;
  bool _isLoading = false;

  final List<String> _categories = [
    'All',
    'Board',
    'Strategy',
    'Word & Puzzle',
    'Sports',
    'Casual',
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
        duration: const Duration(milliseconds: 550),
        curve: PlayNedTokens.animCurve,
      );
    }
  }

  List<GameMetadata> _getFilteredGames() {
    if (_selectedCategory == 'All') return _games;
    return _games.where((g) {
      final cat = g.category.toLowerCase();
      switch (_selectedCategory) {
        case 'Board':
          return cat.contains('board') || g.id == 'quoridor' || g.id == 'pentago' || g.id == 'dots_and_boxes' || g.id == 'reversi';
        case 'Strategy':
          return cat.contains('strat') || g.id == 'quoridor' || g.id == 'pentago' || g.id == 'cricket' || g.id == 'ultimate_tic_tac_toe';
        case 'Word & Puzzle':
          return cat.contains('word') || cat.contains('puzzle') || g.id == 'hangman';
        case 'Sports':
          return cat.contains('sport') || g.id == 'cricket';
        case 'Casual':
          return cat.contains('casual') || g.id == 'shut_the_box' || g.id == 'dots_and_boxes' || g.id == 'bingo' || g.id == 'higher_or_lower';
        default:
          return cat.contains(_selectedCategory.toLowerCase());
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
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PlayNedTokens.space24,
                  vertical: PlayNedTokens.space32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. HERO SECTION
                    _buildHeroSection(context),

                    const SizedBox(height: PlayNedTokens.space64),

                    // 2. QUICK PLAY STRIP
                    _buildQuickPlaySection(context),

                    const SizedBox(height: PlayNedTokens.space64),

                    // 3. EXPLORE GAMES CATALOG
                    _buildExploreSection(context, filteredGames),

                    const SizedBox(height: PlayNedTokens.space64),

                    // 4. MULTIPLAYER SECTION
                    _buildMultiplayerSection(context),

                    const SizedBox(height: PlayNedTokens.space80),

                    // 5. REFINED FOOTER
                    _buildFooter(context),

                    const SizedBox(height: PlayNedTokens.space32),
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
    final isMobile = MediaQuery.of(context).size.width < PlayNedTokens.breakpointSm;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? PlayNedTokens.space48 : PlayNedTokens.space24,
        vertical: isDesktop ? PlayNedTokens.space64 : PlayNedTokens.space40,
      ),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Editorial Typography & CTAs
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    Text(
                      "One platform, endless ways to play",
                      style: (isDesktop
                              ? PlayNedTokens.heroDisplay
                              : GoogleFonts.plusJakartaSans(
                                  fontSize: isMobile ? 32 : 38,
                                  fontWeight: FontWeight.w800,
                                  height: 1.12,
                                  color: PlayNedTokens.textPrimary,
                                  letterSpacing: -0.8,
                                ))
                          .copyWith(color: PlayNedTokens.textPrimary),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.12, end: 0),

                    const SizedBox(height: PlayNedTokens.space16),

                    // Subtitle Narrative
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Text(
                        "Step into strategic board classics, word deduction, tactical sports, and high-stakes card matches. Play solo against intelligent AI, pass the device locally, or invite friends with instant room codes",
                        style: PlayNedTokens.body.copyWith(
                          color: PlayNedTokens.textSecondary,
                          fontSize: isDesktop ? 16 : 14,
                          height: 1.55,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 450.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.12, end: 0),

                    const SizedBox(height: PlayNedTokens.space32),

                    // Call to Action Buttons
                    Wrap(
                      spacing: PlayNedTokens.space12,
                      runSpacing: PlayNedTokens.space12,
                      children: [
                        PlayNedButton(
                          label: "Browse games",
                          icon: Icons.grid_view_rounded,
                          variant: PlayNedButtonVariant.primary,
                          onPressed: () => _scrollToKey(_exploreKey),
                        ),
                        PlayNedButton(
                          label: "IPL Mini Auction",
                          icon: Icons.gavel,
                          variant: PlayNedButtonVariant.secondary,
                          customAccent: PlayNedTokens.brandGold,
                          onPressed: () => context.push('/games/cricket/auction'),
                        ),
                        PlayNedButton(
                          label: "Join match",
                          icon: Icons.meeting_room_outlined,
                          variant: PlayNedButtonVariant.outlined,
                          onPressed: _showJoinRoom,
                        ),
                        PlayNedButton(
                          label: "Host room",
                          icon: Icons.add,
                          variant: PlayNedButtonVariant.ghost,
                          onPressed: _showCreateRoom,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 500.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.12, end: 0),
                  ],
                ),
              ),

              // Interactive Graphic Preview Showcase
              if (isDesktop) ...[
                const SizedBox(width: PlayNedTokens.space40),
                Expanded(
                  flex: 5,
                  child: _HeroInteractiveShowcase(
                    games: _games,
                    onGameSelect: (game) => context.push('/games/${game.id}'),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutCubic)
                      .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // --- 2. QUICK PLAY SECTION ---
  Widget _buildQuickPlaySection(BuildContext context) {
    return Column(
      key: _quickPlayKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Quick play",
          subtitle: "Jump straight into a match without room creation",
        ),
        const SizedBox(height: PlayNedTokens.space20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: PlayNedTokens.space14),
                child: _FeaturedAuctionQuickCard(
                  onTap: () => context.push('/games/cricket/auction'),
                ),
              ),
              ..._games.map((game) {
                return Padding(
                  padding: const EdgeInsets.only(right: PlayNedTokens.space14),
                  child: _QuickPlayCard(
                    game: game,
                    onTap: () => context.push('/games/${game.id}'),
                  ),
                );
              }),
            ],
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
          title: "Explore games",
          subtitle: "Explore the complete collection of board, word, and strategy games",
          trailing: Text(
            "${filteredGames.length} titles available",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: PlayNedTokens.textMuted,
            ),
          ),
        ),

        const SizedBox(height: PlayNedTokens.space24),

        // Clean Category Switcher (No pill chip clichés)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: PlayNedTokens.space8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: PlayNedTokens.animFast,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? PlayNedTokens.surfaceElevated : Colors.transparent,
                      borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                      border: Border.all(
                        color: isSelected ? PlayNedTokens.borderBright : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? PlayNedTokens.textPrimary : PlayNedTokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: PlayNedTokens.space28),

        // Responsive Grid
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            double childAspectRatio = 1.15;

            if (constraints.maxWidth >= 1200) {
              crossAxisCount = 4;
              childAspectRatio = 0.95;
            } else if (constraints.maxWidth >= 900) {
              crossAxisCount = 3;
              childAspectRatio = 1.0;
            } else if (constraints.maxWidth >= 600) {
              crossAxisCount = 2;
              childAspectRatio = 1.12;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGames.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: PlayNedTokens.space20,
                mainAxisSpacing: PlayNedTokens.space20,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final game = filteredGames[index];
                return PlayNedGameCard(game: game)
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: (index * 40).clamp(0, 400)),
                      duration: 350.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(begin: 0.08, end: 0);
              },
            );
          },
        ),
      ],
    );
  }

  // --- 4. MULTIPLAYER SECTION ---
  Widget _buildMultiplayerSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= PlayNedTokens.breakpointMd;

    return Container(
      padding: EdgeInsets.all(isDesktop ? PlayNedTokens.space40 : PlayNedTokens.space24),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Play with friends anywhere",
                          style: PlayNedTokens.sectionHeading,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Instant cross-platform rooms with zero downloads or configuration",
                          style: PlayNedTokens.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: PlayNedTokens.space32),

              // Steps without artificial "01, 02, 03" numbering
              LayoutBuilder(
                builder: (context, stepConstraints) {
                  final stepCards = [
                    _buildFeatureItem(
                      icon: Icons.add_circle_outline,
                      title: "Host a table",
                      description: "Select your game and generate a private 6-character room code instantly.",
                    ),
                    _buildFeatureItem(
                      icon: Icons.share_outlined,
                      title: "Invite your circle",
                      description: "Send the code or link to your friends on mobile, laptop, or tablet.",
                    ),
                    _buildFeatureItem(
                      icon: Icons.bolt,
                      title: "Play in real time",
                      description: "Synchronized turns, live state management, and instant rematching.",
                    ),
                  ];

                  if (stepConstraints.maxWidth >= PlayNedTokens.breakpointMd) {
                    return Row(
                      children: stepCards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
                    );
                  } else {
                    return Column(
                      children: stepCards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
                    );
                  }
                },
              ),

              const SizedBox(height: PlayNedTokens.space32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlayNedButton(
                    label: "Join with code",
                    variant: PlayNedButtonVariant.outlined,
                    onPressed: _showJoinRoom,
                  ),
                  const SizedBox(width: PlayNedTokens.space12),
                  PlayNedButton(
                    label: "Start new match",
                    variant: PlayNedButtonVariant.primary,
                    onPressed: _showCreateRoom,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(PlayNedTokens.space20),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: PlayNedTokens.brandGold),
          const SizedBox(height: PlayNedTokens.space14),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: PlayNedTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: PlayNedTokens.bodyMuted.copyWith(fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }

  // --- 5. REFINED FOOTER ---
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const PlayNedLogo(size: 24, showText: true, fontSize: 13),
                const SizedBox(width: PlayNedTokens.space16),
                Text(
                  "Curated multiplayer gaming",
                  style: GoogleFonts.inter(fontSize: 12, color: PlayNedTokens.textMuted),
                ),
              ],
            ),
            Row(
              children: [
                _FooterLink(label: "Games", onTap: () => _scrollToKey(_exploreKey)),
                const SizedBox(width: PlayNedTokens.space16),
                _FooterLink(label: "Settings", onTap: () => context.push('/settings')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: _isHovered ? PlayNedTokens.textPrimary : PlayNedTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Interactive Hero Showcase Component
class _HeroInteractiveShowcase extends StatefulWidget {
  final List<GameMetadata> games;
  final ValueChanged<GameMetadata> onGameSelect;

  const _HeroInteractiveShowcase({
    required this.games,
    required this.onGameSelect,
  });

  @override
  State<_HeroInteractiveShowcase> createState() => _HeroInteractiveShowcaseState();
}

class _HeroInteractiveShowcaseState extends State<_HeroInteractiveShowcase> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) return const SizedBox.shrink();
    final activeGame = widget.games[_activeIndex % widget.games.length];

    return Container(
      padding: const EdgeInsets.all(PlayNedTokens.space24),
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
              Text(
                "Featured Spotlight",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PlayNedTokens.textMuted,
                ),
              ),
              Row(
                children: List.generate(
                  widget.games.length.clamp(0, 4),
                  (idx) => GestureDetector(
                    onTap: () => setState(() => _activeIndex = idx),
                    child: AnimatedContainer(
                      duration: PlayNedTokens.animFast,
                      margin: const EdgeInsets.only(left: 6),
                      width: _activeIndex == idx ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _activeIndex == idx ? activeGame.accentColor : PlayNedTokens.borderBright,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: PlayNedTokens.space20),

          // Visual Presentation
          AnimatedSwitcher(
            duration: PlayNedTokens.animStandard,
            child: KeyedSubtree(
              key: ValueKey(activeGame.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activeGame.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(activeGame.icon, size: 24, color: activeGame.accentColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeGame.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: PlayNedTokens.textPrimary,
                              ),
                            ),
                            Text(
                              activeGame.category,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: PlayNedTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    activeGame.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: PlayNedTokens.bodyMuted.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${activeGame.minPlayers}–${activeGame.maxPlayers} Players • ~${activeGame.estimatedDurationMinutes} min",
                        style: GoogleFonts.inter(fontSize: 12, color: PlayNedTokens.textMuted),
                      ),
                      PlayNedButton(
                        label: "Play now",
                        variant: PlayNedButtonVariant.primary,
                        customAccent: activeGame.accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        onPressed: () => widget.onGameSelect(activeGame),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Play Card
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
          duration: PlayNedTokens.animFast,
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          width: 175,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? PlayNedTokens.surfaceElevated : PlayNedTokens.surface,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
            border: Border.all(
              color: _isHovered ? g.accentColor.withOpacity(0.5) : PlayNedTokens.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(g.icon, size: 20, color: g.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      g.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PlayNedTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "~${g.estimatedDurationMinutes} min",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: PlayNedTokens.textMuted,
                      ),
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

/// Featured IPL Mini Auction Quick Play Card
class _FeaturedAuctionQuickCard extends StatefulWidget {
  final VoidCallback onTap;

  const _FeaturedAuctionQuickCard({required this.onTap});

  @override
  State<_FeaturedAuctionQuickCard> createState() => _FeaturedAuctionQuickCardState();
}

class _FeaturedAuctionQuickCardState extends State<_FeaturedAuctionQuickCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PlayNedTokens.animFast,
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? PlayNedTokens.surfaceElevated : PlayNedTokens.surface,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
            border: Border.all(
              color: PlayNedTokens.brandGold.withOpacity(_isHovered ? 0.8 : 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.gavel, size: 20, color: PlayNedTokens.brandGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "IPL Auction",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: PlayNedTokens.brandGold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "War Room • ₹120 Cr",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: PlayNedTokens.textSecondary,
                      ),
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
