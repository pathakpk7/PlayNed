import 'dart:math';
import '../models/mafia_models.dart';

const Map<int, Map<MafiaRoleType, int>> kDefaultRoleDistribution = {
  5: {MafiaRoleType.mafia: 1, MafiaRoleType.doctor: 1, MafiaRoleType.detective: 1, MafiaRoleType.villager: 2},
  6: {MafiaRoleType.mafia: 2, MafiaRoleType.doctor: 1, MafiaRoleType.detective: 1, MafiaRoleType.villager: 2},
  7: {MafiaRoleType.mafia: 2, MafiaRoleType.doctor: 1, MafiaRoleType.detective: 1, MafiaRoleType.villager: 3},
  8: {MafiaRoleType.mafia: 2, MafiaRoleType.doctor: 1, MafiaRoleType.detective: 1, MafiaRoleType.villager: 4},
  9: {MafiaRoleType.mafia: 2, MafiaRoleType.doctor: 1, MafiaRoleType.detective: 1, MafiaRoleType.villager: 5},
  10: {MafiaRoleType.mafia: 3, MafiaRoleType.doctor: 1, MafiaRoleType.detective: 1, MafiaRoleType.villager: 5},
  11: {MafiaRoleType.mafia: 3, MafiaRoleType.doctor: 1, MafiaRoleType.detective: 1, MafiaRoleType.villager: 6},
  12: {MafiaRoleType.mafia: 3, MafiaRoleType.doctor: 1, MafiaRoleType.detective: 1, MafiaRoleType.villager: 7},
};

List<MafiaRoleType> getRoleDistribution(
  int playerCount, {
  bool includeJester = false,
  bool includeBodyguard = false,
}) {
  if (playerCount < 5 || playerCount > 12) {
    throw ArgumentError('Mafia requires between 5 and 12 players.');
  }

  final base = Map<MafiaRoleType, int>.from(kDefaultRoleDistribution[playerCount]!);
  if (includeJester && (base[MafiaRoleType.villager] ?? 0) > 1) {
    base[MafiaRoleType.villager] = base[MafiaRoleType.villager]! - 1;
    base[MafiaRoleType.jester] = 1;
  }
  if (includeBodyguard && (base[MafiaRoleType.villager] ?? 0) > 1) {
    base[MafiaRoleType.villager] = base[MafiaRoleType.villager]! - 1;
    base[MafiaRoleType.bodyguard] = 1;
  }

  final roles = <MafiaRoleType>[];
  for (final entry in base.entries) {
    for (int i = 0; i < entry.value; i++) {
      roles.add(entry.key);
    }
  }
  return roles;
}

Map<String, String> assignRoles(
  List<String> playerIds, {
  int? seed,
  bool includeJester = false,
  bool includeBodyguard = false,
}) {
  final roleTypes = getRoleDistribution(
    playerIds.length,
    includeJester: includeJester,
    includeBodyguard: includeBodyguard,
  );
  final rng = seed != null ? Random(seed) : Random();
  final shuffled = List<MafiaRoleType>.from(roleTypes)..shuffle(rng);

  final res = <String, String>{};
  for (int i = 0; i < playerIds.length; i++) {
    res[playerIds[i]] = shuffled[i].toServerString();
  }
  return res;
}

class MafiaLocalEngine {
  MafiaState createInitialState({
    required List<String> playerIds,
    required Map<String, String> playerNames,
    int? seed,
    int discussionDurationSeconds = 120,
    bool allowSelfHeal = false,
    bool revealRoleOnDeath = true,
    bool includeJester = false,
    bool includeBodyguard = false,
  }) {
    if (playerIds.length < 5 || playerIds.length > 12) {
      throw ArgumentError('Mafia requires between 5 and 12 players.');
    }

    final roles = assignRoles(
      playerIds,
      seed: seed,
      includeJester: includeJester,
      includeBodyguard: includeBodyguard,
    );

    return MafiaState(
      phase: MafiaPhase.roleReveal,
      roundNumber: 1,
      playerIds: List.from(playerIds),
      playerNames: Map.from(playerNames),
      aliveStatus: {for (var pid in playerIds) pid: true},
      roleAssignments: roles,
      discussionDurationSeconds: discussionDurationSeconds,
      allowSelfHeal: allowSelfHeal,
      revealRoleOnDeath: revealRoleOnDeath,
      includeJester: includeJester,
      includeBodyguard: includeBodyguard,
      log: ['Match started. Secret roles assigned privately.'],
      lastAction: 'Match started! View your secret role privately.',
    );
  }

