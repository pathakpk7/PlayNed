import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/services/platform_api_service.dart';
import '../../data/cricket_dataset.dart';
import '../../domain/models/cricket_models.dart';
import '../widgets/chit_bowl_widget.dart';

class SuperOverGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local' or 'online'
  final String? roomCode;
  final String? localPlayerId;

  const SuperOverGamePage({
    super.key,
    required this.mode,
    this.roomCode,
    this.localPlayerId,
  });

  @override
  ConsumerState<SuperOverGamePage> createState() => _SuperOverGamePageState();
}

class _SuperOverGamePageState extends ConsumerState<SuperOverGamePage> {
  // Local state or Synced state
  String _status = 'selection'; // selection, innings_1, innings_2, finished
  int _currentInnings = 1;
  String _p1Id = 'p1';
  String _p2Id = 'p2';
  String _p1Name = 'Player 1';
  String _p2Name = 'Player 2';

  // Selection
  final Map<String, List<String>> _selectedBatters = {'p1': [], 'p2': []};
  final Map<String, String?> _selectedBowlers = {'p1': null, 'p2': null};
  final Map<String, bool> _battersExpanded = {'p1': true, 'p2': true};
  final Map<String, bool> _bowlersExpanded = {'p1': true, 'p2': true};
  String _searchQuery = '';
  String _batterFilter = 'All';
  String _bowlerFilter = 'All';

