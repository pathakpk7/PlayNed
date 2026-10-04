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

class ShutTheBoxGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local' or 'online'
  final String? roomCode;
  final String? localPlayerId;

  const ShutTheBoxGamePage({
    super.key,
    this.mode = 'local',
    this.roomCode,
    this.localPlayerId,
  });

  @override
  ConsumerState<ShutTheBoxGamePage> createState() => _ShutTheBoxGamePageState();
}

class _ShutTheBoxGamePageState extends ConsumerState<ShutTheBoxGamePage> with TickerProviderStateMixin {
  // Game Configuration
  int _maxTile = 9; // 9 or 12
  List<String> _playerIds = ['p1', 'p2'];
  Map<String, String> _playerNames = {'p1': 'Player 1', 'p2': 'Player 2'};
  final Map<String, Color> _playerColors = {
    'p1': const Color(0xFFE5A93C),
    'p2': const Color(0xFF48BB78),
    'p3': const Color(0xFF4299E1),
    'p4': const Color(0xFFED8936),
  };

  // Turn State
  int _currentPlayerIndex = 0;
  List<int> _openTiles = [];
  List<int> _shutTiles = [];
  final Set<int> _selectedTiles = {};
  List<int> _dice = [0, 0];
  int _diceSum = 0;
  bool _diceRolled = false;
  bool _isRollingAnimation = false;

  // Match Scoring & Completion
  Map<String, int> _playerScores = {};
  Map<String, bool> _playerRoundsCompleted = {};
  bool _isGameOver = false;
  String? _winnerName;
  String? _winnerId;
  String _lastActionMessage = "Roll the dice to start your round.";

  // Online WebSocket
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  late AnimationController _diceAnimController;

  @override
  void initState() {
    super.initState();
    _diceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initializeGame();
    if (widget.mode == 'online' && widget.roomCode != null) {
      _setupOnlineMode();
    }
  }

  void _initializeGame() {
    _openTiles = List.generate(_maxTile, (i) => i + 1);
    _shutTiles = [];
    _selectedTiles.clear();
    _dice = [0, 0];
    _diceSum = 0;
    _diceRolled = false;
    _currentPlayerIndex = 0;
    _playerScores = {for (var pid in _playerIds) pid: 0};
    _playerRoundsCompleted = {for (var pid in _playerIds) pid: false};
    _isGameOver = false;
    _winnerName = null;
    _winnerId = null;
    final currentPName = _playerNames[_playerIds[0]] ?? 'Player 1';
    _lastActionMessage = "$currentPName's turn to roll the dice.";
  }

