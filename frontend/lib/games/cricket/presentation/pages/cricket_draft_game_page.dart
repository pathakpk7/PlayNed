import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/services/platform_api_service.dart';
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

class BatterScore {
  final String playerId;
  final String name;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  bool isOut = false;
  String dismissal = 'not out';

  BatterScore({required this.playerId, required this.name});
  double get strikeRate => balls == 0 ? 0.0 : (runs / balls) * 100.0;
}

class BowlerScore {
  final String playerId;
  final String name;
  int balls = 0;
  int runs = 0;
  int wickets = 0;
  int maidens = 0;

  BowlerScore({required this.playerId, required this.name});
  String get oversStr => "${balls ~/ 6}.${balls % 6}";
  double get economy => balls == 0 ? 0.0 : (runs / (balls / 6.0));
}

class DraftBallRecord {
  final int ballNumber;
  final int overNumber;
  final int ballInOver;
  final String batsmanName;
  final String bowlerName;
  final int runs;
  final bool isWicket;
  final String commentary;
  final String outcomeBadge;

  DraftBallRecord({
    required this.ballNumber,
    required this.overNumber,
    required this.ballInOver,
    required this.batsmanName,
    required this.bowlerName,
    required this.runs,
    required this.isWicket,
    required this.commentary,
    required this.outcomeBadge,
  });
}

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
  String _status = 'drafting'; // drafting, draft_complete, live_match, innings_break, match_finished
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
  String _lastActionMsg = "Draft started! Budget: 100 credits. Pick players and assign them into 5 squad tactical sections.";

  // Ball-by-Ball Live Simulator State
  int _liveInnings = 1; // 1 or 2
  int _currentBallInInnings = 0; // 0 to 30
  int _innings1Runs = 0;
  int _innings1Wickets = 0;
  int _innings2Runs = 0;
  int _innings2Wickets = 0;
  int _targetScore = 0;

  final List<DraftBallRecord> _in1BallLog = [];
  final List<DraftBallRecord> _in2BallLog = [];

  final Map<String, BatterScore> _in1Batters = {};
  final Map<String, BowlerScore> _in1Bowlers = {};
  final Map<String, BatterScore> _in2Batters = {};
  final Map<String, BowlerScore> _in2Bowlers = {};

  int _strikerIndex = 0;
  int _nonStrikerIndex = 1;
  String _lastBallCommentary = "Match is about to begin! 5 overs per side.";
  String _lastOutcomeBadge = "READY";
  String? _winnerName;
  String _matchSummary = '';

  Timer? _autoPlayTimer;
  bool _isAutoPlaying = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _p1Name = auth.username ?? "Player 1";
    _p2Name = "Player 2";
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
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
        _lastActionMsg = "Draft Completed! Both squads fully assembled into 5 tactical sections. Launch the Ball-by-Ball Live 5-Over Clash!";
      } else {
        _lastActionMsg = "$pname assigned ${player.name} as ${slotDef.title} (${player.draftCost} pts). $_currentTurnName is now on the clock!";
      }
    });
  }

  // --- LIVE 5-OVER BALL-BY-BALL ENGINE ---

  void _startLiveMatch() {
    _initInningsState(innings: 1);
    setState(() {
      _status = 'live_match';
      _liveInnings = 1;
      _currentBallInInnings = 0;
      _innings1Runs = 0;
      _innings1Wickets = 0;
      _innings2Runs = 0;
      _innings2Wickets = 0;
      _targetScore = 0;
      _in1BallLog.clear();
      _in2BallLog.clear();
      _winnerName = null;
      _matchSummary = '';
      _lastBallCommentary = "$_p1Name is batting first! Opening pair walks out to the middle.";
      _lastOutcomeBadge = "START";
    });
  }

  void _initInningsState({required int innings}) {
    final battingPid = (innings == 1) ? _p1Id : _p2Id;
    final bowlingPid = (innings == 1) ? _p2Id : _p1Id;

    final battingSlots = _squadSlots[battingPid]!;
    final bowlingSlots = _squadSlots[bowlingPid]!;

    final orderIds = [
      battingSlots['opening_batter'] ?? '',
      battingSlots['wicket_keeper'] ?? '',
      battingSlots['all_rounder'] ?? '',
      battingSlots['finisher'] ?? '',
      battingSlots['bowler'] ?? '',
    ];

    final battersMap = (innings == 1) ? _in1Batters : _in2Batters;
    final bowlersMap = (innings == 1) ? _in1Bowlers : _in2Bowlers;

    battersMap.clear();
    for (final id in orderIds) {
      final p = CricketDataset.getPlayerById(id);
      if (p != null) {
        battersMap[id] = BatterScore(playerId: id, name: p.name);
      }
    }

    bowlersMap.clear();
    final bowlerId = bowlingSlots['bowler'];
    final arId = bowlingSlots['all_rounder'];
    if (bowlerId != null) {
      final p = CricketDataset.getPlayerById(bowlerId);
      if (p != null) bowlersMap[bowlerId] = BowlerScore(playerId: bowlerId, name: p.name);
    }
    if (arId != null) {
      final p = CricketDataset.getPlayerById(arId);
      if (p != null) bowlersMap[arId] = BowlerScore(playerId: arId, name: p.name);
    }

    _strikerIndex = 0;
    _nonStrikerIndex = 1;
  }

  List<CricketPlayer> _getBattingOrder(int innings) {
    final battingPid = (innings == 1) ? _p1Id : _p2Id;
    final slots = _squadSlots[battingPid]!;
    final order = [
      slots['opening_batter'],
      slots['wicket_keeper'],
      slots['all_rounder'],
      slots['finisher'],
      slots['bowler'],
    ];
    return order
        .map((id) => CricketDataset.getPlayerById(id ?? ''))
        .where((p) => p != null)
        .cast<CricketPlayer>()
        .toList();
  }

  CricketPlayer _getActiveBowler(int innings, int overNumber) {
    final bowlingPid = (innings == 1) ? _p2Id : _p1Id;
    final slots = _squadSlots[bowlingPid]!;
    // Overs 1, 3, 5 by main Bowler, Overs 2, 4 by All-Rounder
    final bowlerKey = (overNumber % 2 == 1) ? 'bowler' : 'all_rounder';
    final id = slots[bowlerKey] ?? slots['bowler'] ?? slots['all_rounder'];
    return CricketDataset.getPlayerById(id ?? '') ?? CricketDataset.allPlayers[0];
  }

  void _bowlNextBall() {
    if (_status != 'live_match') return;

    final isInn1 = (_liveInnings == 1);
    final battingOrder = _getBattingOrder(_liveInnings);
    if (battingOrder.isEmpty) return;

    final currentBall = _currentBallInInnings + 1; // 1 to 30
    final overNum = (currentBall - 1) ~/ 6 + 1;
    final ballInOver = (currentBall - 1) % 6 + 1;

    final striker = (_strikerIndex < battingOrder.length) ? battingOrder[_strikerIndex] : battingOrder.last;
    final activeBowler = _getActiveBowler(_liveInnings, overNum);

    final battersMap = isInn1 ? _in1Batters : _in2Batters;
    final bowlersMap = isInn1 ? _in1Bowlers : _in2Bowlers;

    final bScore = battersMap[striker.id] ?? BatterScore(playerId: striker.id, name: striker.name);
    final bowlScore = bowlersMap[activeBowler.id] ?? BowlerScore(playerId: activeBowler.id, name: activeBowler.name);

    // Finisher boost in death overs
    final isDeathOver = overNum >= 4;
    final finisherId = _squadSlots[isInn1 ? _p1Id : _p2Id]!['finisher'];
    final isFinisher = striker.id == finisherId;
    int powerBonus = (isDeathOver && isFinisher) ? 18 : 0;

    final random = Random();
    final roll = random.nextInt(100) + ((striker.battingRating - activeBowler.bowlingRating) ~/ 3) + powerBonus;

    int runsScored = 0;
    bool isWkt = false;
    String badge = '•';
    String comm = '';

    bScore.balls += 1;
    bowlScore.balls += 1;

    if (roll < 12) {
      // Wicket
      isWkt = true;
      runsScored = 0;
      badge = 'W';
      bScore.isOut = true;
      bScore.dismissal = "b ${activeBowler.name}";
      bowlScore.wickets += 1;

      final wktComms = [
        "OUT! Clean bowled! ${activeBowler.name} crashes through ${striker.name}'s defense with a thunderous delivery!",
        "WICKET! Caught at long-on! ${striker.name} tries to go big but finds the fielder off ${activeBowler.name}!",
        "EDGED AND TAKEN! Superb seam movement from ${activeBowler.name} gets the outside edge of ${striker.name}!",
        "LBW! Pinpoint yorker from ${activeBowler.name} traps ${striker.name} right in front of the stumps!",
      ];
      comm = wktComms[random.nextInt(wktComms.length)];
    } else if (roll > 86) {
      // Six
      runsScored = 6;
      badge = '6';
      bScore.runs += 6;
      bScore.sixes += 1;
      bowlScore.runs += 6;

      final sixComms = [
        "SIX! Massive blow! ${striker.name} launches ${activeBowler.name} way back into the top tier!",
        "MAXIMUM! Cracking sound off the bat as ${striker.name} deposits ${activeBowler.name} over long-off!",
        "SIX RUNS! Slog-sweep perfection from ${striker.name}! Clears the mid-wicket boundary with authority!",
      ];
      comm = sixComms[random.nextInt(sixComms.length)];
      if (isFinisher && isDeathOver) comm += " (⚡ Finisher Death-Over Boost!)";
    } else if (roll > 68) {
      // Four
      runsScored = 4;
      badge = '4';
      bScore.runs += 4;
      bScore.fours += 1;
      bowlScore.runs += 4;

      final fourComms = [
        "FOUR! Exquisite cover drive from ${striker.name}! Races across the turf to the ropes.",
        "BOUNDARY! Pulled away with authority into the deep square leg gap by ${striker.name}!",
        "FOUR RUNS! Steered delicately past backward point for a pristine boundary!",
      ];
      comm = fourComms[random.nextInt(fourComms.length)];
    } else if (roll > 50) {
      // Two runs
      runsScored = 2;
      badge = '2';
      bScore.runs += 2;
      bowlScore.runs += 2;
      comm = "Pushed into the deep gap, excellent hard running between the wickets for 2 runs.";
    } else if (roll > 28) {
      // Single
      runsScored = 1;
      badge = '1';
      bScore.runs += 1;
      bowlScore.runs += 1;
      comm = "Dug out to mid-off, sharp scamper through for a single. Strike rotated.";
    } else {
      // Dot ball
      runsScored = 0;
      badge = '•';
      comm = "Dot ball! Excellent tight line from ${activeBowler.name}, beaten outside the off stump.";
    }

    final ballRecord = DraftBallRecord(
      ballNumber: currentBall,
      overNumber: overNum,
      ballInOver: ballInOver,
      batsmanName: striker.name,
      bowlerName: activeBowler.name,
      runs: runsScored,
      isWicket: isWkt,
      commentary: comm,
      outcomeBadge: badge,
    );

    setState(() {
      _currentBallInInnings = currentBall;
      _lastBallCommentary = "Ov $overNum.$ballInOver: $comm";
      _lastOutcomeBadge = badge;

      if (isInn1) {
        _in1BallLog.add(ballRecord);
        _innings1Runs += runsScored;
        if (isWkt) _innings1Wickets += 1;
      } else {
        _in2BallLog.add(ballRecord);
        _innings2Runs += runsScored;
        if (isWkt) _innings2Wickets += 1;
      }

      // Handle striker rotation or next batter on wicket
      if (isWkt) {
        final nextBatterIdx = max(_strikerIndex, _nonStrikerIndex) + 1;
        _strikerIndex = nextBatterIdx;
      } else if (runsScored % 2 == 1) {
        final temp = _strikerIndex;
        _strikerIndex = _nonStrikerIndex;
        _nonStrikerIndex = temp;
      }

      // End of over: switch strike
      if (ballInOver == 6) {
        final temp = _strikerIndex;
        _strikerIndex = _nonStrikerIndex;
        _nonStrikerIndex = temp;
      }

      // Check Innings 1 Completion
      if (isInn1) {
        if (_innings1Wickets >= 5 || currentBall >= 30) {
          _targetScore = _innings1Runs + 1;
          _status = 'innings_break';
          _isAutoPlaying = false;
          _autoPlayTimer?.cancel();
          _lastBallCommentary = "Innings 1 Complete! $_p1Name scored $_innings1Runs/$_innings1Wickets. $_p2Name needs $_targetScore runs to win!";
        }
      } else {
        // Check Innings 2 Completion
        if (_innings2Runs >= _targetScore) {
          _finishMatch(winner: _p2Name, summary: "$_p2Name won by ${5 - _innings2Wickets} wickets! (Chased $_targetScore in $currentBall balls).");
        } else if (_innings2Wickets >= 5 || currentBall >= 30) {
          if (_innings2Runs == _innings1Runs) {
            _finishMatch(winner: 'Draw', summary: "Match TIED! Both squads scored $_innings1Runs runs in the 5-over clash!");
          } else if (_innings2Runs > _innings1Runs) {
            _finishMatch(winner: _p2Name, summary: "$_p2Name won by ${5 - _innings2Wickets} wickets!");
          } else {
            _finishMatch(winner: _p1Name, summary: "$_p1Name won by ${_innings1Runs - _innings2Runs} runs! (Defended $_innings1Runs runs).");
          }
        }
      }
    });
  }

  void _startSecondInnings() {
    _initInningsState(innings: 2);
    setState(() {
      _liveInnings = 2;
      _currentBallInInnings = 0;
      _status = 'live_match';
      _lastBallCommentary = "2nd Innings Underway! $_p2Name requires $_targetScore runs off 30 balls to win.";
      _lastOutcomeBadge = "CHASE";
    });
  }

  void _simulateRestOfOver() {
    if (_status != 'live_match') return;
    final ballsRemainingInOver = 6 - (_currentBallInInnings % 6);
    for (int i = 0; i < ballsRemainingInOver; i++) {
      if (_status != 'live_match') break;
      _bowlNextBall();
    }
  }

  void _toggleAutoPlay() {
    if (_isAutoPlaying) {
      _autoPlayTimer?.cancel();
      setState(() => _isAutoPlaying = false);
    } else {
      setState(() => _isAutoPlaying = true);
      _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
        if (_status != 'live_match') {
          timer.cancel();
          setState(() => _isAutoPlaying = false);
        } else {
          _bowlNextBall();
        }
      });
    }
  }

  void _finishMatch({required String winner, required String summary}) {
    _autoPlayTimer?.cancel();
    _isAutoPlaying = false;
    _winnerName = winner;
    _matchSummary = summary;
    _status = 'match_finished';

    _recordDraftResult(winner);
  }

  void _recordDraftResult(String? winName) {
    try {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.userId == null) return;

      String outcome = 'tie';
      if (winName == _p1Name) {
        outcome = 'win';
      } else if (winName != null && winName != 'Draw') {
        outcome = 'loss';
      }

      ref.read(platformApiServiceProvider).recordGameResult(
        userId: auth.userId!,
        gameId: 'cricket',
        sectionId: 'draft',
        outcome: outcome,
        score: _innings1Runs,
        opponentName: _p2Name,
        details: {
          'p1_squad': _squadSlots[_p1Id],
          'p2_squad': _squadSlots[_p2Id],
          'p1_runs': _innings1Runs,
          'p2_runs': _innings2Runs,
          'p1_wickets': _innings1Wickets,
          'p2_wickets': _innings2Wickets,
          'summary': _matchSummary,
        },
        extraStatsUpdate: {
          'draft_wins': outcome == 'win' ? 1 : 0,
          'runs': _innings1Runs,
          'wickets': _innings2Wickets,
        },
      );
    } catch (_) {}
  }

  void _resetDraft() {
    _autoPlayTimer?.cancel();
    setState(() {
      _status = 'drafting';
      _currentPickIdx = 0;
      _drafted['p1']!.clear();
      _drafted['p2']!.clear();
      _squadSlots['p1'] = {for (final s in squadSlotDefs) s.key: null};
      _squadSlots['p2'] = {for (final s in squadSlotDefs) s.key: null};
      _budget['p1'] = 100;
      _budget['p2'] = 100;
      _lastActionMsg = "Draft reset! Pick players for each squad.";
      _liveInnings = 1;
      _currentBallInInnings = 0;
      _innings1Runs = 0;
      _innings1Wickets = 0;
      _innings2Runs = 0;
      _innings2Wickets = 0;
      _in1BallLog.clear();
      _in2BallLog.clear();
      _winnerName = null;
      _matchSummary = '';
      _isAutoPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09140E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2218),
        title: Text(
          "CRICKET DRAFT & LIVE 5-OVER CLASH",
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
                  if (_status == 'drafting' || _status == 'draft_complete') ...[
                    _buildDraftHeader(),
                    const SizedBox(height: 16),
                    _buildSquadStatusCards(),
                    const SizedBox(height: 20),
                    if (_status == 'drafting') _buildDraftBoard(),
                    if (_status == 'draft_complete') _buildDraftCompleteCard(),
                  ] else if (_status == 'live_match' || _status == 'innings_break') ...[
                    _buildLiveMatchView(),
                  ] else if (_status == 'match_finished') ...[
                    _buildMatchFinishedView(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- DRAFT VIEW BUILDERS ---

  Widget _buildDraftHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13241B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF28543A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TACTICAL DRAFT",
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFE5A93C)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Pick ${_currentPickIdx + 1} of ${_draftOrder.length}",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _lastActionMsg,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE2DDD1)),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadStatusCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSingleSquadCard(_p1Id, _p1Name, const Color(0xFF3182CE))),
        const SizedBox(width: 12),
        Expanded(child: _buildSingleSquadCard(_p2Id, _p2Name, const Color(0xFFDD6B20))),
      ],
    );
  }

  Widget _buildSingleSquadCard(String pid, String name, Color accentColor) {
    final isTurn = (_status == 'drafting' && _currentTurnPid == pid);
    final slots = _squadSlots[pid]!;
    final budget = _budget[pid]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101E17),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTurn ? const Color(0xFFE5A93C) : accentColor.withOpacity(0.3),
          width: isTurn ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("$budget pts", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...squadSlotDefs.map((slotDef) {
            final playerId = slots[slotDef.key];
            final p = playerId != null ? CricketDataset.getPlayerById(playerId) : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: p != null ? const Color(0xFF172C21) : const Color(0xFF0C1914),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: p != null ? slotDef.color.withOpacity(0.5) : const Color(0xFF1E382A)),
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
                    Text("${p.draftCost}p", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: slotDef.color)),
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
      if (_filterRole == 'Batter' && p.role != 'Batter') return false;
      if (_filterRole == 'Bowler' && p.role != 'Bowler') return false;
      if (_filterRole == 'All-Rounder' && p.role != 'All-Rounder') return false;
      if (_filterRole == 'Wicket-Keeper' && p.role != 'Wicket-Keeper') return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.name.toLowerCase().contains(q) || p.country.toLowerCase().contains(q) || p.role.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lucky Dip Chit Bowl Banner Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
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

        // Universal Search Bar
        TextField(
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD)),
          decoration: InputDecoration(
            hintText: "Search legend by name, country (e.g. India, Australia, Pakistan)...",
            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
            prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFFE5A93C)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Color(0xFFA9A396)),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF13241B),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF28543A))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF28543A))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5A93C))),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
        ),
        const SizedBox(height: 10),

        // Role Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDraftRoleChip('All', '🌟 All (${CricketDataset.allPlayers.length})'),
              const SizedBox(width: 6),
              _buildDraftRoleChip('Batter', '🏏 Batters (${CricketDataset.getPureBatters().length})'),
              const SizedBox(width: 6),
              _buildDraftRoleChip('Bowler', '🎯 Bowlers (${CricketDataset.getPureBowlers().length})'),
              const SizedBox(width: 6),
              _buildDraftRoleChip('All-Rounder', '🛡️ All-Rounders (${CricketDataset.getAllRounders().length})'),
              const SizedBox(width: 6),
              _buildDraftRoleChip('Wicket-Keeper', '🧤 Wicket-Keepers (${CricketDataset.getWicketKeepers().length})'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text("ROSTER SELECTION (${available.length} AVAILABLE)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78))),
        const SizedBox(height: 10),

        if (_filterRole == 'All' || _filterRole == 'Batter')
          _buildDraftCategorySection(
            roleKey: 'Batter',
            roleEmoji: '🏏',
            roleTitle: 'Batters',
            players: _getAvailableCategoryPlayers('Batter'),
          ),

        if (_filterRole == 'All' || _filterRole == 'Bowler')
          _buildDraftCategorySection(
            roleKey: 'Bowler',
            roleEmoji: '🎯',
            roleTitle: 'Bowlers',
            players: _getAvailableCategoryPlayers('Bowler'),
          ),

        if (_filterRole == 'All' || _filterRole == 'All-Rounder')
          _buildDraftCategorySection(
            roleKey: 'All-Rounder',
            roleEmoji: '🛡️',
            roleTitle: 'All-Rounders',
            players: _getAvailableCategoryPlayers('All-Rounder'),
          ),

        if (_filterRole == 'All' || _filterRole == 'Wicket-Keeper')
          _buildDraftCategorySection(
            roleKey: 'Wicket-Keeper',
            roleEmoji: '🧤',
            roleTitle: 'Wicket-Keepers',
            players: _getAvailableCategoryPlayers('Wicket-Keeper'),
          ),
      ],
    );
  }

  List<CricketPlayer> _getAvailableCategoryPlayers(String role) {
    final draftedSet = {..._drafted['p1']!, ..._drafted['p2']!};
    return CricketDataset.allPlayers.where((p) {
      if (draftedSet.contains(p.id)) return false;
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

  Widget _buildDraftCategorySection({
    required String roleKey,
    required String roleEmoji,
    required String roleTitle,
    required List<CricketPlayer> players,
  }) {
    final isExpanded = _categoryExpanded[roleKey] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF102117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF234432)),
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
                    color: const Color(0xFFE5A93C),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && players.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFF1E3A2B)),
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
                  final canPick = _canDraft(_currentTurnPid, p);

                  return InkWell(
                    onTap: canPick ? () => _promptSlotAssignmentAndDraft(p) : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: canPick ? const Color(0xFF132B20) : const Color(0xFF101B15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: canPick ? const Color(0xFF28543A) : const Color(0xFF182A20),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              "${p.name} (${p.draftCost}p)",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: canPick ? FontWeight.w600 : FontWeight.normal,
                                color: canPick ? const Color(0xFFF1EBDD) : const Color(0xFF6B7C72),
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
                              color: canPick ? p.avatarColor : const Color(0xFF4A5568),
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

  Widget _buildDraftRoleChip(String role, String label) {
    final isSelected = _filterRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF28543A),
      backgroundColor: const Color(0xFF13241B),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFFE5A93C) : const Color(0xFFA9A396),
      ),
      side: BorderSide(color: isSelected ? const Color(0xFFE5A93C) : const Color(0xFF1E3A2B)),
      onSelected: (val) {
        if (val) setState(() => _filterRole = role);
      },
    );
  }

  Widget _buildDraftCompleteCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13281E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF48BB78), width: 1.5),
      ),
      child: Column(
        children: [
          Text("SQUADS ASSEMBLED!", style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFFE5A93C))),
          const SizedBox(height: 8),
          Text(
            "Both teams are ready for the 5-Over Clash (30 balls/innings). Play ball-by-ball with interactive delivery simulations, dynamic strike rotation, commentary, and death-over boosts!",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startLiveMatch,
              icon: const Icon(Icons.sports_cricket, size: 20),
              label: Text("START LIVE 5-OVER MATCH ⚡", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48BB78),
                foregroundColor: const Color(0xFF0F1E16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LIVE 5-OVER MATCH VIEW ---

  Widget _buildLiveMatchView() {
    final isInn1 = (_liveInnings == 1);
    final battingName = isInn1 ? _p1Name : _p2Name;
    final bowlingName = isInn1 ? _p2Name : _p1Name;
    final currentRuns = isInn1 ? _innings1Runs : _innings2Runs;
    final currentWickets = isInn1 ? _innings1Wickets : _innings2Wickets;
    final currentBall = _currentBallInInnings;
    final oversStr = "${currentBall ~/ 6}.${currentBall % 6}";
    final double crr = currentBall == 0 ? 0.0 : (currentRuns / (currentBall / 6.0));

    final battingOrder = _getBattingOrder(_liveInnings);
    final striker = (_strikerIndex < battingOrder.length) ? battingOrder[_strikerIndex] : null;
    final nonStriker = (_nonStrikerIndex < battingOrder.length) ? battingOrder[_nonStrikerIndex] : null;

    final overNum = (currentBall == 0) ? 1 : ((currentBall - 1) ~/ 6 + 1);
    final activeBowler = _getActiveBowler(_liveInnings, overNum);

    final battersMap = isInn1 ? _in1Batters : _in2Batters;
    final bowlersMap = isInn1 ? _in1Bowlers : _in2Bowlers;

    final strikerScore = striker != null ? (battersMap[striker.id] ?? BatterScore(playerId: striker.id, name: striker.name)) : null;
    final nonStrikerScore = nonStriker != null ? (battersMap[nonStriker.id] ?? BatterScore(playerId: nonStriker.id, name: nonStriker.name)) : null;
    final bowlerScore = bowlersMap[activeBowler.id] ?? BowlerScore(playerId: activeBowler.id, name: activeBowler.name);

    final currentOverBalls = (isInn1 ? _in1BallLog : _in2BallLog)
        .where((b) => b.overNumber == overNum)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Live Match HUD Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF102117),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isInn1 ? const Color(0xFF3182CE) : const Color(0xFFED8936), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "INNINGS $_liveInnings: $battingName BATTING",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C), letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$currentRuns / $currentWickets",
                            style: GoogleFonts.dmSerifDisplay(fontSize: 34, color: const Color(0xFFF1EBDD)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "($oversStr / 5.0 Ov)",
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFA9A396)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isInn1) ...[
                        Text("TARGET: $_targetScore", style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFED8936))),
                        Text("Need ${_targetScore - currentRuns} from ${30 - currentBall}b", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                      ] else ...[
                        Text("CRR: ${crr.toStringAsFixed(2)}", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF63B3ED))),
                        Text("5 Overs Match", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                      ],
                    ],
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E3A2B), height: 24),

              // Current Batters at Crease
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF152A1F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("🏏 ", style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Text(
                                  "${striker?.name ?? 'Striker'} *",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${strikerScore?.runs ?? 0} (${strikerScore?.balls ?? 0}b) • 4s: ${strikerScore?.fours ?? 0} • 6s: ${strikerScore?.sixes ?? 0}",
                            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFF1EBDD)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13241B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF244A36)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("🏃 ", style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Text(
                                  nonStriker?.name ?? 'Non-Striker',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${nonStrikerScore?.runs ?? 0} (${nonStrikerScore?.balls ?? 0}b) • 4s: ${nonStrikerScore?.fours ?? 0} • 6s: ${nonStrikerScore?.sixes ?? 0}",
                            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFA9A396)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bowler Figures & Current Over Ticker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1914),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text("🎯 ", style: TextStyle(fontSize: 12)),
                        Text(
                          activeBowler.name,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF81E6D9)),
                        ),
                        Text(
                          " (${bowlerScore.oversStr}-${bowlerScore.maidens}-${bowlerScore.runs}-${bowlerScore.wickets})",
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text("Over $overNum: ", style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396))),
                        ...currentOverBalls.map((b) => Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: b.isWicket
                                    ? const Color(0xFFE53E3E)
                                    : (b.runs == 6
                                        ? const Color(0xFF805AD5)
                                        : (b.runs == 4 ? const Color(0xFF3182CE) : const Color(0xFF28543A))),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                b.outcomeBadge,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Commentary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF142B20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF28543A)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _lastOutcomeBadge == 'W'
                            ? const Color(0xFFE53E3E)
                            : (_lastOutcomeBadge == '6'
                                ? const Color(0xFF805AD5)
                                : (_lastOutcomeBadge == '4' ? const Color(0xFF3182CE) : const Color(0xFFE5A93C))),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _lastOutcomeBadge,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lastBallCommentary,
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFF1EBDD), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Controls
        if (_status == 'innings_break') ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF13281E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFED8936), width: 1.5),
            ),
            child: Column(
              children: [
                Text("INNINGS BREAK", style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFED8936))),
                const SizedBox(height: 6),
                Text(
                  "$_p1Name set a target of $_targetScore runs (scored $_innings1Runs/$_innings1Wickets in 5 overs).\n$_p2Name needs $_targetScore runs to win off 30 deliveries!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF1EBDD)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startSecondInnings,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("START 2ND INNINGS CHASE 🏏", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED8936),
                      foregroundColor: const Color(0xFF0F1E16),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _bowlNextBall,
                  icon: const Icon(Icons.sports_cricket, size: 18),
                  label: const Text("BOWL NEXT BALL ⚡", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: const Color(0xFF0F1E16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _simulateRestOfOver,
                  icon: const Icon(Icons.fast_forward, size: 16),
                  label: const Text("OVER ⏩", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF81E6D9),
                    side: const BorderSide(color: Color(0xFF28543A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _toggleAutoPlay,
                  icon: Icon(_isAutoPlaying ? Icons.pause : Icons.play_arrow, size: 16),
                  label: Text(_isAutoPlaying ? "PAUSE" : "AUTO", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAutoPlaying ? const Color(0xFFE53E3E) : const Color(0xFF276749),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // Recent Balls Log
        Text("RECENT DELIVERIES", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
        const SizedBox(height: 8),
        ...((isInn1 ? _in1BallLog : _in2BallLog).reversed.take(6)).map((b) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1C15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1A3325)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: b.isWicket
                        ? const Color(0xFFE53E3E)
                        : (b.runs == 6
                            ? const Color(0xFF805AD5)
                            : (b.runs == 4 ? const Color(0xFF3182CE) : const Color(0xFF28543A))),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    b.outcomeBadge,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Text("Ov ${b.overNumber}.${b.ballInOver}: ", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C))),
                Expanded(
                  child: Text(
                    b.commentary,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E0)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- MATCH FINISHED SCORECARD VIEW ---

  Widget _buildMatchFinishedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF102319),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                _winnerName == 'Draw' ? 'MATCH TIED!' : '🏆 $_winnerName WINS!',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: const Color(0xFFE5A93C)),
              ),
              const SizedBox(height: 8),
              Text(
                _matchSummary,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
              ),
              const Divider(color: Color(0xFF244A36), height: 28),

              // Full 2-Innings Box Scorecard
              _buildInningsBoxScore(
                inningsNum: 1,
                teamName: _p1Name,
                runs: _innings1Runs,
                wickets: _innings1Wickets,
                balls: _in1BallLog.length,
                batters: _in1Batters,
                bowlers: _in1Bowlers,
              ),
              const SizedBox(height: 16),
              _buildInningsBoxScore(
                inningsNum: 2,
                teamName: _p2Name,
                runs: _innings2Runs,
                wickets: _innings2Wickets,
                balls: _in2BallLog.length,
                batters: _in2Batters,
                bowlers: _in2Bowlers,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _resetDraft,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A93C),
                  foregroundColor: const Color(0xFF0F1E16),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("PLAY NEW DRAFT CLASH", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF1EBDD),
                  side: const BorderSide(color: Color(0xFF28543A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("RETURN TO HUB"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInningsBoxScore({
    required int inningsNum,
    required String teamName,
    required int runs,
    required int wickets,
    required int balls,
    required Map<String, BatterScore> batters,
    required Map<String, BowlerScore> bowlers,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1811),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E3A2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Innings $inningsNum: $teamName",
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
              ),
              Text(
                "$runs / $wickets (${balls ~/ 6}.${balls % 6} Ov)",
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("BATTING", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
          const SizedBox(height: 4),
          ...batters.values.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        "${b.name} (${b.dismissal})",
                        style: GoogleFonts.inter(fontSize: 11, color: b.isOut ? const Color(0xFFA9A396) : const Color(0xFFF1EBDD)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "${b.runs} (${b.balls}b) [4s:${b.fours} 6s:${b.sixes}]",
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF81E6D9)),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Text("BOWLING", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
          const SizedBox(height: 4),
          ...bowlers.values.map((bw) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(bw.name, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFF1EBDD))),
                    Text(
                      "${bw.oversStr} Ov • ${bw.runs} Runs • ${bw.wickets} Wkts (Econ ${bw.economy.toStringAsFixed(1)})",
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
