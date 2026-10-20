import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/services/platform_api_service.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/bingo_models.dart';
import '../../services/bingo_engine.dart';
import '../widgets/bingo_card_widget.dart';
import '../widgets/bingo_caller_widget.dart';
import '../widgets/bingo_history_widget.dart';
import '../widgets/bingo_result_dialog.dart';

class BingoGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local', 'ai', 'online'
  final String? roomCode;
  final String? localPlayerId;
  final BingoPattern pattern;
  final BingoDifficulty difficulty;

  const BingoGamePage({
    super.key,
    this.mode = 'local',
    this.roomCode,
    this.localPlayerId,
    this.pattern = BingoPattern.classic,
    this.difficulty = BingoDifficulty.medium,
  });

  @override
  ConsumerState<BingoGamePage> createState() => _BingoGamePageState();
}

class _BingoGamePageState extends ConsumerState<BingoGamePage> {
  late BingoGameState _state;
  bool _isAutoDrawing = false;
  Timer? _autoDrawTimer;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  // Local Pass & Play active view tab (0 = Player 1, 1 = Player 2)
  int _activeLocalPlayerIndex = 0;

  // Online WebSocket
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;
  bool _isHost = false;
  bool _opponentDisconnected = false;

  // Statistics recorded flag
  bool _statsRecorded = false;

  // Match timing
  late DateTime _matchStartTime;

  static const Color _accent = PlayNedTokens.brandGold;

  @override
  void initState() {
    super.initState();
    _matchStartTime = DateTime.now();
    _initializeGameState();

    if (widget.mode == 'online' && widget.roomCode != null) {
      _initOnlineMode();
    }
  }