  int _getResponsiveColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 960) return 5;
    if (w >= 600) return 4;
    return 3;
  }

  // Innings Data
  int _innings1Runs = 0;
  int _innings1Wickets = 0;
  int _innings1Balls = 0;
  List<DeliveryRecord> _innings1Deliveries = [];
  int _innings1BatterIdx = 0;

  int _innings2Runs = 0;
  int _innings2Wickets = 0;
  int _innings2Balls = 0;
  List<DeliveryRecord> _innings2Deliveries = [];
  int _innings2BatterIdx = 0;
  int _target = 0;

  // Active Ball
  String? _selectedDeliveryType;
  String? _selectedShotType;
  DeliveryRecord? _lastDelivery;
  String _lastCommentary = "Super Over ready to begin!";
  String? _winnerId;
  String? _winnerName;
  bool _isTie = false;

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    if (widget.mode == 'local') {
      _p1Name = auth.username ?? "Player 1";
      _p2Name = "Player 2";
    } else {
      _initOnline();
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _initOnline() async {
    if (widget.roomCode == null) return;

    try {
      final api = ref.read(platformApiServiceProvider);
      final pid = widget.localPlayerId ?? 'p1';

      final room = await api.getRoom(widget.roomCode!);
      if (room.matchState != null && mounted) {
        _applyRemoteState(room.matchState!);
      }

      _wsChannel = api.connectWebSocket(widget.roomCode!, pid);
      _wsSubscription = _wsChannel?.stream.listen((message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          if (data['room'] != null && data['room']['match_state'] != null && mounted) {
            _applyRemoteState(data['room']['match_state'] as Map<String, dynamic>);
          }
        } catch (_) {}
      });

      _startPolling();
    } catch (_) {}
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (widget.roomCode == null) return;
      try {
        final api = ref.read(platformApiServiceProvider);
        final room = await api.getRoom(widget.roomCode!);
        if (room.matchState != null && mounted) {
          _applyRemoteState(room.matchState!);
        }
      } catch (_) {}
    });
  }

  void _applyRemoteState(Map<String, dynamic> s) {
    setState(() {
      _status = s['status'] ?? _status;
      _currentInnings = s['current_innings'] ?? _currentInnings;
      final pids = s['player_ids'] as List<dynamic>? ?? ['p1', 'p2'];
      _p1Id = pids.isNotEmpty ? pids[0].toString() : 'p1';
      _p2Id = pids.length > 1 ? pids[1].toString() : 'p2';

      final pnames = s['player_names'] as Map<String, dynamic>? ?? {};
      _p1Name = pnames[_p1Id]?.toString() ?? _p1Name;
      _p2Name = pnames[_p2Id]?.toString() ?? _p2Name;

      final sel = s['selections'] as Map<String, dynamic>? ?? {};
      if (sel[_p1Id] != null) {
        _selectedBatters[_p1Id] = List<String>.from(sel[_p1Id]['batters'] ?? []);
        _selectedBowlers[_p1Id] = sel[_p1Id]['bowler']?.toString();
      }
      if (sel[_p2Id] != null) {
        _selectedBatters[_p2Id] = List<String>.from(sel[_p2Id]['batters'] ?? []);
        _selectedBowlers[_p2Id] = sel[_p2Id]['bowler']?.toString();
      }

      final in1 = s['innings_1'] as Map<String, dynamic>?;
      if (in1 != null) {
        _innings1Runs = in1['total_runs'] ?? 0;
        _innings1Wickets = in1['wickets'] ?? 0;
        _innings1Balls = in1['legal_balls'] ?? 0;
        _innings1BatterIdx = in1['active_batter_index'] ?? 0;
        final dels = in1['deliveries'] as List<dynamic>? ?? [];
        _innings1Deliveries = dels.map((d) => DeliveryRecord.fromJson(d as Map<String, dynamic>)).toList();
      }

      final in2 = s['innings_2'] as Map<String, dynamic>?;
      if (in2 != null) {
        _innings2Runs = in2['total_runs'] ?? 0;
        _innings2Wickets = in2['wickets'] ?? 0;
        _innings2Balls = in2['legal_balls'] ?? 0;
        _target = in2['target'] ?? 0;
        _innings2BatterIdx = in2['active_batter_index'] ?? 0;
        final dels = in2['deliveries'] as List<dynamic>? ?? [];
        _innings2Deliveries = dels.map((d) => DeliveryRecord.fromJson(d as Map<String, dynamic>)).toList();
      }

      if (s['last_delivery_result'] != null) {
        _lastDelivery = DeliveryRecord.fromJson(s['last_delivery_result'] as Map<String, dynamic>);
        _lastCommentary = _lastDelivery?.commentary ?? _lastCommentary;
      }
      _winnerId = s['winner_id']?.toString();
      _winnerName = s['winner_name']?.toString();
      _isTie = s['is_tie'] ?? false;
      if (_status == 'finished') {
        _recordMatchStats();
      }
    });
  }

  // Local Simulation Logic
  void _submitLocalSelection(String pid, List<String> batters, String bowler) {
    setState(() {
      _selectedBatters[pid] = batters;
      _selectedBowlers[pid] = bowler;

      if (_selectedBatters['p1']!.length == 2 &&
          _selectedBowlers['p1'] != null &&
          _selectedBatters['p2']!.length == 2 &&
          _selectedBowlers['p2'] != null) {
        _status = 'innings_1';
        _lastCommentary = "Innings 1: ${_p1Name} to Bat, ${_p2Name} to Bowl!";
      }
    });
  }

  void _submitLocalBall() {
    if (_selectedDeliveryType == null || _selectedShotType == null) return;

    final isInn1 = (_currentInnings == 1);
    final battingPid = isInn1 ? _p1Id : _p2Id;
    final bowlingPid = isInn1 ? _p2Id : _p1Id;

    final battingTeam = _selectedBatters[battingPid]!;
    final bowlerId = _selectedBowlers[bowlingPid]!;
    final batterId = battingTeam[isInn1 ? _innings1BatterIdx : _innings2BatterIdx];

    final batter = CricketDataset.getPlayerById(batterId);
    final bowler = CricketDataset.getPlayerById(bowlerId);

    // Resolve delivery
    final result = _resolveBall(
      ballNumber: (isInn1 ? _innings1Balls : _innings2Balls) + 1,
      batter: batter!,
      bowler: bowler!,
      deliveryType: _selectedDeliveryType!,
      shotType: _selectedShotType!,
    );

    setState(() {
      _lastDelivery = result;
      _lastCommentary = result.commentary;
      _selectedDeliveryType = null;
      _selectedShotType = null;

      if (isInn1) {
        _innings1Deliveries.add(result);
        _innings1Runs += result.runs;
        _innings1Balls += 1;
        if (result.isWicket) {
          _innings1Wickets += 1;
          if (_innings1BatterIdx == 0 && _innings1Wickets < 2) {
            _innings1BatterIdx = 1;
          }
        }

        if (_innings1Balls >= 6 || _innings1Wickets >= 2) {
          // Switch to Innings 2
          _currentInnings = 2;
          _status = 'innings_2';
          _target = _innings1Runs + 1;
          _lastCommentary = "Innings 1 Complete! ${_p1Name} scored $_innings1Runs/$_innings1Wickets. Target for ${_p2Name} is $_target runs.";
        }
      } else {
        _innings2Deliveries.add(result);
        _innings2Runs += result.runs;
        _innings2Balls += 1;
        if (result.isWicket) {
          _innings2Wickets += 1;
          if (_innings2BatterIdx == 0 && _innings2Wickets < 2) {
            _innings2BatterIdx = 1;
          }
        }

        // Check Innings 2 end
        if (_innings2Runs >= _target) {
          _status = 'finished';
          _winnerId = _p2Id;
          _winnerName = _p2Name;
          _lastCommentary = "$_p2Name chases down the target to WIN the Super Over!";
          _recordMatchStats();
        } else if (_innings2Balls >= 6 || _innings2Wickets >= 2) {
          _status = 'finished';
          if (_innings2Runs == _innings1Runs) {
            _isTie = true;
            _winnerName = "Draw";
            _lastCommentary = "MATCH TIED! Scores level at $_innings1Runs each!";
          } else {
            _winnerId = _p1Id;
            _winnerName = _p1Name;
            _lastCommentary = "$_p1Name successfully defends their total to WIN the Super Over!";
          }
          _recordMatchStats();
        }
      }
    });
  }

  bool _statsRecorded = false;

  void _recordMatchStats() {
    if (_statsRecorded) return;
    _statsRecorded = true;
    try {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.userId == null) return;

      final isP1 = widget.localPlayerId == null || widget.localPlayerId == _p1Id;
      final myRuns = isP1 ? _innings1Runs : _innings2Runs;
      final myWickets = isP1 ? _innings2Wickets : _innings1Wickets;

      String outcome = 'tie';
      if (!_isTie) {
        if ((isP1 && _winnerId == _p1Id) || (!isP1 && _winnerId == _p2Id)) {
          outcome = 'win';
        } else {
          outcome = 'loss';
        }
      }

      ref.read(platformApiServiceProvider).recordGameResult(
        userId: auth.userId!,
        gameId: 'cricket',
        sectionId: 'super_over',
        outcome: outcome,
        score: myRuns,
        opponentName: isP1 ? _p2Name : _p1Name,
        details: {
          'my_runs': myRuns,
          'opponent_runs': isP1 ? _innings2Runs : _innings1Runs,
          'innings1_runs': _innings1Runs,
          'innings2_runs': _innings2Runs,
          'target': _target,
        },
        extraStatsUpdate: {
          'runs': myRuns,
          'wickets': myWickets,
        },
      );
    } catch (_) {}
  }

  DeliveryRecord _resolveBall({
    required int ballNumber,
    required CricketPlayer batter,
    required CricketPlayer bowler,
    required String deliveryType,
    required String shotType,
  }) {
    // Realistic probabilistic match engine
    // Base outcome probabilities for T20 Super Over: 0, 1, 2, 4, 6, Wicket
    final probs = <dynamic, double>{
      0: 18.0,
      1: 28.0,
      2: 16.0,
      4: 18.0,
      6: 12.0,
      'W': 8.0,
    };

    // Tactical Matchup Adjustments
    if (deliveryType == 'YORKER') {
      if (shotType == 'LOFT') {
        probs['W'] = (probs['W'] ?? 0) + 30.0;
        probs[0] = (probs[0] ?? 0) + 20.0;
        probs[4] = (probs[4] ?? 0) + 5.0;
        probs[6] = (probs[6] ?? 0) - 8.0;
      } else if (shotType == 'DEFEND') {
        probs[0] = (probs[0] ?? 0) + 40.0;
        probs[1] = (probs[1] ?? 0) + 30.0;
        probs['W'] = (probs['W'] ?? 0) - 4.0;
      } else if (shotType == 'ATTACK') {
        probs[4] = (probs[4] ?? 0) + 15.0;
        probs[1] = (probs[1] ?? 0) + 25.0;
        probs['W'] = (probs['W'] ?? 0) + 10.0;
      } else {
        // NORMAL
        probs[1] = (probs[1] ?? 0) + 35.0;
        probs[2] = (probs[2] ?? 0) + 15.0;
      }
    } else if (deliveryType == 'BOUNCER') {
      if (shotType == 'ATTACK' || shotType == 'LOFT') {
        probs[6] = (probs[6] ?? 0) + 28.0;
        probs[4] = (probs[4] ?? 0) + 22.0;
        probs['W'] = (probs['W'] ?? 0) + 14.0;
        probs[0] = (probs[0] ?? 0) - 8.0;
      } else if (shotType == 'DEFEND') {
        probs[0] = (probs[0] ?? 0) + 50.0;
        probs[1] = (probs[1] ?? 0) + 15.0;
        probs['W'] = (probs['W'] ?? 0) - 5.0;
      } else {
        probs[1] = (probs[1] ?? 0) + 25.0;
        probs[0] = (probs[0] ?? 0) + 20.0;
      }
    } else if (deliveryType == 'SLOWER') {
      if (shotType == 'LOFT') {
        probs[6] = (probs[6] ?? 0) + 24.0;
        probs['W'] = (probs['W'] ?? 0) + 22.0;
        probs[4] = (probs[4] ?? 0) + 15.0;
      } else if (shotType == 'ATTACK') {
        probs[4] = (probs[4] ?? 0) + 25.0;
        probs[2] = (probs[2] ?? 0) + 18.0;
        probs[1] = (probs[1] ?? 0) + 20.0;
      } else {
        probs[1] = (probs[1] ?? 0) + 35.0;
        probs[2] = (probs[2] ?? 0) + 15.0;
      }
    } else if (deliveryType == 'FULL') {
      if (shotType == 'ATTACK' || shotType == 'LOFT') {
        probs[4] = (probs[4] ?? 0) + 32.0;
        probs[6] = (probs[6] ?? 0) + 25.0;
        probs[1] = (probs[1] ?? 0) + 15.0;
        probs['W'] = (probs['W'] ?? 0) - 2.0;
      } else {
        probs[1] = (probs[1] ?? 0) + 30.0;
        probs[4] = (probs[4] ?? 0) + 20.0;
      }
    } else {
      // GOOD_LENGTH
      if (shotType == 'DEFEND') {
        probs[0] = (probs[0] ?? 0) + 45.0;
        probs[1] = (probs[1] ?? 0) + 25.0;
        probs['W'] = (probs['W'] ?? 0) - 4.0;
      } else if (shotType == 'ATTACK') {
        probs[4] = (probs[4] ?? 0) + 25.0;
        probs[6] = (probs[6] ?? 0) + 15.0;
        probs['W'] = (probs['W'] ?? 0) + 10.0;
      } else if (shotType == 'LOFT') {
        probs[6] = (probs[6] ?? 0) + 22.0;
        probs[4] = (probs[4] ?? 0) + 18.0;
        probs['W'] = (probs['W'] ?? 0) + 16.0;
      } else {
        probs[1] = (probs[1] ?? 0) + 35.0;
        probs[2] = (probs[2] ?? 0) + 20.0;
        probs[4] = (probs[4] ?? 0) + 12.0;
      }
    }

    // Player skill rating bonus
    final batPower = (batter.battingRating + batter.timing + batter.power) / 3.0;
    final bwlPower = (bowler.bowlingRating + bowler.accuracy + bowler.pace) / 3.0;
    final advantage = (batPower - bwlPower);

    if (advantage > 0) {
      probs[4] = (probs[4] ?? 0) + (advantage * 0.4);
      probs[6] = (probs[6] ?? 0) + (advantage * 0.3);
      probs['W'] = (probs['W'] ?? 0) - (advantage * 0.2);
    } else {
      probs['W'] = (probs['W'] ?? 0) + (advantage.abs() * 0.4);
      probs[0] = (probs[0] ?? 0) + (advantage.abs() * 0.3);
      probs[6] = (probs[6] ?? 0) - (advantage.abs() * 0.2);
    }

    // Clean and clamp probabilities
    final cleanProbs = <dynamic, double>{};
    for (final entry in probs.entries) {
      cleanProbs[entry.key] = entry.value.clamp(2.0, 150.0);
    }

    final totalWeight = cleanProbs.values.fold(0.0, (sum, w) => sum + w);
    final roll = Random().nextDouble() * totalWeight;

    dynamic selectedOutcome = 0;
    double cumulative = 0.0;
    for (final entry in cleanProbs.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        selectedOutcome = entry.key;
        break;
      }
    }

    int runs = 0;
    bool isWicket = false;
    String outcome = '0';
    String comm = '';

    if (selectedOutcome == 'W') {
      isWicket = true;
      outcome = 'W';
      final wktComms = [
        "OUT! ${bowler.name} strikes! Stunning delivery deceives ${batter.name} completely!",
        "WICKET! In the air and caught! What a sensational breakthrough for ${bowler.name}!",
        "BOWLED'EM! Timber rattled! ${bowler.name} crashes through the defenses of ${batter.name}!",
        "OUT! Edged and safely taken! Clinical bowling by ${bowler.name}!",
      ];
      comm = wktComms[Random().nextInt(wktComms.length)];
    } else {
      runs = selectedOutcome as int;
      outcome = runs.toString();
      if (runs == 6) {
        final sixComms = [
          "MAXIMUM! ${batter.name} launches it high and handsome into the top tier for SIX!",
          "SIX RUNS! Monstrous hit from ${batter.name}! Dispatched miles over long-on!",
          "SWEET AS A NUT! ${batter.name} clears the boundary ropes with tremendous authority!",
        ];
        comm = sixComms[Random().nextInt(sixComms.length)];
      } else if (runs == 4) {
        final fourComms = [
          "FOUR! Sublime timing from ${batter.name}! Races across the turf to the cover boundary!",
          "CRACKING SHOT! ${batter.name} finds the gap through extra cover for a blazing FOUR!",
          "BOUNDARY! Pierces the infield with precision! Four valuable runs for ${batter.name}!",
        ];
        comm = fourComms[Random().nextInt(fourComms.length)];
      } else if (runs == 2) {
        final twoComms = [
          "Pushed into the deep midwicket pocket. Superb running between the wickets for a brace!",
          "Tucked away neatly behind square, they hustle back hard for an easy 2 runs.",
        ];
        comm = twoComms[Random().nextInt(twoComms.length)];
      } else if (runs == 1) {
        final oneComms = [
          "Worked away into the leg-side for a sharp, sensible single.",
          "Dug out to long-off, rotates the strike cleanly for 1 run.",
          "Controlled tap to backward point, quick scamper through for a single.",
        ];
        comm = oneComms[Random().nextInt(oneComms.length)];
      } else {
        final dotComms = [
          "Dot ball! Superb line and length from ${bowler.name}, beaten outside off!",
          "No run! Solid defensive block right back down the pitch.",
          "Swing and a miss! Beaten by the movement, dot ball recorded.",
        ];
        comm = dotComms[Random().nextInt(dotComms.length)];
      }
    }

    return DeliveryRecord(
      ballNumber: ballNumber,
      bowlerId: bowler.id,
      batterId: batter.id,
      deliveryType: deliveryType,
      shotType: shotType,
      runs: runs,
      isWicket: isWicket,
      outcome: outcome,
      commentary: comm,
    );
  }

  void _resetMatch() {
    setState(() {
      _statsRecorded = false;
      _status = 'selection';
      _currentInnings = 1;
      _selectedBatters['p1'] = [];
      _selectedBatters['p2'] = [];
      _selectedBowlers['p1'] = null;
      _selectedBowlers['p2'] = null;
      _innings1Runs = 0;
      _innings1Wickets = 0;
      _innings1Balls = 0;
      _innings1Deliveries = [];
      _innings1BatterIdx = 0;
      _innings2Runs = 0;
      _innings2Wickets = 0;
      _innings2Balls = 0;
      _innings2Deliveries = [];
      _innings2BatterIdx = 0;
      _target = 0;
      _selectedDeliveryType = null;
      _selectedShotType = null;
      _lastDelivery = null;
      _lastCommentary = "Super Over ready to begin!";
      _winnerId = null;
      _winnerName = null;
      _isTie = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09140E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2218),
        title: Text(
          "SUPER OVER DUEL",
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
            child: _status == 'selection' ? _buildSelectionView() : _buildMatchView(),
          ),
        ),
      ),
    );
  }

  // --- SELECTION VIEW ---
  Widget _buildSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF13241B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF28543A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFE5A93C), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Each player must pick exactly 2 Batters and 1 Bowler for the 6-ball Super Over duel. Use the search bar & category filters below to find any star from past or present!",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE2DDD1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Universal Search Bar
          TextField(
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD)),
            decoration: InputDecoration(
              hintText: "Search player by name or country (e.g. Kohli, Head, Bumrah, Warne, Australia)...",
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
          const SizedBox(height: 20),

          _buildTeamSelectionCard(
            playerId: _p1Id,
            playerName: _p1Name,
            accentColor: const Color(0xFF3182CE),
          ),
          const SizedBox(height: 24),

          _buildTeamSelectionCard(
            playerId: _p2Id,
            playerName: _p2Name,
            accentColor: const Color(0xFFDD6B20),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedBatters['p1']!.length == 2 &&
                      _selectedBowlers['p1'] != null &&
                      _selectedBatters['p2']!.length == 2 &&
                      _selectedBowlers['p2'] != null)
                  ? () => _submitLocalSelection(
                        'p1',
                        _selectedBatters['p1']!,
                        _selectedBowlers['p1']!,
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A93C),
                foregroundColor: const Color(0xFF0F1E16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "START SUPER OVER MATCH",
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CricketPlayer> _getEligibleBatters() {
    return CricketDataset.getBatters().where((p) {
      if (_batterFilter == 'Pure Batters' && p.role != 'Batter') return false;
      if (_batterFilter == 'Wicket-Keepers' && p.role != 'Wicket-Keeper') return false;
      if (_batterFilter == 'All-Rounders' && p.role != 'All-Rounder') return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.name.toLowerCase().contains(q) || p.country.toLowerCase().contains(q) || p.role.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  List<CricketPlayer> _getEligibleBowlers() {
    return CricketDataset.getBowlers().where((p) {
      if (_bowlerFilter == 'Fast Bowlers' && !(p.bowlingStyle.toLowerCase().contains('fast') || p.bowlingStyle.toLowerCase().contains('medium') || p.bowlingStyle.toLowerCase().contains('pace'))) return false;
      if (_bowlerFilter == 'Spin Bowlers' && !(p.bowlingStyle.toLowerCase().contains('spin') || p.bowlingStyle.toLowerCase().contains('orthodox') || p.bowlingStyle.toLowerCase().contains('break') || p.bowlingStyle.toLowerCase().contains('googly'))) return false;
      if (_bowlerFilter == 'All-Rounders' && p.role != 'All-Rounder') return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.name.toLowerCase().contains(q) || p.country.toLowerCase().contains(q) || p.bowlingStyle.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildTeamSelectionCard({
    required String playerId,
    required String playerName,
    required Color accentColor,
  }) {
    final batters = _selectedBatters[playerId] ?? [];
    final bowler = _selectedBowlers[playerId];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101E17),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: accentColor,
                    child: Text(
                      playerName[0],
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    playerName,
                    style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE5A93C),
                  side: const BorderSide(color: Color(0xFFD5A84B)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () async {
                  final eligible = CricketDataset.allPlayers.where((p) => !batters.contains(p.id) && bowler != p.id).toList();
                  final picked = await ChitBowlDialog.show(
                    context,
                    title: "$playerName's Lucky Dip",
                    subtitle: "Draw a folded paper chit from the antique auction bowl!",
                    eligiblePlayers: eligible,
                  );
                  if (picked != null) {
                    setState(() {
                      if (picked.role == 'Bowler' && bowler == null) {
                        _selectedBowlers[playerId] = picked.id;
                      } else if (batters.length < 2) {
                        batters.add(picked.id);
                      } else if (bowler == null) {
                        _selectedBowlers[playerId] = picked.id;
                      }
                    });
                  }
                },
                icon: const Icon(Icons.casino, size: 14, color: Color(0xFFE5A93C)),
                label: Text("DRAW FROM CHIT BOWL 📜", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Batters selection collapsible header
          InkWell(
            onTap: () {
              setState(() {
                _battersExpanded[playerId] = !(_battersExpanded[playerId] ?? true);
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF13241B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF28543A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("🏏", style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        "SELECT 2 BATTERS (${batters.length}/2)",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE2DDD1)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (batters.length < 2)
                        InkWell(
                          onTap: () async {
                            final eligible = CricketDataset.getBatters().where((p) => !batters.contains(p.id)).toList();
                            final picked = await ChitBowlDialog.show(
                              context,
                              title: "Draw Batter for $playerName",
                              subtitle: "Pick a random batter from the bowl of chits!",
                              eligiblePlayers: eligible,
                            );
                            if (picked != null) {
                              setState(() {
                                if (batters.length < 2) batters.add(picked.id);
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.touch_app, size: 12, color: Color(0xFF63B3ED)),
                                const SizedBox(width: 4),
                                Text("Chit", style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF63B3ED), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      Icon(
                        (_battersExpanded[playerId] ?? true) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFFE5A93C),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_battersExpanded[playerId] ?? true) ...[
            const SizedBox(height: 8),
            // Batter Category Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pure Batters', 'Wicket-Keepers', 'All-Rounders'].map((cat) {
                  final isSelected = _batterFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                    child: ChoiceChip(
                      label: Text(cat, style: GoogleFonts.inter(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF28543A),
                      backgroundColor: const Color(0xFF13241B),
                      labelStyle: TextStyle(color: isSelected ? const Color(0xFFE5A93C) : const Color(0xFFA9A396)),
                      side: BorderSide(color: isSelected ? const Color(0xFFE5A93C) : const Color(0xFF1E3A2B)),
                      onSelected: (val) {
                        if (val) setState(() => _batterFilter = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Responsive Batter Grid (5 in laptop, 4 in tablet, 3 in mobile)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getResponsiveColumns(context),
                childAspectRatio: 3.2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _getEligibleBatters().length,
              itemBuilder: (ctx, idx) {
                final p = _getEligibleBatters()[idx];
                final isSel = batters.contains(p.id);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSel) {
                        batters.remove(p.id);
                      } else if (batters.length < 2) {
                        batters.add(p.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? accentColor.withOpacity(0.25) : const Color(0xFF13241B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSel ? accentColor : const Color(0xFF1E3A2B),
                        width: isSel ? 1.4 : 0.8,
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
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? const Color(0xFFF1EBDD) : const Color(0xFFA9A396),
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
                            color: isSel ? accentColor : p.avatarColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          // Bowlers selection collapsible header
          InkWell(
            onTap: () {
              setState(() {
                _bowlersExpanded[playerId] = !(_bowlersExpanded[playerId] ?? true);
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF13241B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF28543A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("🎯", style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        "SELECT 1 BOWLER (${bowler != null ? '1/1' : '0/1'})",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE2DDD1)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (bowler == null)
                        InkWell(
                          onTap: () async {
                            final eligible = CricketDataset.getBowlers().where((p) => !batters.contains(p.id)).toList();
                            final picked = await ChitBowlDialog.show(
                              context,
                              title: "Draw Bowler for $playerName",
                              subtitle: "Pick a random strike bowler from the bowl of chits!",
                              eligiblePlayers: eligible,
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedBowlers[playerId] = picked.id;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.touch_app, size: 12, color: Color(0xFFED8936)),
                                const SizedBox(width: 4),
                                Text("Chit", style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFED8936), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      Icon(
                        (_bowlersExpanded[playerId] ?? true) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFFE5A93C),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_bowlersExpanded[playerId] ?? true) ...[
            const SizedBox(height: 8),
            // Bowler Category Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Fast Bowlers', 'Spin Bowlers', 'All-Rounders'].map((cat) {
                  final isSelected = _bowlerFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                    child: ChoiceChip(
                      label: Text(cat, style: GoogleFonts.inter(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF28543A),
                      backgroundColor: const Color(0xFF13241B),
                      labelStyle: TextStyle(color: isSelected ? const Color(0xFFE5A93C) : const Color(0xFFA9A396)),
                      side: BorderSide(color: isSelected ? const Color(0xFFE5A93C) : const Color(0xFF1E3A2B)),
                      onSelected: (val) {
                        if (val) setState(() => _bowlerFilter = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Responsive Bowler Grid (5 in laptop, 4 in tablet, 3 in mobile)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getResponsiveColumns(context),
                childAspectRatio: 3.2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _getEligibleBowlers().length,
              itemBuilder: (ctx, idx) {
                final p = _getEligibleBowlers()[idx];
                final isSel = bowler == p.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBowlers[playerId] = isSel ? null : p.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFE5A93C).withOpacity(0.25) : const Color(0xFF13241B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSel ? const Color(0xFFE5A93C) : const Color(0xFF1E3A2B),
                        width: isSel ? 1.4 : 0.8,
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
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? const Color(0xFFE5A93C) : const Color(0xFFA9A396),
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
                            color: isSel ? const Color(0xFFE5A93C) : p.avatarColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- MATCH VIEW ---
  Widget _buildMatchView() {
    final isInn1 = (_currentInnings == 1);
    final battingPid = isInn1 ? _p1Id : _p2Id;
    final bowlingPid = isInn1 ? _p2Id : _p1Id;
    final battingName = isInn1 ? _p1Name : _p2Name;
    final bowlingName = isInn1 ? _p2Name : _p1Name;

    final runs = isInn1 ? _innings1Runs : _innings2Runs;
    final wickets = isInn1 ? _innings1Wickets : _innings2Wickets;
    final balls = isInn1 ? _innings1Balls : _innings2Balls;
    final deliveries = isInn1 ? _innings1Deliveries : _innings2Deliveries;

    final battingTeam = _selectedBatters[battingPid] ?? ['virat_kohli', 'rohit_sharma'];
    final bowlerId = _selectedBowlers[bowlingPid] ?? 'jasprit_bumrah';
    final batterId = battingTeam[isInn1 ? _innings1BatterIdx : _innings2BatterIdx];

    final activeBatter = CricketDataset.getPlayerById(batterId) ?? CricketDataset.allPlayers[0];
    final activeBowler = CricketDataset.getPlayerById(bowlerId) ?? CricketDataset.allPlayers[15];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Scoreboard Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF162B20), Color(0xFF0F1E16)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E5E41), width: 1.5),
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
                          "INNINGS $_currentInnings : $battingName",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "$runs/$wickets",
                              style: GoogleFonts.dmSerifDisplay(fontSize: 36, color: const Color(0xFFF1EBDD)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(${balls ~/ 6}.${balls % 6} / 1.0 Ov)",
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFA9A396)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!isInn1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F382A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF38684D)),
                        ),
                        child: Column(
                          children: [
                            Text("TARGET", style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396))),
                            Text("$_target", style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFE5A93C))),
                            Text(
                              "${_target - runs} to win off ${6 - balls}b",
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF81E6D9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Ball tracker
                Row(
                  children: [
                    Text("OVERS: ", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        children: List.generate(6, (idx) {
                          final isBowled = idx < deliveries.length;
                          final del = isBowled ? deliveries[idx] : null;
                          Color bg = const Color(0xFF1B2F24);
                          Color textCol = const Color(0xFFA9A396);
                          String txt = "-";

                          if (del != null) {
                            if (del.isWicket) {
                              bg = const Color(0xFFE53E3E);
                              textCol = Colors.white;
                              txt = "W";
                            } else if (del.runs == 6) {
                              bg = const Color(0xFF805AD5);
                              textCol = Colors.white;
                              txt = "6";
                            } else if (del.runs == 4) {
                              bg = const Color(0xFF3182CE);
                              textCol = Colors.white;
                              txt = "4";
                            } else {
                              bg = const Color(0xFF28543A);
                              textCol = const Color(0xFFF1EBDD);
                              txt = "${del.runs}";
                            }
                          }

                          return Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF3B684D)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              txt,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2D Cricket Pitch & Active Matchup Visualizer
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF12281C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A5038), width: 1.2),
            ),
            child: Stack(
              children: [
                // Pitch strip
                Center(
                  child: Container(
                    width: 70,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7A76D).withOpacity(0.2),
                      border: Border.symmetric(
                        vertical: BorderSide(color: const Color(0xFFC7A76D).withOpacity(0.5), width: 1),
                      ),
                    ),
                  ),
                ),
                // Crease Lines
                Positioned(
                  top: 25,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(width: 90, height: 2, color: Colors.white.withOpacity(0.6)),
                  ),
                ),
                Positioned(
                  bottom: 25,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(width: 90, height: 2, color: Colors.white.withOpacity(0.6)),
                  ),
                ),

                // Batter Position (Bottom)
                Positioned(
                  bottom: 12,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: activeBatter.avatarColor,
                            child: const Icon(Icons.sports_cricket, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeBatter.name,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
                              ),
                              Text(
                                "Rating ${activeBatter.battingRating} | ${activeBatter.battingStyle}",
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5A93C).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE5A93C)),
                        ),
                        child: Text("STRIKER", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C))),
                      ),
                    ],
                  ),
                ),

                // Bowler Position (Top)
                Positioned(
                  top: 10,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: activeBowler.avatarColor,
                            child: const Icon(Icons.sports_baseball, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeBowler.name,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
                              ),
                              Text(
                                "Rating ${activeBowler.bowlingRating} | ${activeBowler.bowlingStyle}",
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF48BB78).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF48BB78)),
                        ),
                        child: Text("BOWLER", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Commentary & Last Result Ticker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF28543A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.comment_outlined, size: 16, color: Color(0xFFE5A93C)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _lastCommentary,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFF1EBDD)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_status == 'finished') ...[
            // Result Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF14281E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    _isTie ? "MATCH TIED!" : "$_winnerName WINS!",
                    style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: const Color(0xFFE5A93C)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$_p1Name: $_innings1Runs/$_innings1Wickets  vs  $_p2Name: $_innings2Runs/$_innings2Wickets",
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _resetMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A93C),
                            foregroundColor: const Color(0xFF0F1E16),
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
                            side: const BorderSide(color: Color(0xFF38684D)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("RETURN TO HUB"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Interactive Controls for Bowler & Batter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101E17),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF233B2E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bowler Selection
                  Text(
                    "BOWLER ACTION ($bowlingName)",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ["GOOD_LENGTH", "YORKER", "BOUNCER", "FULL", "SLOWER"].map((del) {
                      final isSel = _selectedDeliveryType == del;
                      return ChoiceChip(
                        label: Text(del.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 11)),
                        selected: isSel,
                        selectedColor: const Color(0xFF48BB78).withOpacity(0.35),
                        backgroundColor: const Color(0xFF182A20),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF48BB78) : const Color(0xFFA9A396),
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedDeliveryType = val ? del : null);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Batter Selection
                  Text(
                    "BATTER ACTION ($battingName)",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ["DEFEND", "NORMAL", "ATTACK", "LOFT"].map((shot) {
                      final isSel = _selectedShotType == shot;
                      return ChoiceChip(
                        label: Text(shot, style: GoogleFonts.inter(fontSize: 11)),
                        selected: isSel,
                        selectedColor: const Color(0xFFE5A93C).withOpacity(0.35),
                        backgroundColor: const Color(0xFF182A20),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFFE5A93C) : const Color(0xFFA9A396),
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedShotType = val ? shot : null);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedDeliveryType != null && _selectedShotType != null)
                          ? _submitLocalBall
                          : null,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(
                        "PLAY DELIVERY",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A93C),
                        foregroundColor: const Color(0xFF0F1E16),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
