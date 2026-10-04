import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/models/game_model.dart';
import '../../../../platform/services/platform_api_service.dart';
import '../../../../platform/presentation/widgets/platform_app_bar.dart';

class PentagoGamePage extends ConsumerStatefulWidget {
  final String? roomCode;
  final String? localPlayerId;
  final String mode; // 'local' or 'online'

  const PentagoGamePage({
    super.key,
    this.roomCode,
    this.localPlayerId,
    this.mode = 'local',
  });

  @override
  ConsumerState<PentagoGamePage> createState() => _PentagoGamePageState();
}

class _PentagoGamePageState extends ConsumerState<PentagoGamePage> {
  // 6x6 board grid (null, "p1", "p2")
  List<List<String?>> _board = List.generate(6, (_) => List.generate(6, (_) => null));
  List<String> _playerIds = ["p1", "p2"];
  Map<String, String> _playerNames = {"p1": "Player 1", "p2": "Player 2"};
  int _currentTurnIndex = 0;
  String _phase = 'place_marble'; // place_marble -> rotate_quadrant
  int? _selectedQuadrantForRotation;
  String _status = 'in_progress';
  String? _winnerName;
  String _lastAction = 'Place a marble on any empty circular cell.';

  final Map<String, Color> _marbleColors = {
    "p1": const Color(0xFFF1EBDD), // White / Light Ivory
    "p2": const Color(0xFFD5A84B), // Gold Amber
  };

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'online' && widget.roomCode != null) {
      _initOnlineMode();
    } else {
      _initLocalMode();
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _initLocalMode() {
    final auth = ref.read(authProvider);
    final p1Name = auth.username ?? "Player 1";
    _playerNames = {"p1": p1Name, "p2": "Player 2"};
  }

  void _initOnlineMode() async {
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
    if (!mounted) return;
    setState(() {
      final rawBoard = state['board'] as List<dynamic>? ?? [];
      _board = rawBoard.map((row) {
        return (row as List<dynamic>).map((cell) => cell?.toString()).toList();
      }).toList();

      _playerIds = List<String>.from(state['player_ids'] ?? ["p1", "p2"]);
      _playerNames = Map<String, String>.from(state['player_names'] ?? {});
      _currentTurnIndex = state['current_turn_index'] ?? 0;
      _phase = state['phase'] ?? 'place_marble';
      _status = state['status'] ?? 'in_progress';
      _winnerName = state['winner_name'];
      _lastAction = state['last_action'] ?? '';
    });
  }

  void _onCellTap(int r, int c) async {
    if (_status != 'in_progress' || _phase != 'place_marble') return;
    if (_board[r][c] != null) return;

    final currentPid = _playerIds[_currentTurnIndex];

    if (widget.mode == 'online' && widget.roomCode != null) {
      if (currentPid != widget.localPlayerId) return;
      // In online mode, we place marble locally and wait for rotation to submit or submit place
      setState(() {
        _board[r][c] = currentPid;
        _phase = 'rotate_quadrant';
        _selectedQuadrantForRotation = _getQuadrantIndex(r, c);
        _lastAction = "Marble placed! Now select a quadrant to twist 90°.";
      });
      return;
    }

    // Local Mode
    setState(() {
      _board[r][c] = currentPid;
      _phase = 'rotate_quadrant';
      _selectedQuadrantForRotation = _getQuadrantIndex(r, c);
      final pname = _playerNames[currentPid] ?? "Player";
      _lastAction = "$pname placed marble at ($r, $c). Choose a 3x3 quadrant to rotate.";
    });
  }

  int _getQuadrantIndex(int r, int c) {
    if (r < 3 && c < 3) return 0;
    if (r < 3 && c >= 3) return 1;
    if (r >= 3 && c < 3) return 2;
    return 3;
  }

  void _onRotateQuadrant(int quadrant, String direction) async {
    if (_status != 'in_progress' || _phase != 'rotate_quadrant') return;
    final currentPid = _playerIds[_currentTurnIndex];

    if (widget.mode == 'online' && widget.roomCode != null) {
      if (currentPid != widget.localPlayerId) return;
      try {
        final api = ref.read(platformApiServiceProvider);
        await api.submitMove(
          roomCode: widget.roomCode!,
          playerId: widget.localPlayerId!,
          move: {'action': 'rotate_quadrant', 'quadrant': quadrant, 'direction': direction},
        );
      } catch (_) {}
      return;
    }

    // Local Mode Rotation Execution
    setState(() {
      _rotateLocalQuadrant(quadrant, direction);
      _phase = 'place_marble';
      _selectedQuadrantForRotation = null;

      // Win check
      final p1Wins = _check5InARow("p1");
      final p2Wins = _check5InARow("p2");

      if (p1Wins && p2Wins) {
        _status = 'draw';
        _winnerName = "Draw";
        _lastAction = "Simultaneous 5-in-a-row achieved! Match is a Draw!";
        _recordPentagoResult("Draw");
      } else if (p1Wins) {
        _status = 'won';
        _winnerName = _playerNames["p1"];
        _lastAction = "Victory! $_winnerName connected 5 in a row!";
        _recordPentagoResult(_winnerName);
      } else if (p2Wins) {
        _status = 'won';
        _winnerName = _playerNames["p2"];
        _lastAction = "Victory! $_winnerName connected 5 in a row!";
        _recordPentagoResult(_winnerName);
      } else {
        _currentTurnIndex = (_currentTurnIndex + 1) % _playerIds.length;
        final nextName = _playerNames[_playerIds[_currentTurnIndex]] ?? "Player";
        _lastAction = "Quadrant rotated. $nextName's turn to place marble.";
      }
    });
  }

  bool _statsRecorded = false;

  void _recordPentagoResult(String? winner) {
    if (_statsRecorded) return;
    _statsRecorded = true;
    try {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.userId == null) return;

      final myPid = widget.localPlayerId ?? 'p1';
      final myName = _playerNames[myPid] ?? 'Player';

      String outcome = 'loss';
      if (winner == myName) {
        outcome = 'win';
      } else if (winner == 'Draw') {
        outcome = 'tie';
      }

      final section = widget.mode == 'online' ? 'multiplayer' : 'classic';

      ref.read(platformApiServiceProvider).recordGameResult(
        userId: auth.userId!,
        gameId: 'pentago',
        sectionId: section,
        outcome: outcome,
        score: outcome == 'win' ? 100 : 0,
        details: {
          'winner': winner,
          'mode': widget.mode,
        },
        extraStatsUpdate: {
          'pentago_wins': outcome == 'win' ? 1 : 0,
        },
      );
    } catch (_) {}
  }

  void _rotateLocalQuadrant(int quadrant, String direction) {
    int rStart = (quadrant == 0 || quadrant == 1) ? 0 : 3;
    int rEnd = rStart + 3;
    int cStart = (quadrant == 0 || quadrant == 2) ? 0 : 3;
    int cEnd = cStart + 3;

    final sub = List.generate(3, (r) => List.generate(3, (c) => _board[rStart + r][cStart + c]));
    final rot = List.generate(3, (_) => List<String?>.filled(3, null));

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (direction == 'cw') {
          rot[c][2 - r] = sub[r][c];
        } else {
          rot[2 - c][r] = sub[r][c];
        }
      }
    }

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        _board[rStart + r][cStart + c] = rot[r][c];
      }
    }
  }

  bool _check5InARow(String pid) {
    // Horizontal
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 2; c++) {
        if (List.generate(5, (i) => _board[r][c + i]).every((cell) => cell == pid)) return true;
      }
    }
    // Vertical
    for (int c = 0; c < 6; c++) {
      for (int r = 0; r < 2; r++) {
        if (List.generate(5, (i) => _board[r + i][c]).every((cell) => cell == pid)) return true;
      }
    }
    // Diagonal \
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 2; c++) {
        if (List.generate(5, (i) => _board[r + i][c + i]).every((cell) => cell == pid)) return true;
      }
    }
    // Anti-Diagonal /
    for (int r = 0; r < 2; r++) {
      for (int c = 4; c < 6; c++) {
        if (List.generate(5, (i) => _board[r + i][c - i]).every((cell) => cell == pid)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentPid = _playerIds[_currentTurnIndex];
    final currentColor = _marbleColors[currentPid] ?? const Color(0xFFD5A84B);
    final isRotatePhase = _phase == 'rotate_quadrant';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0D),
      appBar: PlatformAppBar(
        title: widget.roomCode != null ? "PENTAGO · ${widget.roomCode}" : "PENTAGO",
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Duel Status Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141412),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A26)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _playerIds.map((pid) {
                      final isCurrent = pid == currentPid && _status == 'in_progress';
                      final color = _marbleColors[pid]!;
                      final name = _playerNames[pid] ?? pid;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent ? color.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isCurrent ? color : Colors.transparent, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              name.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: const Color(0xFFF1EBDD)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                // Phase Instruction Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isRotatePhase ? const Color(0xFF48BB78).withOpacity(0.15) : const Color(0xFF181816),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isRotatePhase ? const Color(0xFF48BB78) : const Color(0xFF2A2A26)),
                  ),
                  child: Center(
                    child: Text(
                      _lastAction,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isRotatePhase ? FontWeight.bold : FontWeight.w500,
                        color: isRotatePhase ? const Color(0xFF48BB78) : const Color(0xFFA9A396),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4-Quadrant 6x6 Pentago Board
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14241B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF48BB78).withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuadrantWidget(0, "Top-Left"),
                          const SizedBox(width: 8),
                          _buildQuadrantWidget(1, "Top-Right"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuadrantWidget(2, "Bottom-Left"),
                          const SizedBox(width: 8),
                          _buildQuadrantWidget(3, "Bottom-Right"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Winner Dialog
                if (_status != 'in_progress')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF48BB78).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF48BB78), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _status == 'draw' ? "SIMULTANEOUS 5-IN-A-ROW DRAW" : "$_winnerName VICTORY!",
                          style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFFF1EBDD)),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48BB78), foregroundColor: const Color(0xFF0F0F0D)),
                          onPressed: () => context.go('/'),
                          child: const Text("RETURN TO PLATFORM"),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuadrantWidget(int quadIndex, String quadName) {
    int rStart = (quadIndex == 0 || quadIndex == 1) ? 0 : 3;
    int cStart = (quadIndex == 0 || quadIndex == 2) ? 0 : 3;
    final isSelected = _selectedQuadrantForRotation == quadIndex;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3227),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFFD5A84B) : const Color(0xFF2E4839),
          width: isSelected ? 2.0 : 1.2,
        ),
      ),
      child: Column(
        children: [
          // 3x3 Grid
          Column(
            children: List.generate(3, (rOffset) {
              final r = rStart + rOffset;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (cOffset) {
                  final c = cStart + cOffset;
                  final occupant = _board[r][c];
                  final marbleColor = occupant != null ? _marbleColors[occupant] : null;

                  return InkWell(
                    onTap: () => _onCellTap(r, c),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14241B),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E4839)),
                      ),
                      child: marbleColor != null
                          ? Center(
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: marbleColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              );
            }),
          ),

          const SizedBox(height: 6),

          // Quadrant Rotation Action Buttons
          if (_phase == 'rotate_quadrant')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.rotate_left, size: 18, color: Color(0xFFD5A84B)),
                  tooltip: "Rotate Counter-Clockwise",
                  onPressed: () => _onRotateQuadrant(quadIndex, 'ccw'),
                ),
                Text(
                  quadName,
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396)),
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right, size: 18, color: Color(0xFFD5A84B)),
                  tooltip: "Rotate Clockwise",
                  onPressed: () => _onRotateQuadrant(quadIndex, 'cw'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
