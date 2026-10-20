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

import '../../models/mafia_models.dart';
import '../../services/mafia_engine.dart';
import '../widgets/mafia_role_card_widget.dart';
import '../widgets/mafia_player_list_widget.dart';
import '../widgets/mafia_night_action_dialog.dart';
import '../widgets/mafia_investigation_dialog.dart';
import '../widgets/mafia_announcement_dialog.dart';
import '../widgets/mafia_vote_result_dialog.dart';
import '../widgets/mafia_match_result_dialog.dart';

/// Full interactive Mafia / Werewolf Game Page supporting Local Pass-and-Play & Online Multiplayer.
class MafiaGamePage extends ConsumerStatefulWidget {
  final String mode; // 'local' or 'online'
  final String? roomCode;
  final String? localPlayerId;
  final List<String>? initialPlayerNames;
  final int discussionDurationSeconds;
  final bool allowSelfHeal;
  final bool revealRoleOnDeath;
  final bool includeJester;
  final bool includeBodyguard;

  const MafiaGamePage({
    super.key,
    this.mode = 'local',
    this.roomCode,
    this.localPlayerId,
    this.initialPlayerNames,
    this.discussionDurationSeconds = 120,
    this.allowSelfHeal = false,
    this.revealRoleOnDeath = true,
    this.includeJester = false,
    this.includeBodyguard = false,
  });

  @override
  ConsumerState<MafiaGamePage> createState() => _MafiaGamePageState();
}

class _MafiaGamePageState extends ConsumerState<MafiaGamePage> {
  final MafiaLocalEngine _localEngine = MafiaLocalEngine();
  late MafiaState _state;

  // Local Pass & Play Privacy & Turn Tracking
  int _localPlayerIndex = 0;
  bool _isPrivacyCurtainVisible = false;
  String _privacyTargetPlayerName = '';

  // Timer for Discussion & Voting
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  // Online Multiplayer State
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;

  // Active dialog flag to avoid modal stacking
  bool _isDialogShowing = false;

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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _initLocalGame() {
    final names = widget.initialPlayerNames ??
        ['Player 1', 'Player 2', 'Player 3', 'Player 4', 'Player 5'];
    final pIds = List.generate(names.length, (i) => 'p${i + 1}');
    final pMap = {for (var i = 0; i < names.length; i++) pIds[i]: names[i]};

    _state = _localEngine.createInitialState(
      playerIds: pIds,
      playerNames: pMap,
      discussionDurationSeconds: widget.discussionDurationSeconds,
      allowSelfHeal: widget.allowSelfHeal,
      revealRoleOnDeath: widget.revealRoleOnDeath,
      includeJester: widget.includeJester,
      includeBodyguard: widget.includeBodyguard,
    );

    _localPlayerIndex = 0;
    _privacyTargetPlayerName = names[0];
    _isPrivacyCurtainVisible = true;
  }

  void _initOnlinePlaceholder() {
    _state = MafiaState(
      gameId: 'mafia',
      phase: MafiaPhase.roleReveal,
      playerIds: const [],
      playerNames: const {},
      discussionDurationSeconds: widget.discussionDurationSeconds,
      allowSelfHeal: widget.allowSelfHeal,
      revealRoleOnDeath: widget.revealRoleOnDeath,
      includeJester: widget.includeJester,
      includeBodyguard: widget.includeBodyguard,
    );
  }

  Future<void> _setupOnlineRoom() async {
    if (widget.roomCode == null || widget.localPlayerId == null) return;
    final api = ref.read(platformApiServiceProvider);
    final pid = widget.localPlayerId!;

    try {
      final room = await api.getRoom(widget.roomCode!);
      if (room.matchState != null && mounted) {
        setState(() {
          _state = MafiaState.fromJson(room.matchState!);
        });
      }

      _wsChannel = api.connectWebSocket(widget.roomCode!, pid);
      if (_wsChannel != null) {
        _isConnected = true;
        _wsSubscription = _wsChannel!.stream.listen(
          (data) {
            if (!mounted) return;
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final type = json['type'] as String?;

            if (type == 'GAME_STATE' || type == 'GAME_OVER') {
              final payload = json['state'] as Map<String, dynamic>;
              final newState = MafiaState.fromJson(payload);
              setState(() {
                _state = newState;
                _isConnected = true;
              });
              _syncPhaseModals();
              _syncTimerFromState();
            }
          },
          onError: (err) {
            if (mounted) setState(() => _isConnected = false);
          },
          onDone: () {
            if (mounted) setState(() => _isConnected = false);
          },
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  void _sendOnlineAction(Map<String, dynamic> actionData) {
    if (_wsChannel != null && _isConnected) {
      _wsChannel!.sink.add(jsonEncode(actionData));
    }
  }

  void _syncTimerFromState() {
    _countdownTimer?.cancel();
    if (_state.phase == MafiaPhase.dayDiscussion && _state.discussionEndTime != null) {
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final diff = (_state.discussionEndTime! - nowSec).round();
      _remainingSeconds = diff > 0 ? diff : 0;
      _startLocalTicking();
    } else if (_state.phase == MafiaPhase.dayVoting && _state.votingEndTime != null) {
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final diff = (_state.votingEndTime! - nowSec).round();
      _remainingSeconds = diff > 0 ? diff : 0;
      _startLocalTicking();
    }
  }

  void _startLocalTicking() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        if (widget.mode == 'local') {
          _handleLocalTimerExpiry();
        }
      }
    });
  }