  void _setupOnlineMode() async {
    final api = ref.read(platformApiServiceProvider);
    final pid = widget.localPlayerId ?? 'p1';

    try {
      final room = await api.getRoom(widget.roomCode!);
      if (room.matchState != null) {
        _applyBackendState(room.matchState!);
      }

      _wsChannel = api.connectWebSocket(widget.roomCode!, pid);
      _wsSubscription = _wsChannel?.stream.listen((message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          if (data['room'] != null && data['room']['match_state'] != null) {
            _applyBackendState(data['room']['match_state'] as Map<String, dynamic>);
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void _applyBackendState(Map<String, dynamic> state) {
    setState(() {
      _openTiles = List<int>.from(state['open_tiles'] ?? []);
      _shutTiles = List<int>.from(state['shut_tiles'] ?? []);
      _dice = List<int>.from(state['dice'] ?? [0, 0]);
      _diceSum = state['dice_sum'] ?? 0;
      _diceRolled = state['dice_rolled'] ?? false;
      _lastActionMessage = state['last_action'] ?? _lastActionMessage;
      if (state['player_scores'] != null) {
        _playerScores = Map<String, int>.from(state['player_scores']);
      }
      if (state['player_names'] != null) {
        _playerNames = Map<String, String>.from(state['player_names']);
      }
      if (state['status'] == 'finished') {
        _isGameOver = true;
        _winnerName = state['winner_name'];
      }
    });
  }

  void _sendOnlineAction(String action, Map<String, dynamic> payload) {
    if (_wsChannel != null) {
      _wsChannel!.sink.add(jsonEncode({
        'action': action,
        'move': payload,
      }));
    }
  }

  @override
  void dispose() {
    _diceAnimController.dispose();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  String get _currentTurnPlayerId => _playerIds[_currentPlayerIndex];
  String get _currentTurnPlayerName => _playerNames[_currentTurnPlayerId] ?? 'Player';
  Color get _currentTurnColor => _playerColors[_currentTurnPlayerId] ?? const Color(0xFFE5A93C);

  int get _selectedSum => _selectedTiles.fold(0, (sum, t) => sum + t);
  bool get _canRollOneDie => _openTiles.fold(0, (sum, t) => sum + t) <= 6;

  List<List<int>> _findValidCombinations(List<int> open, int target) {
    final List<List<int>> results = [];
    void find(int index, int currentSum, List<int> currentCombo) {
      if (currentSum == target) {
        results.add(List.from(currentCombo));
        return;
      }
      if (currentSum > target || index >= open.length) return;

      for (int i = index; i < open.length; i++) {
        currentCombo.add(open[i]);
        find(i + 1, currentSum + open[i], currentCombo);
        currentCombo.removeLast();
      }
    }

    find(0, 0, []);
    return results;
  }

  void _rollDice({bool oneDie = false}) async {
    if (_diceRolled && _findValidCombinations(_openTiles, _diceSum).isNotEmpty) return;
    if (_isRollingAnimation || _isGameOver) return;

    setState(() => _isRollingAnimation = true);
    _diceAnimController.forward(from: 0.0);

    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    final rand = Random();
    int d1 = rand.nextInt(6) + 1;
    int d2 = oneDie ? 0 : (rand.nextInt(6) + 1);

    setState(() {
      _isRollingAnimation = false;
      _dice = [d1, d2];
      _diceSum = d1 + d2;
      _diceRolled = true;
      _selectedTiles.clear();

      final rollStr = oneDie ? "$d1" : "$d1 + $d2 = ${d1 + d2}";
      _lastActionMessage = "$_currentTurnPlayerName rolled $rollStr.";

      final combos = _findValidCombinations(_openTiles, _diceSum);
      if (combos.isEmpty) {
        _lastActionMessage += " No valid combinations exist! Round over.";
      }
    });

    if (widget.mode == 'online') {
      _sendOnlineAction('roll_dice', {'action': 'roll_dice', 'one_die': oneDie});
    }
  }

  void _toggleTileSelection(int tile) {
    if (!_diceRolled || !_openTiles.contains(tile) || _isGameOver) return;

    setState(() {
      if (_selectedTiles.contains(tile)) {
        _selectedTiles.remove(tile);
      } else {
        _selectedTiles.add(tile);
      }
    });
  }

  void _shutSelectedTiles() {
    if (_selectedSum != _diceSum || _selectedTiles.isEmpty || _isGameOver) return;

    final tilesToShut = _selectedTiles.toList()..sort();

    setState(() {
      for (var t in tilesToShut) {
        _openTiles.remove(t);
        _shutTiles.add(t);
      }
      _shutTiles.sort();
      _selectedTiles.clear();
      _diceRolled = false;

      final shutStr = tilesToShut.join(" + ");
      _lastActionMessage = "$_currentTurnPlayerName shut tile(s): [$shutStr]. Roll again!";

      // Check for SHUT THE BOX (0 points - instant win of round)
      if (_openTiles.isEmpty) {
        _lastActionMessage = "$_currentTurnPlayerName SHUT THE BOX! Perfect 0 penalty score!";
        _playerScores[_currentTurnPlayerId] = 0;
        _advancePlayerRound(shutBox: true);
      }
    });

    if (widget.mode == 'online') {
      _sendOnlineAction('shut_tiles', {'action': 'shut_tiles', 'tiles': tilesToShut});
    }
  }

  void _endRound() {
    final penalty = _openTiles.fold(0, (sum, t) => sum + t);
    setState(() {
      _playerScores[_currentTurnPlayerId] = penalty;
      _advancePlayerRound();
    });

    if (widget.mode == 'online') {
      _sendOnlineAction('end_turn', {'action': 'end_turn'});
    }
  }

  void _advancePlayerRound({bool shutBox = false}) {
    _playerRoundsCompleted[_currentTurnPlayerId] = true;

    // Check if match is finished
    if (_playerRoundsCompleted.values.every((completed) => completed)) {
      _isGameOver = true;
      int minScore = _playerScores.values.reduce(min);
      final bestPids = _playerScores.entries.where((e) => e.value == minScore).map((e) => e.key).toList();

      if (bestPids.length == 1) {
        _winnerId = bestPids.first;
        _winnerName = _playerNames[_winnerId] ?? 'Player';
        _lastActionMessage = "Victory! $_winnerName wins with a low score of $minScore!";
      } else {
        _winnerName = "Tie";
        final names = bestPids.map((pid) => _playerNames[pid] ?? pid).join(" & ");
        _lastActionMessage = "Match ended in a Tie between $names ($minScore pts)!";
      }
      return;
    }

    // Advance to next player
    int nextIdx = (_currentPlayerIndex + 1) % _playerIds.length;
    while (_playerRoundsCompleted[_playerIds[nextIdx]] == true) {
      nextIdx = (nextIdx + 1) % _playerIds.length;
    }

    _currentPlayerIndex = nextIdx;
    _openTiles = List.generate(_maxTile, (i) => i + 1);
    _shutTiles = [];
    _selectedTiles.clear();
    _dice = [0, 0];
    _diceSum = 0;
    _diceRolled = false;
    _lastActionMessage += " Next round: $_currentTurnPlayerName.";
  }

  void _showConfigureMatchDialog() {
    int tempTileCount = _maxTile;
    int tempPlayerCount = _playerIds.length;
    final Map<String, TextEditingController> controllers = {
      for (var pid in ['p1', 'p2', 'p3', 'p4']) pid: TextEditingController(text: _playerNames[pid] ?? 'Player ${pid.substring(1)}')
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF181816),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE5A93C), width: 1.5),
          ),
          title: Text(
            "MATCH SETTINGS",
            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TILE BOX SET", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
                const SizedBox(height: 8),
                Row(
                  children: [9, 12].map((cnt) {
                    final isSel = tempTileCount == cnt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Center(child: Text("$cnt TILES (1–$cnt)")),
                          selected: isSel,
                          selectedColor: const Color(0xFFE5A93C),
                          backgroundColor: const Color(0xFF11110F),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? const Color(0xFF0F0F0D) : const Color(0xFFF1EBDD),
                          ),
                          onSelected: (_) => setDialogState(() => tempTileCount = cnt),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text("NUMBER OF PLAYERS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
                const SizedBox(height: 8),
                Row(
                  children: [1, 2, 3, 4].map((cnt) {
                    final isSel = tempPlayerCount == cnt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: ChoiceChip(
                          label: Center(child: Text("${cnt}P")),
                          selected: isSel,
                          selectedColor: const Color(0xFFE5A93C),
                          backgroundColor: const Color(0xFF11110F),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? const Color(0xFF0F0F0D) : const Color(0xFFF1EBDD),
                          ),
                          onSelected: (_) => setDialogState(() => tempPlayerCount = cnt),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text("CUSTOM PLAYER NAMES", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
                const SizedBox(height: 8),
                ...List.generate(tempPlayerCount, (index) {
                  final pid = "p${index + 1}";
                  final color = _playerColors[pid] ?? const Color(0xFFE5A93C);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: color.withOpacity(0.2),
                          child: Text(
                            controllers[pid]!.text.isNotEmpty ? controllers[pid]!.text[0].toUpperCase() : "${index + 1}",
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controllers[pid],
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD)),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFF11110F),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2A2A26))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("CANCEL", style: GoogleFonts.inter(color: const Color(0xFFA9A396))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A93C), foregroundColor: const Color(0xFF0F0F0D)),
              onPressed: () {
                setState(() {
                  _maxTile = tempTileCount;
                  _playerIds = List.generate(tempPlayerCount, (i) => "p${i + 1}");
                  _playerNames = {
                    for (var pid in _playerIds) pid: controllers[pid]!.text.trim().isNotEmpty ? controllers[pid]!.text.trim() : "Player ${pid.substring(1)}"
                  };
                  _initializeGame();
                });
                Navigator.pop(ctx);
              },
              child: const Text("APPLY & RESTART"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCombos = _diceRolled ? _findValidCombinations(_openTiles, _diceSum) : <List<int>>[];
    final hasValidCombos = validCombos.isNotEmpty;
    final canShut = _selectedSum == _diceSum && _selectedTiles.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SHUT THE BOX", style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD))),
            Text(
              "PLAYNED CASUAL DICE STRATEGY",
              style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFFE5A93C)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            tooltip: "Match Settings",
            onPressed: _showConfigureMatchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: "Restart Game",
            onPressed: () => setState(_initializeGame),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                // Turn & Scoreboard Banner
                _buildPlayerHeader(),
                const SizedBox(height: 14),

                // Wooden Box of Numbered Tiles
                _buildWoodenTileBox(),
                const SizedBox(height: 16),

                // Dice Rolling & Combination Area
                _buildDiceSection(hasValidCombos, canShut, validCombos),
                const SizedBox(height: 16),

                // Action Message Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181816),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A26)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: _currentTurnColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastActionMessage,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD)),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isGameOver) ...[
                  const SizedBox(height: 16),
                  _buildGameOverCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181816),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _currentTurnColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _currentTurnColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: _currentTurnColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _currentTurnPlayerName.isNotEmpty ? _currentTurnPlayerName[0].toUpperCase() : "P",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: _currentTurnColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isGameOver ? "MATCH FINISHED" : "$_currentTurnPlayerName's TURN",
                        style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD)),
                      ),
                      Text(
                        _isGameOver ? "Review Final Scores" : "Shut open tiles to lower your penalty score",
                        style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFA9A396)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF11110F),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2A2A26)),
                ),
                child: Text(
                  "ROUND ${_playerRoundsCompleted.values.where((v) => v).length + 1} / ${_playerIds.length}",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Mini Score Tracker
          Row(
            children: _playerIds.map((pid) {
              final isCurrent = pid == _currentTurnPlayerId && !_isGameOver;
              final isDone = _playerRoundsCompleted[pid] ?? false;
              final score = _playerScores[pid] ?? 0;
              final color = _playerColors[pid] ?? const Color(0xFFE5A93C);

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? color.withOpacity(0.15) : const Color(0xFF11110F),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isCurrent ? color : const Color(0xFF2A2A26), width: isCurrent ? 1.5 : 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _playerNames[pid] ?? pid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: const Color(0xFFF1EBDD)),
                      ),
                      Text(
                        isDone ? "$score pts" : "—",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isDone ? color : const Color(0xFFA9A396)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodenTileBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF221A11), // Rich dark wood tone
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.4), width: 2.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Brass Nameplate
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5A84B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD5A84B).withOpacity(0.5)),
                ),
                child: Text(
                  "PLAYNED SHUT-THE-BOX",
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: const Color(0xFFE5A93C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tiles Row
          LayoutBuilder(
            builder: (context, constraints) {
              final double tileWidth = (constraints.maxWidth - (_maxTile * 6)) / _maxTile;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_maxTile, (index) {
                  final tile = index + 1;
                  final isOpen = _openTiles.contains(tile);
                  final isSelected = _selectedTiles.contains(tile);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: isOpen ? () => _toggleTileSelection(tile) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: tileWidth.clamp(32.0, 54.0),
                        height: 80,
                        decoration: BoxDecoration(
                          color: isOpen
                              ? (isSelected ? const Color(0xFFE5A93C) : const Color(0xFF382A1C))
                              : const Color(0xFF14100B),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFFFFF)
                                : (isOpen ? const Color(0xFFD5A84B).withOpacity(0.7) : const Color(0xFF2A2016)),
                            width: isSelected ? 2.0 : 1.2,
                          ),
                          boxShadow: isOpen
                              ? [
                                  BoxShadow(
                                    color: isSelected ? const Color(0xFFE5A93C).withOpacity(0.4) : Colors.black.withOpacity(0.4),
                                    blurRadius: isSelected ? 8 : 4,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (!isOpen)
                              Positioned(
                                top: 6,
                                child: Text(
                                  "SHUT",
                                  style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: const Color(0xFF4A3C2D)),
                                ),
                              ),
                            Text(
                              "$tile",
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 26,
                                color: isOpen
                                    ? (isSelected ? const Color(0xFF0F0F0D) : const Color(0xFFF1EBDD))
                                    : const Color(0xFF3D3022),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiceSection(bool hasValidCombos, bool canShut, List<List<int>> validCombos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141412),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A26)),
      ),
      child: Column(
        children: [
          // Dice Display Area
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDieWidget(_dice[0]),
              const SizedBox(width: 14),
              if (_dice[1] > 0 || !_diceRolled) ...[
                _buildDieWidget(_dice[1]),
                const SizedBox(width: 14),
              ],
              if (_diceRolled) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A93C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5A93C)),
                  ),
                  child: Column(
                    children: [
                      Text("TARGET SUM", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396))),
                      Text("$_diceSum", style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFE5A93C))),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons (Roll / Shut / End)
          if (!_diceRolled) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5A93C),
                      foregroundColor: const Color(0xFF0F0F0D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _isGameOver ? null : () => _rollDice(oneDie: false),
                    icon: const Icon(Icons.casino, size: 18),
                    label: Text("ROLL 2 DICE", style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13)),
                  ),
                ),
                if (_canRollOneDie) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF1EBDD),
                        side: const BorderSide(color: Color(0xFFE5A93C), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _isGameOver ? null : () => _rollDice(oneDie: true),
                      icon: const Icon(Icons.looks_one, size: 18, color: Color(0xFFE5A93C)),
                      label: Text("ROLL 1 DIE (SUM ≤ 6)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canShut ? const Color(0xFF48BB78) : const Color(0xFF2A2A26),
                      foregroundColor: canShut ? const Color(0xFF0F0F0D) : const Color(0xFFA9A396),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: canShut ? _shutSelectedTiles : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      canShut ? "SHUT TILES (SUM = $_selectedSum)" : "SELECT TILES (SUM = $_selectedSum / $_diceSum)",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                if (!hasValidCombos) ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE57373),
                      foregroundColor: const Color(0xFF0F0F0D),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _endRound,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: Text("END ROUND", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ],
            ),

            if (validCombos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text("Suggested Combos:", style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFA9A396))),
                  ...validCombos.map((combo) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        setState(() {
                          _selectedTiles.clear();
                          _selectedTiles.addAll(combo);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A14),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.4)),
                        ),
                        child: Text(
                          combo.join(" + "),
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDieWidget(int value) {
    return AnimatedBuilder(
      animation: _diceAnimController,
      builder: (context, child) {
        final angle = _isRollingAnimation ? sin(_diceAnimController.value * pi * 4) * 0.35 : 0.0;
        final scale = _isRollingAnimation ? 0.9 + (sin(_diceAnimController.value * pi * 4).abs() * 0.2) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: angle,
            child: child,
          ),
        );
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFDF8), Color(0xFFE8DECA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC7BCA3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 2,
              offset: Offset(-1, -1),
            ),
          ],
        ),
        child: value > 0
            ? Padding(
                padding: const EdgeInsets.all(7.0),
                child: CustomPaint(
                  painter: _DiceFacePainter(value: value),
                ),
              )
            : Center(
                child: Icon(
                  Icons.casino,
                  color: const Color(0xFFB0A48E),
                  size: 30,
                ),
              ),
      ),
    );
  }
  Widget _buildGameOverCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1910),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 36, color: Color(0xFFE5A93C)),
          const SizedBox(height: 8),
          Text(
            _winnerName == "Tie" ? "MATCH TIED!" : "$_winnerName WINS!",
            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD)),
          ),
          const SizedBox(height: 4),
          Text(
            "Lowest penalty score takes the championship.",
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFA9A396)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A93C),
              foregroundColor: const Color(0xFF0F0F0D),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => setState(_initializeGame),
            icon: const Icon(Icons.replay, size: 16),
            label: Text("PLAY AGAIN", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }
}

