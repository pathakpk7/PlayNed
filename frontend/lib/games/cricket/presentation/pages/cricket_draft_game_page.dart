import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/cricket_dataset.dart';
import '../../domain/models/cricket_models.dart';
import '../widgets/chit_bowl_widget.dart';

class SquadSlotDef {
  final String key;
  final String title;
  final String icon;
  final IconData iconData;
  final Color color;
  final String description;
  final List<String> recommendedRoles;

  const SquadSlotDef({
    required this.key,
    required this.title,
    required this.icon,
    required this.iconData,
    required this.color,
    required this.description,
    required this.recommendedRoles,
  });
}

const List<SquadSlotDef> squadSlotDefs = [
  SquadSlotDef(
    key: 'opening_batter',
    title: 'Opening Batter',
    icon: '🏏',
    iconData: Icons.sports_cricket,
    color: Color(0xFF48BB78),
    description: 'Anchor the innings & face the new ball in Powerplay.',
    recommendedRoles: ['Batter', 'All-Rounder', 'Wicket-Keeper'],
  ),
  SquadSlotDef(
    key: 'finisher',
    title: 'Finisher',
    icon: '⚡',
    iconData: Icons.local_fire_department,
    color: Color(0xFFED8936),
    description: 'High strike-rate death overs hitter & game closer.',
    recommendedRoles: ['Batter', 'All-Rounder', 'Wicket-Keeper'],
  ),
  SquadSlotDef(
    key: 'all_rounder',
    title: 'All-Rounder',
    icon: '🛡️',
    iconData: Icons.shield,
    color: Color(0xFF3182CE),
    description: 'Dual-threat impact in middle order batting & bowling.',
    recommendedRoles: ['All-Rounder', 'Batter', 'Bowler'],
  ),
  SquadSlotDef(
    key: 'wicket_keeper',
    title: 'Wicket-Keeper',
    icon: '🧤',
    iconData: Icons.pan_tool,
    color: Color(0xFFECC94B),
    description: 'Master of glovework behind the stumps & key batter.',
    recommendedRoles: ['Wicket-Keeper', 'Batter', 'All-Rounder'],
  ),
  SquadSlotDef(
    key: 'bowler',
    title: 'Bowler',
    icon: '🎯',
    iconData: Icons.adjust,
    color: Color(0xFF9F7AEA),
    description: 'Strike specialist to deliver opening & death overs.',
    recommendedRoles: ['Bowler', 'All-Rounder'],
  ),
];

class CricketDraftGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local' or 'online'
  final String? roomCode;
  final String? localPlayerId;

  const CricketDraftGamePage({
    super.key,
    this.mode = 'local',
    this.roomCode,
    this.localPlayerId,
  });

  @override
  ConsumerState<CricketDraftGamePage> createState() => _CricketDraftGamePageState();
}

class _CricketDraftGamePageState extends ConsumerState<CricketDraftGamePage> {
  String _p1Name = 'Player 1';
  String _p2Name = 'Player 2';
  final String _p1Id = 'p1';
  final String _p2Id = 'p2';

  // Draft State
  String _status = 'drafting'; // drafting, draft_complete, match_simulated
  final List<String> _draftOrder = ['p1', 'p2', 'p2', 'p1', 'p1', 'p2', 'p2', 'p1', 'p1', 'p2'];
  int _currentPickIdx = 0;

  final Map<String, List<String>> _drafted = {'p1': [], 'p2': []};
  final Map<String, Map<String, String?>> _squadSlots = {
    'p1': {for (final s in squadSlotDefs) s.key: null},
    'p2': {for (final s in squadSlotDefs) s.key: null},
  };
  final Map<String, int> _budget = {'p1': 100, 'p2': 100};

  String _filterRole = 'All';
  String _searchQuery = '';
  String _lastActionMsg = "Draft started! Budget: 100 credits. Pick players and assign them into 5 squad tactical sections.";

