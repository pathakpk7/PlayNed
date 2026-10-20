import 'dart:math';
import '../models/raja_mantri_models.dart';

class RajaMantriLocalEngine {
  static const List<RajaMantriRole> allRoles = [
    RajaMantriRole.raja,
    RajaMantriRole.mantri,
    RajaMantriRole.sipahi,
    RajaMantriRole.chor,
  ];

  static Map<String, RajaMantriRole> shuffleChits(List<String> playerIds, {Random? rng}) {
    if (playerIds.length != 4) {
      throw ArgumentError('Raja Mantri Chor Sipahi requires exactly 4 players.');
    }
    final random = rng ?? Random();
    final shuffled = List<RajaMantriRole>.from(allRoles)..shuffle(random);
    return {
      playerIds[0]: shuffled[0],
      playerIds[1]: shuffled[1],
      playerIds[2]: shuffled[2],
      playerIds[3]: shuffled[3],
    };
  }

  static RajaMantriState createInitialState({
    required List<String> playerIds,
    required Map<String, String> playerNames,
    int totalRounds = 5,
    Random? rng,
  }) {
    if (playerIds.length != 4) {
      throw ArgumentError('Raja Mantri Chor Sipahi requires exactly 4 players.');
    }

    final assignments = shuffleChits(playerIds, rng: rng);
    final rajaPid = assignments.entries.firstWhere((e) => e.value == RajaMantriRole.raja).key;
    final mantriPid = assignments.entries.firstWhere((e) => e.value == RajaMantriRole.mantri).key;
    final sipahiPid = assignments.entries.firstWhere((e) => e.value == RajaMantriRole.sipahi).key;
    final chorPid = assignments.entries.firstWhere((e) => e.value == RajaMantriRole.chor).key;

    final random = rng ?? Random();
    final eligible = [sipahiPid, chorPid]..shuffle(random);

    final cumulative = {for (final pid in playerIds) pid: 0};

    return RajaMantriState(
      phase: RajaMantriPhase.chitReveal,
      playerIds: playerIds,
      playerNames: playerNames,
      currentRound: 1,
      totalRounds: totalRounds,
      roleAssignments: assignments,
      revealedRoles: const {},
      rajaPlayerId: rajaPid,
      mantriPlayerId: mantriPid,
      sipahiPlayerId: sipahiPid,
      chorPlayerId: chorPid,
      eligibleSuspectIds: eligible,
      acknowledgedPlayers: const [],
      cumulativeScores: cumulative,
      lastAction: 'Round 1: Each player must privately view their secret chit.',
    );
  }

  static RajaMantriState acknowledgeChit(RajaMantriState state, String playerId, {bool forceAdvance = false}) {
    final ack = List<String>.from(state.acknowledgedPlayers);
    if (!ack.contains(playerId)) {
      ack.add(playerId);
    }

    if (ack.length >= 4 || forceAdvance) {
      final rajaPid = state.rajaPlayerId!;
      final rajaName = state.getPlayerName(rajaPid);
      return RajaMantriState(
        phase: RajaMantriPhase.rajaReveal,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        currentRound: state.currentRound,
        totalRounds: state.totalRounds,
        roleAssignments: state.roleAssignments,
        revealedRoles: {rajaPid: RajaMantriRole.raja},
        rajaPlayerId: state.rajaPlayerId,
        mantriPlayerId: state.mantriPlayerId,
        sipahiPlayerId: state.sipahiPlayerId,
        chorPlayerId: state.chorPlayerId,
        eligibleSuspectIds: state.eligibleSuspectIds,
        acknowledgedPlayers: ack,
        cumulativeScores: state.cumulativeScores,
        roundHistory: state.roundHistory,
        lastAction: 'Raja revealed: $rajaName commands "Mera Mantri Kaun Hai?"',
      );
    }

    return RajaMantriState(
      phase: state.phase,
      playerIds: state.playerIds,
      playerNames: state.playerNames,
      currentRound: state.currentRound,
      totalRounds: state.totalRounds,
      roleAssignments: state.roleAssignments,
      revealedRoles: state.revealedRoles,
      rajaPlayerId: state.rajaPlayerId,
      mantriPlayerId: state.mantriPlayerId,
      sipahiPlayerId: state.sipahiPlayerId,
      chorPlayerId: state.chorPlayerId,
      eligibleSuspectIds: state.eligibleSuspectIds,
      acknowledgedPlayers: ack,
      cumulativeScores: state.cumulativeScores,
      roundHistory: state.roundHistory,
      lastAction: state.lastAction,
    );
  }