  void _handleLocalTimerExpiry() {
    if (_state.phase == MafiaPhase.dayDiscussion) {
      setState(() {
        _state = _localEngine.transitionToVoting(_state);
        _remainingSeconds = 60; // 60s for voting
      });
      _startLocalTicking();
    } else if (_state.phase == MafiaPhase.dayVoting) {
      _resolveLocalVotes();
    }
  }

  void _resolveLocalVotes() {
    _countdownTimer?.cancel();
    setState(() {
      _state = _localEngine.resolveVoting(_state);
    });
    _syncPhaseModals();
  }

  void _syncPhaseModals() {
    if (_isDialogShowing || !mounted) return;

    if (_state.phase == MafiaPhase.dayAnnouncement) {
      _showDayAnnouncementModal();
    } else if (_state.phase == MafiaPhase.voteResolution) {
      _showVoteResultModal();
    } else if (_state.phase == MafiaPhase.matchResults) {
      _showMatchResultModal();
    }
  }

  // Current active player identity (Local vs Online)
  String get _currentPlayerId {
    if (widget.mode == 'local') {
      if (_state.playerIds.isEmpty) return 'p1';
      return _state.playerIds[_localPlayerIndex.clamp(0, _state.playerIds.length - 1)];
    }
    return widget.localPlayerId ?? (_state.playerIds.isNotEmpty ? _state.playerIds.first : 'p1');
  }

  String get _currentPlayerName => _state.getPlayerName(_currentPlayerId);

  MafiaRoleType get _currentPlayerRole {
    if (widget.mode == 'local') {
      final raw = _state.roleAssignments[_currentPlayerId] ?? 'villager';
      return MafiaRoleType.fromString(raw);
    }
    final raw = _state.myRole ?? 'villager';
    return MafiaRoleType.fromString(raw);
  }

  bool get _isCurrentPlayerAlive => _state.isAlive(_currentPlayerId);

  // ---------------------------------------------------------
  // Local Pass & Play Turn Progression
  // ---------------------------------------------------------

  void _dismissPrivacyCurtain() {
    setState(() {
      _isPrivacyCurtainVisible = false;
    });
  }

  void _advanceLocalPlayerRoleReveal() {
    final nextIndex = _localPlayerIndex + 1;
    if (nextIndex < _state.playerIds.length) {
      setState(() {
        _localPlayerIndex = nextIndex;
        _privacyTargetPlayerName = _state.getPlayerName(_state.playerIds[nextIndex]);
        _isPrivacyCurtainVisible = true;
      });
    } else {
      // All players acknowledged their roles -> begin Night 1
      setState(() {
        _state = _localEngine.transitionToNight(_state);
        _localPlayerIndex = 0;
        _privacyTargetPlayerName = _state.getPlayerName(_state.playerIds[0]);
        _isPrivacyCurtainVisible = true;
      });
    }
  }

  void _advanceLocalNightPlayer() {
    final nextIndex = _localPlayerIndex + 1;
    if (nextIndex < _state.playerIds.length) {
      setState(() {
        _localPlayerIndex = nextIndex;
        _privacyTargetPlayerName = _state.getPlayerName(_state.playerIds[nextIndex]);
        _isPrivacyCurtainVisible = true;
      });
    } else {
      // All living players took their night turns -> resolve night
      setState(() {
        _state = _localEngine.resolveNight(_state);
      });
      _syncPhaseModals();
    }
  }

  // ---------------------------------------------------------
  // Modals & Dialogs
  // ---------------------------------------------------------

