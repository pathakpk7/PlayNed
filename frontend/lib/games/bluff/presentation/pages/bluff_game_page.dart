import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/platform_app_bar.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/services/platform_api_service.dart';

import '../../models/bluff_models.dart';
import '../../services/bluff_engine.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/bluff_table_widget.dart';
import '../widgets/bluff_privacy_dialog.dart';
import '../widgets/bluff_challenge_dialog.dart';

class BluffGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local' or 'online'
  final String? roomCode;
  final String? localPlayerId;
  final List<String>? initialPlayerNames;

  const BluffGamePage({
    super.key,
    this.mode = 'local',
    this.roomCode,
    this.localPlayerId,
    this.initialPlayerNames,
  });

  @override
  ConsumerState<BluffGamePage> createState() => _BluffGamePageState();
}

class _BluffGamePageState extends ConsumerState<BluffGamePage> {
  final BluffLocalEngine _localEngine = BluffLocalEngine();
  late BluffState _state;

  // Local Pass & Play State
  int _localTurnIndex = 0;
  bool _isPrivacyScreenVisible = false;

  // Selected Cards for Active Play
  final Set<String> _selectedCardCodes = {};

  // Online Multiplayer State
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;
  bool _isOnlineMoveLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'local') {
      _initLocalGame();
    } else {
      _initOnlinePlaceholder();
      _setupOnlineRoom();
    }
  }

  void _initLocalGame() {
    final names = widget.initialPlayerNames ?? ['Player 1', 'Player 2', 'Player 3'];
    final pIds = List.generate(names.length, (i) => 'p${i + 1}');
    final pMap = {for (var i = 0; i < names.length; i++) pIds[i]: names[i]};

    _state = _localEngine.createInitialState(
      playerIds: pIds,
      playerNames: pMap,
    );
    _localTurnIndex = 0;
    _isPrivacyScreenVisible = true; // Start with privacy screen so Player 1 can view
  }

  void _initOnlinePlaceholder() {
    _state = BluffState(
      phase: BluffPhase.play,
      playerIds: const [],
      playerNames: const {},
      currentPlayerId: widget.localPlayerId ?? 'p1',
      lastAction: 'Connecting to room ${widget.roomCode ?? ''}...',
    );
  }

  Future<void> _setupOnlineRoom() async {
    if (widget.roomCode == null) return;
    final api = ref.read(platformApiServiceProvider);
    final pid = widget.localPlayerId ?? 'p1';

    try {
      final room = await api.getRoom(widget.roomCode!);
      if (room.matchState != null && mounted) {
        setState(() {
          _state = BluffState.fromJson(room.matchState!);
        });
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
      if (roomData != null && roomData['match_state'] != null && mounted) {
        setState(() {
          _state = BluffState.fromJson(roomData['match_state']);
          _selectedCardCodes.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  String get _currentPerspectivePlayerId {
    if (widget.mode == 'local') {
      if (_state.playerIds.isEmpty) return 'p1';
      return _state.playerIds[_localTurnIndex % _state.playerIds.length];
    }
    return widget.localPlayerId ?? (_state.playerIds.isNotEmpty ? _state.playerIds[0] : 'p1');
  }

  List<PlayingCard> get _currentVisibleHand {
    if (widget.mode == 'local') {
      final pid = _currentPerspectivePlayerId;
      return _state.hands[pid] ?? [];
    }
    return _state.myHand;
  }

  void _toggleCardSelection(PlayingCard card) {
    if (_state.phase != BluffPhase.play) return;
    if (_state.currentPlayerId != _currentPerspectivePlayerId) return;

    setState(() {
      if (_selectedCardCodes.contains(card.rawCode)) {
        _selectedCardCodes.remove(card.rawCode);
      } else {
        _selectedCardCodes.add(card.rawCode);
      }
    });
  }

  void _handlePlayCards() {
    if (_selectedCardCodes.isEmpty) return;
    final pid = _currentPerspectivePlayerId;
    final cardsList = _selectedCardCodes.toList();

    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, pid, {
          'action': 'play_cards',
          'cards': cardsList,
        });
        _selectedCardCodes.clear();
      });
    } else {
      _sendOnlineMove({
        'action': 'play_cards',
        'cards': cardsList,
      });
    }
  }

  void _handleChallenge([String? specificChallengerId]) {
    final challengerId = specificChallengerId ?? _currentPerspectivePlayerId;
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, challengerId, {
          'action': 'challenge',
        });
      });
    } else {
      _sendOnlineMove({
        'action': 'challenge',
      });
    }
  }

  void _handlePass() {
    final pid = _currentPerspectivePlayerId;
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, pid, {
          'action': 'pass',
          'force_advance': true, // In pass & play, tapping Next Turn advances
        });
        if (_state.phase == BluffPhase.play) {
          _localTurnIndex = _state.currentPlayerIndex;
          _isPrivacyScreenVisible = true; // Show privacy screen for next player
        }
      });
    } else {
      _sendOnlineMove({
        'action': 'pass',
      });
    }
  }

  void _handleContinueAfterChallenge() {
    final pid = _currentPerspectivePlayerId;
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, pid, {
          'action': 'continue_after_challenge',
        });
        if (_state.phase == BluffPhase.play) {
          _localTurnIndex = _state.currentPlayerIndex;
          _isPrivacyScreenVisible = true; // Pass device to next lead player
        }
      });
    } else {
      _sendOnlineMove({
        'action': 'continue_after_challenge',
      });
    }
  }

  void _handleRematch() {
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, _currentPerspectivePlayerId, {
          'action': 'rematch',
        });
        _localTurnIndex = 0;
        _isPrivacyScreenVisible = true;
        _selectedCardCodes.clear();
      });
    } else {
      _sendOnlineMove({
        'action': 'rematch',
      });
    }
  }

  void _sendOnlineMove(Map<String, dynamic> move) {
    if (widget.roomCode == null) return;
    final pid = widget.localPlayerId ?? 'p1';

    setState(() => _isOnlineMoveLoading = true);
    if (_wsChannel != null && _isConnected) {
      _wsChannel!.sink.add(jsonEncode({
        'type': 'MOVE',
        'move': move,
      }));
      setState(() => _isOnlineMoveLoading = false);
    } else {
      final api = ref.read(platformApiServiceProvider);
      api.submitMove(
        roomCode: widget.roomCode!,
        playerId: pid,
        move: move,
      ).then((room) {
        if (mounted && room.matchState != null) {
          setState(() {
            _state = BluffState.fromJson(room.matchState!);
            _selectedCardCodes.clear();
            _isOnlineMoveLoading = false;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _isOnlineMoveLoading = false);
      });
    }
  }

  void _showLocalWhoIsChallengingDialog() {
    final lastPlayerId = _state.lastPlay?.playerId;
    final opponents = _state.playerIds.where((p) => p != lastPlayerId).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF13101E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          side: const BorderSide(color: Color(0xFFE11D48), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PlayNedTokens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WHO IS CALLING BLUFF?',
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFB7185),
                ),
              ),
              const SizedBox(height: 12),
              ...opponents.map((pid) {
                final name = _state.getPlayerName(pid);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleChallenge(pid);
                      },
                      child: Text(
                        '$name Calls Bluff!',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPid = _currentPerspectivePlayerId;
    final isMyTurn = _state.currentPlayerId == currentPid;
    final currentHand = _currentVisibleHand;
    final lastPlay = _state.lastPlay;
    final canChallenge = _state.phase == BluffPhase.challenge &&
        (widget.mode == 'local' || lastPlay?.playerId != currentPid);
    final canPass = _state.phase == BluffPhase.challenge &&
        (widget.mode == 'local' || lastPlay?.playerId != currentPid);

    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: PlatformAppBar(
        title: widget.mode == 'local'
            ? 'Bluff (${_state.playerIds.length}P Local)'
            : 'Bluff / Cheat Room',
      ),
      body: PlayNedBackgroundPattern(
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.all(PlayNedTokens.space12),
                    child: Column(
                      children: [
                        // 1. Table Arena (Opponents + Center Pile + Challenge banner)
                        Expanded(
                          flex: 11,
                          child: BluffTableWidget(
                            state: _state,
                            activePerspectivePlayerId: currentPid,
                            canChallenge: canChallenge,
                            canPass: canPass,
                            onChallengePressed: () {
                              if (widget.mode == 'local') {
                                _showLocalWhoIsChallengingDialog();
                              } else {
                                _handleChallenge();
                              }
                            },
                            onPassPressed: _handlePass,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 2. Status / Action Log Ribbon
                        _buildStatusRibbon(isMyTurn),

                        const SizedBox(height: 10),

                        // 3. Player's Hand Tray & Action Controls
                        Expanded(
                          flex: 9,
                          child: _buildHandTray(isMyTurn, currentHand),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Privacy Screen Overlay for Local Pass & Play
            if (widget.mode == 'local' && _isPrivacyScreenVisible)
              Positioned.fill(
                child: BluffPrivacyDialog(
                  nextPlayerName: _state.getPlayerName(currentPid),
                  onReveal: () {
                    setState(() => _isPrivacyScreenVisible = false);
                  },
                ),
              ),

            // Challenge Reveal Dialog
            if (_state.phase == BluffPhase.challengeReveal && _state.challengeResult != null)
              Positioned.fill(
                child: BluffChallengeDialog(
                  result: _state.challengeResult!,
                  onContinue: _handleContinueAfterChallenge,
                ),
              ),

            // Game Over Dialog
            if (_state.phase == BluffPhase.gameOver)
              Positioned.fill(
                child: _buildGameOverOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRibbon(bool isMyTurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(
          color: isMyTurn ? const Color(0xFF8B5CF6) : PlayNedTokens.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMyTurn ? Icons.play_arrow : Icons.info_outline,
            size: 16,
            color: isMyTurn ? const Color(0xFF8B5CF6) : PlayNedTokens.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _state.lastAction,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isMyTurn ? FontWeight.bold : FontWeight.w500,
                color: isMyTurn ? PlayNedTokens.textPrimary : PlayNedTokens.textSecondary,
              ),
            ),
          ),
          if (widget.mode == 'local')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.18),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Turn: ${_state.getPlayerName(_currentPerspectivePlayerId)}',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFA78BFA),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHandTray(bool isMyTurn, List<PlayingCard> hand) {
    final count = _selectedCardCodes.length;
    final reqRank = _state.requiredRank;

    return PlayNedCard(
      padding: const EdgeInsets.all(PlayNedTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hand Header: Card count & Play Action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.style, size: 16, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 6),
                  Text(
                    'YOUR HAND (${hand.length})',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: PlayNedTokens.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_state.phase == BluffPhase.play && isMyTurn)
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_upward, size: 14),
                  label: Text(
                    count == 0
                        ? 'SELECT CARDS TO PLAY'
                        : 'PLAY $count CARD${count > 1 ? 'S' : ''} AS ${reqRank}S',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: count > 0 ? const Color(0xFF8B5CF6) : PlayNedTokens.surfaceHover,
                    foregroundColor: count > 0 ? Colors.white : PlayNedTokens.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (count > 0 && !_isOnlineMoveLoading) ? _handlePlayCards : null,
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Scrollable Hand Cards
          Expanded(
            child: hand.isEmpty
                ? Center(
                    child: Text(
                      'No cards in hand!',
                      style: GoogleFonts.spaceMono(
                        fontSize: 13,
                        color: PlayNedTokens.textMuted,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: hand.map((card) {
                        final isSelected = _selectedCardCodes.contains(card.rawCode);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8, top: 8),
                          child: PlayingCardWidget(
                            card: card,
                            isFaceUp: true,
                            isSelected: isSelected,
                            width: 66,
                            height: 98,
                            onTap: () => _toggleCardSelection(card),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final winnerName = _state.winnerName ?? 'Player';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(PlayNedTokens.space16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(PlayNedTokens.space24),
        decoration: BoxDecoration(
          color: const Color(0xFF13101E),
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
          border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.35),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 52, color: Color(0xFFEAB308)),
            const SizedBox(height: 12),
            Text(
              'VICTORY!',
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFEAB308),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$winnerName WINS!',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: PlayNedTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Successfully emptied hand and survived all challenges.',
              textAlign: TextAlign.center,
              style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: PlayNedTokens.border),
                    ),
                    onPressed: () => context.go('/'),
                    child: Text(
                      'EXIT TO HUB',
                      style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _handleRematch,
                    child: Text(
                      'PLAY AGAIN',
                      style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