  bool validateMove(MafiaState state, String playerId, Map<String, dynamic> move) {
    if (!state.playerIds.contains(playerId)) return false;
    final action = move['action'];
    final isAlive = state.isAlive(playerId);

    if (!isAlive && action != 'acknowledge_role' && action != 'rematch') {
      return false;
    }

    if (action == 'acknowledge_role') {
      return state.phase == MafiaPhase.roleReveal;
    }

    if (action == 'mafia_vote') {
      if (state.phase != MafiaPhase.nightActions) return false;
      if (state.roleAssignments[playerId] != 'mafia') return false;
      final target = move['target_id'] ?? move['target_player_id'];
      return target != null && state.isAlive(target);
    }

    if (action == 'doctor_protect') {
      if (state.phase != MafiaPhase.nightActions) return false;
      if (state.roleAssignments[playerId] != 'doctor') return false;
      final target = move['target_id'] ?? move['target_player_id'];
      if (target == null || !state.isAlive(target)) return false;
      if (!state.allowSelfHeal && target == playerId) return false;
      return true;
    }

    if (action == 'detective_investigate') {
      if (state.phase != MafiaPhase.nightActions) return false;
      if (state.roleAssignments[playerId] != 'detective') return false;
      final target = move['target_id'] ?? move['target_player_id'];
      return target != null && state.isAlive(target) && target != playerId;
    }

    if (action == 'resolve_night') {
      return state.phase == MafiaPhase.nightActions;
    }

    if (action == 'acknowledge_announcement') {
      return state.phase == MafiaPhase.dayAnnouncement;
    }

    if (action == 'start_voting') {
      return state.phase == MafiaPhase.dayDiscussion;
    }

    if (action == 'cast_vote' || action == 'vote') {
      if (state.phase != MafiaPhase.dayVoting) return false;
      final target = move['target_id'] ?? move['target_player_id'];
      if (target != null && target != 'abstain' && target != 'skip') {
        if (!state.isAlive(target) || target == playerId) return false;
      }
      return true;
    }

    if (action == 'resolve_voting') {
      return state.phase == MafiaPhase.dayVoting;
    }

    if (action == 'next_night') {
      return state.phase == MafiaPhase.voteResolution || state.phase == MafiaPhase.dayAnnouncement;
    }

    if (action == 'rematch') {
      return state.phase == MafiaPhase.matchResults;
    }

    return false;
  }

