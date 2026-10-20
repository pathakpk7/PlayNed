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

import '../../models/spyfall_models.dart';
import '../../services/spyfall_engine.dart';
import '../widgets/spyfall_role_card_widget.dart';
import '../widgets/spyfall_timer_widget.dart';
import '../widgets/spyfall_player_roster_widget.dart';
import '../widgets/spyfall_voting_dialog.dart';
import '../widgets/spyfall_location_guess_dialog.dart';
import '../widgets/spyfall_round_result_dialog.dart';

class SpyfallGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local' or 'online'
  final String? roomCode;
  final String? localPlayerId;
  final List<String>? initialPlayerNames;
  final int roundDurationMinutes;
  final int totalRounds;
  final String category;

  const SpyfallGamePage({
    super.key,
    this.mode = 'local',
    this.roomCode,
    this.localPlayerId,
    this.initialPlayerNames,
    this.roundDurationMinutes = 8,
    this.totalRounds = 3,
    this.category = 'All',
  });

  @override
  ConsumerState<SpyfallGamePage> createState() => _SpyfallGamePageState();
}

class _SpyfallGamePageState extends ConsumerState<SpyfallGamePage> {
  final SpyfallLocalEngine _localEngine = SpyfallLocalEngine();
  late SpyfallState _state;

  // Local Pass & Play State
  int _localRevealIndex = 0;
  bool _isPrivacyScreenVisible = false;
  Timer? _localTimer;

  // Online State
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;

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
    final names = widget.initialPlayerNames ?? ['Agent Alpha', 'Agent Bravo', 'Agent Charlie'];
    final pIds = List.generate(names.length, (i) => 'p${i + 1}');
    final pMap = {for (var i = 0; i < names.length; i++) pIds[i]: names[i]};

