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
import 'package:hangman_reimagined/games/ultimate_tic_tac_toe/models/ultimate_tic_tac_toe_state.dart';

class UltimateTicTacToeGamePage extends ConsumerStatefulWidget {
  final String? roomCode;
  final String? localPlayerId;
  final String mode; // 'local' or 'online'

  const UltimateTicTacToeGamePage({
    super.key,
    this.roomCode,
    this.localPlayerId,
    this.mode = 'local',
  });

  @override
  ConsumerState<UltimateTicTacToeGamePage> createState() => _UltimateTicTacToeGamePageState();
}

class _UltimateTicTacToeGamePageState extends ConsumerState<UltimateTicTacToeGamePage>
    with SingleTickerProviderStateMixin {
  // State Model
  late UltimateTicTacToeState _gameState;
  List<String> _playerIds = ["p1", "p2"];
  Map<String, String> _playerNames = {"p1": "Player 1", "p2": "Player 2"};
  String? _localPlayerMark; // 'X' or 'O' in online mode
  bool _isAiThinking = false;
  bool _statsRecorded = false;

  // Visual Palette
  static const Color _colorX = Color(0xFF38BDF8); // Electric Cyan
  static const Color _colorO = Color(0xFFF59E0B); // Amber Gold
  static const Color _colorDraw = Color(0xFF94A3B8); // Slate
  static const Color _colorBg = Color(0xFF0F1117);
  static const Color _colorMacroCard = Color(0xFF181C26);
  static const Color _colorMicroCard = Color(0xFF222838);

  // Animation controller for active board pulsation
  late AnimationController _glowAnimController;
  late Animation<double> _glowAnim;

  // WebSocket
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  // Winning combinations
  static const List<List<int>> _winCombos = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
    [0, 4, 8], [2, 4, 6],             // Diagonals
  ];

  @override
  void initState() {
    super.initState();
    _glowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowAnimController, curve: Curves.easeInOut),
    );

    _initLocalState();

    if (widget.mode == 'online' && widget.roomCode != null) {
      _initOnlineMode();
    }
  }

  @override
  void dispose() {
    _glowAnimController.dispose();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _initLocalState() {
    final auth = ref.read(authProvider);
    final p1Name = auth.username ?? "Player 1";
    final isAi = widget.mode == 'ai';
    final p2Name = isAi ? "Tactical AI Bot" : "Player 2";
    _playerNames = {"p1": p1Name, "p2": p2Name};
    _playerIds = ["p1", "p2"];
    _gameState = UltimateTicTacToeState.initial(
      p1Id: "p1",
      p2Id: "p2",
      p1Name: p1Name,
      p2Name: p2Name,
    );
    _statsRecorded = false;
    _isAiThinking = false;
  }

  void _initOnlineMode() async {
    final api = ref.read(platformApiServiceProvider);
    final pid = widget.localPlayerId ?? 'p1';

    try {
      final room = await api.getRoom(widget.roomCode!);
      if (room.players.isNotEmpty) {
        _playerIds = room.players.map((p) => p.playerId).toList();
        _playerNames = {for (var p in room.players) p.playerId: p.displayName};
        final pIdx = _playerIds.indexOf(pid);
        _localPlayerMark = pIdx == 0 ? 'X' : (pIdx == 1 ? 'O' : null);
      }

      if (room.matchState != null) {
        _applyBackendState(room.matchState!);
      }

      _wsChannel = api.connectWebSocket(widget.roomCode!, pid);
      _wsSubscription = _wsChannel?.stream.listen((message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          if (data['room'] != null && data['room']['match_state'] != null) {
            _applyBackendState(data['room']['match_state'] as Map<String, dynamic>);
          } else if (data['match_state'] != null) {
            _applyBackendState(data['match_state'] as Map<String, dynamic>);
          }
          if (data['room'] != null) {
            final r = PlatformRoom.fromJson(data['room'] as Map<String, dynamic>);
            if (mounted) {
              setState(() {
                _playerIds = r.players.map((p) => p.playerId).toList();
                _playerNames = {for (var p in r.players) p.playerId: p.displayName};
                final pIdx = _playerIds.indexOf(pid);
                _localPlayerMark = pIdx == 0 ? 'X' : (pIdx == 1 ? 'O' : null);
              });
            }
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void _applyBackendState(Map<String, dynamic> state) {
    if (!mounted) return;
    setState(() {
      _gameState = UltimateTicTacToeState.fromJson(state);
    });
    if (_gameState.status == 'won' || _gameState.status == 'draw') {
      _recordMatchStats(_gameState.status, _gameState.winnerSymbol);
    }
  }

  // --- Local Game Engine Logic ---
  String? _checkMicroWinner(List<String?> cells) {
    for (final combo in _winCombos) {
      final a = cells[combo[0]];
      final b = cells[combo[1]];
      final c = cells[combo[2]];
      if (a != null && a == b && b == c && (a == 'X' || a == 'O')) {
        return a;
      }
    }
    return null;
  }

  List<int>? _getMicroWinningLine(List<String?> cells) {
    for (final combo in _winCombos) {
      final a = cells[combo[0]];
      final b = cells[combo[1]];
      final c = cells[combo[2]];
      if (a != null && a == b && b == c && (a == 'X' || a == 'O')) {
        return combo;
      }
    }
    return null;
  }

  String? _checkMacroWinner(List<String?> macroBoard) {
    for (final combo in _winCombos) {
      final a = macroBoard[combo[0]];
      final b = macroBoard[combo[1]];
      final c = macroBoard[combo[2]];
      if (a != null && a == b && b == c && (a == 'X' || a == 'O')) {
        return a;
      }
    }
    return null;
  }

  List<int>? _getWinningMacroLine(List<String?> macroBoard) {
    for (final combo in _winCombos) {
      final a = macroBoard[combo[0]];
      final b = macroBoard[combo[1]];
      final c = macroBoard[combo[2]];
      if (a != null && a == b && b == c && (a == 'X' || a == 'O')) {
        return combo;
      }
    }
    return null;
  }

  void _handleCellTap(int boardIdx, int cellIdx) {
    if (_gameState.status != 'in_progress' && _gameState.status != 'active') return;
    if (_isAiThinking) return;

    // Check if target board is valid
    final validBoards = _gameState.validBoards;
    if (!validBoards.contains(boardIdx)) return;

    // Check if cell is empty
    if (_gameState.boards[boardIdx].cells[cellIdx] != null) return;

    if (widget.mode == 'online' && widget.roomCode != null) {
      // Validate it's our turn
      if (_localPlayerMark != null && _localPlayerMark != _gameState.currentSymbol) {
        return;
      }
      // Send move to backend via WS
      if (_wsChannel != null) {
        _wsChannel!.sink.add(jsonEncode({
          'type': 'MOVE',
          'action': 'move',
          'move': {
            'board': boardIdx,
            'cell': cellIdx,
            'player': _gameState.currentSymbol,
          },
        }));
      }
      // Also fallback/guarantee via REST API
      final api = ref.read(platformApiServiceProvider);
      final myPid = widget.localPlayerId ?? 'p1';
      api.submitMove(
        roomCode: widget.roomCode!,
        playerId: myPid,
        move: {
          'board': boardIdx,
          'cell': cellIdx,
        },
      ).then((room) {
        if (mounted && room.matchState != null) {
          _applyBackendState(room.matchState!);
        }
      }).catchError((_) {});
      return;
    }

    _executeLocalMove(boardIdx, cellIdx);
  }

  void _executeLocalMove(int boardIdx, int cellIdx) {
    // Local / AI Pass & Play Execution
    final currentMark = _gameState.currentSymbol;
    final currentPid = _gameState.currentTurnPlayerId;
    final currentPName = _playerNames[currentPid] ?? (currentMark == 'X' ? 'Player 1' : 'Player 2');

    final updatedBoards = List<MicroBoardState>.from(_gameState.boards);
    final targetBoard = updatedBoards[boardIdx];
    final updatedCells = List<String?>.from(targetBoard.cells);
    updatedCells[cellIdx] = currentMark;

    // Check micro win/draw
    String? microWinner = targetBoard.winner;
    String microStatus = targetBoard.status;
    List<int>? microWinningLine = targetBoard.winningLine;

    if (microWinner == null) {
      final w = _checkMicroWinner(updatedCells);
      if (w != null) {
        microWinner = w;
        microStatus = 'won';
        microWinningLine = _getMicroWinningLine(updatedCells);
      } else if (!updatedCells.contains(null)) {
        microWinner = 'draw';
        microStatus = 'draw';
      }
    }

    updatedBoards[boardIdx] = MicroBoardState(
      index: boardIdx,
      cells: updatedCells,
      winner: microWinner,
      status: microStatus,
      winningLine: microWinningLine,
    );

    // Update Macro Board
    final updatedMacro = List<String?>.from(_gameState.macroBoard);
    updatedMacro[boardIdx] = microWinner;

    // Count boards won
    final xWon = updatedMacro.where((w) => w == 'X').length;
    final oWon = updatedMacro.where((w) => w == 'O').length;

    // Check macro win / draw
    String status = 'in_progress';
    String? overallWinner = _checkMacroWinner(updatedMacro);
    List<int>? macroWinningLine;
    String? winnerId;
    String? winnerName;
    String? winnerSymbol;

    if (overallWinner != null) {
      status = 'won';
      macroWinningLine = _getWinningMacroLine(updatedMacro);
      winnerSymbol = overallWinner;
      winnerId = overallWinner == 'X' ? _playerIds[0] : _playerIds[1];
      winnerName = _playerNames[winnerId] ?? (overallWinner == 'X' ? 'Player 1' : 'Player 2');
    } else {
      final allCompleted = updatedBoards.every((b) => b.isCompleted);
      if (allCompleted) {
        status = 'draw';
        overallWinner = 'draw';
        winnerSymbol = 'draw';
      }
    }

    // Calculate next board
    int? nextB;
    if (status == 'in_progress') {
      final targetNext = updatedBoards[cellIdx];
      if (targetNext.isCompleted) {
        nextB = null; // Free move
      } else {
        nextB = cellIdx;
      }
    }

    final nextTurnIndex = _gameState.currentTurnIndex == 0 ? 1 : 0;
    final nextPid = _playerIds[nextTurnIndex];
    final nextSymbol = currentMark == 'X' ? 'O' : 'X';
    final nextPName = _playerNames[nextPid] ?? (nextSymbol == 'X' ? 'Player 1' : 'Player 2');

    final moveRecord = {
      'board': boardIdx,
      'cell': cellIdx,
      'player': currentMark,
      'player_id': currentPid,
    };
    final updatedHistory = List<Map<String, dynamic>>.from(_gameState.moveHistory)..add(moveRecord);

    String lastAction;
    if (status == 'won') {
      lastAction = '$winnerName ($winnerSymbol) won the match with 3 macro boards in a row!';
    } else if (status == 'draw') {
      lastAction = 'The game ended in a draw! All boards completed.';
    } else if (nextB == null) {
      lastAction = '$currentPName placed $currentMark at Board ${boardIdx + 1}, Cell ${cellIdx + 1}. $nextPName has a FREE MOVE!';
    } else {
      lastAction = '$currentPName placed $currentMark at Board ${boardIdx + 1}, Cell ${cellIdx + 1}. $nextPName must play in Board ${nextB + 1}.';
    }

    setState(() {
      _gameState = UltimateTicTacToeState(
        playerIds: _playerIds,
        playerNames: _playerNames,
        playerSymbols: _gameState.playerSymbols,
        boards: updatedBoards,
        macroBoard: updatedMacro,
        macroWinningLine: macroWinningLine,
        currentTurnIndex: nextTurnIndex,
        currentTurnPlayerId: nextPid,
        currentSymbol: nextSymbol,
        nextBoard: nextB,
        moveHistory: updatedHistory,
        turnNumber: _gameState.turnNumber + 1,
        status: status,
        winnerId: winnerId,
        winnerName: winnerName,
        winnerSymbol: winnerSymbol,
        xBoardsWon: xWon,
        oBoardsWon: oWon,
        lastMove: moveRecord,
        lastAction: lastAction,
      );
    });

    if (status == 'won' || status == 'draw') {
      _recordMatchStats(status, winnerSymbol);
    } else if (widget.mode == 'ai' && nextSymbol == 'O') {
      _triggerAiMove();
    }
  }

  void _triggerAiMove() async {
    if (_isAiThinking || (_gameState.status != 'in_progress' && _gameState.status != 'active')) return;
    setState(() => _isAiThinking = true);

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || (_gameState.status != 'in_progress' && _gameState.status != 'active') || _gameState.currentSymbol != 'O') {
      if (mounted) setState(() => _isAiThinking = false);
      return;
    }

    final move = _calculateBestAiMove(_gameState);
    setState(() => _isAiThinking = false);
    if (move != null) {
      _executeLocalMove(move['board']!, move['cell']!);
    }
  }

  Map<String, int>? _calculateBestAiMove(UltimateTicTacToeState state) {
    final validBoards = state.validBoards;
    if (validBoards.isEmpty) return null;

    final List<Map<String, int>> possibleMoves = [];
    for (final bIdx in validBoards) {
      final board = state.boards[bIdx];
      for (int cIdx = 0; cIdx < 9; cIdx++) {
        if (board.cells[cIdx] == null) {
          possibleMoves.add({'board': bIdx, 'cell': cIdx});
        }
      }
    }
    if (possibleMoves.isEmpty) return null;

    int bestScore = -999999;
    Map<String, int> bestMove = possibleMoves.first;

    for (final move in possibleMoves) {
      final bIdx = move['board']!;
      final cIdx = move['cell']!;
      int score = 0;

      // 1. Check if this move wins the micro board for 'O'
      final microBoard = state.boards[bIdx];
      final simCells = List<String?>.from(microBoard.cells);
      simCells[cIdx] = 'O';

      final willWinMicro = _checkMicroWinner(simCells) == 'O';
      if (willWinMicro) {
        score += 120;

        // Check if winning this micro board wins the macro game
        final simMacro = List<String?>.from(state.macroBoard);
        simMacro[bIdx] = 'O';
        if (_checkMacroWinner(simMacro) == 'O') {
          score += 10000; // Match-winning move!
        }
      }

      // 2. Check if this move blocks 'X' from winning the micro board
      final oppCells = List<String?>.from(microBoard.cells);
      oppCells[cIdx] = 'X';
      if (_checkMicroWinner(oppCells) == 'X') {
        score += 65; // Critical block
      }

      // 3. Routing evaluation (which board is opponent sent to?)
      final targetNextBoard = state.boards[cIdx];
      if (targetNextBoard.isCompleted || (willWinMicro && bIdx == cIdx)) {
        // Sending opponent to completed board gives them a FREE MOVE!
        score -= 40;
      } else {
        bool oppCouldWinNext = false;
        for (int oppC = 0; oppC < 9; oppC++) {
          if (targetNextBoard.cells[oppC] == null) {
            final testCells = List<String?>.from(targetNextBoard.cells);
            testCells[oppC] = 'X';
            if (_checkMicroWinner(testCells) == 'X') {
              oppCouldWinNext = true;
              break;
            }
          }
        }
        if (oppCouldWinNext) {
          score -= 35;
        } else {
          score += 15;
        }
      }

      // 4. Positional cell preferences (center > corners > edges)
      if (cIdx == 4) {
        score += 14;
      } else if (cIdx == 0 || cIdx == 2 || cIdx == 6 || cIdx == 8) {
        score += 8;
      } else {
        score += 3;
      }

      if (bIdx == 4) {
        score += 10;
      } else if (bIdx == 0 || bIdx == 2 || bIdx == 6 || bIdx == 8) {
        score += 6;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  void _recordMatchStats(String finalStatus, String? winnerSymbol) {
    if (_statsRecorded) return;
    _statsRecorded = true;
    try {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.userId == null) return;

      final mySymbol = widget.mode == 'online' ? (_localPlayerMark ?? 'X') : 'X';
      String outcome = 'loss';
      if (winnerSymbol == mySymbol) {
        outcome = 'win';
      } else if (finalStatus == 'draw' || winnerSymbol == 'draw') {
        outcome = 'tie';
      }

      final section = widget.mode == 'online'
          ? 'multiplayer'
          : (widget.mode == 'ai' ? 'vs_ai' : 'pass_and_play');

      ref.read(platformApiServiceProvider).recordGameResult(
        userId: auth.userId!,
        gameId: 'ultimate_tic_tac_toe',
        sectionId: section,
        outcome: outcome,
      );
    } catch (_) {}
  }

  void _resetLocalMatch() {
    setState(() {
      _initLocalState();
    });
  }

  void _requestOnlineRematch() {
    if (_wsChannel != null) {
      _wsChannel!.sink.add(jsonEncode({
        'type': 'REMATCH',
        'action': 'rematch',
        'move': {},
      }));
    }
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181C26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _colorO.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.help_outline_rounded, color: _colorO, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "How to Play",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRuleItem(
                "1. The 3×3 Macro Grid",
                "The board consists of 9 smaller Tic-Tac-Toe boards. Winning a smaller board claims that square on the main board.",
                Icons.grid_view_rounded,
                _colorO,
              ),
              const SizedBox(height: 12),
              _buildRuleItem(
                "2. Dynamic Routing",
                "Where you play inside a small board determines which board your opponent must play in next (e.g., top-right cell sends them to the top-right board).",
                Icons.alt_route_rounded,
                _colorX,
              ),
              const SizedBox(height: 12),
              _buildRuleItem(
                "3. Free Move Rule",
                "If you are sent to a board that is already won or full, you get a FREE MOVE and can play in ANY open board!",
                Icons.electric_bolt_rounded,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildRuleItem(
                "4. Winning the Match",
                "Win 3 smaller boards in a row (horizontal, vertical, or diagonal) on the Macro Grid to achieve Ultimate Victory!",
                Icons.emoji_events_rounded,
                const Color(0xFFEC4899),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              backgroundColor: _colorO,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text("Got it!", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      backgroundColor: _colorBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavBar(),
            Expanded(
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Top Navigation Bar ---
  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _colorMacroCard,
        border: Border(bottom: BorderSide(color: Color(0xFF262D3D), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            tooltip: "Leave Game",
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grid_4x4_rounded, color: Colors.black, size: 18),
                const SizedBox(width: 6),
                Text(
                  "ULTIMATE",
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tic-Tac-Toe",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
            tooltip: "Game Rules",
            onPressed: _showRulesDialog,
          ),
          if (widget.mode == 'local' || widget.mode == 'ai')
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: "Restart Game",
              onPressed: _resetLocalMatch,
            ),
        ],
      ),
    );
  }

  // --- Desktop Layout ---
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
                  child: _buildMacroBoard(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMatchHeaderCard(),
                  const SizedBox(height: 16),
                  _buildTurnStatusCard(),
                  const SizedBox(height: 16),
                  _buildMiniMacroMapCard(),
                  const SizedBox(height: 16),
                  _buildMoveTickerCard(),
                  const SizedBox(height: 20),
                  if (_gameState.status == 'won' || _gameState.status == 'draw' || _gameState.status == 'finished')
                    _buildGameOverCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Mobile Layout ---
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMatchHeaderCard(),
          const SizedBox(height: 10),
          _buildTurnStatusCard(),
          const SizedBox(height: 14),
          Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 480),
                child: _buildMacroBoard(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_gameState.status == 'won' || _gameState.status == 'draw' || _gameState.status == 'finished') ...[
            _buildGameOverCard(),
            const SizedBox(height: 16),
          ],
          _buildMiniMacroMapCard(),
          const SizedBox(height: 16),
          _buildMoveTickerCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- Match Header Card ---
  Widget _buildMatchHeaderCard() {
    final p1Name = _playerNames[_playerIds.isNotEmpty ? _playerIds[0] : 'p1'] ?? 'Player 1';
    final p2Name = _playerNames[_playerIds.length > 1 ? _playerIds[1] : 'p2'] ?? 'Player 2';

    final xBoardsCount = _gameState.macroBoard.where((w) => w == 'X').length;
    final oBoardsCount = _gameState.macroBoard.where((w) => w == 'O').length;

    final isPlaying = _gameState.status == 'in_progress' || _gameState.status == 'active';
    final isXTurn = _gameState.currentSymbol == 'X' && isPlaying;
    final isOTurn = _gameState.currentSymbol == 'O' && isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _colorMacroCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262D3D), width: 1.5),
      ),
      child: Row(
        children: [
          // Player X
          Expanded(
            child: _buildPlayerProfile(
              name: p1Name,
              mark: 'X',
              color: _colorX,
              boardsClaimed: xBoardsCount,
              isActive: isXTurn,
              isLocalUser: widget.mode == 'online' && _localPlayerMark == 'X',
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF222838),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "VS",
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          // Player O
          Expanded(
            child: _buildPlayerProfile(
              name: p2Name,
              mark: 'O',
              color: _colorO,
              boardsClaimed: oBoardsCount,
              isActive: isOTurn,
              isLocalUser: widget.mode == 'online' && _localPlayerMark == 'O',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerProfile({
    required String name,
    required String mark,
    required Color color,
    required int boardsClaimed,
    required bool isActive,
    required bool isLocalUser,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    mark,
                    style: GoogleFonts.outfit(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$boardsClaimed boards",
                style: GoogleFonts.inter(
                  color: color.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isLocalUser) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "YOU",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (widget.mode == 'ai' && mark == 'O') ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _colorO.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _colorO.withOpacity(0.6), width: 0.8),
                  ),
                  child: Text(
                    "BOT",
                    style: GoogleFonts.outfit(
                      color: _colorO,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- Turn / Target Board Status Card ---
  Widget _buildTurnStatusCard() {
    final isFreeMove = _gameState.isFreeMove;
    final currentMark = _gameState.currentSymbol;
    final currentColor = currentMark == 'X' ? _colorX : _colorO;
    final isFinished = _gameState.status == 'won' || _gameState.status == 'draw' || _gameState.status == 'finished';

    String statusText;
    if (isFinished) {
      if (_gameState.status == 'draw' || _gameState.winnerSymbol == 'draw') {
        statusText = "Match Ended in a Draw!";
      } else {
        final winnerName = _gameState.winnerName ??
            (_gameState.winnerSymbol == 'X'
                ? (_playerNames[_playerIds.isNotEmpty ? _playerIds[0] : 'p1'] ?? 'Player 1')
                : (_playerNames[_playerIds.length > 1 ? _playerIds[1] : 'p2'] ?? 'Player 2'));
        statusText = "$winnerName Wins the Match!";
      }
    } else if (_isAiThinking) {
      statusText = "Tactical AI is strategizing...";
    } else if (isFreeMove) {
      statusText = "FREE MOVE: Play in any open board!";
    } else {
      final boardNum = _gameState.nextBoard! + 1;
      statusText = "Must play in Board #$boardNum";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _isAiThinking
            ? _colorO.withOpacity(0.15)
            : (isFreeMove
                ? const Color(0xFF10B981).withOpacity(0.15)
                : currentColor.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAiThinking
              ? _colorO.withOpacity(0.5)
              : (isFreeMove
                  ? const Color(0xFF10B981).withOpacity(0.5)
                  : currentColor.withOpacity(0.4)),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isAiThinking
                ? Icons.smart_toy_outlined
                : (isFreeMove
                    ? Icons.electric_bolt_rounded
                    : (isFinished
                        ? Icons.emoji_events_rounded
                        : Icons.track_changes_rounded)),
            color: _isAiThinking
                ? _colorO
                : (isFreeMove ? const Color(0xFF10B981) : currentColor),
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusText,
              style: GoogleFonts.outfit(
                color: _isAiThinking
                    ? _colorO
                    : (isFreeMove ? const Color(0xFF34D399) : Colors.white),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Macro Board ---
  Widget _buildMacroBoard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _colorMacroCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E384D), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = 8.0;
          final availableSize = constraints.maxWidth - (spacing * 2);
          final microSize = availableSize / 3;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int row = 0; row < 3; row++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int col = 0; col < 3; col++)
                      SizedBox(
                        width: microSize,
                        height: microSize,
                        child: _buildMicroBoard(row * 3 + col),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Single 3x3 Micro Board ---
  Widget _buildMicroBoard(int boardIdx) {
    final microState = _gameState.boards[boardIdx];
    final isPlaying = _gameState.status == 'in_progress' || _gameState.status == 'active';
    final isValidTarget = isPlaying && _gameState.validBoards.contains(boardIdx);
    final isWon = microState.winner != null;
    final isMacroWinningBoard = _gameState.macroWinningLine?.contains(boardIdx) ?? false;

    Color borderColor;
    if (isMacroWinningBoard) {
      borderColor = const Color(0xFFF59E0B);
    } else if (isValidTarget) {
      borderColor = _gameState.currentSymbol == 'X' ? _colorX : _colorO;
    } else {
      borderColor = const Color(0xFF262D3D);
    }

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _colorMicroCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isValidTarget
                  ? borderColor.withOpacity(_glowAnim.value)
                  : borderColor,
              width: isValidTarget ? 2.5 : 1.2,
            ),
            boxShadow: isValidTarget
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.3 * _glowAnim.value),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // 3x3 Internal Cell Grid
                Column(
                  children: [
                    for (int r = 0; r < 3; r++)
                      Expanded(
                        child: Row(
                          children: [
                            for (int c = 0; c < 3; c++)
                              Expanded(
                                child: _buildCell(
                                  boardIdx,
                                  r * 3 + c,
                                  microState.cells[r * 3 + c],
                                  isValidTarget,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Completed Micro Board Overlay
                if (isWon) _buildMicroWinnerOverlay(microState.winner!, isMacroWinningBoard),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Individual Interactive Cell ---
  Widget _buildCell(int boardIdx, int cellIdx, String? mark, bool isTargetBoard) {
    final isLastMove = _gameState.lastMove != null &&
        _gameState.lastMove!['board'] == boardIdx &&
        _gameState.lastMove!['cell'] == cellIdx;

    final isPlaying = _gameState.status == 'in_progress' || _gameState.status == 'active';
    final isClickable = isTargetBoard && mark == null && isPlaying;

    return GestureDetector(
      onTap: isClickable ? () => _handleCellTap(boardIdx, cellIdx) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isLastMove
              ? (mark == 'X' ? _colorX : _colorO).withOpacity(0.25)
              : (isClickable ? const Color(0xFF283044) : const Color(0xFF1B202D)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isLastMove
                ? (mark == 'X' ? _colorX : _colorO)
                : (isClickable ? const Color(0xFF38435C) : Colors.transparent),
            width: isLastMove ? 1.5 : 0.8,
          ),
        ),
        child: Center(
          child: mark == null
              ? (isClickable
                  ? Opacity(
                      opacity: 0.15,
                      child: Text(
                        _gameState.currentSymbol,
                        style: GoogleFonts.outfit(
                          color: _gameState.currentSymbol == 'X' ? _colorX : _colorO,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : const SizedBox.shrink())
              : _buildMarkGlyph(mark),
        ),
      ),
    );
  }

  Widget _buildMarkGlyph(String mark) {
    final isX = mark == 'X';
    final color = isX ? _colorX : _colorO;

    return Text(
      mark,
      style: GoogleFonts.outfit(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 18,
        shadows: [
          Shadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  // --- Large Overlay for Completed Micro Board ---
  Widget _buildMicroWinnerOverlay(String winner, bool isMacroWinningBoard) {
    final isDraw = winner == 'draw';
    final color = isDraw
        ? _colorDraw
        : (winner == 'X' ? _colorX : _colorO);

    return Container(
      color: Colors.black.withOpacity(isMacroWinningBoard ? 0.8 : 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDraw ? "—" : winner,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 48,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.8),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
            if (isMacroWinningBoard)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "WINNER",
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Mini Macro Overview Map Card ---
  Widget _buildMiniMacroMapCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _colorMacroCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262D3D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                "MACRO BOARD OVERVIEW",
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: 9,
                itemBuilder: (context, idx) {
                  final winner = _gameState.macroBoard[idx];
                  final isPlaying = _gameState.status == 'in_progress' || _gameState.status == 'active';
                  final isCurrentTarget = _gameState.validBoards.contains(idx) && isPlaying;
                  final isMacroWin = _gameState.macroWinningLine?.contains(idx) ?? false;

                  Color bg = const Color(0xFF222838);
                  Color textCol = Colors.white54;
                  if (isMacroWin) {
                    bg = const Color(0xFFF59E0B).withOpacity(0.35);
                    textCol = const Color(0xFFF59E0B);
                  } else if (winner == 'X') {
                    bg = _colorX.withOpacity(0.25);
                    textCol = _colorX;
                  } else if (winner == 'O') {
                    bg = _colorO.withOpacity(0.25);
                    textCol = _colorO;
                  } else if (winner == 'draw') {
                    bg = _colorDraw.withOpacity(0.2);
                    textCol = _colorDraw;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCurrentTarget
                            ? Colors.white
                            : (winner != null ? textCol : const Color(0xFF334155)),
                        width: isCurrentTarget ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        winner ?? "${idx + 1}",
                        style: GoogleFonts.outfit(
                          color: winner != null ? textCol : Colors.white30,
                          fontWeight: FontWeight.w800,
                          fontSize: winner != null ? 16 : 11,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Move Ticker Card ---
  Widget _buildMoveTickerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _colorMacroCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262D3D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MATCH STATS",
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                "Move #${_gameState.turnNumber}",
                style: GoogleFonts.inter(
                  color: const Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _gameState.lastAction.isNotEmpty
                ? _gameState.lastAction
                : (_gameState.lastMove != null
                    ? "Last Move: Player ${_gameState.lastMove!['player']} placed in Board #${(_gameState.lastMove!['board'] as int) + 1}, Cell #${(_gameState.lastMove!['cell'] as int) + 1}"
                    : "Game Started. First move has choice of any board."),
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- Game Over Banner Card ---
  Widget _buildGameOverCard() {
    final isDraw = _gameState.status == 'draw' || _gameState.winnerSymbol == 'draw';
    final winnerMark = _gameState.winnerSymbol;
    final winnerColor = isDraw
        ? _colorDraw
        : (winnerMark == 'X' ? _colorX : _colorO);

    final winnerName = isDraw
        ? "Draw Match"
        : (_gameState.winnerName ??
            (winnerMark == 'X'
                ? (_playerNames[_playerIds.isNotEmpty ? _playerIds[0] : 'p1'] ?? 'Player 1')
                : (_playerNames[_playerIds.length > 1 ? _playerIds[1] : 'p2'] ?? 'Player 2')));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            winnerColor.withOpacity(0.2),
            _colorMacroCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: winnerColor, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            isDraw ? Icons.handshake_rounded : Icons.emoji_events_rounded,
            color: winnerColor,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            isDraw ? "STALEMATE!" : "$winnerName WINS!",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isDraw
                ? "All boards have been completed without a 3-in-a-row."
                : "Successfully completed 3 boards in a row on the Macro Grid!",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.mode == 'online'
                      ? _requestOnlineRematch
                      : _resetLocalMatch,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    "Play Again",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: winnerColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
