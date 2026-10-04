import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/presentation/widgets/platform_app_bar.dart';
import '../../../../platform/services/platform_api_service.dart';
import '../../../../platform/theme/playned_design_tokens.dart';
import '../../models/reversi_game_state.dart';
import '../widgets/reversi_board_widget.dart';
import '../widgets/reversi_strategy_dialog.dart';

class ReversiGamePage extends ConsumerStatefulWidget {
  final String mode; // 'ai', 'local', 'online'
  final String variant; // 'othello', 'reversi_classic'
  final String difficulty; // 'novice', 'tactician', 'grandmaster'
  final String? roomCode;
  final String? localPlayerId;

  const ReversiGamePage({
    super.key,
    this.mode = 'ai',
    this.variant = 'othello',
    this.difficulty = 'grandmaster',
    this.roomCode,
    this.localPlayerId,
  });

  @override
  ConsumerState<ReversiGamePage> createState() => _ReversiGamePageState();
}

class _ReversiGamePageState extends ConsumerState<ReversiGamePage> {
  late ReversiGameState _gameState;
  late ReversiDifficulty _difficulty;
  bool _isAiThinking = false;
  bool _showLegalHints = true;
  String? _passBannerMessage;
  Timer? _passBannerTimer;
  bool _hasSavedResult = false;

  // Online multiplayer state
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  String _blackPlayerName = "Black";
  String _whitePlayerName = "White";

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _passBannerTimer?.cancel();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _initGame() {
    final variant = widget.variant == 'reversi_classic'
        ? ReversiVariant.reversiClassic
        : ReversiVariant.othello;

    _difficulty = ReversiDifficulty.values.firstWhere(
      (d) => d.name == widget.difficulty,
      orElse: () => ReversiDifficulty.grandmaster,
    );

    _gameState = ReversiGameState.initial(variant: variant);

    final auth = ref.read(authProvider);
    final myName = auth.username ?? "Player";

    if (widget.mode == 'ai') {
      _blackPlayerName = myName;
      _whitePlayerName = "AI (${widget.difficulty.toUpperCase()})";
    } else if (widget.mode == 'local') {
      _blackPlayerName = "$myName (Black)";
      _whitePlayerName = "Player 2 (White)";
    } else if (widget.mode == 'online' && widget.roomCode != null) {
      _initOnlineMode();
    }
  }