  @override
  void dispose() {
    _autoDrawTimer?.cancel();
    _countdownTimer?.cancel();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _initializeGameState() {
    final auth = ref.read(authProvider);
    final p1Name = auth.username ?? 'Player 1';
    final isAi = widget.mode == 'ai';
    final p2Name = isAi ? 'CPU Bot (${widget.difficulty.displayName})' : 'Player 2';

    _state = BingoEngine.createInitialState(
      playerIds: ['p1', 'p2'],
      playerNames: {'p1': p1Name, 'p2': p2Name},
      pattern: widget.pattern,
    );
    _statsRecorded = false;
    _matchStartTime = DateTime.now();
  }

  void _initOnlineMode() async {
    final api = ref.read(platformApiServiceProvider);
    final pid = widget.localPlayerId ?? 'p1';

    try {
      final room = await api.getRoom(widget.roomCode!);
      _isHost = (room.hostPlayerId == pid);

      // Find opponent
      final opp = room.players.firstWhere(
        (p) => p.playerId != pid,
        orElse: () => room.players.first,
      );
      if (opp.playerId != pid) {
        _opponentName = opp.displayName;
      }

      if (room.matchState != null) {
        if (mounted) {
          setState(() {
            _state = BingoGameState.fromJson(room.matchState!);
          });
        }
      }

      _wsChannel = api.connectWebSocket(widget.roomCode!, pid);
      if (_wsChannel != null) {
        setState(() => _isConnected = true);
        _wsSubscription = _wsChannel!.stream.listen(
          (message) {
            try {
              final data = jsonDecode(message as String) as Map<String, dynamic>;
              _handleWebSocketEvent(data);
            } catch (_) {}
          },
          onDone: () {
            if (mounted) setState(() => _isConnected = false);
          },
          onError: (_) {
            if (mounted) setState(() => _isConnected = false);
          },
        );
      }
    } catch (_) {}
  }

  void _handleWebSocketEvent(Map<String, dynamic> data) {
    final eventType = data['type'] as String?;
    if (eventType == 'STATE_UPDATED' || eventType == 'GAME_STARTED') {
      final roomData = data['room'] as Map<String, dynamic>?;
      if (roomData != null && roomData['match_state'] != null) {
        if (mounted) {
          setState(() {
            _state = BingoGameState.fromJson(roomData['match_state']);
            _opponentDisconnected = false;
          });
          if (_state.isGameOver) {
            _handleGameOver();
          }
        }
      }
    } else if (eventType == 'PLAYER_DISCONNECTED') {
      final pid = data['player_id'];
      if (pid != (widget.localPlayerId ?? 'p1')) {
        if (mounted) {
          setState(() => _opponentDisconnected = true);
        }
      }
    } else if (eventType == 'PLAYER_CONNECTED') {
      final pid = data['player_id'];
      if (pid != (widget.localPlayerId ?? 'p1')) {
        if (mounted) {
          setState(() => _opponentDisconnected = false);
        }
      }
    }
  }

  void _drawNextNumber() {
    if (_state.isGameOver) return;

    HapticFeedback.lightImpact();

    if (widget.mode == 'online') {
      // Send draw move to authoritative server
      if (_wsChannel != null) {
        _wsChannel!.sink.add(jsonEncode({
          'type': 'MOVE',
          'move': {'action': 'draw_number'},
        }));
      }
      return;
    }

    // Local / AI mode: Client deterministic engine
    setState(() {
      _state = BingoEngine.drawNextNumber(_state);
    });

    if (_state.isGameOver) {
      _stopAutoDraw();
      _handleGameOver();
    }
  }

  void _toggleAutoDraw() {
    setState(() {
      _isAutoDrawing = !_isAutoDrawing;
      if (_isAutoDrawing) {
        _startAutoDrawLoop();
      } else {
        _stopAutoDraw();
      }
    });
  }

  void _startAutoDrawLoop() {
    _autoDrawTimer?.cancel();
    _countdownTimer?.cancel();
    _countdownSeconds = 3;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isAutoDrawing || _state.isGameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
        } else {
          _countdownSeconds = 3;
          _drawNextNumber();
        }
      });
    });
  }

  void _stopAutoDraw() {
    _autoDrawTimer?.cancel();
    _countdownTimer?.cancel();
    _isAutoDrawing = false;
    _countdownSeconds = 3;
  }

  void _handleGameOver() {
    if (_statsRecorded) return;
    _statsRecorded = true;

    final auth = ref.read(authProvider);
    final userId = auth.userId;
    if (userId != null) {
      final isLocalWinner = _state.winnerId == 'p1';
      final outcome = _state.winnerId == 'tie'
          ? 'tie'
          : (isLocalWinner ? 'win' : 'loss');

      final api = ref.read(platformApiServiceProvider);
      api.recordGameResult(
        userId: userId,
        gameId: 'bingo',
        sectionId: widget.mode == 'ai'
            ? 'solo_ai'
            : (widget.mode == 'online' ? 'multiplayer' : 'classic'),
        outcome: outcome,
        score: _state.drawnNumbers.length,
        extraStatsUpdate: {
          'pattern': _state.pattern.displayName,
          'balls_drawn': _state.drawnNumbers.length,
          'mode': widget.mode,
        },
      ).catchError((_) => null);
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    final localPid = widget.localPlayerId ?? 'p1';
    final isWinnerLocal = _state.winnerId == localPid;
    final isTie = _state.winnerId == 'tie';
    final duration = DateTime.now().difference(_matchStartTime);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BingoResultDialog(
        winnerName: _state.winnerName ?? 'Winner',
        isWinnerLocalPlayer: isWinnerLocal,
        isTie: isTie,
        patternName: _state.winningPattern ?? _state.pattern.displayName,
        numbersDrawn: _state.drawnNumbers.length,
        matchDuration: duration,
        accentColor: _accent,
        onRematch: () {
          Navigator.pop(ctx);
          _rematch();
        },
        onBackToGames: () {
          Navigator.pop(ctx);
          context.go('/games/bingo');
        },
      ),
    );
  }

  void _rematch() {
    if (widget.mode == 'online') {
      if (_wsChannel != null) {
        _wsChannel!.sink.add(jsonEncode({'type': 'REMATCH'}));
      }
    } else {
      setState(() {
        _initializeGameState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localPid = widget.localPlayerId ?? 'p1';
    final otherPid = _state.playerIds.firstWhere((id) => id != localPid, orElse: () => 'p2');

    final player1Card = _state.cards['p1'] ?? _state.cards.values.first;
    final player2Card = _state.cards['p2'] ?? (_state.cards.length > 1 ? _state.cards.values.last : player1Card);

    final localCard = _state.cards[localPid] ?? player1Card;
    final opponentCard = _state.cards[otherPid] ?? player2Card;

    final p1Name = _state.playerNames['p1'] ?? 'Player 1';
    final p2Name = _state.playerNames['p2'] ?? 'Player 2';

    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: AppBar(
        backgroundColor: PlayNedTokens.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: PlayNedTokens.textSecondary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/games/bingo');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                border: Border.all(color: _accent.withOpacity(0.4)),
              ),
              child: Text(
                'BINGO',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: _accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _state.pattern.displayName.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: PlayNedTokens.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Auto-Draw Toggle (Local & AI mode)
          if (widget.mode != 'online' && !_state.isGameOver)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: _isAutoDrawing ? _accent.withOpacity(0.2) : PlayNedTokens.surfaceElevated,
                  foregroundColor: _isAutoDrawing ? _accent : PlayNedTokens.textSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill)),
                ),
                onPressed: _toggleAutoDraw,
                icon: Icon(
                  _isAutoDrawing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  size: 16,
                ),
                label: Text(
                  _isAutoDrawing ? 'PAUSE AUTO' : 'AUTO DRAW',
                  style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),

          // Online Status Badge
          if (widget.mode == 'online')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? PlayNedTokens.accentPentago.withOpacity(0.15)
                        : PlayNedTokens.terracotta.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
                    border: Border.all(
                      color: _isConnected ? PlayNedTokens.accentPentago : PlayNedTokens.terracotta,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isConnected ? PlayNedTokens.accentPentago : PlayNedTokens.terracotta,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected ? 'ROOM: ${widget.roomCode}' : 'OFFLINE',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isConnected ? PlayNedTokens.accentPentago : PlayNedTokens.terracotta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;

            if (_opponentDisconnected && widget.mode == 'online') {
              return _buildDisconnectedBanner();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(PlayNedTokens.space16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: isDesktop
                      ? _buildDesktopLayout(localCard, opponentCard, p1Name, p2Name)
                      : _buildMobileLayout(localCard, opponentCard, p1Name, p2Name),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDisconnectedBanner() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PlayNedTokens.surface,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
          border: Border.all(color: PlayNedTokens.terracotta),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: PlayNedTokens.terracotta),
            const SizedBox(height: 12),
            Text(
              'Opponent Disconnected',
              style: PlayNedTokens.gameTitle.copyWith(color: PlayNedTokens.terracotta),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for opponent to reconnect to room ${widget.roomCode}...',
              style: PlayNedTokens.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PlayNedTokens.surfaceElevated,
                foregroundColor: PlayNedTokens.textPrimary,
              ),
              onPressed: () => context.go('/games/bingo'),
              child: const Text('EXIT ROOM'),
            ),
          ],
        ),
      ),
    );
  }

  /// Desktop layout: Side-by-side (Card on left, Caller + History + Opponent progress on right)
  Widget _buildDesktopLayout(
    BingoCard localCard,
    BingoCard opponentCard,
    String p1Name,
    String p2Name,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Player Bingo Card (or Pass-and-play tabs)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.mode == 'local') _buildLocalPlayerTabs(p1Name, p2Name),
              const SizedBox(height: 8),
              BingoCardWidget(
                card: widget.mode == 'local'
                    ? (_activeLocalPlayerIndex == 0 ? localCard : opponentCard)
                    : localCard,
                playerTitle: widget.mode == 'local'
                    ? (_activeLocalPlayerIndex == 0 ? p1Name : p2Name)
                    : p1Name,
                accentColor: _accent,
                winningCells: _state.winningCells,
                lastCalledNumber: _state.currentNumber,
              ),
            ],
          ),
        ),
        const SizedBox(width: PlayNedTokens.space24),

        // Right Column: Caller, Opponent Progress, Called Numbers Board
        Expanded(
          flex: 5,
          child: Column(
            children: [
              BingoCallerWidget(
                currentNumber: _state.currentNumber,
                currentLetter: _state.currentLetter,
                drawCount: _state.drawnNumbers.length,
                totalPoolCount: 75,
                onDrawPressed: (widget.mode != 'online' || _isHost) ? _drawNextNumber : null,
                isAutoDrawing: _isAutoDrawing,
                autoDrawCountdown: _countdownSeconds,
                isGameOver: _state.isGameOver,
                accentColor: _accent,
              ),
              const SizedBox(height: PlayNedTokens.space16),

              // Opponent Progress Card (in AI or Online modes)
              if (widget.mode != 'local') ...[
                _buildOpponentProgressCard(opponentCard, p2Name),
                const SizedBox(height: PlayNedTokens.space16),
              ],

              BingoHistoryWidget(
                drawnNumbers: _state.drawnNumbers,
                latestNumber: _state.currentNumber,
                accentColor: _accent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile layout: Stacked vertically with prominent Card
  Widget _buildMobileLayout(
    BingoCard localCard,
    BingoCard opponentCard,
    String p1Name,
    String p2Name,
  ) {
    return Column(
      children: [
        // Caller Display
        BingoCallerWidget(
          currentNumber: _state.currentNumber,
          currentLetter: _state.currentLetter,
          drawCount: _state.drawnNumbers.length,
          totalPoolCount: 75,
          onDrawPressed: (widget.mode != 'online' || _isHost) ? _drawNextNumber : null,
          isAutoDrawing: _isAutoDrawing,
          autoDrawCountdown: _countdownSeconds,
          isGameOver: _state.isGameOver,
          accentColor: _accent,
        ),
        const SizedBox(height: PlayNedTokens.space12),

        // Opponent Progress bar (in AI or Online modes)
        if (widget.mode != 'local') ...[
          _buildOpponentProgressCard(opponentCard, p2Name),
          const SizedBox(height: PlayNedTokens.space12),
        ],

        // Local Pass & Play Tabs
        if (widget.mode == 'local') ...[
          _buildLocalPlayerTabs(p1Name, p2Name),
          const SizedBox(height: PlayNedTokens.space8),
        ],

        // Bingo Card
        BingoCardWidget(
          card: widget.mode == 'local'
              ? (_activeLocalPlayerIndex == 0 ? localCard : opponentCard)
              : localCard,
          playerTitle: widget.mode == 'local'
              ? (_activeLocalPlayerIndex == 0 ? p1Name : p2Name)
              : p1Name,
          accentColor: _accent,
          winningCells: _state.winningCells,
          lastCalledNumber: _state.currentNumber,
        ),
        const SizedBox(height: PlayNedTokens.space16),

        // Called Numbers History Board
        BingoHistoryWidget(
          drawnNumbers: _state.drawnNumbers,
          latestNumber: _state.currentNumber,
          accentColor: _accent,
        ),
      ],
    );
  }

  Widget _buildLocalPlayerTabs(String p1Name, String p2Name) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
        border: Border.all(color: PlayNedTokens.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
              onTap: () => setState(() => _activeLocalPlayerIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeLocalPlayerIndex == 0 ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                ),
                alignment: Alignment.center,
                child: Text(
                  p1Name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _activeLocalPlayerIndex == 0 ? PlayNedTokens.textInverse : PlayNedTokens.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
              onTap: () => setState(() => _activeLocalPlayerIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeLocalPlayerIndex == 1 ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                ),
                alignment: Alignment.center,
                child: Text(
                  p2Name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _activeLocalPlayerIndex == 1 ? PlayNedTokens.textInverse : PlayNedTokens.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentProgressCard(BingoCard opponentCard, String opponentName) {
    final markedCount = opponentCard.markedCount;
    final progress = markedCount / 25.0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(PlayNedTokens.space12),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(color: PlayNedTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.mode == 'ai' ? Icons.smart_toy_outlined : Icons.person_outline,
                    size: 15,
                    color: PlayNedTokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opponentName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PlayNedTokens.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '$markedCount/25 MARKED',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: PlayNedTokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: PlayNedTokens.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(_accent.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
