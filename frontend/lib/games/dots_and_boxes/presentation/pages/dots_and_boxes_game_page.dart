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

class DotsAndBoxesGamePage extends ConsumerStatefulWidget {
  final String? roomCode;
  final String? localPlayerId;
  final String mode; // 'local' or 'online'
  final int gridRows;
  final int gridCols;
  final int playerCount;

  const DotsAndBoxesGamePage({
    super.key,
    this.roomCode,
    this.localPlayerId,
    this.mode = 'local',
    this.gridRows = 4,
    this.gridCols = 4,
    this.playerCount = 2,
  });

  @override
  ConsumerState<DotsAndBoxesGamePage> createState() => _DotsAndBoxesGamePageState();
}

class _DotsAndBoxesGamePageState extends ConsumerState<DotsAndBoxesGamePage> {
  // Game State
  late int _gridRows;
  late int _gridCols;
  late int _boxRows;
  late int _boxCols;

  final Map<String, String> _hLines = {}; // "r,c" -> pid
  final Map<String, String> _vLines = {}; // "r,c" -> pid
  final Map<String, String> _boxes = {};  // "r,c" -> pid
  final Map<String, int> _scores = {};
  List<String> _playerIds = [];
  Map<String, String> _playerNames = {};
  int _currentTurnIndex = 0;
  String _status = 'in_progress'; // in_progress, won, draw
  String? _winnerName;
  String _lastAction = 'Tap any dashed line to connect dots.';
  bool _bonusTurn = false;