  void _initOnlineMode() async {
    final api = ref.read(platformApiServiceProvider);
    final pid = widget.localPlayerId ?? 'p1';

    try {
      final room = await api.getRoom(widget.roomCode!);
      if (room.matchState != null) {
        _applyBackendMatchState(room.matchState!);
      }

      _wsChannel = api.connectWebSocket(widget.roomCode!, pid);
      _wsSubscription = _wsChannel?.stream.listen((message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          if (data['room'] != null && data['room']['match_state'] != null) {
            _applyBackendMatchState(data['room']['match_state'] as Map<String, dynamic>);
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void _applyBackendMatchState(Map<String, dynamic> state) {
    if (!mounted) return;
    setState(() {
      final rawBoard = state['board'] as List<dynamic>? ?? [];
      final board = rawBoard.map((row) {
        return (row as List<dynamic>).map((cell) {
          if (cell == 'black' || cell == 'p1' || cell == 'B' || cell == 1) return 1;
          if (cell == 'white' || cell == 'p2' || cell == 'W' || cell == 2) return 2;
          return 0;
        }).toList();
      }).toList();

      final currentTurnStr = state['current_player'] ?? state['current_turn'];
      final currentTurnColor = (currentTurnStr == 'white' || currentTurnStr == 'p2' || currentTurnStr == 'W' || currentTurnStr == 2)
          ? 2
          : 1;

      final isGameOver = state['status'] == 'completed' || state['game_over'] == true;
      int? winner;
      if (state['winner'] == 'black' || state['winner'] == 'p1' || state['winner'] == 'B' || state['winner'] == 1) {
        winner = 1;
      } else if (state['winner'] == 'white' || state['winner'] == 'p2' || state['winner'] == 'W' || state['winner'] == 2) {
        winner = 2;
      } else if (isGameOver && state['winner'] == null) {
        winner = 0;
      }

      int bCount = 0;
      int wCount = 0;
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (board[r][c] == 1) bCount++;
          if (board[r][c] == 2) wCount++;
        }
      }

      _gameState = ReversiGameState(
        board: board,
        currentTurnColor: currentTurnColor,
        variant: _gameState.variant,
        blackCount: state['black_count'] ?? bCount,
        whiteCount: state['white_count'] ?? wCount,
        blackReserves: state['black_reserves'] ?? _gameState.blackReserves,
        whiteReserves: state['white_reserves'] ?? _gameState.whiteReserves,
        consecutivePasses: state['consecutive_passes'] ?? 0,
        isGameOver: isGameOver,
        winnerColor: winner,
        lastMoveCoord: state['last_move'] != null
            ? ReversiCoord(state['last_move']['row'], state['last_move']['col'])
            : _gameState.lastMoveCoord,
        statusMessage: state['status_message'] ?? _gameState.statusMessage,
      );

      final names = state['player_names'] as Map<String, dynamic>?;
      if (names != null) {
        _blackPlayerName = names['p1'] ?? names['black'] ?? "Black";
        _whitePlayerName = names['p2'] ?? names['white'] ?? "White";
      }

      if (isGameOver && !_hasSavedResult) {
        _recordMatchStats();
      }
    });
  }

  void _onCellTap(int row, int col) async {
    if (_gameState.isGameOver || _isAiThinking) return;

    if (widget.mode == 'online' && widget.roomCode != null) {
      final pid = widget.localPlayerId ?? 'p1';
      final isMyTurn = (pid == 'p1' && _gameState.currentTurnColor == 1) ||
          (pid == 'p2' && _gameState.currentTurnColor == 2);
      if (!isMyTurn) return;

      final coord = ReversiCoord(row, col);
      if (!_gameState.currentLegalMoves.containsKey(coord)) return;

      final api = ref.read(platformApiServiceProvider);
      api.submitMove(
        roomCode: widget.roomCode!,
        playerId: pid,
        move: {'row': row, 'col': col},
      );
      return;
    }

    // Local or AI Mode
    final coord = ReversiCoord(row, col);
    if (!_gameState.currentLegalMoves.containsKey(coord)) return;

    final newState = _gameState.applyMove(row, col);
    setState(() {
      _gameState = newState;
    });

    _checkPassOrGameOver();

    if (!_gameState.isGameOver && widget.mode == 'ai' && _gameState.currentTurnColor == 2) {
      _triggerAiMove();
    }
  }

  void _triggerAiMove() async {
    setState(() => _isAiThinking = true);
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted || _gameState.isGameOver) {
      if (mounted) setState(() => _isAiThinking = false);
      return;
    }

    final aiMove = ReversiAI.selectMove(_gameState, _difficulty);
    if (aiMove != null) {
      final afterAiState = _gameState.applyMove(aiMove.r, aiMove.c);
      setState(() {
        _gameState = afterAiState;
        _isAiThinking = false;
      });
      _checkPassOrGameOver();
    } else {
      setState(() {
        _isAiThinking = false;
        _showPassBanner("AI had no legal moves and passed turn.");
      });
      _checkPassOrGameOver();
    }
  }

  void _checkPassOrGameOver() {
    if (_gameState.isGameOver) {
      if (!_hasSavedResult) {
        _recordMatchStats();
      }
      return;
    }

    if (_gameState.statusMessage.contains("passed")) {
      _showPassBanner(_gameState.statusMessage);
      if (widget.mode == 'ai' && _gameState.currentTurnColor == 2) {
        _triggerAiMove();
      }
    }
  }

  void _showPassBanner(String msg) {
    _passBannerTimer?.cancel();
    setState(() => _passBannerMessage = msg);
    _passBannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _passBannerMessage = null);
    });
  }

  void _recordMatchStats() async {
    _hasSavedResult = true;
    try {
      final auth = ref.read(authProvider);
      if (auth.userId == null) return;

      final api = ref.read(platformApiServiceProvider);
      final won = _gameState.winnerColor == 1;
      final isDraw = _gameState.winnerColor == 0;

      await api.recordGameResult(
        userId: auth.userId!,
        gameId: 'reversi',
        sectionId: _gameState.variant == ReversiVariant.othello ? 'othello' : 'classic',
        outcome: isDraw ? 'draw' : (won ? 'win' : 'loss'),
        score: _gameState.blackCount,
        details: {
          'variant': _gameState.variant.name,
          'difficulty': _difficulty.name,
          'mode': widget.mode,
          'black_count': _gameState.blackCount,
          'white_count': _gameState.whiteCount,
        },
      );
    } catch (_) {}
  }

  void _resetMatch() {
    _passBannerTimer?.cancel();
    _hasSavedResult = false;
    setState(() {
      _gameState = ReversiGameState.initial(variant: _gameState.variant);
      _isAiThinking = false;
      _passBannerMessage = null;
    });
  }

  void _openAcademy() {
    showDialog(
      context: context,
      builder: (ctx) => const ReversiStrategyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: PlatformAppBar(
        title: _gameState.variant == ReversiVariant.othello ? "OTHELLO" : "REVERSI",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Column(
                children: [
                  // Action Toolbar (Academy, Hint toggle, Reset)
                  _buildActionBar(),
                  const SizedBox(height: 12),

                  // Pass Banner Notification
                  if (_passBannerMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _passBannerMessage!,
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Top Status HUD (Player scores, disc pills, turn state)
                  _buildStatusHud(),
                  const SizedBox(height: 16),

                  // Main 8x8 Board Container
                  Center(
                    child: ReversiBoardWidget(
                      state: _gameState,
                      showHints: _showLegalHints,
                      isInteractive: !_isAiThinking && !_gameState.isGameOver,
                      onCellTapped: _onCellTap,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Mobility & Tactics Bar
                  _buildTacticsStatusBar(),

                  // Game Over Card if finished
                  if (_gameState.isGameOver) ...[
                    const SizedBox(height: 20),
                    _buildGameOverSummary(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: _openAcademy,
          icon: const Icon(Icons.school_outlined, size: 16, color: PlayNedTokens.brandGold),
          label: const Text("STRATEGY & RULES"),
          style: OutlinedButton.styleFrom(
            foregroundColor: PlayNedTokens.brandGold,
            side: const BorderSide(color: PlayNedTokens.brandGold),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
            textStyle: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _showLegalHints = !_showLegalHints),
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _showLegalHints ? PlayNedTokens.accentReversi.withOpacity(0.15) : PlayNedTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: _showLegalHints ? PlayNedTokens.accentReversi : PlayNedTokens.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showLegalHints ? Icons.lightbulb : Icons.lightbulb_outline,
                      size: 14,
                      color: _showLegalHints ? PlayNedTokens.accentReversi : PlayNedTokens.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showLegalHints ? "HINTS ON" : "HINTS OFF",
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _showLegalHints ? PlayNedTokens.accentReversi : PlayNedTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: PlayNedTokens.textSecondary),
              tooltip: "Restart Match",
              onPressed: _resetMatch,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusHud() {
    final isBlackTurn = _gameState.currentTurnColor == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.border),
      ),
      child: Row(
        children: [
          // Black Player Pill
          Expanded(
            child: _buildPlayerPill(
              colorId: 1,
              name: _blackPlayerName,
              score: _gameState.blackCount,
              reserves: _gameState.variant == ReversiVariant.reversiClassic ? _gameState.blackReserves : null,
              isActive: isBlackTurn && !_gameState.isGameOver,
              isThinking: false,
            ),
          ),
          const SizedBox(width: 12),

          // Center Turn & Move Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: PlayNedTokens.surfaceElevated,
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
              border: Border.all(color: PlayNedTokens.borderSubtle),
            ),
            child: Column(
              children: [
                Text(
                  "DISCS PLACED",
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: PlayNedTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _gameState.isGameOver
                      ? "MATCH OVER"
                      : (_isAiThinking ? "AI THINKING..." : (isBlackTurn ? "BLACK'S TURN" : "WHITE'S TURN")),
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _gameState.isGameOver
                        ? PlayNedTokens.brandGold
                        : (_isAiThinking ? PlayNedTokens.accentReversi : PlayNedTokens.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // White Player Pill
          Expanded(
            child: _buildPlayerPill(
              colorId: 2,
              name: _whitePlayerName,
              score: _gameState.whiteCount,
              reserves: _gameState.variant == ReversiVariant.reversiClassic ? _gameState.whiteReserves : null,
              isActive: !isBlackTurn && !_gameState.isGameOver,
              isThinking: _isAiThinking,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPill({
    required int colorId,
    required String name,
    required int score,
    int? reserves,
    required bool isActive,
    required bool isThinking,
  }) {
    final isBlack = colorId == 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? (isBlack ? const Color(0xFF1E2822) : const Color(0xFF2C2F2B))
            : PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(
          color: isActive
              ? (isBlack ? PlayNedTokens.accentReversi : PlayNedTokens.brandGold)
              : PlayNedTokens.borderSubtle,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBlack ? const Color(0xFF121413) : const Color(0xFFF1EBDD),
              border: Border.all(
                color: isBlack ? const Color(0xFF333D35) : const Color(0xFFC4B89B),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isBlack ? Colors.black54 : Colors.white24,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: isThinking
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isBlack ? PlayNedTokens.accentReversi : Colors.black,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PlayNedTokens.body.copyWith(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? PlayNedTokens.textPrimary : PlayNedTokens.textMuted,
                  ),
                ),
                if (reserves != null)
                  Text(
                    "$reserves left",
                    style: GoogleFonts.spaceMono(fontSize: 9, color: PlayNedTokens.textMuted),
                  ),
              ],
            ),
          ),
          Text(
            "$score",
            style: GoogleFonts.spaceMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? PlayNedTokens.textPrimary : PlayNedTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticsStatusBar() {
    final availableMoves = _gameState.currentLegalMoves.length;
    final maxFlipsInOneMove = _gameState.currentLegalMoves.isEmpty
        ? 0
        : _gameState.currentLegalMoves.values.map((flips) => flips.length).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTacticsPill(
            icon: Icons.alt_route_rounded,
            label: "CURRENT MOBILITY",
            val: "$availableMoves Moves",
            color: availableMoves > 0 ? PlayNedTokens.accentReversi : Colors.red,
          ),
          Container(width: 1, height: 20, color: PlayNedTokens.borderSubtle),
          _buildTacticsPill(
            icon: Icons.swap_horizontal_circle_outlined,
            label: "MAX SANDWICH FLIP",
            val: "$maxFlipsInOneMove Discs",
            color: PlayNedTokens.brandGold,
          ),
          Container(width: 1, height: 20, color: PlayNedTokens.borderSubtle),
          _buildTacticsPill(
            icon: Icons.crop_square_rounded,
            label: "EMPTY SQUARES",
            val: "${64 - _gameState.blackCount - _gameState.whiteCount}",
            color: PlayNedTokens.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTacticsPill({
    required IconData icon,
    required String label,
    required String val,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.spaceMono(fontSize: 8, color: PlayNedTokens.textMuted)),
            Text(val, style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildGameOverSummary() {
    final winner = _gameState.winnerColor;
    final isDraw = winner == 0;
    final isBlackWinner = winner == 1;

    String title = isDraw
        ? "HONORABLE DRAW!"
        : (isBlackWinner ? "$_blackPlayerName VICTORIOUS!" : "$_whitePlayerName VICTORIOUS!");

    final diff = (_gameState.blackCount - _gameState.whiteCount).abs();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.brandGold),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PlayNedTokens.surface,
            PlayNedTokens.brandGold.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            isDraw ? Icons.handshake_outlined : Icons.emoji_events_outlined,
            size: 48,
            color: PlayNedTokens.brandGold,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.cinzel(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PlayNedTokens.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isDraw
                ? "Both tacticians finished with 32 discs each. Perfect balance!"
                : "Dominant board capture with a $diff disc margin (${_gameState.blackCount} to ${_gameState.whiteCount}).",
            style: PlayNedTokens.bodyMuted.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _resetMatch,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("REMATCH"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PlayNedTokens.brandGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd)),
                  textStyle: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/games/reversi/hub'),
                icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
                label: const Text("CHANGE MODE / HUB"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PlayNedTokens.textPrimary,
                  side: const BorderSide(color: PlayNedTokens.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd)),
                  textStyle: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
