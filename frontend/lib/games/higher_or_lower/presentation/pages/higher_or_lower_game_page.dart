import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hangman_reimagined/core/session/client_session.dart';
import 'package:hangman_reimagined/platform/models/game_model.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/game_how_to_play_demo_dialog.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/platform_app_bar.dart';
import 'package:hangman_reimagined/platform/services/platform_api_service.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import 'package:hangman_reimagined/games/higher_or_lower/models/higher_or_lower_models.dart';
import 'package:hangman_reimagined/games/higher_or_lower/services/higher_or_lower_engine.dart';

class HigherOrLowerGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local', 'ai', 'online'
  final String? roomCode;
  final String? localPlayerId;

  const HigherOrLowerGamePage({
    super.key,
    this.mode = 'ai',
    this.roomCode,
    this.localPlayerId,
  });

  @override
  ConsumerState<HigherOrLowerGamePage> createState() => _HigherOrLowerGamePageState();
}

class _HigherOrLowerGamePageState extends ConsumerState<HigherOrLowerGamePage>
    with SingleTickerProviderStateMixin {
  late HigherOrLowerState _state;
  final HigherOrLowerLocalEngine _engine = HigherOrLowerLocalEngine();
  bool _isAiThinking = false;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  late AnimationController _cardAnimController;
  late Animation<double> _cardScaleAnim;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutBack),
    );
    _cardAnimController.forward();

    if (widget.mode == 'online' && widget.roomCode != null) {
      _initOnlineMode();
    } else {
      _initLocalMode();
    }
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _initLocalMode() {
    final session = ref.read(clientSessionProvider);
    final isAi = widget.mode == 'ai';
    final p1 = session.playerId;
    final p2 = isAi ? 'bot_ai' : 'p2';
    final pNames = {
      p1: session.playerName,
      p2: isAi ? 'Predictor AI' : 'Player 2',
    };

    _state = _engine.createInitialState(
      playerIds: [p1, p2],
      playerNames: pNames,
      matchMode: 'classic',
      totalRounds: 20,
    );
  }

  void _initOnlineMode() async {
    final session = ref.read(clientSessionProvider);
    final myPid = widget.localPlayerId ?? session.playerId;
    final api = ref.read(platformApiServiceProvider);

    try {
      final room = await api.getRoom(widget.roomCode!);
      if (room.matchState != null) {
        _applyBackendState(room.matchState!);
      } else {
        _initLocalMode();
      }

      _wsChannel = api.connectWebSocket(widget.roomCode!, myPid);
      _wsSubscription = _wsChannel?.stream.listen((message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          if (data['room'] != null && data['room']['match_state'] != null) {
            _applyBackendState(data['room']['match_state'] as Map<String, dynamic>);
          } else if (data['match_state'] != null) {
            _applyBackendState(data['match_state'] as Map<String, dynamic>);
          }
        } catch (_) {}
      });
    } catch (_) {
      _initLocalMode();
    }
  }

  void _applyBackendState(Map<String, dynamic> stateJson) {
    if (!mounted) return;
    setState(() {
      _state = HigherOrLowerState.fromJson(stateJson);
    });
    _cardAnimController.forward(from: 0.0);
  }

  void _submitPrediction(PredictionDirection direction) async {
    if (_state.isFinished || _isAiThinking) return;

    final session = ref.read(clientSessionProvider);
    final myPid = widget.localPlayerId ?? session.playerId;

    if (widget.mode == 'online' && widget.roomCode != null) {
      if (_state.currentTurnPlayerId != myPid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wait for your opponent's turn!")),
        );
        return;
      }

      final movePayload = {'direction': direction.toServerString()};
      if (_wsChannel != null) {
        _wsChannel!.sink.add(jsonEncode({
          'type': 'MOVE',
          'action': 'predict',
          'move': movePayload,
        }));
      }

      final api = ref.read(platformApiServiceProvider);
      api.submitMove(
        roomCode: widget.roomCode!,
        playerId: myPid,
        move: movePayload,
      ).then((room) {
        if (mounted && room.matchState != null) {
          _applyBackendState(room.matchState!);
        }
      }).catchError((_) {});
      return;
    }

    // Local / AI execution
    final updated = _engine.applyPrediction(
      _state,
      playerId: _state.currentTurnPlayerId,
      direction: direction,
    );

    setState(() {
      _state = updated;
    });
    _cardAnimController.forward(from: 0.0);

    // If next turn is AI
    if (widget.mode == 'ai' && !_state.isFinished && _state.currentTurnPlayerId == 'bot_ai') {
      _triggerAiTurn();
    }
  }

  void _triggerAiTurn() async {
    setState(() => _isAiThinking = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted || _state.isFinished) {
      setState(() => _isAiThinking = false);
      return;
    }

    final aiPred = _engine.getAiPrediction(_state.currentNumber);
    final updated = _engine.applyPrediction(
      _state,
      playerId: 'bot_ai',
      direction: aiPred,
    );

    if (mounted) {
      setState(() {
        _state = updated;
        _isAiThinking = false;
      });
      _cardAnimController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(clientSessionProvider);
    final myPid = widget.localPlayerId ?? session.playerId;
    final isMyTurn = widget.mode != 'online' || _state.currentTurnPlayerId == myPid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: PlatformAppBar(
        title: "HIGHER OR LOWER",
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF6366F1)),
            tooltip: "Demo & Rules",
            onPressed: () => GameHowToPlayDemoDialog.show(context, 'higher_or_lower'),
          ),
          if (widget.mode != 'online')
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: "Restart Match",
              onPressed: () => setState(() => _initLocalMode()),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Match Header Info
                  _buildHeaderCard(),
                  const SizedBox(height: 20),

                  // Center Number Display
                  ScaleTransition(
                    scale: _cardScaleAnim,
                    child: _buildNumberCard(),
                  ),
                  const SizedBox(height: 20),

                  // Action Announcement
                  _buildActionAnnouncement(),
                  const SizedBox(height: 24),

                  // Prediction Action Buttons
                  if (!_state.isFinished)
                    Row(
                      children: [
                        Expanded(
                          child: _buildPredictionButton(
                            label: "LOWER",
                            icon: Icons.arrow_downward_rounded,
                            color: const Color(0xFFEF4444),
                            enabled: isMyTurn && !_isAiThinking,
                            onTap: () => _submitPrediction(PredictionDirection.lower),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildPredictionButton(
                            label: "HIGHER",
                            icon: Icons.arrow_upward_rounded,
                            color: const Color(0xFF10B981),
                            enabled: isMyTurn && !_isAiThinking,
                            onTap: () => _submitPrediction(PredictionDirection.higher),
                          ),
                        ),
                      ],
                    ),

                  if (_state.isFinished) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_events, color: Color(0xFFFBBF24), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            "MATCH FINISHED!",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _state.lastAction,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (widget.mode == 'online') {
                                context.pop();
                              } else {
                                setState(() => _initLocalMode());
                              }
                            },
                            child: Text(widget.mode == 'online' ? "Return to Lobby" : "Play Again"),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Scoreboard
                  _buildScoreboard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161926),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E344A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.casino_outlined, color: Color(0xFF6366F1), size: 18),
              const SizedBox(width: 8),
              Text(
                "Round ${_state.roundNumber}${_state.totalRounds != null ? '/${_state.totalRounds}' : ''}",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
            ),
            child: Text(
              _isAiThinking ? "AI Thinking..." : "Turn: ${_state.playerNames[_state.currentTurnPlayerId] ?? 'Player'}",
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFA5B4FC)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFF2E2259), Color(0xFF131122)],
          radius: 1.0,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6366F1), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "CURRENT NUMBER",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: const Color(0xFFA5B4FC),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${_state.currentNumber}",
                style: GoogleFonts.outfit(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Range: ${_state.minNumber} - ${_state.maxNumber}",
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionAnnouncement() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181C2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C3246)),
      ),
      child: Text(
        _state.lastAction,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFFE2E8F0),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPredictionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: enabled ? 6 : 0,
      ),
      onPressed: enabled ? onTap : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E344A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SCOREBOARD & STREAKS",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: const Color(0xFFA5B4FC),
            ),
          ),
          const SizedBox(height: 12),
          ..._state.playerIds.map((pid) {
            final name = _state.playerNames[pid] ?? pid;
            final score = _state.scores[pid] ?? 0;
            final streak = _state.streaks[pid] ?? 0;
            final maxStreak = _state.maxStreaks[pid] ?? 0;
            final isCurrent = pid == _state.currentTurnPlayerId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF262C40) : const Color(0xFF1A1F30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isCurrent ? const Color(0xFF6366F1) : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCurrent ? Icons.arrow_right_alt : Icons.person_outline,
                        color: isCurrent ? const Color(0xFF6366F1) : Colors.white60,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "🔥 ${streak}x (Max $maxStreak)",
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "$score pts",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
