import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/services/platform_api_service.dart';
import '../../data/cricket_dataset.dart';
import '../../domain/models/cricket_models.dart';

class StatChallengePreset {
  final String key;
  final String title;
  final String label;
  final int target;
  final String description;

  const StatChallengePreset({
    required this.key,
    required this.title,
    required this.label,
    required this.target,
    required this.description,
  });
}

const List<StatChallengePreset> statPresets = [
  StatChallengePreset(
    key: 'odi_runs',
    title: 'ODI Runs Milestone',
    label: 'ODI Runs',
    target: 38000,
    description: 'Select 5 players whose combined ODI Runs come closest to 38,000 without crossing it.',
  ),
  StatChallengePreset(
    key: 'test_runs',
    title: 'Test Run Summit',
    label: 'Test Runs',
    target: 42000,
    description: 'Select 5 players whose combined Test Runs come closest to 42,000 without crossing it.',
  ),
  StatChallengePreset(
    key: 'international_runs',
    title: 'International Run Mountain',
    label: 'International Runs',
    target: 70000,
    description: 'Select 5 players whose total International Runs across all formats come closest to 70,000 without crossing it.',
  ),
  StatChallengePreset(
    key: 't20i_runs',
    title: 'T20I Blitz Aggregate',
    label: 'T20I Runs',
    target: 9500,
    description: 'Select 5 players whose combined T20 International Runs come closest to 9,500 without crossing it.',
  ),
  StatChallengePreset(
    key: 'odi_wickets',
    title: 'ODI Wicket Harvest',
    label: 'ODI Wickets',
    target: 1100,
    description: 'Select 5 players whose combined ODI Wickets come closest to 1,100 without crossing it.',
  ),
  StatChallengePreset(
    key: 'test_wickets',
    title: 'Test Wicket Fortress',
    label: 'Test Wickets',
    target: 1600,
    description: 'Select 5 players whose combined Test Wickets come closest to 1,600 without crossing it.',
  ),
  StatChallengePreset(
    key: 'international_wickets',
    title: 'International Wicket Titans',
    label: 'International Wickets',
    target: 2400,
    description: 'Select 5 players whose combined International Wickets come closest to 2,400 without crossing it.',
  ),
  StatChallengePreset(
    key: 'international_centuries',
    title: 'International Century Vault',
    label: 'International 100s',
    target: 160,
    description: 'Select 5 players whose combined International 100s come closest to 160 without crossing it.',
  ),
  StatChallengePreset(
    key: 'odi_centuries',
    title: 'ODI Century Club',
    label: 'ODI Centuries',
    target: 90,
    description: 'Select 5 players whose combined ODI Centuries come closest to 90 without crossing it.',
  ),
  StatChallengePreset(
    key: 'test_centuries',
    title: 'Test Century Kings',
    label: 'Test Centuries',
    target: 100,
    description: 'Select 5 players whose combined Test Centuries come closest to 100 without crossing it.',
  ),
  StatChallengePreset(
    key: 'international_sixes',
    title: 'Maximum Sixes Engine',
    label: 'International Sixes',
    target: 800,
    description: 'Select 5 players whose combined International Sixes come closest to 800 without crossing it.',
  ),
  StatChallengePreset(
    key: 'international_catches',
    title: 'Safe Hands Outfield',
    label: 'International Catches',
    target: 850,
    description: 'Select 5 players whose combined International Catches come closest to 850 without crossing it.',
  ),
  StatChallengePreset(
    key: 'odi_fifties',
    title: 'ODI Half-Century Vault',
    label: 'ODI Fifties',
    target: 220,
    description: 'Select 5 players whose combined ODI Fifties come closest to 220 without crossing it.',
  ),
  StatChallengePreset(
    key: 'test_matches',
    title: 'Test Match Veterans',
    label: 'Test Matches',
    target: 500,
    description: 'Select 5 players whose combined Test Matches come closest to 500 without crossing it.',
  ),
  StatChallengePreset(
    key: 'odi_matches',
    title: 'ODI Match Marathon',
    label: 'ODI Matches',
    target: 1200,
    description: 'Select 5 players whose combined ODI Matches come closest to 1,200 without crossing it.',
  ),
  StatChallengePreset(
    key: 'test_five_wickets',
    title: 'Five-Wicket Haul Masters',
    label: 'Test 5-Wkt Hauls',
    target: 75,
    description: 'Select 5 players whose combined Test 5-Wicket Hauls come closest to 75 without crossing it.',
  ),
  StatChallengePreset(
    key: 'wk_dismissals',
    title: 'Wicketkeeper Gloves Citadel',
    label: 'WK Dismissals',
    target: 1200,
    description: 'Select 5 players whose combined Wicketkeeper Dismissals (catches + stumpings) come closest to 1,200 without crossing it.',
  ),
  StatChallengePreset(
    key: 'wk_stumpings',
    title: 'Lightning Stumpings Vault',
    label: 'WK Stumpings',
    target: 200,
    description: 'Select 5 players whose combined Wicketkeeping Stumpings come closest to 200 without crossing it.',
  ),
  StatChallengePreset(
    key: 'captaincy_wins',
    title: 'Victorious Captains',
    label: 'Captaincy Wins',
    target: 350,
    description: 'Select 5 players whose combined International Wins as Captain come closest to 350 without crossing it.',
  ),
  StatChallengePreset(
    key: 'captaincy_matches',
    title: 'Skipper Marathon',
    label: 'Captaincy Matches',
    target: 550,
    description: 'Select 5 players whose combined International Matches as Captain come closest to 550 without crossing it.',
  ),
  StatChallengePreset(
    key: 't20i_wickets',
    title: 'T20I Strike Force',
    label: 'T20I Wickets',
    target: 350,
    description: 'Select 5 players whose combined T20 International Wickets come closest to 350 without crossing it.',
  ),
];

class StatClashGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local' or 'online'
  final String? roomCode;
  final String? localPlayerId;

  const StatClashGamePage({
    super.key,
    required this.mode,
    this.roomCode,
    this.localPlayerId,
  });

  @override
  ConsumerState<StatClashGamePage> createState() => _StatClashGamePageState();
}

class _StatClashGamePageState extends ConsumerState<StatClashGamePage> {
  String _seriesMode = 'best_of_3'; // single, best_of_3, best_of_5
  int _currentRound = 1;
  int _maxRounds = 3;
  int _roundsToWin = 2;

  String _p1Name = 'Player 1';
  String _p2Name = 'Player 2';
  int _p1Score = 0;
  int _p2Score = 0;

  int _activeChallengeIdx = 0;
  String _status = 'drafting'; // drafting, round_resolved, finished
  String? _seriesWinner;
  bool _isSeriesTie = false;

  // Selected squads
  final List<String> _p1Squad = [];
  final List<String> _p2Squad = [];

  // Round resolution data
  int _p1Total = 0;
  int _p2Total = 0;
  bool _p1Busted = false;
  bool _p2Busted = false;
  String _roundSummary = '';

  String _filterRole = 'All';
  String _searchQuery = '';
  final Map<String, bool> _categoryExpanded = {
    'Batter': true,
    'Bowler': true,
    'All-Rounder': true,
    'Wicket-Keeper': true,
  };

