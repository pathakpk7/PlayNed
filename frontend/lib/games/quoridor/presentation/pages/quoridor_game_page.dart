import 'dart:async';
import 'dart:collection';
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

class QuoridorGamePage extends ConsumerStatefulWidget {
  final String? roomCode;
  final String? localPlayerId;
  final String mode; // 'local' or 'online'
  final int playerCount;

  const QuoridorGamePage({
    super.key,
    this.roomCode,
    this.localPlayerId,
    this.mode = 'local',
    this.playerCount = 2,
  });

  @override
  ConsumerState<QuoridorGamePage> createState() => _QuoridorGamePageState();
}

class _QuoridorGamePageState extends ConsumerState<QuoridorGamePage> {
  static const int boardSize = 9;

  // Pawn & Wall State
  Map<String, Map<String, dynamic>> _pawns = {};
  List<Map<String, dynamic>> _hWalls = [];
  List<Map<String, dynamic>> _vWalls = [];
  List<String> _playerIds = [];
  Map<String, String> _playerNames = {};
  int _currentTurnIndex = 0;
  String _status = 'in_progress';
  String? _winnerName;
  String _lastAction = 'Move your pawn or place a 2-space wall.';

  // Mode Selection: 'move' or 'wall_h' or 'wall_v'
  String _selectedAction = 'move';

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
    _playerIds = widget.playerCount == 4 ? ["p1", "p2", "p3", "p4"] : ["p1", "p2"];
    _playerNames = {
      "p1": p1Name,
      "p2": "Player 2",
      if (widget.playerCount == 4) "p3": "Player 3",
      if (widget.playerCount == 4) "p4": "Player 4",
    };

    final wallsPerPlayer = widget.playerCount == 4 ? 5 : 10;
    _pawns = {
      "p1": {"r": 8, "c": 4, "goal_type": "row", "goal_val": 0, "color": const Color(0xFF4E89FF), "walls_left": wallsPerPlayer},
      "p2": {"r": 0, "c": 4, "goal_type": "row", "goal_val": 8, "color": const Color(0xFFE57373), "walls_left": wallsPerPlayer},
    };
    if (widget.playerCount == 4) {
      _pawns["p3"] = {"r": 4, "c": 0, "goal_type": "col", "goal_val": 8, "color": const Color(0xFF81C784), "walls_left": wallsPerPlayer};
      _pawns["p4"] = {"r": 4, "c": 8, "goal_type": "col", "goal_val": 0, "color": const Color(0xFFFFD54F), "walls_left": wallsPerPlayer};
    }
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
      _hWalls = List<Map<String, dynamic>>.from(state['horizontal_walls'] ?? []);
      _vWalls = List<Map<String, dynamic>>.from(state['vertical_walls'] ?? []);
      _playerIds = List<String>.from(state['player_ids'] ?? []);
      _playerNames = Map<String, String>.from(state['player_names'] ?? {});
      _currentTurnIndex = state['current_turn_index'] ?? 0;
      _status = state['status'] ?? 'in_progress';
      _winnerName = state['winner_name'];
      _lastAction = state['last_action'] ?? '';