  final List<Color> _playerColors = [
    const Color(0xFF4E89FF), // Blue
    const Color(0xFFE57373), // Red
    const Color(0xFF81C784), // Green
    const Color(0xFFFFD54F), // Yellow
  ];

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _gridRows = widget.gridRows.clamp(4, 9);
    _gridCols = widget.gridCols.clamp(4, 9);
    _boxRows = _gridRows - 1;
    _boxCols = _gridCols - 1;

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
    _playerIds = List.generate(widget.playerCount, (i) => "p${i + 1}");
    _playerNames = {
      for (int i = 0; i < widget.playerCount; i++)
        "p${i + 1}": i == 0 ? p1Name : "Player ${i + 1}"
    };
    for (final pid in _playerIds) {
      _scores[pid] = 0;
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
      _gridRows = (state['grid_rows'] as int? ?? _gridRows).clamp(4, 9);
      _gridCols = (state['grid_cols'] as int? ?? _gridCols).clamp(4, 9);
      _boxRows = _gridRows - 1;
      _boxCols = _gridCols - 1;

      _hLines.clear();
      (state['horizontal_lines'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        _hLines[k] = v.toString();
      });

      _vLines.clear();
      (state['vertical_lines'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        _vLines[k] = v.toString();
      });

      _boxes.clear();
      (state['boxes'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        _boxes[k] = v.toString();
      });

      _scores.clear();
      (state['scores'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        _scores[k] = int.tryParse(v.toString()) ?? 0;
      });

      _playerIds = List<String>.from(state['player_ids'] ?? []);
      _playerNames = Map<String, String>.from(state['player_names'] ?? {});
      _currentTurnIndex = state['current_turn_index'] ?? 0;
      _status = state['status'] ?? 'in_progress';
      _winnerName = state['winner_name'];
      _lastAction = state['last_action'] ?? '';
      _bonusTurn = state['bonus_turn'] ?? false;
    });
  }

  void _onLineTap(String type, int r, int c) async {
    if (_status != 'in_progress') return;

    final key = "$r,$c";
    if (type == 'h' && _hLines.containsKey(key)) return;
    if (type == 'v' && _vLines.containsKey(key)) return;

    final currentPid = _playerIds.isNotEmpty ? _playerIds[_currentTurnIndex] : "p1";

    if (widget.mode == 'online' && widget.roomCode != null) {
      if (currentPid != widget.localPlayerId) return;
      try {
        final api = ref.read(platformApiServiceProvider);
        await api.submitMove(
          roomCode: widget.roomCode!,
          playerId: widget.localPlayerId!,
          move: {'type': type, 'r': r, 'c': c},
        );
      } catch (_) {}
      return;
    }

    // Local Mode Execution
    setState(() {
      if (type == 'h') {
        _hLines[key] = currentPid;
      } else {
        _vLines[key] = currentPid;
      }

      // Check completed boxes
      final completed = <String>[];
      final candidateBoxes = type == 'h' ? [(r - 1, c), (r, c)] : [(r, c - 1), (r, c)];

      for (final (br, bc) in candidateBoxes) {
        if (br >= 0 && br < _boxRows && bc >= 0 && bc < _boxCols) {
          final bKey = "$br,$bc";
          if (!_boxes.containsKey(bKey)) {
            final top = _hLines.containsKey("$br,$bc");
            final bottom = _hLines.containsKey("${br + 1},$bc");
            final left = _vLines.containsKey("$br,$bc");
            final right = _vLines.containsKey("$br,${bc + 1}");
            if (top && bottom && left && right) {
              _boxes[bKey] = currentPid;
              completed.add(bKey);
            }
          }
        }
      }

      final pname = _playerNames[currentPid] ?? "Player";
      final pInitial = pname.trim().isNotEmpty ? pname.trim()[0].toUpperCase() : 'P';

      if (completed.isNotEmpty) {
        _scores[currentPid] = (_scores[currentPid] ?? 0) + completed.length;
        _bonusTurn = true;
        _lastAction = "$pname ($pInitial) completed ${completed.length} box! Bonus turn.";
      } else {
        _bonusTurn = false;
        _currentTurnIndex = (_currentTurnIndex + 1) % _playerIds.length;
        final nextName = _playerNames[_playerIds[_currentTurnIndex]] ?? "Player";
        _lastAction = "$pname drew a line. $nextName's turn.";
      }

      // Game End Check
      if (_boxes.length >= _boxRows * _boxCols) {
        int maxScore = -1;
        String? bestPid;
        bool isTie = false;

        _scores.forEach((pid, sc) {
          if (sc > maxScore) {
            maxScore = sc;
            bestPid = pid;
            isTie = false;
          } else if (sc == maxScore) {
            isTie = true;
          }
        });

        if (isTie) {
          _status = 'draw';
          _winnerName = "Draw";
          _lastAction = "Game over! Draw with $maxScore boxes each.";
        } else {
          _status = 'won';
          _winnerName = _playerNames[bestPid];
          _lastAction = "Game over! $_winnerName wins with $maxScore boxes!";
        }
      }
    });
  }

  void _showRenameDialog(String pid) {
    final controller = TextEditingController(text: _playerNames[pid] ?? "");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181816),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF4E89FF), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF4E89FF), size: 18),
            const SizedBox(width: 8),
            Text(
              "RENAME PLAYER",
              style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter custom player name. The first letter will be marked inside captured boxes:",
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF1EBDD)),
              decoration: const InputDecoration(
                labelText: "Player Name",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.inter(color: const Color(0xFFA9A396))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4E89FF),
              foregroundColor: const Color(0xFF0F0F0D),
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _playerNames[pid] = newName;
                });
                Navigator.pop(ctx);
              }
            },
            child: Text("SAVE", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBoardSizeDialog() {
    int tempSize = _gridRows;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF181816),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF4E89FF), width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.grid_4x4, color: Color(0xFF4E89FF), size: 20),
              const SizedBox(width: 8),
              Text(
                "SELECT BOARD SIZE",
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose grid dimension from 4x4 up to 9x9:",
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [4, 5, 6, 7, 8, 9].map((size) {
                  final isSelected = tempSize == size;
                  final boxCount = (size - 1) * (size - 1);
                  return ChoiceChip(
                    label: Text(
                      "$size×$size ($boxCount boxes)",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0F0F0D) : const Color(0xFFF1EBDD),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4E89FF),
                    backgroundColor: const Color(0xFF2A2A26),
                    onSelected: (val) {
                      if (val) {
                        setModalState(() => tempSize = size);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("CANCEL", style: GoogleFonts.inter(color: const Color(0xFFA9A396))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E89FF),
                foregroundColor: const Color(0xFF0F0F0D),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _resetGameWithNewSize(tempSize);
              },
              child: Text("APPLY & RESTART", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _resetGameWithNewSize(int newSize) {
    setState(() {
      _gridRows = newSize.clamp(4, 9);
      _gridCols = newSize.clamp(4, 9);
      _boxRows = _gridRows - 1;
      _boxCols = _gridCols - 1;
      _hLines.clear();
      _vLines.clear();
      _boxes.clear();
      for (final p in _playerIds) {
        _scores[p] = 0;
      }
      _currentTurnIndex = 0;
      _status = 'in_progress';
      _lastAction = 'Started ${_gridRows}x${_gridCols} game (${_boxRows * _boxCols} boxes).';
      _bonusTurn = false;
    });
  }

  Color _getPlayerColor(String? pid) {
    if (pid == null) return Colors.transparent;
    final idx = _playerIds.indexOf(pid);
    if (idx >= 0 && idx < _playerColors.length) {
      return _playerColors[idx];
    }
    return const Color(0xFF4E89FF);
  }

  String _getPlayerInitial(String? pid) {
    if (pid == null) return '';
    final name = _playerNames[pid] ?? 'P';
    return name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';
  }

  @override
  Widget build(BuildContext context) {
    final currentPid = _playerIds.isNotEmpty ? _playerIds[_currentTurnIndex] : "p1";
    final currentColor = _getPlayerColor(currentPid);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0D),
      appBar: PlatformAppBar(
        title: widget.roomCode != null ? "DOTS & BOXES · ${widget.roomCode}" : "DOTS & BOXES",
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                // Top Configuration Row (Board Size & Edit Names)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showBoardSizeDialog,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181816),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF4E89FF).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.grid_4x4, size: 14, color: Color(0xFF4E89FF)),
                            const SizedBox(width: 6),
                            Text(
                              "BOARD: ${_gridRows}×${_gridCols} (${_boxRows * _boxCols} BOXES)",
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF1EBDD),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFFA9A396)),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      "TAP PLAYER NAME TO RENAME",
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA9A396),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Scoreboard Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141412),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A26)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _playerIds.map((pid) {
                      final isCurrent = pid == currentPid && _status == 'in_progress';
                      final color = _getPlayerColor(pid);
                      final name = _playerNames[pid] ?? pid;
                      final initial = _getPlayerInitial(pid);
                      final score = _scores[pid] ?? 0;

                      return InkWell(
                        onTap: () => _showRenameDialog(pid),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCurrent ? color.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCurrent ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F0F0D),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    name.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                      color: isCurrent ? color : const Color(0xFFA9A396),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, size: 10, color: Color(0xFFA9A396)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$score BOXES",
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 18,
                                  color: const Color(0xFFF1EBDD),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                // Status Action Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bonusTurn ? const Color(0xFF48BB78).withOpacity(0.12) : const Color(0xFF181816),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _bonusTurn ? const Color(0xFF48BB78).withOpacity(0.5) : const Color(0xFF2A2A26),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _lastAction,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: _bonusTurn ? FontWeight.bold : FontWeight.w500,
                        color: _bonusTurn ? const Color(0xFF48BB78) : const Color(0xFFA9A396),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Interactive 2D Grid with Adaptive Sizing
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxAvailableWidth = constraints.maxWidth - 40;
                    // Compute adaptive dimensions based on grid count (4 to 9)
                    final double boxDimension = ((maxAvailableWidth - (_gridCols * 12.0)) / (_gridCols - 1))
                        .clamp(32.0, 72.0);
                    final double dotSize = (boxDimension * 0.22).clamp(8.0, 14.0);
                    final double lineThickness = (boxDimension * 0.12).clamp(5.0, 8.0);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121620),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4E89FF).withOpacity(0.3), width: 1.5),
                      ),
                      child: _buildAdaptiveGrid(currentColor, boxDimension, dotSize, lineThickness),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Winner Dialog / Game Over Bar
                if (_status != 'in_progress')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4E89FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4E89FF), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _status == 'draw' ? "GAME TIED" : "$_winnerName VICTORY!",
                          style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD)),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4E89FF),
                            foregroundColor: const Color(0xFF0F0F0D),
                          ),
                          onPressed: () {
                            if (widget.mode == 'local') {
                              _resetGameWithNewSize(_gridRows);
                            } else {
                              context.go('/');
                            }
                          },
                          icon: const Icon(Icons.replay, size: 16),
                          label: Text(widget.mode == 'local' ? "PLAY AGAIN" : "RETURN TO LOBBY"),
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

  Widget _buildAdaptiveGrid(Color currentColor, double boxDimension, double dotSize, double lineThickness) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_gridRows, (r) {
        return Column(
          children: [
            // Row of Dots and Horizontal Line Segments
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_gridCols, (c) {
                return Row(
                  children: [
                    // Dot
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1EBDD),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Horizontal line to right dot (if c < _gridCols - 1)
                    if (c < _gridCols - 1)
                      InkWell(
                        onTap: () => _onLineTap('h', r, c),
                        child: Container(
                          width: boxDimension,
                          height: dotSize + 12,
                          alignment: Alignment.center,
                          child: Container(
                            height: lineThickness,
                            decoration: BoxDecoration(
                              color: _hLines.containsKey("$r,$c")
                                  ? _getPlayerColor(_hLines["$r,$c"])
                                  : const Color(0xFF2A2A26),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),

            // Row of Vertical Lines and Box Spaces (if r < _gridRows - 1)
            if (r < _gridRows - 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_gridCols, (c) {
                  return Row(
                    children: [
                      // Vertical Line below dot
                      InkWell(
                        onTap: () => _onLineTap('v', r, c),
                        child: Container(
                          width: dotSize + 12,
                          height: boxDimension,
                          alignment: Alignment.center,
                          child: Container(
                            width: lineThickness,
                            decoration: BoxDecoration(
                              color: _vLines.containsKey("$r,$c")
                                  ? _getPlayerColor(_vLines["$r,$c"])
                                  : const Color(0xFF2A2A26),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      // Box Interior (if c < _gridCols - 1)
                      if (c < _gridCols - 1)
                        Container(
                          width: boxDimension - 12,
                          height: boxDimension,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _boxes.containsKey("$r,$c")
                                ? _getPlayerColor(_boxes["$r,$c"]).withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _boxes.containsKey("$r,$c")
                              ? Text(
                                  _getPlayerInitial(_boxes["$r,$c"]),
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: (boxDimension * 0.45).clamp(12.0, 24.0),
                                    fontWeight: FontWeight.bold,
                                    color: _getPlayerColor(_boxes["$r,$c"]),
                                  ),
                                )
                              : null,
                        ),
                    ],
                  );
                }),
              ),
          ],
        );
      }),
    );
  }
}