    _state = _localEngine.createInitialState(
      playerIds: pIds,
      playerNames: pMap,
      roundDurationMinutes: widget.roundDurationMinutes,
      totalRounds: widget.totalRounds,
      category: widget.category,
    );
    _localRevealIndex = 0;
    _isPrivacyScreenVisible = true; // Show privacy curtain before Player 1 views
    _startOrUpdateLocalTimer();
  }

  void _initOnlinePlaceholder() {
    _state = SpyfallState(
      gameId: 'spyfall',
      phase: SpyfallPhase.roleReveal,
      playerIds: const [],
      playerNames: const {},
      currentRound: 1,
      totalRounds: widget.totalRounds,
      roundDurationMinutes: widget.roundDurationMinutes,
      category: widget.category,
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
          _state = SpyfallState.fromJson(room.matchState!);
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
          _state = SpyfallState.fromJson(roomData['match_state']);
        });
      }
    }
  }

  void _startOrUpdateLocalTimer() {
    _localTimer?.cancel();
    if (widget.mode != 'local') return;

    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_state.phase == SpyfallPhase.discussion && !_state.isTimerPaused) {
        if (_state.remainingSeconds > 0) {
          setState(() {
            _state = _state.copyWith(remainingSeconds: _state.remainingSeconds - 1);
          });
        } else {
          // Timer expired!
          setState(() {
            _state = _localEngine.applyMove(_state, _currentPerspectivePlayerId, {
              'action': 'time_expired',
            });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  String get _currentPerspectivePlayerId {
    if (widget.mode == 'local') {
      if (_state.phase == SpyfallPhase.roleReveal) {
        if (_state.playerIds.isEmpty) return 'p1';
        return _state.playerIds[_localRevealIndex % _state.playerIds.length];
      }
      return _state.playerIds.isNotEmpty ? _state.playerIds[0] : 'p1';
    }
    return widget.localPlayerId ?? (_state.playerIds.isNotEmpty ? _state.playerIds[0] : 'p1');
  }

  void _sendOnlineMove(Map<String, dynamic> move) {
    if (_wsChannel != null) {
      _wsChannel!.sink.add(jsonEncode({
        'action': 'move',
        'move': move,
      }));
    }
  }

  void _handleAccuse(String accusedId) {
    final accuserId = _currentPerspectivePlayerId;
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, accuserId, {
          'action': 'accuse',
          'accused_id': accusedId,
        });
      });
    } else {
      _sendOnlineMove({
        'action': 'accuse',
        'accused_id': accusedId,
      });
    }
  }

  void _handleVote(String voterId, String choice) {
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, voterId, {
          'action': 'vote',
          'choice': choice,
        });
      });
    } else {
      _sendOnlineMove({
        'action': 'vote',
        'choice': choice,
      });
    }
  }

  void _handleSpyGuess(String locationName) {
    final pid = _currentPerspectivePlayerId;
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, pid, {
          'action': 'spy_guess',
          'location': locationName,
        });
      });
    } else {
      _sendOnlineMove({
        'action': 'spy_guess',
        'location': locationName,
      });
    }
  }

  void _handleNextRound() {
    final pid = _currentPerspectivePlayerId;
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, pid, {
          'action': 'next_round',
        });
        _localRevealIndex = 0;
        _isPrivacyScreenVisible = true;
      });
    } else {
      _sendOnlineMove({
        'action': 'next_round',
      });
    }
  }

  void _handleRematch() {
    final pid = _currentPerspectivePlayerId;
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.applyMove(_state, pid, {
          'action': 'rematch',
        });
        _localRevealIndex = 0;
        _isPrivacyScreenVisible = true;
      });
    } else {
      _sendOnlineMove({
        'action': 'rematch',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: const PlatformAppBar(
        title: 'SPYFALL',
      ),
      body: SafeArea(
        child: PlayNedBackgroundPattern(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildMainContent(),
                  ),
                ),
              ),

              // Active Modals & Overlays
              if (_state.phase == SpyfallPhase.accusationVoting) _buildVotingOverlay(),
              if (_state.phase == SpyfallPhase.spyGuess) _buildSpyGuessOverlay(),
              if (_state.phase == SpyfallPhase.roundResolution || _state.phase == SpyfallPhase.matchResults)
                _buildRoundResultOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.mode == 'local' && _state.phase == SpyfallPhase.roleReveal) {
      return _buildLocalRoleReveal();
    }

    final isSpy = widget.mode == 'local'
        ? (_state.spyPlayerId == _currentPerspectivePlayerId)
        : (_state.myRole == 'spy');

    final locationName = widget.mode == 'local'
        ? (_state.spyPlayerId == _currentPerspectivePlayerId ? null : _state.secretLocation?.name)
        : _state.myLocation;

    final category = widget.mode == 'local'
        ? (_state.spyPlayerId == _currentPerspectivePlayerId ? null : _state.secretLocation?.category)
        : _state.myLocationCategory;

    final description = widget.mode == 'local'
        ? (_state.spyPlayerId == _currentPerspectivePlayerId ? null : _state.secretLocation?.description)
        : null;

    final themes = widget.mode == 'local'
        ? (_state.spyPlayerId == _currentPerspectivePlayerId ? <String>[] : _state.secretLocation?.themes ?? <String>[])
        : <String>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Stats Bar: Round and Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: PlayNedTokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(PlayNedTokens.radiusFull),
                      border: Border.all(color: PlayNedTokens.borderSubtle),
                    ),
                    child: Text(
                      'ROUND ${_state.currentRound} OF ${_state.totalRounds}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PlayNedTokens.brandGold,
                      ),
                    ),
                  ),
                  if (widget.mode == 'online') ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? PlayNedTokens.sageGreen : PlayNedTokens.accentSpyfall,
                      ),
                    ),
                  ],
                ],
              ),
              SpyfallTimerWidget(
                remainingSeconds: _state.remainingSeconds,
                totalDurationSeconds: _state.roundDurationMinutes * 60,
                isPaused: _state.isTimerPaused,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Classified Dossier Card
          SpyfallRoleCardWidget(
            isSpy: isSpy,
            locationName: locationName,
            category: category,
            description: description,
            themes: themes,
            onBrowseLocations: () => _openLocationDialog(isGuessMode: false),
          ),
          const SizedBox(height: 20),

          // Action Toolbar (Spy Guess or Browse)
          Row(
            children: [
              Expanded(
                child: PlayNedButton(
                  label: 'BROWSE LOCATIONS',
                  icon: Icons.map,
                  variant: PlayNedButtonVariant.secondary,
                  onPressed: () => _openLocationDialog(isGuessMode: false),
                ),
              ),
              if (isSpy || widget.mode == 'local') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: PlayNedButton(
                    label: 'GUESS LOCATION',
                    icon: Icons.my_location,
                    variant: PlayNedButtonVariant.primary,
                    accentColor: PlayNedTokens.accentSpyfall,
                    onPressed: () => _openLocationDialog(isGuessMode: true),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Player Roster
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUSPECTS & AGENTS (${_state.playerIds.length})',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: PlayNedTokens.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'TAP GAVEL TO ACCUSE',
                style: PlayNedTokens.metadata.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SpyfallPlayerRosterWidget(
            playerIds: _state.playerIds,
            playerNames: _state.playerNames,
            scores: _state.scores,
            myPlayerId: _currentPerspectivePlayerId,
            activeAccusedId: _state.activeAccusedId,
            activeAccuserId: _state.activeAccuserId,
            currentVotes: _state.currentVotes,
            canAccuse: _state.phase == SpyfallPhase.discussion,
            onAccuse: _handleAccuse,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLocalRoleReveal() {
    if (_state.playerIds.isEmpty) return const SizedBox.shrink();

    final currentPlayerId = _state.playerIds[_localRevealIndex];
    final currentPlayerName = _state.playerNames[currentPlayerId] ?? currentPlayerId;
    final isSpy = _state.spyPlayerId == currentPlayerId;
    final isLastPlayer = _localRevealIndex == _state.playerIds.length - 1;

    if (_isPrivacyScreenVisible) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PlayNedTokens.surfaceElevated,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            border: Border.all(color: PlayNedTokens.brandGold.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48, color: PlayNedTokens.brandGold),
              const SizedBox(height: 16),
              Text(
                'PASS DEVICE TO:',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: PlayNedTokens.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentPlayerName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: PlayNedTokens.brandGold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ensure no other players can see the screen before continuing.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: PlayNedTokens.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              PlayNedButton(
                label: 'I AM $currentPlayerName - VIEW DOSSIER',
                icon: Icons.visibility,
                variant: PlayNedButtonVariant.primary,
                accentColor: PlayNedTokens.brandGold,
                onPressed: () => setState(() => _isPrivacyScreenVisible = false),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DOSSIER FOR $currentPlayerName (${_localRevealIndex + 1}/${_state.playerIds.length})',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: PlayNedTokens.brandGold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            SpyfallRoleCardWidget(
              isSpy: isSpy,
              locationName: isSpy ? null : _state.secretLocation?.name,
              category: isSpy ? null : _state.secretLocation?.category,
              description: isSpy ? null : _state.secretLocation?.description,
              themes: isSpy ? const [] : _state.secretLocation?.themes ?? const [],
              onBrowseLocations: () => _openLocationDialog(isGuessMode: false),
            ),
            const SizedBox(height: 24),
            PlayNedButton(
              label: isLastPlayer ? 'START DISCUSSION' : 'CONCEAL & PASS TO NEXT AGENT',
              icon: isLastPlayer ? Icons.play_arrow : Icons.arrow_forward,
              variant: PlayNedButtonVariant.primary,
              accentColor: PlayNedTokens.brandGold,
              onPressed: () {
                if (isLastPlayer) {
                  setState(() {
                    _state = _localEngine.applyMove(_state, currentPlayerId, {
                      'action': 'acknowledge_role',
                    });
                  });
                } else {
                  setState(() {
                    _localRevealIndex++;
                    _isPrivacyScreenVisible = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingOverlay() {
    final accusedName = _state.playerNames[_state.activeAccusedId] ?? 'Suspect';
    final accuserName = _state.playerNames[_state.activeAccuserId] ?? 'Accuser';

    // In local pass & play, determine which player needs to vote next
    final eligibleVoters = _state.playerIds.where((id) => id != _state.activeAccusedId).toList();
    final remainingVoters = eligibleVoters.where((id) => !_state.currentVotes.containsKey(id)).toList();

    if (remainingVoters.isEmpty) return const SizedBox.shrink();

    final currentVoterId = widget.mode == 'local' ? remainingVoters.first : _currentPerspectivePlayerId;
    final currentVoterName = _state.playerNames[currentVoterId] ?? currentVoterId;

    if (widget.mode == 'online' && (_currentPerspectivePlayerId == _state.activeAccusedId || _state.currentVotes.containsKey(_currentPerspectivePlayerId))) {
      return Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PlayNedTokens.surfaceElevated,
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Waiting for other agents to cast votes...',
                  style: GoogleFonts.spaceGrotesk(color: PlayNedTokens.textPrimary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: SpyfallVotingDialog(
          accusedName: accusedName,
          accuserName: accuserName,
          currentVoterName: currentVoterName,
          onVote: (choice) => _handleVote(currentVoterId, choice),
        ),
      ),
    );
  }

  Widget _buildSpyGuessOverlay() {
    final spyId = _state.spyPlayerId ?? _state.playerIds.first;
    final spyName = _state.playerNames[spyId] ?? 'The Spy';
    final isMe = _currentPerspectivePlayerId == spyId || widget.mode == 'local';

    if (!isMe) {
      return Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PlayNedTokens.surfaceElevated,
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: PlayNedTokens.accentSpyfall),
                const SizedBox(height: 16),
                Text(
                  '$spyName has one final chance to guess the secret location...',
                  style: GoogleFonts.spaceGrotesk(color: PlayNedTokens.textPrimary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: SpyfallLocationGuessDialog(
          isGuessMode: true,
          onGuessSubmitted: _handleSpyGuess,
        ),
      ),
    );
  }

  Widget _buildRoundResultOverlay() {
    final secretLocation = _state.secretLocation?.name ?? _state.lastOutcome ?? 'Classified';
    final spyId = _state.spyPlayerId ?? '';
    final spyName = _state.playerNames[spyId] ?? 'The Spy';
    final accusedName = _state.playerNames[_state.activeAccusedId];
    final isMatchOver = _state.phase == SpyfallPhase.matchResults || _state.currentRound >= _state.totalRounds;

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: SpyfallRoundResultDialog(
          outcome: _state.lastOutcome ?? 'ROUND_COMPLETE',
          secretLocation: secretLocation,
          spyName: spyName,
          accusedName: accusedName,
          spyGuess: _state.lastSpyGuess,
          roundPoints: _state.lastRoundPoints,
          totalScores: _state.scores,
          playerNames: _state.playerNames,
          currentRound: _state.currentRound,
          totalRounds: _state.totalRounds,
          isMatchOver: isMatchOver,
          onNextRound: isMatchOver ? _handleRematch : _handleNextRound,
          onLeave: () => context.pop(),
        ),
      ),
    );
  }

  void _openLocationDialog({required bool isGuessMode}) {
    showDialog(
      context: context,
      builder: (ctx) => SpyfallLocationGuessDialog(
        isGuessMode: isGuessMode,
        onGuessSubmitted: _handleSpyGuess,
      ),
    );
  }
}