      final rawPawns = state['pawns'] as Map<String, dynamic>? ?? {};
      _pawns = {};
      final colors = [const Color(0xFF4E89FF), const Color(0xFFE57373), const Color(0xFF81C784), const Color(0xFFFFD54F)];
      int idx = 0;
      rawPawns.forEach((k, v) {
        final pMap = Map<String, dynamic>.from(v as Map);
        pMap['color'] = colors[idx % colors.length];
        _pawns[k] = pMap;
        idx++;
      });
    });
  }

  bool _isWallBlocking(int r1, int c1, int r2, int c2) {
    if (c1 == c2) {
      final minR = r1 < r2 ? r1 : r2;
      for (final w in _hWalls) {
        final wr = w['r'] as int;
        final wc = w['c'] as int;
        if (wr == minR && (wc == c1 || wc == c1 - 1)) return true;
      }
    } else if (r1 == r2) {
      final minC = c1 < c2 ? c1 : c2;
      for (final w in _vWalls) {
        final wr = w['r'] as int;
        final wc = w['c'] as int;
        if (wc == minC && (wr == r1 || wr == r1 - 1)) return true;
      }
    }
    return false;
  }

  List<(int, int)> _getLegalPawnMoves(String pid) {
    final pawn = _pawns[pid];
    if (pawn == null) return [];
    final pr = pawn['r'] as int;
    final pc = pawn['c'] as int;

    final occupied = <(int, int)>{};
    _pawns.forEach((k, v) {
      if (k != pid) occupied.add((v['r'] as int, v['c'] as int));
    });

    final moves = <(int, int)>[];
    final dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final (dr, dc) in dirs) {
      final nr = pr + dr;
      final nc = pc + dc;
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
        if (!_isWallBlocking(pr, pc, nr, nc)) {
          if (occupied.contains((nr, nc))) {
            // Jump straight over
            final jr = nr + dr;
            final jc = nc + dc;
            if (jr >= 0 && jr < boardSize && jc >= 0 && jc < boardSize &&
                !_isWallBlocking(nr, nc, jr, jc) && !occupied.contains((jr, jc))) {
              moves.add((jr, jc));
            } else {
              // Diagonal side jumps
              for (final (sdr, sdc) in dirs) {
                if ((sdr, sdc) != (dr, dc) && (sdr, sdc) != (-dr, -dc)) {
                  final dnr = nr + sdr;
                  final dnc = nc + sdc;
                  if (dnr >= 0 && dnr < boardSize && dnc >= 0 && dnc < boardSize &&
                      !_isWallBlocking(nr, nc, dnr, dnc) && !occupied.contains((dnr, dnc))) {
                    moves.add((dnr, dnc));
                  }
                }
              }
            }
          } else {
            moves.add((nr, nc));
          }
        }
      }
    }
    return moves;
  }

  void _onCellTap(int r, int c) async {
    if (_status != 'in_progress') return;
    final currentPid = _playerIds.isNotEmpty ? _playerIds[_currentTurnIndex] : "p1";

    if (widget.mode == 'online' && widget.roomCode != null) {
      if (currentPid != widget.localPlayerId) return;
      final legalMoves = _getLegalPawnMoves(currentPid);
      if (!legalMoves.contains((r, c))) return;

      try {
        final api = ref.read(platformApiServiceProvider);
        await api.submitMove(
          roomCode: widget.roomCode!,
          playerId: widget.localPlayerId!,
          move: {'action': 'move_pawn', 'r': r, 'c': c},
        );
      } catch (_) {}
      return;
    }

    // Local Move
    final legalMoves = _getLegalPawnMoves(currentPid);
    if (!legalMoves.contains((r, c))) return;

    setState(() {
      final pawn = _pawns[currentPid]!;
      pawn['r'] = r;
      pawn['c'] = c;
      final pname = _playerNames[currentPid] ?? "Player";

      // Win check
      if ((pawn['goal_type'] == 'row' && r == pawn['goal_val']) ||
          (pawn['goal_type'] == 'col' && c == pawn['goal_val'])) {
        _status = 'won';
        _winnerName = pname;
        _lastAction = "$pname reached the goal line and WON!";
        _recordQuoridorResult(pname);
        return;
      }

      _currentTurnIndex = (_currentTurnIndex + 1) % _playerIds.length;
      final nextName = _playerNames[_playerIds[_currentTurnIndex]] ?? "Player";
      _lastAction = "$pname moved pawn to ($r, $c). $nextName's turn.";
    });
  }

  bool _statsRecorded = false;

  void _recordQuoridorResult(String winner) {
    if (_statsRecorded) return;
    _statsRecorded = true;
    try {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.userId == null) return;

      final myPid = widget.localPlayerId ?? 'p1';
      final isWin = winner == (_playerNames[myPid] ?? 'Player');

      final section = widget.mode == 'online' ? 'multiplayer' : 'classic';

      ref.read(platformApiServiceProvider).recordGameResult(
        userId: auth.userId!,
        gameId: 'quoridor',
        sectionId: section,
        outcome: isWin ? 'win' : 'loss',
        score: isWin ? 100 : 0,
        details: {
          'winner': winner,
          'mode': widget.mode,
        },
        extraStatsUpdate: {
          'quoridor_wins': isWin ? 1 : 0,
        },
      );
    } catch (_) {}
  }

  void _onWallTap(String orientation, int wr, int wc) async {
    if (_status != 'in_progress') return;
    final currentPid = _playerIds.isNotEmpty ? _playerIds[_currentTurnIndex] : "p1";
    final pawn = _pawns[currentPid];
    if (pawn == null || (pawn['walls_left'] as int) <= 0) return;

    if (widget.mode == 'online' && widget.roomCode != null) {
      if (currentPid != widget.localPlayerId) return;
      try {
        final api = ref.read(platformApiServiceProvider);
        await api.submitMove(
          roomCode: widget.roomCode!,
          playerId: widget.localPlayerId!,
          move: {'action': 'place_wall', 'wall_type': orientation, 'r': wr, 'c': wc},
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Cannot place wall: $e")),
          );
        }
      }
      return;
    }

    // Local Placement Validation & Application
    // Overlap checks
    if (orientation == 'h') {
      for (final vw in _vWalls) {
        if (vw['r'] == wr && vw['c'] == wc) return;
      }
      for (final hw in _hWalls) {
        if (hw['r'] == wr && (hw['c'] == wc || hw['c'] == wc - 1 || hw['c'] == wc + 1)) return;
      }
    } else {
      for (final hw in _hWalls) {
        if (hw['r'] == wr && hw['c'] == wc) return;
      }
      for (final vw in _vWalls) {
        if (vw['c'] == wc && (vw['r'] == wr || vw['r'] == wr - 1 || vw['r'] == wr + 1)) return;
      }
    }

    setState(() {
      final wallObj = {'r': wr, 'c': wc, 'placed_by': currentPid};
      if (orientation == 'h') {
        _hWalls.add(wallObj);
      } else {
        _vWalls.add(wallObj);
      }

      pawn['walls_left'] = (pawn['walls_left'] as int) - 1;
      final pname = _playerNames[currentPid] ?? "Player";
      _currentTurnIndex = (_currentTurnIndex + 1) % _playerIds.length;
      final nextName = _playerNames[_playerIds[_currentTurnIndex]] ?? "Player";
      _lastAction = "$pname placed a wall. $nextName's turn.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPid = _playerIds.isNotEmpty ? _playerIds[_currentTurnIndex] : "p1";
    final currentPawn = _pawns[currentPid];
    final legalMoves = _status == 'in_progress' ? _getLegalPawnMoves(currentPid) : <(int, int)>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0D),
      appBar: PlatformAppBar(
        title: widget.roomCode != null ? "QUORIDOR · ${widget.roomCode}" : "QUORIDOR",
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                // Score & Wall Inventory Bar
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
                      final pData = _pawns[pid];
                      final color = pData?['color'] as Color? ?? const Color(0xFFE57373);
                      final name = _playerNames[pid] ?? pid;
                      final wallsLeft = pData?['walls_left'] ?? 10;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent ? color.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isCurrent ? color : Colors.transparent, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(
                                  name.toUpperCase(),
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, color: isCurrent ? color : const Color(0xFFA9A396)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$wallsLeft WALLS",
                              style: GoogleFonts.dmSerifDisplay(fontSize: 15, color: const Color(0xFFF1EBDD)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                // Action Mode Switcher (Move Pawn vs Place Wall H vs Place Wall V)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionChip(
                      label: "MOVE PAWN",
                      icon: Icons.pan_tool_alt,
                      isSelected: _selectedAction == 'move',
                      onTap: () => setState(() => _selectedAction = 'move'),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: "WALL HORIZONTAL",
                      icon: Icons.border_horizontal,
                      isSelected: _selectedAction == 'wall_h',
                      onTap: () => setState(() => _selectedAction = 'wall_h'),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: "WALL VERTICAL",
                      icon: Icons.border_vertical,
                      isSelected: _selectedAction == 'wall_v',
                      onTap: () => setState(() => _selectedAction = 'wall_v'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181816),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2A2A26)),
                  ),
                  child: Center(
                    child: Text(
                      _lastAction,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 9x9 Quoridor Board
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1515),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE57373).withOpacity(0.3), width: 1.5),
                  ),
                  child: _buildQuoridorBoard(legalMoves),
                ),

                const SizedBox(height: 20),

                if (_status != 'in_progress')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE57373), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text("$_winnerName REACHED THE GOAL!", style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFFF1EBDD))),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE57373), foregroundColor: const Color(0xFF0F0F0D)),
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

  Widget _buildQuoridorBoard(List<(int, int)> legalMoves) {
    const double cellSize = 36.0;
    const double wallGap = 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(boardSize, (r) {
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(boardSize, (c) {
                // Find if pawn is on (r, c)
                String? occupantPid;
                Color? occupantColor;
                _pawns.forEach((pid, pData) {
                  if (pData['r'] == r && pData['c'] == c) {
                    occupantPid = pid;
                    occupantColor = pData['color'] as Color?;
                  }
                });

                final isLegal = legalMoves.contains((r, c));

                return Row(
                  children: [
                    // Board Square
                    InkWell(
                      onTap: () => _onCellTap(r, c),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: isLegal
                              ? const Color(0xFFD5A84B).withOpacity(0.3)
                              : const Color(0xFF261E1E),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isLegal ? const Color(0xFFD5A84B) : const Color(0xFF382A2A),
                            width: isLegal ? 1.5 : 1.0,
                          ),
                        ),
                        child: occupantPid != null
                            ? Center(
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: occupantColor ?? const Color(0xFFE57373),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      (_playerNames[occupantPid!] ?? 'P')[0].toUpperCase(),
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F0F0D)),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),

                    // Vertical Wall Slot (if c < 8)
                    if (c < boardSize - 1)
                      InkWell(
                        onTap: () => _onWallTap('v', r, c),
                        child: Container(
                          width: wallGap,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: _hasVerticalWallAt(r, c)
                                ? const Color(0xFFE57373)
                                : (_selectedAction == 'wall_v' ? const Color(0xFF382A2A) : Colors.transparent),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),

            // Horizontal Wall Row (if r < 8)
            if (r < boardSize - 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(boardSize, (c) {
                  return Row(
                    children: [
                      InkWell(
                        onTap: () => _onWallTap('h', r, c),
                        child: Container(
                          width: cellSize,
                          height: wallGap,
                          decoration: BoxDecoration(
                            color: _hasHorizontalWallAt(r, c)
                                ? const Color(0xFFE57373)
                                : (_selectedAction == 'wall_h' ? const Color(0xFF382A2A) : Colors.transparent),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (c < boardSize - 1)
                        Container(width: wallGap, height: wallGap, color: const Color(0xFF181212)),
                    ],
                  );
                }),
              ),
          ],
        );
      }),
    );
  }

  bool _hasHorizontalWallAt(int r, int c) {
    for (final hw in _hWalls) {
      final wr = hw['r'] as int;
      final wc = hw['c'] as int;
      if (wr == r && (wc == c || wc == c - 1)) return true;
    }
    return false;
  }

  bool _hasVerticalWallAt(int r, int c) {
    for (final vw in _vWalls) {
      final wr = vw['r'] as int;
      final wc = vw['c'] as int;
      if (wc == c && (wr == r || wr == r - 1)) return true;
    }
    return false;
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE57373).withOpacity(0.18) : const Color(0xFF181816),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFFE57373) : const Color(0xFF2A2A26), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFFE57373) : const Color(0xFFA9A396)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFE57373) : const Color(0xFFA9A396),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