  void _showNightActionModal() {
    if (!_isCurrentPlayerAlive) return;
    final role = _currentPlayerRole;
    if (role == MafiaRoleType.villager || role == MafiaRoleType.jester) return;

    final livingPids = _state.playerIds.where((p) => _state.isAlive(p)).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MafiaNightActionDialog(
        role: role,
        myPlayerId: _currentPlayerId,
        livingPlayerIds: livingPids,
        playerNames: _state.playerNames,
        mafiaTeammates: _state.mafiaTeammates,
        allowSelfHeal: _state.allowSelfHeal,
        onConfirmTarget: (targetId) {
          Navigator.of(ctx).pop();
          if (widget.mode == 'local') {
            setState(() {
              _state = _localEngine.submitNightAction(
                _state,
                actorId: _currentPlayerId,
                targetId: targetId,
              );
            });
            _advanceLocalNightPlayer();
          } else {
            _sendOnlineAction({
              'action': 'submit_night_action',
              'target_id': targetId,
            });
          }
        },
        onSkip: () {
          Navigator.of(ctx).pop();
          if (widget.mode == 'local') {
            setState(() {
              _state = _localEngine.submitNightAction(
                _state,
                actorId: _currentPlayerId,
                targetId: null,
              );
            });
            _advanceLocalNightPlayer();
          } else {
            _sendOnlineAction({
              'action': 'skip_night_action',
            });
          }
        },
      ),
    );
  }

  void _showInvestigationDossier() {
    showDialog(
      context: context,
      builder: (ctx) => MafiaInvestigationDialog(
        investigations: _state.myInvestigations,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showDayAnnouncementModal() {
    _isDialogShowing = true;
    final casualtyId = _state.lastNightCasualty;
    final casualtyName = casualtyId != null ? _state.getPlayerName(casualtyId) : null;
    MafiaRoleType? casualtyRole;
    if (casualtyId != null && _state.roleAssignments.containsKey(casualtyId)) {
      casualtyRole = MafiaRoleType.fromString(_state.roleAssignments[casualtyId]!);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MafiaAnnouncementDialog(
        roundNumber: _state.roundNumber,
        casualtyId: casualtyId,
        casualtyName: casualtyName,
        casualtyRole: casualtyRole,
        revealRole: _state.revealRoleOnDeath,
        onProceedToDiscussion: () {
          Navigator.of(ctx).pop();
          _isDialogShowing = false;
          if (widget.mode == 'local') {
            setState(() {
              _state = _localEngine.transitionToDiscussion(_state);
              _remainingSeconds = _state.discussionDurationSeconds;
            });
            _startLocalTicking();
          }
        },
      ),
    );
  }

  void _showVoteResultModal() {
    _isDialogShowing = true;
    final exiledId = _state.lastVotedOut;
    final exiledName = exiledId != null ? _state.getPlayerName(exiledId) : null;
    MafiaRoleType? exiledRole;
    if (exiledId != null && _state.roleAssignments.containsKey(exiledId)) {
      exiledRole = MafiaRoleType.fromString(_state.roleAssignments[exiledId]!);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MafiaVoteResultDialog(
        roundNumber: _state.roundNumber,
        exiledId: exiledId,
        exiledName: exiledName,
        exiledRole: exiledRole,
        revealRole: _state.revealRoleOnDeath,
        votes: _state.votes,
        playerNames: _state.playerNames,
        isGameOver: _state.isGameOver,
        onProceed: () {
          Navigator.of(ctx).pop();
          _isDialogShowing = false;
          if (_state.isGameOver) {
            _showMatchResultModal();
          } else if (widget.mode == 'local') {
            setState(() {
              _state = _localEngine.transitionToNight(_state);
              _localPlayerIndex = 0;
              _privacyTargetPlayerName = _state.getPlayerName(_state.playerIds[0]);
              _isPrivacyCurtainVisible = true;
            });
          }
        },
      ),
    );
  }

  void _showMatchResultModal() {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MafiaMatchResultDialog(
        winningFaction: _state.winningFaction ?? 'town',
        winnerPlayerIds: _state.winnerPlayerIds,
        playerIds: _state.playerIds,
        playerNames: _state.playerNames,
        roleAssignments: _state.roleAssignments,
        aliveStatus: _state.aliveStatus,
        onRematch: () {
          Navigator.of(ctx).pop();
          _isDialogShowing = false;
          if (widget.mode == 'local') {
            _initLocalGame();
          } else {
            _sendOnlineAction({'action': 'restart_game'});
          }
        },
        onLeave: () {
          Navigator.of(ctx).pop();
          _isDialogShowing = false;
          context.go('/');
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // UI Builder
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isPrivacyCurtainVisible && widget.mode == 'local') {
      return _buildPrivacyCurtain();
    }

    final role = _currentPlayerRole;
    final isAlive = _isCurrentPlayerAlive;
    final isDetective = role == MafiaRoleType.detective;

    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: const PlatformAppBar(
        title: 'MAFIA',
      ),
      body: PlayNedBackgroundPattern(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Round, Turn, and Phase
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: PlayNedTokens.surface,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: PlayNedTokens.textSecondary, size: 20),
                      onPressed: () => context.go('/'),
                      tooltip: 'Leave Game',
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROUND ${_state.roundNumber}',
                          style: GoogleFonts.cinzel(
                            color: PlayNedTokens.brandGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          widget.mode == 'local'
                              ? 'Pass & Play • $_currentPlayerName'
                              : 'Online Room ${widget.roomCode ?? ""}',
                          style: GoogleFonts.spaceMono(
                            color: PlayNedTokens.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isDetective && isAlive)
                      IconButton(
                        icon: const Icon(Icons.manage_search, color: PlayNedTokens.accentDots),
                        tooltip: 'Detective Dossier',
                        onPressed: _showInvestigationDossier,
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: PlayNedTokens.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PlayNedTokens.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _state.phase == MafiaPhase.nightActions
                                ? Icons.nightlight_round
                                : Icons.wb_sunny,
                            color: _state.phase == MafiaPhase.nightActions
                                ? PlayNedTokens.accentMafia
                                : PlayNedTokens.brandGold,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _state.phase.toServerString().replaceAll('_', ' '),
                            style: GoogleFonts.spaceMono(
                              color: PlayNedTokens.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Header Phase Bar & Timer
              _buildPhaseHeaderBar(),

              // Scrollable Core Game Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Player's Role Card
                          MafiaRoleCardWidget(
                            roleName: role.displayName,
                            isAlive: isAlive,
                            mafiaTeammates: _state.mafiaTeammates,
                            playerNames: _state.playerNames,
                            hasInvestigations: _state.myInvestigations.isNotEmpty,
                            onOpenInvestigations: isDetective ? _showInvestigationDossier : null,
                          ),
                          const SizedBox(height: 16),

                          // Action Toolbar for Current Phase
                          _buildPhaseActionControls(),
                          const SizedBox(height: 20),

                          // Players Roster Grid
                          MafiaPlayerListWidget(
                            playerIds: _state.playerIds,
                            playerNames: _state.playerNames,
                            aliveStatus: _state.aliveStatus,
                            myPlayerId: _currentPlayerId,
                            selectedTargetId: _state.votes[_currentPlayerId],
                            votedPlayerIds: _state.votedPlayerIds,
                            isTargetingAllowed: isAlive && _state.phase == MafiaPhase.dayVoting,
                            actionLabel: 'VOTE',
                            actionColor: PlayNedTokens.accentMafia,
                            onTargetSelected: (targetId) => _castVote(targetId),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCurtain() {
    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      body: PlayNedBackgroundPattern(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: PlayNedTokens.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PlayNedTokens.accentMafia.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: PlayNedTokens.accentMafia.withValues(alpha: 0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PlayNedTokens.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: PlayNedTokens.accentMafia.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.screen_lock_portrait, color: PlayNedTokens.accentMafia, size: 40),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'PASS THE DEVICE',
                        style: GoogleFonts.cinzel(
                          color: PlayNedTokens.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hand device to $_privacyTargetPlayerName.\nAll other citizens must look away to preserve role secrecy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(
                          color: PlayNedTokens.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      PlayNedButton(
                        label: 'I am $_privacyTargetPlayerName',
                        onPressed: _dismissPrivacyCurtain,
                        variant: PlayNedButtonVariant.primary,
                        customAccent: PlayNedTokens.accentMafia,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        border: Border(bottom: BorderSide(color: PlayNedTokens.border)),
      ),
      child: Row(
        children: [
          Icon(
            _state.phase == MafiaPhase.nightActions
                ? Icons.bedtime
                : (_state.phase == MafiaPhase.dayVoting ? Icons.how_to_vote : Icons.forum),
            color: PlayNedTokens.brandGold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _phaseInstructionText(),
              style: GoogleFonts.spaceMono(
                color: PlayNedTokens.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          if (_remainingSeconds > 0 &&
              (_state.phase == MafiaPhase.dayDiscussion || _state.phase == MafiaPhase.dayVoting)) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _remainingSeconds < 15
                    ? PlayNedTokens.accentMafia.withValues(alpha: 0.2)
                    : PlayNedTokens.surfaceHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _remainingSeconds < 15 ? PlayNedTokens.accentMafia : PlayNedTokens.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    color: _remainingSeconds < 15 ? PlayNedTokens.accentMafia : PlayNedTokens.brandGold,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.spaceMono(
                      color: _remainingSeconds < 15 ? PlayNedTokens.accentMafia : PlayNedTokens.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _phaseInstructionText() {
    switch (_state.phase) {
      case MafiaPhase.roleReveal:
        return 'Read your secret role. Memorize your allegiance.';
      case MafiaPhase.nightActions:
        return 'Night has fallen. Active roles execute secret covert actions.';
      case MafiaPhase.dayAnnouncement:
        return 'Morning town square briefing.';
      case MafiaPhase.dayDiscussion:
        return 'Debate, question alibis, and find the Mafia.';
      case MafiaPhase.dayVoting:
        return 'Vote for the player you wish to exile from the town.';
      case MafiaPhase.voteResolution:
        return 'Reviewing town vote results...';
      case MafiaPhase.matchResults:
        return 'Game Over.';
      default:
        return 'Stand by...';
    }
  }

  Widget _buildPhaseActionControls() {
    if (_state.phase == MafiaPhase.roleReveal) {
      return PlayNedButton(
        label: widget.mode == 'local'
            ? (_localPlayerIndex < _state.playerIds.length - 1
                ? 'I Understand - Pass to Next Player'
                : 'All Roles Acknowledged - Begin Night')
            : 'I Understand My Role',
        onPressed: () {
          if (widget.mode == 'local') {
            _advanceLocalPlayerRoleReveal();
          } else {
            _sendOnlineAction({'action': 'acknowledge_role'});
          }
        },
        variant: PlayNedButtonVariant.primary,
        customAccent: PlayNedTokens.accentMafia,
      );
    }

    if (_state.phase == MafiaPhase.nightActions) {
      final role = _currentPlayerRole;
      final isNightActive = role != MafiaRoleType.villager && role != MafiaRoleType.jester;

      if (!isNightActive || !_isCurrentPlayerAlive) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PlayNedTokens.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PlayNedTokens.border),
          ),
          child: Column(
            children: [
              Text(
                'You have no night action. Keep your eyes closed.',
                style: GoogleFonts.spaceMono(color: PlayNedTokens.textMuted, fontSize: 12),
              ),
              if (widget.mode == 'local') ...[
                const SizedBox(height: 10),
                PlayNedButton(
                  label: 'Done - Pass Device',
                  onPressed: _advanceLocalNightPlayer,
                  variant: PlayNedButtonVariant.secondary,
                ),
              ],
            ],
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: PlayNedButton(
              label: 'Perform Night Action (${role.displayName})',
              onPressed: _showNightActionModal,
              variant: PlayNedButtonVariant.primary,
              customAccent: PlayNedTokens.accentMafia,
            ),
          ),
        ],
      );
    }

    if (_state.phase == MafiaPhase.dayDiscussion) {
      if (widget.mode == 'local') {
        return Row(
          children: [
            Expanded(
              child: PlayNedButton(
                label: 'End Discussion Early & Start Voting',
                onPressed: () {
                  setState(() {
                    _state = _localEngine.transitionToVoting(_state);
                    _remainingSeconds = 60;
                  });
                  _startLocalTicking();
                },
                variant: PlayNedButtonVariant.secondary,
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    if (_state.phase == MafiaPhase.dayVoting) {
      final hasVoted = _state.votes.containsKey(_currentPlayerId);
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PlayNedTokens.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PlayNedTokens.border),
        ),
        child: Column(
          children: [
            Text(
              hasVoted
                  ? 'Your vote is recorded! Select another player to change vote, or skip.'
                  : 'Tap any alive player in the list below to cast your vote to exile them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                color: PlayNedTokens.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PlayNedButton(
                    label: 'Abstain / Skip Vote',
                    onPressed: () => _castVote(null),
                    variant: PlayNedButtonVariant.secondary,
                  ),
                ),
                if (widget.mode == 'local') ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: PlayNedButton(
                      label: 'Tally Votes Now',
                      onPressed: _resolveLocalVotes,
                      variant: PlayNedButtonVariant.primary,
                      customAccent: PlayNedTokens.brandGold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _castVote(String? targetId) {
    if (widget.mode == 'local') {
      setState(() {
        _state = _localEngine.castVote(
          _state,
          voterId: _currentPlayerId,
          targetId: targetId,
        );
      });
    } else {
      if (targetId != null) {
        _sendOnlineAction({'action': 'cast_vote', 'target_id': targetId});
      } else {
        _sendOnlineAction({'action': 'skip_vote'});
      }
    }
  }
}
