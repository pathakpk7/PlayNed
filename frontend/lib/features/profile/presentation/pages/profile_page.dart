import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../game/presentation/providers/game_provider.dart';
import '../../../../platform/services/platform_api_service.dart';

final profileFutureProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  return api.getProfile(userId);
});

final allGameStatsFutureProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final platformApi = ref.watch(platformApiServiceProvider);
  return platformApi.fetchUserAllGameStats(userId);
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String _selectedGameFilter = 'all';

  static const List<Map<String, dynamic>> _gameTabs = [
    {'id': 'all', 'label': 'Overview', 'icon': Icons.dashboard_outlined, 'color': Color(0xFFD5A84B)},
    {'id': 'cricket', 'label': 'Cricket', 'icon': Icons.sports_cricket, 'color': Color(0xFF38A169)},
    {'id': 'hangman', 'label': 'Hangman', 'icon': Icons.menu_book_outlined, 'color': Color(0xFFD5A84B)},
    {'id': 'shut_the_box', 'label': 'Shut The Box', 'icon': Icons.casino_outlined, 'color': Color(0xFFE5A93C)},
    {'id': 'dots_and_boxes', 'label': 'Dots & Boxes', 'icon': Icons.grid_4x4, 'color': Color(0xFF4E89FF)},
    {'id': 'quoridor', 'label': 'Quoridor', 'icon': Icons.view_quilt_outlined, 'color': Color(0xFF9F7AEA)},
    {'id': 'pentago', 'label': 'Pentago', 'icon': Icons.rotate_right_outlined, 'color': Color(0xFF38B2AC)},
  ];

  static const Map<String, List<Map<String, String>>> _sectionMetadata = {
    'cricket': [
      {'id': 'super_over', 'title': 'Super Over Duel', 'desc': 'Tactical 6-ball death-over batting & bowling showdowns', 'icon': '⚡'},
      {'id': 'draft', 'title': 'Tactical Draft Clash', 'desc': 'Squad-building strategy & 5-over simulated tournament', 'icon': '📋'},
      {'id': 'stat_clash', 'title': 'Stats Clash Series', 'desc': 'Strategic head-to-head real career numbers quiz duel', 'icon': '⚔️'},
      {'id': 'challenges', 'title': 'Challenge Hub', 'desc': 'Career timeline sorting, Who Am I, & Stat or Fiction masteries', 'icon': '🏆'},
    ],
    'hangman': [
      {'id': 'classic', 'title': 'Classic Level Progression', 'desc': 'Story vocabulary journey with heart health regeneration', 'icon': '📜'},
      {'id': 'timed', 'title': 'Speed Rush Timed Mode', 'desc': 'Fast paced 60-second rapid word solving trials', 'icon': '⏱️'},
      {'id': 'daily', 'title': 'Daily Curated Challenge', 'desc': 'Synchronized global word puzzle challenge', 'icon': '📅'},
      {'id': 'category', 'title': 'Category Domain Arena', 'desc': 'Thematic taxonomy challenges across literature and science', 'icon': '🗂️'},
      {'id': 'infinite', 'title': 'Infinite Streak Trial', 'desc': 'Continuous consecutive word mastery endurance run', 'icon': '♾️'},
    ],
    'shut_the_box': [
      {'id': 'classic', 'title': 'Classic Table Match', 'desc': 'Traditional 12-tile dice rolling strategy', 'icon': '🎲'},
      {'id': 'solo', 'title': 'Solitaire Trial', 'desc': 'Solo high-efficiency shut box pursuit', 'icon': '🎯'},
      {'id': 'multiplayer', 'title': 'Online Multiplayer Duel', 'desc': 'Turn-based head-to-head tabletop pressure', 'icon': '🌐'},
    ],
    'dots_and_boxes': [
      {'id': 'grid_3x3', 'title': '3×3 Mini Grid', 'desc': 'Quick tactical line completion arena', 'icon': '🔹'},
      {'id': 'grid_4x4', 'title': '4×4 Standard Grid', 'desc': 'Classic double-cross and chain trapping field', 'icon': '🔶'},
      {'id': 'grid_5x5', 'title': '5×5 Grand Grid', 'desc': 'Grandmaster chain calculation board', 'icon': '🔷'},
      {'id': 'multiplayer', 'title': 'Online Multiplayer Grid', 'desc': 'Live synchronized box territory capture', 'icon': '🌐'},
    ],
    'quoridor': [
      {'id': 'classic', 'title': 'Classic Arena (9×9)', 'desc': 'Tactical pawn pathfinding & wooden wall barricades', 'icon': '🧱'},
      {'id': 'multiplayer', 'title': 'Online Corridor Battle', 'desc': 'Live multiplayer labyrinth interception', 'icon': '🌐'},
    ],
    'pentago': [
      {'id': 'classic', 'title': 'Classic Mind Twist (6×6)', 'desc': 'Place marble and rotate 3×3 quadrant to connect 5', 'icon': '⚪'},
      {'id': 'multiplayer', 'title': 'Online Quadrant Clash', 'desc': 'Live spatial alignment mental duel', 'icon': '🌐'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isLoggedIn || authState.userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("PLAYER PROFILE", style: GoogleFonts.dmSerifDisplay())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 56, color: Color(0xFFA9A396)),
                const SizedBox(height: 16),
                Text(
                  "Sign in to track your permanent statistics, records, and match logs across all PlayNed games.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF1EBDD)),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF1EBDD),
                    side: const BorderSide(color: Color(0xFFD5A84B)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () => context.push('/auth'),
                  icon: const Icon(Icons.login_outlined, size: 18),
                  label: Text("LOGIN / SIGN UP", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(profileFutureProvider(authState.userId!));
    final allStatsAsync = ref.watch(allGameStatsFutureProvider(authState.userId!));

    return Scaffold(
      backgroundColor: const Color(0xFF10100E),
      appBar: AppBar(
        title: Text("PLAYER RECORD & STATS", style: GoogleFonts.dmSerifDisplay()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: "Refresh Stats",
            onPressed: () {
              ref.invalidate(profileFutureProvider);
              ref.invalidate(allGameStatsFutureProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            tooltip: "Logout",
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD5A84B))),
        error: (err, stack) => Center(child: Text("Error loading profile: $err", style: const TextStyle(color: Color(0xFFB95745)))),
        data: (profile) {
          final username = profile['username'] ?? authState.username;
          final email = profile['email'] ?? authState.email;
          final hearts = profile['hearts_remaining'] ?? 5;
          final level = profile['classic_level'] ?? 1;
          final wordLifelines = profile['word_lifelines'] ?? 2;
          final hangmanModeStats = Map<String, dynamic>.from(profile['mode_stats'] ?? {});

          final allStatsData = allStatsAsync.value ?? {};
          final gamesMap = Map<String, dynamic>.from(allStatsData['games'] ?? {});
          final recentMatches = List<dynamic>.from(allStatsData['recent_matches'] ?? []);
          final totalGamesPlayed = allStatsData['total_games_played'] ?? 0;
          final totalGamesWon = allStatsData['total_games_won'] ?? 0;
          final overallWinRate = totalGamesPlayed > 0 ? ((totalGamesWon / totalGamesPlayed) * 100).toStringAsFixed(0) : "0";

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Player Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181816),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A26)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFD5A84B),
                                child: Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : "P",
                                  style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF10100E), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username.toUpperCase(),
                                      style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD)),
                                    ),
                                    Text(
                                      email,
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF242420),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF383832)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "$overallWinRate%",
                                      style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFD5A84B)),
                                    ),
                                    Text(
                                      "GLOBAL WIN RATE",
                                      style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF2A2A26)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniBadge("TOTAL MATCHES", "$totalGamesPlayed", Icons.sports_esports_outlined, const Color(0xFFF1EBDD)),
                              _buildMiniBadge("TOTAL VICTORIES", "$totalGamesWon", Icons.emoji_events_outlined, const Color(0xFF38A169)),
                              _buildMiniBadge("HANGMAN LVL", "$level", Icons.menu_book, const Color(0xFFD5A84B)),
                              _buildMiniBadge("HEARTS", "$hearts/5", Icons.favorite, const Color(0xFFB95745)),
                              _buildMiniBadge("LIFELINES", "$wordLifelines", Icons.flash_on, const Color(0xFFE5A93C)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Game Category Selector Chips
                    Text(
                      "SELECT GAME TO VIEW SECTION-BY-SECTION DATA",
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFFA9A396)),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _gameTabs.map((tab) {
                          final isSelected = _selectedGameFilter == tab['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              selected: isSelected,
                              showCheckmark: false,
                              avatar: Icon(
                                tab['icon'] as IconData,
                                size: 16,
                                color: isSelected ? const Color(0xFF10100E) : (tab['color'] as Color),
                              ),
                              label: Text(tab['label'] as String),
                              labelStyle: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF10100E) : const Color(0xFFF1EBDD),
                              ),
                              backgroundColor: const Color(0xFF181816),
                              selectedColor: tab['color'] as Color,
                              side: BorderSide(color: isSelected ? (tab['color'] as Color) : const Color(0xFF2A2A26)),
                              onSelected: (_) {
                                setState(() {
                                  _selectedGameFilter = tab['id'] as String;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Active Section Content
                    if (_selectedGameFilter == 'all')
                      _buildAllGamesSummary(gamesMap, hangmanModeStats)
                    else
                      _buildSpecificGameSections(_selectedGameFilter, gamesMap, hangmanModeStats),

                    const SizedBox(height: 32),

                    // Match History Timeline
                    if (recentMatches.isNotEmpty) ...[
                      Text(
                        "RECENT MATCH ACTIVITY LOG",
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFFA9A396)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181816),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2A2A26)),
                        ),
                        child: Column(
                          children: recentMatches.take(10).map((log) {
                            final gId = log['game_id']?.toString() ?? 'game';
                            final secId = log['section_id']?.toString() ?? 'section';
                            final outcome = log['outcome']?.toString().toLowerCase() ?? 'win';
                            final score = log['score'] ?? 0;
                            final opp = log['opponent_name']?.toString();
                            final playedAt = log['played_at']?.toString().split('T').first ?? '';

                            final isWin = outcome == 'win';
                            final isTie = outcome == 'tie' || outcome == 'draw';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141412),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF22221E)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isWin
                                          ? const Color(0xFF38A169).withOpacity(0.2)
                                          : (isTie ? const Color(0xFFE5A93C).withOpacity(0.2) : const Color(0xFFE53E3E).withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isWin ? const Color(0xFF38A169) : (isTie ? const Color(0xFFE5A93C) : const Color(0xFFE53E3E)),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      outcome.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isWin ? const Color(0xFF38A169) : (isTie ? const Color(0xFFE5A93C) : const Color(0xFFE53E3E)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${gId.toUpperCase().replaceAll('_', ' ')} · ${secId.replaceAll('_', ' ').toUpperCase()}",
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
                                        ),
                                        if (opp != null && opp.isNotEmpty)
                                          Text(
                                            "vs $opp",
                                            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFA9A396)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Score: $score",
                                        style: GoogleFonts.dmSerifDisplay(fontSize: 14, color: const Color(0xFFD5A84B)),
                                      ),
                                      Text(
                                        playedAt,
                                        style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF718096)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniBadge(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 8.5, color: const Color(0xFFA9A396), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAllGamesSummary(Map<String, dynamic> gamesMap, Map<String, dynamic> hangmanModeStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CROSS-PLATFORM GAME TILES",
          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFFA9A396)),
        ),
        const SizedBox(height: 12),
        ..._gameTabs.where((t) => t['id'] != 'all').map((tab) {
          final gid = tab['id'] as String;
          final gData = gamesMap[gid] as Map<String, dynamic>? ?? {};
          int played = gData['total_played'] ?? 0;
          int won = gData['total_won'] ?? 0;
          int lost = gData['total_lost'] ?? 0;

          if (gid == 'hangman' && played == 0) {
            for (final ms in hangmanModeStats.values) {
              if (ms is Map) {
                played += (ms['games_played'] as int? ?? 0);
                won += (ms['games_won'] as int? ?? 0);
                lost += (ms['games_lost'] as int? ?? 0);
              }
            }
          }

          final winRate = played > 0 ? ((won / played) * 100).toStringAsFixed(0) : "0";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF181816),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A26)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (tab['color'] as Color).withOpacity(0.2),
                  child: Icon(tab['icon'] as IconData, size: 20, color: tab['color'] as Color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tab['label'] as String,
                        style: GoogleFonts.dmSerifDisplay(fontSize: 17, color: const Color(0xFFF1EBDD)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$played matches · $won wins · $lost losses",
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFA9A396)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$winRate%",
                      style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: tab['color'] as Color),
                    ),
                    Text(
                      "WIN RATE",
                      style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396)),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFA9A396)),
                  onPressed: () {
                    setState(() {
                      _selectedGameFilter = gid;
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSpecificGameSections(String gameId, Map<String, dynamic> gamesMap, Map<String, dynamic> hangmanModeStats) {
    final gameMeta = _gameTabs.firstWhere((t) => t['id'] == gameId, orElse: () => _gameTabs[0]);
    final sections = _sectionMetadata[gameId] ?? [];
    final gData = gamesMap[gameId] as Map<String, dynamic>? ?? {};
    final sectionsMap = Map<String, dynamic>.from(gData['sections'] ?? {});

    int totalPlayed = gData['total_played'] ?? 0;
    int totalWon = gData['total_won'] ?? 0;
    int totalLost = gData['total_lost'] ?? 0;
    int totalTied = gData['total_tied'] ?? 0;
    int highScore = gData['high_score'] ?? 0;

    if (gameId == 'hangman' && totalPlayed == 0) {
      for (final ms in hangmanModeStats.values) {
        if (ms is Map) {
          totalPlayed += (ms['games_played'] as int? ?? 0);
          totalWon += (ms['games_won'] as int? ?? 0);
          totalLost += (ms['games_lost'] as int? ?? 0);
          final sc = ms['best_score'] as int? ?? 0;
          if (sc > highScore) highScore = sc;
        }
      }
    }

    final winRate = totalPlayed > 0 ? ((totalWon / totalPlayed) * 100).toStringAsFixed(0) : "0";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF161C18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (gameMeta['color'] as Color).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: (gameMeta['color'] as Color).withOpacity(0.2),
                child: Icon(gameMeta['icon'] as IconData, size: 22, color: gameMeta['color'] as Color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${gameMeta['label']} Career Record".toUpperCase(),
                      style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
                    ),
                    Text(
                      "Total Matches: $totalPlayed · Victories: $totalWon · Losses: $totalLost · Ties: $totalTied",
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$winRate%",
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: gameMeta['color'] as Color),
                  ),
                  Text(
                    "WIN RATE",
                    style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          "SECTIONS & GAME MODES BREAKDOWN",
          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFFA9A396)),
        ),
        const SizedBox(height: 12),

        // Section Cards
        ...sections.map((sec) {
          final secId = sec['id']!;
          final secData = sectionsMap[secId] as Map<String, dynamic>? ?? {};

          int played = secData['matches_played'] ?? 0;
          int won = secData['matches_won'] ?? 0;
          int lost = secData['matches_lost'] ?? 0;
          int tied = secData['matches_tied'] ?? 0;
          int secHighScore = secData['high_score'] ?? 0;
          int streak = secData['current_streak'] ?? 0;
          int bestStreak = secData['best_streak'] ?? 0;
          final extra = Map<String, dynamic>.from(secData['extra_data'] ?? {});

          // Fallback for Hangman legacy structure
          if (gameId == 'hangman' && played == 0 && hangmanModeStats.containsKey(secId)) {
            final ms = hangmanModeStats[secId] as Map<String, dynamic>? ?? {};
            played = ms['games_played'] ?? 0;
            won = ms['games_won'] ?? 0;
            lost = ms['games_lost'] ?? 0;
            secHighScore = ms['best_score'] ?? 0;
            streak = ms['current_streak'] ?? 0;
          }

          final secWinRate = played > 0 ? ((won / played) * 100).toStringAsFixed(0) : "0";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF181816),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A26)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(sec['icon'] ?? '🎮', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec['title']!,
                            style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD)),
                          ),
                          Text(
                            sec['desc']!,
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22221E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "$secWinRate% WIN",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD5A84B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF242420)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatMetric("PLAYED", "$played"),
                    _buildStatMetric("WON", "$won", color: const Color(0xFF38A169)),
                    _buildStatMetric("LOST", "$lost", color: const Color(0xFFE53E3E)),
                    _buildStatMetric("TIED", "$tied"),
                    _buildStatMetric("HIGH SCORE", "$secHighScore", color: const Color(0xFFD5A84B)),
                    _buildStatMetric("STREAK", "$streak (Best: $bestStreak)"),
                  ],
                ),
                if (extra.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141412),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: extra.entries.map((e) {
                        final keyClean = e.key.replaceAll('_', ' ').toUpperCase();
                        return Text(
                          "$keyClean: ${e.value}",
                          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF81E6D9)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatMetric(String label, String value, {Color color = const Color(0xFFF1EBDD)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFFA9A396), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
