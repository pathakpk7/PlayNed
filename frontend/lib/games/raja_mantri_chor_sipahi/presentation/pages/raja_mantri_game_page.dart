import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../platform/services/platform_api_service.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import '../../models/raja_mantri_models.dart';
import '../../services/raja_mantri_engine.dart';
import '../widgets/role_card_widget.dart';
import '../widgets/privacy_screen_widget.dart';
import '../widgets/round_result_dialog.dart';

class RajaMantriGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local', 'online'
  final String? roomCode;
  final String? localPlayerId;
  final List<String>? initialPlayerNames;
  final int totalRounds;

  const RajaMantriGamePage({
    super.key,
    this.mode = 'local',
    this.roomCode,
    this.localPlayerId,
    this.initialPlayerNames,
    this.totalRounds = 5,
  });

  @override
  ConsumerState<RajaMantriGamePage> createState() => _RajaMantriGamePageState();
}

class _RajaMantriGamePageState extends ConsumerState<RajaMantriGamePage> {
  late RajaMantriState _state;

  // Local Pass & Play private view index (0..3)
  int _localPassIndex = 0;

  // Suspect selection for Mantri
  String? _selectedSuspectId;

  // Online WebSocket
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;
  bool _isHost = false;
  bool _opponentDisconnected = false;

  // Statistics recorded flag
  bool _statsRecorded = false;