  int _getResponsiveColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 960) return 5;
    if (w >= 600) return 4;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _p1Name = auth.username ?? "Player 1";
    _p2Name = "Player 2";
    _updateSeriesConfig();
  }

  void _updateSeriesConfig() {
    setState(() {
      if (_seriesMode == 'single') {
        _maxRounds = 1;
        _roundsToWin = 1;
      } else if (_seriesMode == 'best_of_5') {
        _maxRounds = 5;
        _roundsToWin = 3;
      } else {
        _maxRounds = 3;
        _roundsToWin = 2;
      }
    });
  }

  int _calculateSquadStat(List<String> squad, String statKey) {
    int total = 0;
    for (final id in squad) {
      final p = CricketDataset.getPlayerById(id);
      if (p != null) {
        total += p.getStatValue(statKey);
      }
    }
    return total;
  }

  void _resolveCurrentRound() {
    final challenge = statPresets[_activeChallengeIdx];
    final statKey = challenge.key;
    final target = challenge.target;

    _p1Total = _calculateSquadStat(_p1Squad, statKey);
    _p2Total = _calculateSquadStat(_p2Squad, statKey);

    _p1Busted = _p1Total > target;
    _p2Busted = _p2Total > target;

    final p1Diff = _p1Busted ? 999999 : (target - _p1Total);
    final p2Diff = _p2Busted ? 999999 : (target - _p2Total);

    if (_p1Busted && _p2Busted) {
      _roundSummary = "Both players busted by exceeding $target ${challenge.label}! Round is a Tie.";
    } else if (_p1Busted) {
      _p2Score += 1;
      _roundSummary = "$_p2Name wins Round $_currentRound! ($_p2Total vs $_p1Name's bust of $_p1Total).";
    } else if (_p2Busted) {
      _p1Score += 1;
      _roundSummary = "$_p1Name wins Round $_currentRound! ($_p1Total vs $_p2Name's bust of $_p2Total).";
    } else if (p1Diff < p2Diff) {
      _p1Score += 1;
      _roundSummary = "$_p1Name wins Round $_currentRound! ($_p1Total vs $_p2Total, closer by ${p2Diff - p1Diff} ${challenge.label}).";
    } else if (p2Diff < p1Diff) {
      _p2Score += 1;
      _roundSummary = "$_p2Name wins Round $_currentRound! ($_p2Total vs $_p1Total, closer by ${p1Diff - p2Diff} ${challenge.label}).";
    } else {
      _roundSummary = "Dead Heat! Both players scored exactly $_p1Total ${challenge.label}! Round is a Tie.";
    }

    // Check if series is over
    if (_p1Score >= _roundsToWin) {
      _status = 'finished';
      _seriesWinner = _p1Name;
      _recordStatClashResult();
    } else if (_p2Score >= _roundsToWin) {
      _status = 'finished';
      _seriesWinner = _p2Name;
      _recordStatClashResult();
    } else if (_currentRound >= _maxRounds) {
      _status = 'finished';
      if (_p1Score > _p2Score) {
        _seriesWinner = _p1Name;
      } else if (_p2Score > _p1Score) {
        _seriesWinner = _p2Name;
      } else {
        _isSeriesTie = true;
      }
      _recordStatClashResult();
    } else {
      _status = 'round_resolved';
    }

    setState(() {});
  }

  void _recordStatClashResult() {
    try {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.userId == null) return;

      String outcome = 'tie';
      if (_seriesWinner == _p1Name) {
        outcome = 'win';
      } else if (_seriesWinner != null && !_isSeriesTie) {
        outcome = 'loss';
      }

      ref.read(platformApiServiceProvider).recordGameResult(
        userId: auth.userId!,
        gameId: 'cricket',
        sectionId: 'stat_clash',
        outcome: outcome,
        score: _p1Score,
        opponentName: _p2Name,
        details: {
          'p1_rounds_won': _p1Score,
          'p2_rounds_won': _p2Score,
          'total_rounds': _currentRound,
        },
        extraStatsUpdate: {
          'stat_clash_wins': outcome == 'win' ? 1 : 0,
          'rounds_won': _p1Score,
        },
      );
    } catch (_) {}
  }

  void _nextRound() {
    setState(() {
      _currentRound += 1;
      _activeChallengeIdx = (_activeChallengeIdx + 1) % statPresets.length;
      _p1Squad.clear();
      _p2Squad.clear();
      _status = 'drafting';
      _roundSummary = '';
    });
  }

  void _resetSeries() {
    setState(() {
      _currentRound = 1;
      _p1Score = 0;
      _p2Score = 0;
      _p1Squad.clear();
      _p2Squad.clear();
      _status = 'drafting';
      _seriesWinner = null;
      _isSeriesTie = false;
      _roundSummary = '';
      _activeChallengeIdx = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final challenge = statPresets[_activeChallengeIdx];

    return Scaffold(
      backgroundColor: const Color(0xFF0C1626),
      appBar: AppBar(
        backgroundColor: const Color(0xFF112238),
        title: Text(
          "STAT CLASH",
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFF1EBDD)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF1EBDD)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Series Header & Scoreboard
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF152A47), Color(0xFF0F1E33)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2B5282), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "ROUND $_currentRound / $_maxRounds (${_seriesMode.replaceAll('_', ' ').toUpperCase()})",
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF63B3ED)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A365D),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$_p1Name $_p1Score — $_p2Score $_p2Name",
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Challenge Banner
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3182CE).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.track_changes, color: Color(0xFF63B3ED), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    challenge.title,
                                    style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
                                  ),
                                  Text(
                                    challenge.description,
                                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFA0AEC0)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (_status == 'finished') ...[
                    // Series Winner Card
                    _buildSeriesWinnerCard(),
                  ] else if (_status == 'round_resolved') ...[
                    // Round Summary Card
                    _buildRoundSummaryCard(challenge),
                  ] else ...[
                    // Drafting UI
                    _buildDraftingUI(challenge),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftingUI(StatChallengePreset challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Squad Selection Trackers (Stats Hidden to test player knowledge!)
        Row(
          children: [
            Expanded(
              child: _buildSquadGauge(
                playerName: _p1Name,
                squad: _p1Squad,
                color: const Color(0xFF3182CE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSquadGauge(
                playerName: _p2Name,
                squad: _p2Squad,
                color: const Color(0xFFED8936),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Search & Role Filter Tabs
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF112035),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF233B5D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD)),
                decoration: InputDecoration(
                  hintText: "Search by player name, country (e.g. India, Australia), or role...",
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF63B3ED)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Color(0xFF718096)),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF0D1B2D),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3182CE))),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRoleFilterChip('All', '🌟 All (${CricketDataset.allPlayers.length})'),
                    const SizedBox(width: 6),
                    _buildRoleFilterChip('Batter', '🏏 Batters (${CricketDataset.getPureBatters().length})'),
                    const SizedBox(width: 6),
                    _buildRoleFilterChip('Bowler', '🎯 Bowlers (${CricketDataset.getPureBowlers().length})'),
                    const SizedBox(width: 6),
                    _buildRoleFilterChip('All-Rounder', '🛡️ All-Rounders (${CricketDataset.getAllRounders().length})'),
                    const SizedBox(width: 6),
                    _buildRoleFilterChip('Wicket-Keeper', '🧤 Wicket-Keepers (${CricketDataset.getWicketKeepers().length})'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SELECT 5 PLAYERS PER SQUAD (STATS CONCEALED)",
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: const Color(0xFF63B3ED)),
            ),
            Text(
              "Target: ${challenge.label} ≤ ${challenge.target}",
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA0AEC0)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_filterRole == 'All' || _filterRole == 'Batter')
          _buildPlayerCategorySection(
            roleKey: 'Batter',
            roleEmoji: '🏏',
            roleTitle: 'Batters',
            players: _getCategoryPlayers('Batter'),
          ),

        if (_filterRole == 'All' || _filterRole == 'Bowler')
          _buildPlayerCategorySection(
            roleKey: 'Bowler',
            roleEmoji: '🎯',
            roleTitle: 'Bowlers',
            players: _getCategoryPlayers('Bowler'),
          ),

        if (_filterRole == 'All' || _filterRole == 'All-Rounder')
          _buildPlayerCategorySection(
            roleKey: 'All-Rounder',
            roleEmoji: '🛡️',
            roleTitle: 'All-Rounders',
            players: _getCategoryPlayers('All-Rounder'),
          ),

        if (_filterRole == 'All' || _filterRole == 'Wicket-Keeper')
          _buildPlayerCategorySection(
            roleKey: 'Wicket-Keeper',
            roleEmoji: '🧤',
            roleTitle: 'Wicket-Keepers',
            players: _getCategoryPlayers('Wicket-Keeper'),
          ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_p1Squad.length == 5 && _p2Squad.length == 5) ? _resolveCurrentRound : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3182CE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              (_p1Squad.length == 5 && _p2Squad.length == 5)
                  ? "SUBMIT SQUADS & REVEAL ROUND SHOWDOWN"
                  : "SELECT 5 PLAYERS FOR BOTH P1 & P2 (${_p1Squad.length}/5, ${_p2Squad.length}/5)",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSquadGauge({
    required String playerName,
    required List<String> squad,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF112035),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(playerName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("${squad.length} / 5 Picked", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (idx) {
              final isFilled = idx < squad.length;
              final player = isFilled ? CricketDataset.getPlayerById(squad[idx]) : null;

              return Expanded(
                child: Container(
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isFilled ? color.withOpacity(0.3) : const Color(0xFF1E3A5F).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isFilled ? color : const Color(0xFF2B5282)),
                  ),
                  child: Center(
                    child: isFilled
                        ? Text(
                            player?.name.split(' ').last ?? "✓",
                            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            "${idx + 1}",
                            style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF718096)),
                          ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundSummaryCard(StatChallengePreset challenge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF132338),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3182CE)),
      ),
      child: Column(
        children: [
          Text("ROUND $_currentRound SHOWDOWN", style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD))),
          const SizedBox(height: 4),
          Text("Target: ${challenge.label} ≤ ${challenge.target}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14243B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2B5282)),
            ),
            child: Text(_roundSummary, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF63B3ED))),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPlayerShowdownBreakdown(
                  playerName: _p1Name,
                  squad: _p1Squad,
                  statKey: challenge.key,
                  total: _p1Total,
                  target: challenge.target,
                  isBusted: _p1Busted,
                  color: const Color(0xFF3182CE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlayerShowdownBreakdown(
                  playerName: _p2Name,
                  squad: _p2Squad,
                  statKey: challenge.key,
                  total: _p2Total,
                  target: challenge.target,
                  isBusted: _p2Busted,
                  color: const Color(0xFFED8936),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182CE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("PROCEED TO NEXT ROUND", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerShowdownBreakdown({
    required String playerName,
    required List<String> squad,
    required String statKey,
    required int total,
    required int target,
    required bool isBusted,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E33),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(playerName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
              Text(
                "$total",
                style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: isBusted ? const Color(0xFFE53E3E) : color),
              ),
            ],
          ),
          Text(
            isBusted ? "BUSTED (Exceeded $target by ${total - target})" : "Distance to target: ${target - total}",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isBusted ? const Color(0xFFE53E3E) : const Color(0xFF68D391),
            ),
          ),
          const Divider(color: Color(0xFF1E3A5F), height: 16),
          ...squad.map((id) {
            final p = CricketDataset.getPlayerById(id);
            final val = p?.getStatValue(statKey) ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p?.name ?? id,
                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFCBD5E0)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "$val",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF63B3ED)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSeriesWinnerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF132338),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            _isSeriesTie ? "SERIES DRAW!" : "$_seriesWinner WINS THE STAT CLASH!",
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFFE5A93C)),
          ),
          const SizedBox(height: 10),
          Text(
            "Final Score: $_p1Name $_p1Score — $_p2Score $_p2Name",
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _resetSeries,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3182CE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("PLAY AGAIN", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF1EBDD),
                    side: const BorderSide(color: Color(0xFF2B5282)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("RETURN TO HUB"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<CricketPlayer> _getCategoryPlayers(String role) {
    return CricketDataset.allPlayers.where((p) {
      if (p.role != role) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(query) ||
            p.country.toLowerCase().contains(query) ||
            p.role.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  Widget _buildPlayerCategorySection({
    required String roleKey,
    required String roleEmoji,
    required String roleTitle,
    required List<CricketPlayer> players,
  }) {
    final isExpanded = _categoryExpanded[roleKey] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF112035),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF233B5D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _categoryExpanded[roleKey] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(roleEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        "$roleTitle (${players.length})",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF1EBDD),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF63B3ED),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && players.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFF1E3A5F)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getResponsiveColumns(context),
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: players.length,
                itemBuilder: (ctx, idx) {
                  final p = players[idx];
                  final inP1 = _p1Squad.contains(p.id);
                  final inP2 = _p2Squad.contains(p.id);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (inP1) {
                          _p1Squad.remove(p.id);
                        } else if (inP2) {
                          _p2Squad.remove(p.id);
                        } else {
                          if (_p1Squad.length < 5) {
                            _p1Squad.add(p.id);
                          } else if (_p2Squad.length < 5) {
                            _p2Squad.add(p.id);
                          }
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: inP1
                            ? const Color(0xFF2B6CB0).withOpacity(0.3)
                            : inP2
                                ? const Color(0xFFC05621).withOpacity(0.3)
                                : const Color(0xFF0D1B2D),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: inP1
                              ? const Color(0xFF3182CE)
                              : inP2
                                  ? const Color(0xFFED8936)
                                  : const Color(0xFF1E3A5F),
                          width: (inP1 || inP2) ? 1.4 : 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: (inP1 || inP2) ? FontWeight.bold : FontWeight.w500,
                                color: inP1
                                    ? const Color(0xFF63B3ED)
                                    : inP2
                                        ? const Color(0xFFF6AD55)
                                        : const Color(0xFFE2E8F0),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: inP1
                                  ? const Color(0xFF3182CE)
                                  : inP2
                                      ? const Color(0xFFED8936)
                                      : p.avatarColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String role, String label) {
    final isSelected = _filterRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF3182CE),
      backgroundColor: const Color(0xFF0F1E33),
      labelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFFA0AEC0),
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF63B3ED) : const Color(0xFF1E3A5F),
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _filterRole = role);
        }
      },
    );
  }

  List<CricketPlayer> _getFilteredPlayers() {
    var list = CricketDataset.allPlayers.where((p) {
      if (_filterRole != 'All' && p.role != _filterRole) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(query);
        final matchCountry = p.country.toLowerCase().contains(query);
        final matchRole = p.role.toLowerCase().contains(query);
        if (!matchName && !matchCountry && !matchRole) return false;
      }
      return true;
    }).toList();

    if (_filterRole == 'All') {
      // Group logically: Batters, All-Rounders, Wicket-Keepers, Bowlers
      const rolePriority = {'Batter': 0, 'All-Rounder': 1, 'Wicket-Keeper': 2, 'Bowler': 3};
      list.sort((a, b) {
        final rA = rolePriority[a.role] ?? 99;
        final rB = rolePriority[b.role] ?? 99;
        if (rA != rB) return rA.compareTo(rB);
        return b.battingRating.compareTo(a.battingRating);
      });
    }
    return list;
  }
}