  static RajaMantriState callMantri(RajaMantriState state) {
    if (state.phase != RajaMantriPhase.rajaReveal) return state;

    final mantriPid = state.mantriPlayerId!;
    final mantriName = state.getPlayerName(mantriPid);
    final revealed = Map<String, RajaMantriRole>.from(state.revealedRoles)
      ..[mantriPid] = RajaMantriRole.mantri;

    return RajaMantriState(
      phase: RajaMantriPhase.mantriReveal,
      playerIds: state.playerIds,
      playerNames: state.playerNames,
      currentRound: state.currentRound,
      totalRounds: state.totalRounds,
      roleAssignments: state.roleAssignments,
      revealedRoles: revealed,
      rajaPlayerId: state.rajaPlayerId,
      mantriPlayerId: state.mantriPlayerId,
      sipahiPlayerId: state.sipahiPlayerId,
      chorPlayerId: state.chorPlayerId,
      eligibleSuspectIds: state.eligibleSuspectIds,
      acknowledgedPlayers: state.acknowledgedPlayers,
      cumulativeScores: state.cumulativeScores,
      roundHistory: state.roundHistory,
      lastAction: 'Mantri stepped forward: $mantriName stands ready to serve.',
    );
  }

  static RajaMantriState stepForward(RajaMantriState state) {
    if (state.phase != RajaMantriPhase.mantriReveal) return state;

    final mantriName = state.getPlayerName(state.mantriPlayerId!);
    return RajaMantriState(
      phase: RajaMantriPhase.chorGuess,
      playerIds: state.playerIds,
      playerNames: state.playerNames,
      currentRound: state.currentRound,
      totalRounds: state.totalRounds,
      roleAssignments: state.roleAssignments,
      revealedRoles: state.revealedRoles,
      rajaPlayerId: state.rajaPlayerId,
      mantriPlayerId: state.mantriPlayerId,
      sipahiPlayerId: state.sipahiPlayerId,
      chorPlayerId: state.chorPlayerId,
      eligibleSuspectIds: state.eligibleSuspectIds,
      acknowledgedPlayers: state.acknowledgedPlayers,
      cumulativeScores: state.cumulativeScores,
      roundHistory: state.roundHistory,
      lastAction: '$mantriName must deduce who the Chor is among the two suspects.',
    );
  }

  static RajaMantriState submitGuess(RajaMantriState state, String targetPid) {
    if (state.phase != RajaMantriPhase.chorGuess) return state;
    if (targetPid == state.mantriPlayerId || targetPid == state.rajaPlayerId) return state;
    if (!state.eligibleSuspectIds.contains(targetPid)) return state;

    final actualChorPid = state.chorPlayerId!;
    final guessCorrect = (targetPid == actualChorPid);

    // Fixed points per role:
    // Raja: 1000, Mantri: 0, Sipahi: 500, Chor: 800
    final roundPts = <String, int>{};
    for (final entry in state.roleAssignments.entries) {
      roundPts[entry.key] = entry.value.points;
    }

    final newCumulative = Map<String, int>.from(state.cumulativeScores);
    for (final entry in roundPts.entries) {
      newCumulative[entry.key] = (newCumulative[entry.key] ?? 0) + entry.value;
    }

    final targetName = state.getPlayerName(targetPid);
    final chorName = state.getPlayerName(actualChorPid);
    final outcomeMsg = guessCorrect
        ? 'Mantri correctly accused $targetName! Thief apprehended!'
        : 'Mantri accused $targetName incorrectly! $chorName was the Thief!';

    final history = List<Map<String, dynamic>>.from(state.roundHistory)
      ..add({
        'round_number': state.currentRound,
        'role_assignments': state.roleAssignments.map((k, v) => MapEntry(k, v.displayName)),
        'guessed_chor_player_id': targetPid,
        'actual_chor_player_id': actualChorPid,
        'guess_correct': guessCorrect,
        'round_points': roundPts,
        'cumulative_scores': newCumulative,
      });

    return RajaMantriState(
      phase: RajaMantriPhase.fullReveal,
      playerIds: state.playerIds,
      playerNames: state.playerNames,
      currentRound: state.currentRound,
      totalRounds: state.totalRounds,
      roleAssignments: state.roleAssignments,
      revealedRoles: Map<String, RajaMantriRole>.from(state.roleAssignments),
      rajaPlayerId: state.rajaPlayerId,
      mantriPlayerId: state.mantriPlayerId,
      sipahiPlayerId: state.sipahiPlayerId,
      chorPlayerId: state.chorPlayerId,
      eligibleSuspectIds: state.eligibleSuspectIds,
      acknowledgedPlayers: state.acknowledgedPlayers,
      guessedChorPlayerId: targetPid,
      guessCorrect: guessCorrect,
      roundPoints: roundPts,
      cumulativeScores: newCumulative,
      roundHistory: history,
      lastAction: outcomeMsg,
    );
  }