  static const Color _accent = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    if (widget.mode == 'local') {
      final names = widget.initialPlayerNames ?? ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
      final pIds = ['p1', 'p2', 'p3', 'p4'];
      final pNames = {
        'p1': names.isNotEmpty ? names[0] : 'Player 1',
        'p2': names.length > 1 ? names[1] : 'Player 2',
        'p3': names.length > 2 ? names[2] : 'Player 3',
        'p4': names.length > 3 ? names[3] : 'Player 4',
      };

      _state = RajaMantriLocalEngine.createInitialState(
        playerIds: pIds,
        playerNames: pNames,
        totalRounds: widget.totalRounds,
      );
    } else {
      // Temporary initial state for online room while fetching
      _state = RajaMantriState(
        phase: RajaMantriPhase.chitReveal,
        playerIds: const [],
        playerNames: const {},
        totalRounds: widget.totalRounds,
      );
      _setupOnlineRoom();
    }
  }

  Future<void> _setupOnlineRoom() async {
    if (widget.roomCode == null) return;
    final api = ref.read(platformApiServiceProvider);
    final pid = widget.localPlayerId ?? 'p_player';

    try {
      final room = await api.getRoom(widget.roomCode!);
      _isHost = (room.hostPlayerId == pid);

      if (room.matchState != null) {
        if (mounted) {
          setState(() {
            _state = RajaMantriState.fromJson(room.matchState!);
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
            _state = RajaMantriState.fromJson(roomData['match_state']);
            _opponentDisconnected = false;
          });
          if (_state.phase == RajaMantriPhase.fullReveal || _state.phase == RajaMantriPhase.matchResults) {
            _showResultModal();
          }
        }
      }
    } else if (eventType == 'PLAYER_DISCONNECTED') {
      final pid = data['player_id'];
      if (pid != (widget.localPlayerId ?? 'p1')) {
        if (mounted) setState(() => _opponentDisconnected = true);
      }
    } else if (eventType == 'PLAYER_CONNECTED') {
      final pid = data['player_id'];
      if (pid != (widget.localPlayerId ?? 'p1')) {
        if (mounted) setState(() => _opponentDisconnected = false);
      }
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _sendOnlineMove(Map<String, dynamic> move) {
    if (widget.mode != 'online' || widget.roomCode == null) return;
    final pid = widget.localPlayerId ?? 'p1';

    if (_wsChannel != null && _isConnected) {
      _wsChannel!.sink.add(jsonEncode({
        'type': 'MOVE',
        'move': move,
      }));
    } else {
      final api = ref.read(platformApiServiceProvider);
      api.submitMove(
        roomCode: widget.roomCode!,
        playerId: pid,
        move: move,
      ).then((room) {
        if (mounted && room.matchState != null) {
          setState(() {
            _state = RajaMantriState.fromJson(room.matchState!);
          });
        }
      }).catchError((_) {});
    }
  }

  // Local Pass & Play actions
  void _onLocalRoleHiddenAndPassed() {
    if (_localPassIndex < 3) {
      setState(() {
        _localPassIndex++;
      });
    } else {
      // All 4 players have seen their chits
      setState(() {
        _state = RajaMantriLocalEngine.acknowledgeChit(
          _state,
          _state.playerIds[3],
          forceAdvance: true,
        );
        _localPassIndex = 0;
      });
    }
  }

  void _onCallMantri() {
    if (widget.mode == 'local') {
      setState(() {
        _state = RajaMantriLocalEngine.callMantri(_state);
      });
    } else {
      _sendOnlineMove({'action': 'call_mantri'});
    }
  }

  void _onStepForward() {
    if (widget.mode == 'local') {
      setState(() {
        _state = RajaMantriLocalEngine.stepForward(_state);
      });
    } else {
      _sendOnlineMove({'action': 'step_forward'});
    }
  }

  void _confirmAndSubmitGuess(String targetPid) {
    final targetName = _state.getPlayerName(targetPid);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PlayNedTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
          side: const BorderSide(color: _accent, width: 1.5),
        ),
        title: Text(
          'ACCUSE CHOR?',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PlayNedTokens.textPrimary,
          ),
        ),
        content: Text(
          'Are you certain that $targetName is the secret Chor? Once locked in, this accusation cannot be changed.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: PlayNedTokens.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(color: PlayNedTokens.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: PlayNedTokens.textInverse,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeGuess(targetPid);
            },
            child: Text(
              'LOCK ACCUSATION',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _executeGuess(String targetPid) {
    if (widget.mode == 'local') {
      setState(() {
        _state = RajaMantriLocalEngine.submitGuess(_state, targetPid);
        _selectedSuspectId = null;
      });
      _showResultModal();
    } else {
      _sendOnlineMove({
        'action': 'guess_chor',
        'target_player_id': targetPid,
      });
    }
  }

  void _showResultModal() {
    if (_state.phase == RajaMantriPhase.matchResults || _state.isGameOver) {
      _recordMatchStats();
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => RajaMantriResultDialog(
          state: _state,
          isHost: _isHost,
          onNextRound: () {
            Navigator.pop(context);
            _advanceToNextRound();
          },
          onRematch: () {
            Navigator.pop(context);
            _restartMatch();
          },
        ),
      );
    });
  }

  void _advanceToNextRound() {
    if (widget.mode == 'local') {
      setState(() {
        _state = RajaMantriLocalEngine.nextRound(_state);
        _localPassIndex = 0;
        _selectedSuspectId = null;
      });
      if (_state.phase == RajaMantriPhase.matchResults) {
        _showResultModal();
      }
    } else {
      _sendOnlineMove({'action': 'next_round'});
    }
  }

  void _restartMatch() {
    if (widget.mode == 'local') {
      setState(() {
        _statsRecorded = false;
        _initializeGame();
      });
    } else {
      _sendOnlineMove({'action': 'rematch'});
    }
  }

  void _recordMatchStats() {
    if (_statsRecorded) return;
    _statsRecorded = true;

    final auth = ref.read(authProvider);
    final userId = auth.userId;
    if (userId != null) {
      final isLocalWinner = _state.winnerPlayerIds.contains(_state.playerIds.first);
      final outcome = _state.isTie ? 'tie' : (isLocalWinner ? 'win' : 'loss');

      final api = ref.read(platformApiServiceProvider);
      api.recordGameResult(
        userId: userId,
        gameId: 'raja_mantri_chor_sipahi',
        sectionId: widget.mode == 'online' ? 'multiplayer' : 'local_pass_and_play',
        outcome: outcome,
        score: _state.getPlayerScore(_state.playerIds.first),
        extraStatsUpdate: {
          'rounds_played': _state.currentRound,
          'mode': widget.mode,
        },
      ).catchError((_) => null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: AppBar(
        backgroundColor: PlayNedTokens.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PlayNedTokens.textPrimary),
          onPressed: () => context.go('/games/raja_mantri_chor_sipahi'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RAJA MANTRI CHOR SIPAHI',
              style: GoogleFonts.cinzel(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: PlayNedTokens.textPrimary,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Round ${_state.currentRound} of ${_state.totalRounds} • ${widget.mode.toUpperCase()}',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: _accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Online connection pill
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
        child: _opponentDisconnected && widget.mode == 'online'
            ? _buildDisconnectedBanner()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(PlayNedTokens.space16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: _buildPhaseContent(),
                  ),
                ),
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
              'A Player Disconnected',
              style: PlayNedTokens.gameTitle.copyWith(color: PlayNedTokens.terracotta),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for players to reconnect to room ${widget.roomCode}...',
              style: PlayNedTokens.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PlayNedTokens.surfaceElevated,
                foregroundColor: PlayNedTokens.textPrimary,
              ),
              onPressed: () => context.go('/games/raja_mantri_chor_sipahi'),
              child: const Text('EXIT ROOM'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_state.phase) {
      case RajaMantriPhase.chitReveal:
        return _buildChitRevealPhase();
      case RajaMantriPhase.rajaReveal:
        return _buildRajaRevealPhase();
      case RajaMantriPhase.mantriReveal:
        return _buildMantriRevealPhase();
      case RajaMantriPhase.chorGuess:
        return _buildChorGuessPhase();
      case RajaMantriPhase.fullReveal:
      case RajaMantriPhase.roundResults:
      case RajaMantriPhase.matchResults:
        return _buildFullRevealView();
    }
  }

  // 1. Private Chit Reveal
  Widget _buildChitRevealPhase() {
    if (widget.mode == 'local') {
      final pid = _state.playerIds[_localPassIndex];
      final name = _state.getPlayerName(pid);
      final role = _state.roleAssignments[pid] ?? RajaMantriRole.raja;

      return LocalPassPrivacyWidget(
        key: ValueKey('local_pass_$_localPassIndex'),
        playerIndex: _localPassIndex,
        playerName: name,
        role: role,
        onRoleHiddenAndPassed: _onLocalRoleHiddenAndPassed,
      );
    }

    // Online Mode: Private Chit View
    final myRole = _state.myRole;
    final myPid = widget.localPlayerId ?? 'p1';
    final hasAck = _state.acknowledgedPlayers.contains(myPid);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        border: Border.all(color: PlayNedTokens.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
              border: Border.all(color: _accent.withOpacity(0.4)),
            ),
            child: Text(
              'SECRET CHIT REVEAL',
              style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w700, color: _accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'YOUR ASSIGNED ROLE',
            style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.w800, color: PlayNedTokens.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your role confidential from other players!',
            style: GoogleFonts.inter(fontSize: 13, color: PlayNedTokens.textSecondary),
          ),
          const SizedBox(height: 24),
          if (myRole != null)
            RoleCardWidget(
              role: myRole,
              isRevealed: true,
              playerName: _state.getPlayerName(myPid),
              width: 170,
              height: 230,
              showPoints: true,
            ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasAck ? PlayNedTokens.surfaceElevated : _accent,
              foregroundColor: hasAck ? PlayNedTokens.textMuted : PlayNedTokens.textInverse,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
            ),
            onPressed: hasAck ? null : () => _sendOnlineMove({'action': 'acknowledge_chit'}),
            icon: Icon(hasAck ? Icons.check : Icons.lock_outline, size: 18),
            label: Text(
              hasAck
                  ? 'WAITING FOR OTHERS (${_state.acknowledgedPlayers.length}/4)'
                  : 'I HAVE SEEN MY CHIT',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Raja Reveal
  Widget _buildRajaRevealPhase() {
    final rajaPid = _state.rajaPlayerId!;
    final rajaName = _state.getPlayerName(rajaPid);
    final isMeRaja = (widget.mode == 'online' && widget.localPlayerId == rajaPid) ||
        (widget.mode == 'local');

    return Column(
      children: [
        _buildPhaseHeader(
          badge: 'PHASE 2: THE KING COMMANDS',
          headline: 'MERA MANTRI KAUN HAI?',
          description: '$rajaName is the Raja (King) and summons their Minister to step forward!',
        ),
        const SizedBox(height: 24),
        Center(
          child: RoleCardWidget(
            role: RajaMantriRole.raja,
            isRevealed: true,
            playerName: rajaName,
            width: 180,
            height: 240,
            subtitle: 'The Sovereign King',
          ),
        ),
        const SizedBox(height: 32),
        if (isMeRaja || _isHost)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: PlayNedTokens.textInverse,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
            ),
            onPressed: _onCallMantri,
            icon: const Icon(Icons.campaign, size: 20),
            label: Text(
              'CALL MANTRI TO STEP FORWARD',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          )
        else
          Text(
            'Waiting for Raja to summon the Mantri...',
            style: GoogleFonts.inter(fontSize: 13, color: PlayNedTokens.textMuted),
          ),
      ],
    );
  }

  // 3. Mantri Reveal
  Widget _buildMantriRevealPhase() {
    final rajaPid = _state.rajaPlayerId!;
    final rajaName = _state.getPlayerName(rajaPid);
    final mantriPid = _state.mantriPlayerId!;
    final mantriName = _state.getPlayerName(mantriPid);
    final isMeMantri = (widget.mode == 'online' && widget.localPlayerId == mantriPid) ||
        (widget.mode == 'local');

    return Column(
      children: [
        _buildPhaseHeader(
          badge: 'PHASE 3: THE MINISTER REVEALS',
          headline: 'MANTRI STEPS FORWARD',
          description: '$mantriName bows before the King and must now find the hidden Chor!',
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoleCardWidget(
              role: RajaMantriRole.raja,
              isRevealed: true,
              playerName: rajaName,
              width: 160,
              height: 220,
            ),
            const SizedBox(width: 20),
            RoleCardWidget(
              role: RajaMantriRole.mantri,
              isRevealed: true,
              playerName: mantriName,
              width: 160,
              height: 220,
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (isMeMantri || _isHost)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: PlayNedTokens.textInverse,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
            ),
            onPressed: _onStepForward,
            icon: const Icon(Icons.search, size: 20),
            label: Text(
              'INVESTIGATE SUSPECTS',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          )
        else
          Text(
            'Waiting for Mantri to begin investigation...',
            style: GoogleFonts.inter(fontSize: 13, color: PlayNedTokens.textMuted),
          ),
      ],
    );
  }

  // 4. Chor Guess
  Widget _buildChorGuessPhase() {
    final mantriName = _state.getPlayerName(_state.mantriPlayerId ?? '');
    final eligible = _state.eligibleSuspectIds;
    final isMeMantri = (widget.mode == 'online' && widget.localPlayerId == _state.mantriPlayerId) ||
        (widget.mode == 'local');

    return Column(
      children: [
        _buildPhaseHeader(
          badge: 'PHASE 4: DEDUCTION & ACCUSATION',
          headline: 'WHO IS THE CHOR?',
          description: '$mantriName must choose between the two unrevealed players.',
        ),
        const SizedBox(height: 24),
        Text(
          'SUSPECT LINEUP (ONE IS SIPAHI, ONE IS CHOR)',
          style: GoogleFonts.spaceMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: PlayNedTokens.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: eligible.map((suspectPid) {
            final suspectName = _state.getPlayerName(suspectPid);
            final isSelected = _selectedSuspectId == suspectPid;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: RoleCardWidget(
                isRevealed: false,
                playerName: suspectName,
                subtitle: 'SUSPECT',
                isSelected: isSelected,
                isEligibleSuspect: true,
                width: 160,
                height: 220,
                onTap: isMeMantri
                    ? () {
                        setState(() {
                          _selectedSuspectId = suspectPid;
                        });
                      }
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        if (isMeMantri) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedSuspectId != null ? const Color(0xFFF43F5E) : PlayNedTokens.surfaceElevated,
              foregroundColor: _selectedSuspectId != null ? Colors.white : PlayNedTokens.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
            ),
            onPressed: _selectedSuspectId != null
                ? () => _confirmAndSubmitGuess(_selectedSuspectId!)
                : null,
            icon: const Icon(Icons.gavel, size: 20),
            label: Text(
              _selectedSuspectId != null
                  ? 'ACCUSE ${_state.getPlayerName(_selectedSuspectId!).toUpperCase()}'
                  : 'SELECT A SUSPECT ABOVE',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ] else ...[
          Text(
            'Waiting for Mantri ($mantriName) to deduce the Chor...',
            style: GoogleFonts.inter(fontSize: 13, color: PlayNedTokens.textMuted),
          ),
        ],
      ],
    );
  }

  // 5. Full Reveal View
  Widget _buildFullRevealView() {
    return Column(
      children: [
        _buildPhaseHeader(
          badge: 'ALL ROLES REVEALED',
          headline: _state.guessCorrect == true ? 'THIEF APPREHENDED!' : 'THIEF EVADED CAPTURE!',
          description: _state.lastAction,
        ),
        const SizedBox(height: 24),

        // Grid of 4 Role Cards
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _state.playerIds.map((pid) {
            final role = _state.getPlayerRole(pid);
            final name = _state.getPlayerName(pid);
            final pts = _state.getPlayerRoundPoints(pid);

            return RoleCardWidget(
              role: role,
              isRevealed: true,
              playerName: name,
              subtitle: '+$pts PTS',
              width: 155,
              height: 215,
              showPoints: true,
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // View Results Dialog Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: PlayNedTokens.textInverse,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm)),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => RajaMantriResultDialog(
                state: _state,
                isHost: _isHost,
                onNextRound: () {
                  Navigator.pop(context);
                  _advanceToNextRound();
                },
                onRematch: () {
                  Navigator.pop(context);
                  _restartMatch();
                },
              ),
            );
          },
          icon: const Icon(Icons.leaderboard, size: 20),
          label: Text(
            _state.phase == RajaMantriPhase.matchResults ? 'VIEW FINAL STANDINGS' : 'VIEW SCOREBOARD',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseHeader({
    required String badge,
    required String headline,
    required String description,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusPill),
            border: Border.all(color: _accent.withOpacity(0.4)),
          ),
          child: Text(
            badge,
            style: GoogleFonts.spaceMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _accent,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: PlayNedTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: PlayNedTokens.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