  // Post Draft Simulation Data
  Map<String, dynamic>? _simulatedMatch;
  String? _winnerName;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _p1Name = auth.username ?? "Player 1";
    _p2Name = "Player 2";
  }

  String get _currentTurnPid => _currentPickIdx < _draftOrder.length ? _draftOrder[_currentPickIdx] : 'p1';
  String get _currentTurnName => _currentTurnPid == _p1Id ? _p1Name : _p2Name;

  List<String> _getEmptySlotKeys(String pid) {
    final slots = _squadSlots[pid]!;
    return squadSlotDefs.where((s) => slots[s.key] == null).map((s) => s.key).toList();
  }

  bool _canDraft(String pid, CricketPlayer p) {
    if (_budget[pid]! < p.draftCost) return false;
    if (_getEmptySlotKeys(pid).isEmpty) return false;
    return true;
  }

  Future<void> _promptSlotAssignmentAndDraft(CricketPlayer player) async {
    final pid = _currentTurnPid;
    final pname = _currentTurnName;
    final currentSlots = _squadSlots[pid]!;

    final selectedSlotKey = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1C15),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: player.avatarColor,
                      child: Text(
                        player.name[0],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
                          ),
                          Text(
                            "${player.country} • ${player.role} • Cost: ${player.draftCost} pts • Rating: ${player.battingRating}/${player.bowlingRating}",
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF81E6D9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "ASSIGN SQUAD SECTION FOR $pname",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFFE5A93C), letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  "Choose which section to place ${player.name} in your 5-player lineup:",
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
                ),
                const SizedBox(height: 14),
                ...squadSlotDefs.map((slotDef) {
                  final occupiedPid = currentSlots[slotDef.key];
                  final isOccupied = occupiedPid != null;
                  final occupiedPlayer = isOccupied ? CricketDataset.getPlayerById(occupiedPid) : null;
                  final isRecommended = slotDef.recommendedRoles.contains(player.role);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isOccupied ? const Color(0xFF15221B).withOpacity(0.6) : const Color(0xFF132B20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOccupied
                            ? const Color(0xFF20362B)
                            : (isRecommended ? const Color(0xFFE5A93C) : const Color(0xFF28543A)),
                        width: isRecommended && !isOccupied ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: slotDef.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(slotDef.icon, style: const TextStyle(fontSize: 18)),
                      ),
                      title: Row(
                        children: [
                          Text(
                            slotDef.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isOccupied ? const Color(0xFF718096) : const Color(0xFFF1EBDD),
                            ),
                          ),
                          if (isRecommended && !isOccupied) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A93C).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFE5A93C), width: 0.8),
                              ),
                              child: Text(
                                "FIT",
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        isOccupied
                            ? "Occupied: ${occupiedPlayer?.name ?? 'Player'}"
                            : slotDef.description,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isOccupied ? const Color(0xFFE53E3E) : const Color(0xFFA9A396),
                        ),
                      ),
                      trailing: isOccupied
                          ? const Icon(Icons.lock, size: 16, color: Color(0xFF718096))
                          : ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(slotDef.key),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: slotDef.color,
                                foregroundColor: const Color(0xFF0C1914),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text("ASSIGN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                      onTap: isOccupied ? null : () => Navigator.of(ctx).pop(slotDef.key),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSlotKey != null) {
      _assignPlayerToSlot(player, selectedSlotKey);
    }
  }

  void _assignPlayerToSlot(CricketPlayer player, String slotKey) {
    final pid = _currentTurnPid;
    final pname = _currentTurnName;
    final slotDef = squadSlotDefs.firstWhere((s) => s.key == slotKey);

    setState(() {
      _squadSlots[pid]![slotKey] = player.id;
      _drafted[pid]!.add(player.id);
      _budget[pid] = _budget[pid]! - player.draftCost;
      _currentPickIdx += 1;

      if (_currentPickIdx >= _draftOrder.length) {
        _status = 'draft_complete';
        _lastActionMsg = "Draft Completed! Both squads fully assembled into 5 tactical sections. You can now Simulate the 5-Over Clash!";
      } else {
        _lastActionMsg = "$pname assigned ${player.name} as ${slotDef.title} (${player.draftCost} pts). $_currentTurnName is now on the clock!";
      }
    });
  }

  void _simulate5OverClash() {
    final p1Slots = _squadSlots[_p1Id]!;
    final p2Slots = _squadSlots[_p2Id]!;

    // Innings 1: P1 Bats vs P2 Bowls
    final in1 = _simulateTacticalInnings(p1Slots, p2Slots, target: null);
    // Innings 2: P2 Chases vs P1 Bowls
    final in2 = _simulateTacticalInnings(p2Slots, p1Slots, target: in1['runs'] + 1);

    String summary = '';
    String? winName;

    if (in2['runs'] > in1['runs']) {
      winName = _p2Name;
      summary = "$_p2Name won by ${5 - (in2['wickets'] as int)} wickets! (Chased down ${in1['runs'] + 1} in ${in2['balls']} balls).";
    } else if (in2['runs'] < in1['runs']) {
      winName = _p1Name;
      summary = "$_p1Name won by ${(in1['runs'] as int) - (in2['runs'] as int)} runs! (Defended ${in1['runs']}).";
    } else {
      winName = "Draw";
      summary = "Match TIED! Both teams scored ${in1['runs']} runs in the 5-over draft clash!";
    }

    setState(() {
      _simulatedMatch = {
        'in1': in1,
        'in2': in2,
        'summary': summary,
      };
      _winnerName = winName;
      _status = 'match_simulated';
      _lastActionMsg = summary;
    });
  }

  Map<String, dynamic> _simulateTacticalInnings(
    Map<String, String?> battingSlots,
    Map<String, String?> bowlingSlots, {
    int? target,
  }) {
    final opener = CricketDataset.getPlayerById(battingSlots['opening_batter'] ?? '') ?? CricketDataset.allPlayers[0];
    final finisher = CricketDataset.getPlayerById(battingSlots['finisher'] ?? '') ?? CricketDataset.allPlayers[1];
    final allRounderBat = CricketDataset.getPlayerById(battingSlots['all_rounder'] ?? '') ?? CricketDataset.allPlayers[2];
    final wk = CricketDataset.getPlayerById(battingSlots['wicket_keeper'] ?? '') ?? CricketDataset.allPlayers[3];
    final bowlerBat = CricketDataset.getPlayerById(battingSlots['bowler'] ?? '') ?? CricketDataset.allPlayers[4];

    final mainBowler = CricketDataset.getPlayerById(bowlingSlots['bowler'] ?? '') ?? CricketDataset.allPlayers[4];
    final arBowler = CricketDataset.getPlayerById(bowlingSlots['all_rounder'] ?? '') ?? CricketDataset.allPlayers[2];

    final battingOrder = [opener, wk, allRounderBat, finisher, bowlerBat];

    int runs = 0;
    int wickets = 0;
    int balls = 0;
    final List<String> highlights = [];
    final random = Random();

    int currentBatterIdx = 0;

    for (int ball = 1; ball <= 30; ball++) {
      balls += 1;
      final overNum = (ball - 1) ~/ 6 + 1;
      final ballInOver = (ball - 1) % 6 + 1;

      // Bowler: Overs 1, 3, 5 by main Bowler, Overs 2, 4 by All-Rounder
      final activeBowler = (overNum % 2 == 1) ? mainBowler : arBowler;
      final activeBatter = battingOrder[currentBatterIdx % battingOrder.length];

      // Finisher bonus in death overs (Over 4 & 5)
      final isDeathOver = overNum >= 4;
      final isFinisherAtCrease = activeBatter.id == finisher.id;
      int powerBonus = (isDeathOver && isFinisherAtCrease) ? 15 : 0;

      final chance = random.nextInt(100) + (activeBatter.battingRating - activeBowler.bowlingRating) ~/ 3 + powerBonus;

      if (chance < 12) {
        wickets += 1;
        highlights.add("Over $overNum.$ballInOver: WICKET! ${activeBowler.name} dismisses ${activeBatter.name}!");
        currentBatterIdx += 1;
        if (wickets >= 5) break;
      } else if (chance > 86) {
        runs += 6;
        highlights.add("Over $overNum.$ballInOver: SIX! ${activeBatter.name} launches ${activeBowler.name} into the stands!");
      } else if (chance > 68) {
        runs += 4;
        highlights.add("Over $overNum.$ballInOver: FOUR! Glorious boundary by ${activeBatter.name} off ${activeBowler.name}.");
      } else if (chance > 35) {
        runs += random.nextBool() ? 1 : 2;
      }

      if (target != null && runs >= target) break;
    }

    return {
      'runs': runs,
      'wickets': wickets,
      'balls': balls,
      'overs': "${balls ~/ 6}.${balls % 6}",
      'highlights': highlights,
    };
  }

  void _showPlayerStatsModal(CricketPlayer p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: p.avatarColor,
                        child: Text(p.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD))),
                            Text("${p.country} • ${p.role}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396))),
                            Text("Span: ${p.careerSpan} • Draft Cost: ${p.draftCost} pts", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF81E6D9), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("TACTICAL RATINGS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildRatingTile("Batting", p.battingRating, const Color(0xFF38A169)),
                      const SizedBox(width: 10),
                      _buildRatingTile("Bowling", p.bowlingRating, const Color(0xFF3182CE)),
                      const SizedBox(width: 10),
                      _buildRatingTile("Power", p.power, const Color(0xFFDD6B20)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("INTERNATIONAL CAREER RECORD", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatBox("Int'l Runs", "${p.internationalRuns}", "${p.internationalCenturies} Centuries"),
                      const SizedBox(width: 10),
                      _buildStatBox("Int'l Wickets", "${p.internationalWickets}", "${p.testFiveWickets} 5-Wkt Hauls"),
                      const SizedBox(width: 10),
                      _buildStatBox("Int'l Sixes", "${p.internationalSixes}", "${p.internationalCatches} Catches"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("MULTI-FORMAT BREAKDOWN", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C))),
                  const SizedBox(height: 10),
                  _buildFormatTable(p),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRatingTile(String label, int val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(color: const Color(0xFF132B20), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF28543A))),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396))),
            const SizedBox(height: 4),
            Text("$val", style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: col)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(color: const Color(0xFF132B20), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF28543A))),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396))),
            const SizedBox(height: 4),
            Text(val, style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFFF1EBDD))),
            Text(sub, style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFFA9A396))),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatTable(CricketPlayer p) {
    return Table(
      border: TableBorder.all(color: const Color(0xFF234432)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF173326)),
          children: [
            _tableCell("Format", isHeader: true),
            _tableCell("Matches", isHeader: true),
            _tableCell("Runs (Avg)", isHeader: true),
            _tableCell("Wkts (Econ)", isHeader: true),
            _tableCell("100s / 5Ws", isHeader: true),
          ],
        ),
        TableRow(
          children: [
            _tableCell("Test"),
            _tableCell("${p.testMatches}"),
            _tableCell("${p.testRuns} (${p.testAverage})"),
            _tableCell("${p.testWickets}"),
            _tableCell("${p.testCenturies} / ${p.testFiveWickets}"),
          ],
        ),
        TableRow(
          children: [
            _tableCell("ODI"),
            _tableCell("${p.odiMatches}"),
            _tableCell("${p.odiRuns} (${p.odiAverage})"),
            _tableCell("${p.odiWickets} (${p.odiEconomy})"),
            _tableCell("${p.odiCenturies} / 0"),
          ],
        ),
        TableRow(
          children: [
            _tableCell("T20I"),
            _tableCell("${p.t20iMatches}"),
            _tableCell("${p.t20iRuns} (SR ${p.t20iStrikeRate})"),
            _tableCell("${p.t20iWickets} (${p.t20iEconomy})"),
            _tableCell("-"),
          ],
        ),
      ],
    );
  }

  Widget _tableCell(String txt, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        txt,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? const Color(0xFFE5A93C) : const Color(0xFFF1EBDD),
        ),
      ),
    );
  }

  void _resetDraft() {
    setState(() {
      _squadSlots[_p1Id] = {for (final s in squadSlotDefs) s.key: null};
      _squadSlots[_p2Id] = {for (final s in squadSlotDefs) s.key: null};
      _drafted[_p1Id]!.clear();
      _drafted[_p2Id]!.clear();
      _budget[_p1Id] = 100;
      _budget[_p2Id] = 100;
      _currentPickIdx = 0;
      _status = 'drafting';
      _simulatedMatch = null;
      _winnerName = null;
      _lastActionMsg = "Draft restarted! Budget: 100 credits. Pick players and assign them into 5 squad tactical sections.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09140E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F241A),
        title: Text("CRICKET DRAFT", style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFF1EBDD))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF1EBDD)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Budget & Turn Header
                  _buildBudgetHeader(),
                  const SizedBox(height: 16),

                  // Live Squad Trackers
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSquadTracker(_p1Id, _p1Name, const Color(0xFF3182CE))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSquadTracker(_p2Id, _p2Name, const Color(0xFFED8936))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Last action ticker
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0F2117), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF234432))),
                    child: Text(_lastActionMsg, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE2DDD1))),
                  ),
                  const SizedBox(height: 18),

                  if (_status == 'drafting') ...[
                    _buildDraftBoard(),
                  ] else ...[
                    _buildPostDraftView(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF162E20), Color(0xFF0D1C14)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C593E), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("BUDGET CAP: 100 CREDITS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C))),
              const SizedBox(height: 4),
              Text(
                _status == 'drafting' ? "ON THE CLOCK: $_currentTurnName (Pick ${_currentPickIdx + 1}/10)" : "DRAFT COMPLETED",
                style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF1D3B2B), borderRadius: BorderRadius.circular(8)),
            child: Text("5 Tactical Sections", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF81E6D9), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadTracker(String pid, String pname, Color col) {
    final slots = _squadSlots[pid]!;
    final budgetLeft = _budget[pid]!;
    final filledCount = slots.values.where((v) => v != null).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pname, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
              Text("Budget: $budgetLeft", style: GoogleFonts.dmSerifDisplay(fontSize: 14, color: budgetLeft < 20 ? const Color(0xFFE53E3E) : const Color(0xFFE5A93C))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Squad Lineup ($filledCount/5):",
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
          ),
          const SizedBox(height: 6),
          ...squadSlotDefs.map((slotDef) {
            final pidInSlot = slots[slotDef.key];
            final p = pidInSlot != null ? CricketDataset.getPlayerById(pidInSlot) : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: p != null ? const Color(0xFF14291F) : const Color(0xFF0D1B13),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: p != null ? slotDef.color.withOpacity(0.4) : const Color(0xFF1C3628),
                ),
              ),
              child: Row(
                children: [
                  Text(slotDef.icon, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p != null ? "${slotDef.title}: ${p.name}" : "${slotDef.title}: [ Empty ]",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: p != null ? FontWeight.w600 : FontWeight.normal,
                        color: p != null ? const Color(0xFFF1EBDD) : const Color(0xFF5A6A60),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p != null)
                    Text("${p.draftCost} pts", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: slotDef.color)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDraftBoard() {
    final allDrafted = _drafted[_p1Id]! + _drafted[_p2Id]!;
    final available = CricketDataset.allPlayers.where((p) {
      if (allDrafted.contains(p.id)) return false;
      if (_filterRole != 'All' && p.role != _filterRole) return false;
      if (_searchQuery.isNotEmpty && !p.name.toLowerCase().contains(_searchQuery)) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lucky Dip Chit Bowl Banner Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD5A84B),
              foregroundColor: const Color(0xFF1E1710),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            onPressed: () async {
              final eligible = available.where((p) => _canDraft(_currentTurnPid, p)).toList();
              if (eligible.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No eligible players found within budget and squad constraints.")),
                );
                return;
              }
              final picked = await ChitBowlDialog.show(
                context,
                title: "$_currentTurnName's Auction Lucky Dip",
                subtitle: "Draw a folded player chit from the antique brass bowl! (${eligible.length} eligible chits)",
                eligiblePlayers: eligible,
              );
              if (picked != null) {
                await _promptSlotAssignmentAndDraft(picked);
              }
            },
            icon: const Icon(Icons.casino, size: 20, color: Color(0xFF1E1710)),
            label: Text(
              "DRAW PICK FROM CHIT BOWL 📜 (LUCKY DIP)",
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
            ),
          ),
        ),

        // Search & Role Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD)),
                decoration: InputDecoration(
                  hintText: "Search legend...",
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF718096)),
                  filled: true,
                  fillColor: const Color(0xFF13241B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _filterRole,
              dropdownColor: const Color(0xFF13241B),
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD)),
              items: ['All', 'Batter', 'All-Rounder', 'Bowler', 'Wicket-Keeper']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => setState(() => _filterRole = val ?? 'All'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Text("OR SELECT MANUALLY FROM ROSTER (${available.length})", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78))),
        const SizedBox(height: 10),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: available.length,
          itemBuilder: (ctx, idx) {
            final p = available[idx];
            final canPick = _canDraft(_currentTurnPid, p);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF102117),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF234432)),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: p.avatarColor, child: Text(p.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                        Text("${p.country} • ${p.role} • Rating ${p.battingRating}/${p.bowlingRating}", style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFA9A396))),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showPlayerStatsModal(p),
                    icon: const Icon(Icons.analytics_outlined, size: 14, color: Color(0xFF81E6D9)),
                    label: const Text("STATS", style: TextStyle(fontSize: 10, color: Color(0xFF81E6D9))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: canPick ? () => _promptSlotAssignmentAndDraft(p) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5A93C),
                      foregroundColor: const Color(0xFF0F1E16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text("${p.draftCost} pts", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPostDraftView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF13281E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF48BB78), width: 1.5),
          ),
          child: Column(
            children: [
              Text("SQUADS ASSEMBLED!", style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFE5A93C))),
              const SizedBox(height: 8),
              Text("Both teams have assigned their 5 legends into their tactical sections within the 100 budget.", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396))),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _simulate5OverClash,
                      icon: const Icon(Icons.sports_cricket, size: 18),
                      label: const Text("SIMULATE 5-OVER CLASH", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48BB78),
                        foregroundColor: const Color(0xFF0F1E16),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_simulatedMatch != null) ...[
          const SizedBox(height: 20),
          _buildSimulationResultCard(),
        ],

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _resetDraft,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A93C), foregroundColor: const Color(0xFF0F1E16)),
                child: const Text("NEW DRAFT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF1EBDD), side: const BorderSide(color: Color(0xFF28543A))),
                child: const Text("RETURN TO HUB"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimulationResultCard() {
    final in1 = _simulatedMatch!['in1'] as Map<String, dynamic>;
    final in2 = _simulatedMatch!['in2'] as Map<String, dynamic>;
    final summary = _simulatedMatch!['summary'] as String;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102319),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("5-OVER CLASH RESULT", style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFFE5A93C))),
              if (_winnerName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A93C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5A93C)),
                  ),
                  child: Text(
                    _winnerName == 'Draw' ? 'TIED' : 'WINNER: $_winnerName',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(summary, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
          const Divider(color: Color(0xFF244A36), height: 24),

          Text("$_p1Name: ${in1['runs']}/${in1['wickets']} (${in1['overs']} Ov)", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF63B3ED))),
          const SizedBox(height: 6),
          Text("$_p2Name: ${in2['runs']}/${in2['wickets']} (${in2['overs']} Ov)", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFED8936))),

          const SizedBox(height: 16),
          Text("MATCH HIGHLIGHTS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
          const SizedBox(height: 6),
          ...((in1['highlights'] as List<String>) + (in2['highlights'] as List<String>)).take(6).map((h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text("• $h", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE2DDD1))),
              )),
        ],
      ),
    );
  }
}