  static RajaMantriState nextRound(RajaMantriState state, {Random? rng}) {
    if (state.phase != RajaMantriPhase.fullReveal && state.phase != RajaMantriPhase.roundResults) {
      return state;
    }

    if (state.currentRound >= state.totalRounds) {
      // End of match
      final maxScore = state.cumulativeScores.values.isEmpty
          ? 0
          : state.cumulativeScores.values.reduce(max);
      final winners = state.cumulativeScores.entries
          .where((e) => e.value == maxScore)
          .map((e) => e.key)
          .toList();
      final isTie = winners.length > 1;

      final outcome = isTie
          ? 'Match ended in a tie between ${winners.map(state.getPlayerName).join(" & ")} with $maxScore pts!'
          : '${state.getPlayerName(winners[0])} wins the match with $maxScore pts!';

      return RajaMantriState(
        phase: RajaMantriPhase.matchResults,
        status: 'finished',
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        currentRound: state.currentRound,
        totalRounds: state.totalRounds,
        roleAssignments: state.roleAssignments,
        revealedRoles: state.revealedRoles,
        rajaPlayerId: state.rajaPlayerId,
        mantriPlayerId: state.mantriPlayerId,
        sipahiPlayerId: state.sipahiPlayerId,
        chorPlayerId: state.chorPlayerId,
        eligibleSuspectIds: state.eligibleSuspectIds,
        roundPoints: state.roundPoints,
        cumulativeScores: state.cumulativeScores,
        roundHistory: state.roundHistory,
        lastAction: outcome,
        winnerPlayerIds: winners,
        isTie: isTie,
      );
    }

    final newRoundNum = state.currentRound + 1;
    final assignments = shuffleChits(state.playerIds, rng: rng);
    final rajaPid = assignments.entries.firstWhere((e) => e.value == RajaMantriRole.raja).key;
    final mantriPid = assignments.entries.firstWhere((e) => e.value == RajaMantriRole.mantri).key;
    final sipahiPid = assignments.entries.firstWhere((e) => e.value == RajaMantriRole.sipahi).key;
    final chorPid = assignments.entries.firstWhere((e) => e.value == RajaMantriRole.chor).key;

    final random = rng ?? Random();
    final eligible = [sipahiPid, chorPid]..shuffle(random);

    return RajaMantriState(
      phase: RajaMantriPhase.chitReveal,
      playerIds: state.playerIds,
      playerNames: state.playerNames,
      currentRound: newRoundNum,
      totalRounds: state.totalRounds,
      roleAssignments: assignments,
      revealedRoles: const {},
      rajaPlayerId: rajaPid,
      mantriPlayerId: mantriPid,
      sipahiPlayerId: sipahiPid,
      chorPlayerId: chorPid,
      eligibleSuspectIds: eligible,
      acknowledgedPlayers: const [],
      cumulativeScores: state.cumulativeScores,
      roundHistory: state.roundHistory,
      lastAction: 'Round $newRoundNum: View your new secret role.',
    );
  }
}
