import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/game_model.dart';
import '../../registry/game_registry.dart';
import '../../services/platform_api_service.dart';
import '../widgets/platform_app_bar.dart';
import '../widgets/game_card.dart';

class PlatformHomePage extends ConsumerStatefulWidget {
  const PlatformHomePage({super.key});

  @override
  ConsumerState<PlatformHomePage> createState() => _PlatformHomePageState();
}

class _PlatformHomePageState extends ConsumerState<PlatformHomePage> {
  String _selectedCategory = 'ALL';
  List<GameMetadata> _games = PlayNedGameRegistry.allGames;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGames();
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

  @override
  Widget build(BuildContext context) {
    final categories = ['ALL', 'STRATEGY', 'WORD / PUZZLE', 'BOARD'];

    final filteredGames = _selectedCategory == 'ALL'
        ? _games
        : _games.where((g) => g.category.toUpperCase().contains(_selectedCategory)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0D),
      appBar: const PlatformAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform Hero Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1A14), Color(0xFF131311)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD5A84B).withOpacity(0.35), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD5A84B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "2D MULTIPLAYER",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: const Color(0xFF0F0F0D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "GAME PLATFORM",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: const Color(0xFFA9A396),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Play something.",
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 34,
                          color: const Color(0xFFF1EBDD),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Casual, strategy, deduction, and board games. Play locally on the same screen or create a room code to battle friends in real-time.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFA9A396),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD5A84B),
                              foregroundColor: const Color(0xFF0F0F0D),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () {
                              // Scroll to games catalog
                            },
                            icon: const Icon(Icons.grid_view_rounded, size: 16),
                            label: Text(
                              "BROWSE GAMES",
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12),
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF1EBDD),
                              side: const BorderSide(color: Color(0xFF2A2A26), width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => context.push('/games/hangman/hub'),
                            icon: const Icon(Icons.spellcheck, size: 16, color: Color(0xFFD5A84B)),
                            label: Text(
                              "HANGMAN REIMAGINED",
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Category Filter Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "FEATURED GAMES",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: const Color(0xFFA9A396),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFD5A84B).withOpacity(0.18) : const Color(0xFF181816),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFD5A84B) : const Color(0xFF2A2A26),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFFD5A84B) : const Color(0xFFA9A396),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Responsive Game Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredGames.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: crossAxisCount == 2 ? 1.75 : 2.0,
                      ),
                      itemBuilder: (context, index) {
                        final game = filteredGames[index];
                        return PlayNedGameCard(game: game);
                      },
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Platform Rooms Promo & Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141412),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A26)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5A84B).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.hub_outlined, color: Color(0xFFD5A84B), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Universal Room & Multiplayer Lobby",
                              style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Every game on PlayNed supports 6-character room codes and shareable web links with real-time turn synchronization.",
                              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFA9A396)),
                            ),
                          ],
                        ),
                      ),
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