  MafiaState applyMove(MafiaState state, String playerId, Map<String, dynamic> move) {
    if (!validateMove(state, playerId, move)) {
      throw ArgumentError('Illegal move: $move for player $playerId');
    }

    final action = move['action'];
    final history = List<String>.from(state.log);
    final pName = state.getPlayerName(playerId);

    if (action == 'acknowledge_role') {
      final ack = List<String>.from(state.acknowledgedPlayers);
      if (!ack.contains(playerId)) ack.add(playerId);

      if (ack.length >= state.playerIds.length || move['force_advance'] == true) {
        const msg = 'All citizens acknowledged roles. Night 1 descends upon the town.';
        history.add(msg);
        return state.copyWith(
          phase: MafiaPhase.nightActions,
          acknowledgedPlayers: ack,
          mafiaVotes: const {},
          doctorTarget: null,
          detectiveTarget: null,
          log: history,
          lastAction: msg,
        );
      }
      return state.copyWith(
        acknowledgedPlayers: ack,
        lastAction: '$pName acknowledged their role.',
      );
    }

    if (action == 'mafia_vote') {
      final target = (move['target_id'] ?? move['target_player_id']) as String;
      final mVotes = Map<String, String>.from(state.mafiaVotes)..[playerId] = target;
      final updated = state.copyWith(
        mafiaVotes: mVotes,
        lastAction: 'Mafia member $pName selected elimination target.',
      );
      if (_allNightActionsSubmitted(updated) || move['force_resolve'] == true) {
        return _resolveNightActions(updated);
      }
      return updated;
    }

    if (action == 'doctor_protect') {
      final target = (move['target_id'] ?? move['target_player_id']) as String;
      final updated = state.copyWith(
        doctorTarget: target,
        lastAction: 'Doctor selected a citizen to protect.',
      );
      if (_allNightActionsSubmitted(updated) || move['force_resolve'] == true) {
        return _resolveNightActions(updated);
      }
      return updated;
    }

    if (action == 'detective_investigate') {
      final target = (move['target_id'] ?? move['target_player_id']) as String;
      final updated = state.copyWith(
        detectiveTarget: target,
        lastAction: 'Detective investigating a suspect.',
      );
      if (_allNightActionsSubmitted(updated) || move['force_resolve'] == true) {
        return _resolveNightActions(updated);
      }
      return updated;
    }

    if (action == 'resolve_night') {
      return _resolveNightActions(state);
    }

    if (action == 'acknowledge_announcement') {
      final msg = 'Day ${state.roundNumber} discussion begins.';
      history.add(msg);
      return state.copyWith(
        phase: MafiaPhase.dayDiscussion,
        log: history,
        lastAction: msg,
      );
    }

    if (action == 'start_voting') {
      final msg = 'Day ${state.roundNumber} discussion ended. Court is in session—cast your votes!';
      history.add(msg);
      return state.copyWith(
        phase: MafiaPhase.dayVoting,
        votes: const {},
        votedPlayerIds: const [],
        log: history,
        lastAction: msg,
      );
    }

    if (action == 'cast_vote' || action == 'vote') {
      final target = (move['target_id'] ?? move['target_player_id']) as String;
      final votes = Map<String, String>.from(state.votes)..[playerId] = target;
      final votedPids = List<String>.from(state.votedPlayerIds);
      if (!votedPids.contains(playerId)) votedPids.add(playerId);

      final livingCount = state.playerIds.where((p) => state.isAlive(p)).length;
      final updated = state.copyWith(
        votes: votes,
        votedPlayerIds: votedPids,
        lastAction: '$pName cast their vote.',
      );

      if (votes.length >= livingCount || move['force_resolve'] == true) {
        return _resolveDayVoting(updated);
      }
      return updated;
    }

    if (action == 'resolve_voting') {
      return _resolveDayVoting(state);
    }

    if (action == 'next_night') {
      final nextRound = state.roundNumber + 1;
      final msg = 'Night $nextRound falls upon the town.';
      history.add(msg);
      return state.copyWith(
        phase: MafiaPhase.nightActions,
        roundNumber: nextRound,
        mafiaVotes: const {},
        doctorTarget: null,
        detectiveTarget: null,
        bodyguardTarget: null,
        log: history,
        lastAction: msg,
      );
    }

    if (action == 'rematch') {
      return createInitialState(
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        discussionDurationSeconds: state.discussionDurationSeconds,
        allowSelfHeal: state.allowSelfHeal,
        revealRoleOnDeath: state.revealRoleOnDeath,
        includeJester: state.includeJester,
        includeBodyguard: state.includeBodyguard,
      );
    }

    return state;
  }

  MafiaState submitNightAction(
    MafiaState state, {
    required String actorId,
    String? targetId,
  }) {
    if (targetId == null) return state;
    final role = state.roleAssignments[actorId];
    if (role == 'mafia') {
      return applyMove(state, actorId, {'action': 'mafia_vote', 'target_id': targetId});
    } else if (role == 'doctor') {
      return applyMove(state, actorId, {'action': 'doctor_protect', 'target_id': targetId});
    } else if (role == 'detective') {
      return applyMove(state, actorId, {'action': 'detective_investigate', 'target_id': targetId});
    }
    return state;
  }

  MafiaState resolveNight(MafiaState state) {
    return _resolveNightActions(state);
  }

  MafiaState transitionToDiscussion(MafiaState state) {
    return applyMove(state, state.playerIds.first, {'action': 'acknowledge_announcement'});
  }

  MafiaState transitionToVoting(MafiaState state) {
    return applyMove(state, state.playerIds.first, {'action': 'start_voting'});
  }

  MafiaState castVote(
    MafiaState state, {
    required String voterId,
    String? targetId,
  }) {
    return applyMove(state, voterId, {
      'action': 'cast_vote',
      'target_id': targetId ?? 'abstain',
    });
  }

  MafiaState resolveVoting(MafiaState state) {
    return _resolveDayVoting(state);
  }

  MafiaState transitionToNight(MafiaState state) {
    return applyMove(state, state.playerIds.first, {'action': 'next_night'});
  }

  ({String winningFaction, List<String> winnerPlayerIds})? checkWinCondition(MafiaState state) {
    final faction = _checkWinConditions(state);
    if (faction == null) return null;
    final winners = <String>[];
    if (faction == 'town') {
      winners.addAll(state.playerIds.where((p) => state.roleAssignments[p] != 'mafia' && state.roleAssignments[p] != 'jester'));
    } else if (faction == 'mafia') {
      winners.addAll(state.playerIds.where((p) => state.roleAssignments[p] == 'mafia'));
    }
    return (winningFaction: faction, winnerPlayerIds: winners);
  }