class _DiceFacePainter extends CustomPainter {
  final int value;

  const _DiceFacePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = w * 0.11; // pip radius

    final Paint darkPip = Paint()
      ..color = const Color(0xFF1E1A16)
      ..style = PaintingStyle.fill;

    final Paint redPip = Paint()
      ..color = const Color(0xFFC53030)
      ..style = PaintingStyle.fill;

    final Offset center = Offset(w / 2, h / 2);
    final Offset topLeft = Offset(w * 0.24, h * 0.24);
    final Offset topRight = Offset(w * 0.76, h * 0.24);
    final Offset midLeft = Offset(w * 0.24, h * 0.5);
    final Offset midRight = Offset(w * 0.76, h * 0.5);
    final Offset bottomLeft = Offset(w * 0.24, h * 0.76);
    final Offset bottomRight = Offset(w * 0.76, h * 0.76);

    switch (value) {
      case 1:
        // Traditional larger red center pip
        canvas.drawCircle(center, r * 1.35, redPip);
        break;
      case 2:
        canvas.drawCircle(topRight, r, darkPip);
        canvas.drawCircle(bottomLeft, r, darkPip);
        break;
      case 3:
        canvas.drawCircle(topRight, r, darkPip);
        canvas.drawCircle(center, r, darkPip);
        canvas.drawCircle(bottomLeft, r, darkPip);
        break;
      case 4:
        canvas.drawCircle(topLeft, r, darkPip);
        canvas.drawCircle(topRight, r, darkPip);
        canvas.drawCircle(bottomLeft, r, darkPip);
        canvas.drawCircle(bottomRight, r, darkPip);
        break;
      case 5:
        canvas.drawCircle(topLeft, r, darkPip);
        canvas.drawCircle(topRight, r, darkPip);
        canvas.drawCircle(center, r, darkPip);
        canvas.drawCircle(bottomLeft, r, darkPip);
        canvas.drawCircle(bottomRight, r, darkPip);
        break;
      case 6:
        canvas.drawCircle(topLeft, r, darkPip);
        canvas.drawCircle(topRight, r, darkPip);
        canvas.drawCircle(midLeft, r, darkPip);
        canvas.drawCircle(midRight, r, darkPip);
        canvas.drawCircle(bottomLeft, r, darkPip);
        canvas.drawCircle(bottomRight, r, darkPip);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter oldDelegate) => oldDelegate.value != value;
}