  bool _allNightActionsSubmitted(MafiaState state) {
    final livingMafia = state.playerIds.where((p) => state.isAlive(p) && state.roleAssignments[p] == 'mafia');
    if (livingMafia.isNotEmpty && !livingMafia.every((m) => state.mafiaVotes.containsKey(m))) {
      return false;
    }
    final livingDoc = state.playerIds.where((p) => state.isAlive(p) && state.roleAssignments[p] == 'doctor');
    if (livingDoc.isNotEmpty && state.doctorTarget == null) {
      return false;
    }
    final livingDet = state.playerIds.where((p) => state.isAlive(p) && state.roleAssignments[p] == 'detective');
    if (livingDet.isNotEmpty && state.detectiveTarget == null) {
      return false;
    }
    return true;
  }

  MafiaState _resolveNightActions(MafiaState state) {
    final history = List<String>.from(state.log);
    final alive = Map<String, bool>.from(state.aliveStatus);

    // 1. Faction target
    final targetCounts = <String, int>{};
    for (final tgt in state.mafiaVotes.values) {
      if (tgt.isNotEmpty && (alive[tgt] ?? false)) {
        targetCounts[tgt] = (targetCounts[tgt] ?? 0) + 1;
      }
    }

    String? attackTarget;
    if (targetCounts.isNotEmpty) {
      attackTarget = targetCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    final isSaved = attackTarget != null && attackTarget == state.doctorTarget;
    String? casualty;
    String msg;

    if (attackTarget != null && !isSaved) {
      casualty = attackTarget;
      alive[casualty] = false;
      final victimName = state.getPlayerName(casualty);
      final roleName = state.roleAssignments[casualty]?.toUpperCase() ?? 'UNKNOWN';
      msg = state.revealRoleOnDeath
          ? 'Night casualty: $victimName was found dead! They were a $roleName.'
          : 'Night casualty: $victimName was found dead!';
    } else if (isSaved) {
      msg = 'Morning arrives. The town awakens to find that nobody died last night!';
    } else {
      msg = 'Morning arrives. The town was quiet—nobody was eliminated.';
    }
    history.add(msg);

    // 2. Detective investigation
    final invs = List<InvestigationResult>.from(state.myInvestigations);
    if (state.detectiveTarget != null) {
      final tgt = state.detectiveTarget!;
      final isMaf = state.roleAssignments[tgt] == 'mafia';
      invs.add(InvestigationResult(
        round: state.roundNumber,
        targetId: tgt,
        targetName: state.getPlayerName(tgt),
        isMafia: isMaf,
      ));
    }

    final nextState = state.copyWith(
      phase: MafiaPhase.dayAnnouncement,
      aliveStatus: alive,
      lastNightCasualty: casualty,
      myInvestigations: invs,
      log: history,
      lastAction: msg,
    );

    final winner = _checkWinConditions(nextState);
    if (winner != null) {
      return _concludeMatch(nextState, winner, history);
    }
    return nextState;
  }

  MafiaState _resolveDayVoting(MafiaState state) {
    final history = List<String>.from(state.log);
    final alive = Map<String, bool>.from(state.aliveStatus);
    final votes = state.votes;

    final voteCounts = <String, int>{};
    for (final tgt in votes.values) {
      if (tgt.isNotEmpty && tgt != 'abstain' && tgt != 'skip' && (alive[tgt] ?? false)) {
        voteCounts[tgt] = (voteCounts[tgt] ?? 0) + 1;
      }
    }

    String? exiled;
    String msg;

    if (voteCounts.isNotEmpty) {
      final sorted = voteCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;

      if (sorted.length > 1 && sorted[1].value == top.value) {
        msg = 'Voting tied with ${top.value} votes each! No citizen was exiled today.';
      } else {
        exiled = top.key;
        alive[exiled] = false;
        final exiledName = state.getPlayerName(exiled);
        final roleName = state.roleAssignments[exiled]?.toUpperCase() ?? 'UNKNOWN';

        msg = state.revealRoleOnDeath
            ? 'The town voted (${top.value} votes) to exile $exiledName! Their true role was $roleName.'
            : 'The town voted (${top.value} votes) to exile $exiledName.';

        if (state.roleAssignments[exiled] == 'jester') {
          history.add(msg);
          final jesterState = state.copyWith(
            aliveStatus: alive,
            lastVotedOut: exiled,
            log: history,
          );
          return _concludeMatch(jesterState, 'jester', history, jesterId: exiled);
        }
      }
    } else {
      msg = 'The town abstained from voting. No citizen was exiled today.';
    }
    history.add(msg);

    final nextState = state.copyWith(
      phase: MafiaPhase.voteResolution,
      aliveStatus: alive,
      lastVotedOut: exiled,
      log: history,
      lastAction: msg,
    );

    final winner = _checkWinConditions(nextState);
    if (winner != null) {
      return _concludeMatch(nextState, winner, history);
    }
    return nextState;
  }

  String? _checkWinConditions(MafiaState state) {
    int livingMafia = 0;
    int livingNonMafia = 0;

    for (final pid in state.playerIds) {
      if (state.isAlive(pid)) {
        if (state.roleAssignments[pid] == 'mafia') {
          livingMafia++;
        } else {
          livingNonMafia++;
        }
      }
    }

    if (livingMafia == 0) return 'town';
    if (livingMafia >= livingNonMafia) return 'mafia';
    return null;
  }

  MafiaState _concludeMatch(
    MafiaState state,
    String winner,
    List<String> history, {
    String? jesterId,
  }) {
    final winnerPids = <String>[];
    String winMsg;

    if (winner == 'town') {
      winnerPids.addAll(state.playerIds.where((p) => state.roleAssignments[p] != 'mafia' && state.roleAssignments[p] != 'jester'));
      winMsg = 'VICTORY FOR THE TOWN! All Mafia members have been eliminated!';
    } else if (winner == 'mafia') {
      winnerPids.addAll(state.playerIds.where((p) => state.roleAssignments[p] == 'mafia'));
      winMsg = 'VICTORY FOR THE MAFIA! The syndicate has overpowered the town!';
    } else if (winner == 'jester' && jesterId != null) {
      winnerPids.add(jesterId);
      final jName = state.getPlayerName(jesterId);
      winMsg = 'JESTER VICTORY! $jName fooled the town and got exiled!';
    } else {
      winMsg = 'Match concluded.';
    }

    history.add(winMsg);
    return state.copyWith(
      phase: MafiaPhase.matchResults,
      winningFaction: winner,
      winnerPlayerIds: winnerPids,
      lastAction: winMsg,
      log: history,
    );
  }

  MafiaState filterStateForPlayer(MafiaState state, String playerId) {
    final myRole = state.roleAssignments[playerId];
    final isOver = state.phase == MafiaPhase.matchResults;

    if (isOver) {
      return state.copyWith(myRole: myRole);
    }

    final isMafia = myRole == 'mafia';
    final isDoc = myRole == 'doctor';
    final isDet = myRole == 'detective';

    final mafiaTeammates = isMafia
        ? state.playerIds.where((p) => state.roleAssignments[p] == 'mafia').toList()
        : <String>[];

    final investigations = isDet ? state.myInvestigations : <InvestigationResult>[];

    return MafiaState(
      gameId: state.gameId,
      phase: state.phase,
      roundNumber: state.roundNumber,
      playerIds: state.playerIds,
      playerNames: state.playerNames,
      aliveStatus: state.aliveStatus,
      acknowledgedPlayers: state.acknowledgedPlayers,
      myRole: myRole,
      mafiaTeammates: mafiaTeammates,
      myInvestigations: investigations,
      roleAssignments: const {}, // Stripped!
      mafiaVotes: isMafia ? state.mafiaVotes : const {},
      doctorTarget: isDoc ? state.doctorTarget : null,
      detectiveTarget: isDet ? state.detectiveTarget : null,
      bodyguardTarget: null,
      lastNightCasualty: state.lastNightCasualty,
      lastVotedOut: state.lastVotedOut,
      discussionDurationSeconds: state.discussionDurationSeconds,
      discussionEndTime: state.discussionEndTime,
      votingEndTime: state.votingEndTime,
      votes: state.phase == MafiaPhase.dayVoting ? const {} : state.votes,
      votedPlayerIds: state.votedPlayerIds,
      allowSelfHeal: state.allowSelfHeal,
      revealRoleOnDeath: state.revealRoleOnDeath,
      includeJester: state.includeJester,
      includeBodyguard: state.includeBodyguard,
      winningFaction: state.winningFaction,
      winnerPlayerIds: state.winnerPlayerIds,
      log: state.log,
      lastAction: state.lastAction,
    );
  }
}
