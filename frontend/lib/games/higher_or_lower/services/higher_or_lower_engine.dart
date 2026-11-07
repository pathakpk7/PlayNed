import 'dart:math';
import '../models/higher_or_lower_models.dart';

/// Local gameplay engine and AI bot for Higher or Lower: Numbers.
class HigherOrLowerLocalEngine {
  final Random _rng;

  HigherOrLowerLocalEngine({Random? rng}) : _rng = rng ?? Random();

  int generateNumber(int minVal, int maxVal) {
    return minVal + _rng.nextInt(maxVal - minVal + 1);
  }

  HigherOrLowerState createInitialState({
    required List<String> playerIds,
    required Map<String, String> playerNames,
    String matchMode = 'classic',
    int? totalRounds,
    int? targetScore,
    int minNumber = 1,
    int maxNumber = 100,
    int? initialNumber,
  }) {
    if (playerIds.length < 2 || playerIds.length > 4) {
      throw ArgumentError('Higher or Lower requires 2 to 4 players. Provided: ${playerIds.length}');
    }

    String modeType = 'fixed_rounds';
    int? resolvedRounds = 20;
    int? resolvedTarget;

    if (matchMode == 'quick') {
      modeType = 'first_to_points';
      resolvedTarget = targetScore ?? 10;
      resolvedRounds = null;
    } else if (matchMode == 'extended') {
      modeType = 'fixed_rounds';
      resolvedRounds = totalRounds ?? 50;
      resolvedTarget = null;
    } else if (matchMode == 'custom') {
      if (targetScore != null && targetScore > 0) {
        modeType = 'first_to_points';
        resolvedTarget = targetScore;
        resolvedRounds = null;
      } else {
        modeType = 'fixed_rounds';
        resolvedRounds = totalRounds ?? 30;
        resolvedTarget = null;
      }
    } else {
      matchMode = 'classic';
      modeType = 'fixed_rounds';
      resolvedRounds = totalRounds ?? 20;
      resolvedTarget = null;
    }

    final startingNumber = initialNumber ?? generateNumber(minNumber, maxNumber);
    final firstPlayer = playerIds.first;
    final firstName = playerNames[firstPlayer] ?? firstPlayer;

    return HigherOrLowerState(
      gameId: 'higher_or_lower',
      minNumber: minNumber,
      maxNumber: maxNumber,
      playerIds: List.from(playerIds),
      playerNames: Map.from(playerNames),
      currentPlayerIndex: 0,
      currentTurnPlayerId: firstPlayer,
      currentNumber: startingNumber,
      scores: {for (var id in playerIds) id: 0},
      attempts: {for (var id in playerIds) id: 0},
      correctCounts: {for (var id in playerIds) id: 0},
      tieCounts: {for (var id in playerIds) id: 0},
      streaks: {for (var id in playerIds) id: 0},
      maxStreaks: {for (var id in playerIds) id: 0},
      roundNumber: 1,
      turnsTakenThisRound: 0,
      totalRounds: resolvedRounds,
      targetScore: resolvedTarget,
      modeType: modeType,
      matchMode: matchMode,
      status: 'in_progress',
      history: const [],
      lastAction: 'Match started with number $startingNumber. $firstName to predict!',
    );
  }

  /// AI decision making for solo mode against computer.
  PredictionDirection getAiPrediction(int currentNumber, {int minNumber = 1, int maxNumber = 100}) {
    final midpoint = (minNumber + maxNumber) / 2.0;
    if (currentNumber <= midpoint) {
      return PredictionDirection.higher;
    } else {
      return PredictionDirection.lower;
    }
  }

  HigherOrLowerState applyPrediction(
    HigherOrLowerState state, {
    required String playerId,
    required PredictionDirection direction,
    int? overrideNextNumber,
  }) {
    if (state.isFinished) return state;
    if (state.currentTurnPlayerId != playerId) {
      throw ArgumentError('Not player $playerId\'s turn.');
    }

    final currentNum = state.currentNumber;
    final nextNum = overrideNextNumber ?? generateNumber(state.minNumber, state.maxNumber);
    final dirStr = direction.toServerString();
    final pName = state.getPlayerName(playerId);

    String outcome;
    int points;
    bool isCorrect;
    String explanation;

    if (nextNum == currentNum) {
      outcome = 'EQUAL';
      points = 0;
      isCorrect = false;
      explanation = 'Identical numbers ($nextNum == $currentNum). Tied prediction: 0 points.';
    } else if ((direction == PredictionDirection.higher && nextNum > currentNum) ||
        (direction == PredictionDirection.lower && nextNum < currentNum)) {
      outcome = 'CORRECT';
      points = 1;
      isCorrect = true;
      final comp = nextNum > currentNum ? 'higher than' : 'lower than';
      explanation = 'Correct! $nextNum is $comp $currentNum. (+1 point)';
    } else {
      outcome = 'INCORRECT';
      points = 0;
      isCorrect = false;
      final comp = nextNum > currentNum ? 'higher than' : 'lower than';
      explanation = 'Incorrect. $nextNum is $comp $currentNum. (0 points)';
    }

    final scores = Map<String, int>.from(state.scores);
    final attempts = Map<String, int>.from(state.attempts);
    final correctCounts = Map<String, int>.from(state.correctCounts);
    final tieCounts = Map<String, int>.from(state.tieCounts);
    final streaks = Map<String, int>.from(state.streaks);
    final maxStreaks = Map<String, int>.from(state.maxStreaks);

    scores[playerId] = (scores[playerId] ?? 0) + points;
    attempts[playerId] = (attempts[playerId] ?? 0) + 1;

    if (outcome == 'CORRECT') {
      correctCounts[playerId] = (correctCounts[playerId] ?? 0) + 1;
      final currStreak = (streaks[playerId] ?? 0) + 1;
      streaks[playerId] = currStreak;
      if (currStreak > (maxStreaks[playerId] ?? 0)) {
        maxStreaks[playerId] = currStreak;
      }
    } else if (outcome == 'EQUAL') {
      tieCounts[playerId] = (tieCounts[playerId] ?? 0) + 1;
      streaks[playerId] = 0;
    } else {
      streaks[playerId] = 0;
    }

    final record = PredictionRecord(
      playerId: playerId,
      playerName: pName,
      direction: dirStr,
      previousNumber: currentNum,
      revealedNumber: nextNum,
      outcome: outcome,
      pointsAwarded: points,
      explanation: explanation,
      round: state.roundNumber,
    );

    final history = List<PredictionRecord>.from(state.history)..add(record);
    if (history.length > 30) history.removeAt(0);

    if (state.isSuddenDeath) {
      return _advanceSuddenDeath(
        state: state,
        playerId: playerId,
        isCorrect: isCorrect,
        nextNumber: nextNum,
        record: record,
        scores: scores,
        attempts: attempts,
        correctCounts: correctCounts,
        tieCounts: tieCounts,
        streaks: streaks,
        maxStreaks: maxStreaks,
        history: history,
      );
    } else {
      return _advanceRegularMatch(
        state: state,
        playerId: playerId,
        nextNumber: nextNum,
        record: record,
        scores: scores,
        attempts: attempts,
        correctCounts: correctCounts,
        tieCounts: tieCounts,
        streaks: streaks,
        maxStreaks: maxStreaks,
        history: history,
      );
    }
  }

  HigherOrLowerState _advanceRegularMatch({
    required HigherOrLowerState state,
    required String playerId,
    required int nextNumber,
    required PredictionRecord record,
    required Map<String, int> scores,
    required Map<String, int> attempts,
    required Map<String, int> correctCounts,
    required Map<String, int> tieCounts,
    required Map<String, int> streaks,
    required Map<String, int> maxStreaks,
    required List<PredictionRecord> history,
  }) {
    final pIds = state.playerIds;
    final pIdx = state.currentPlayerIndex;
    final turnsInRound = state.turnsTakenThisRound + 1;
    final currRound = state.roundNumber;

    final roundCompleted = turnsInRound >= pIds.length;
    final nextPIdx = (pIdx + 1) % pIds.length;
    final nextTurnId = pIds[nextPIdx];
    final nextRound = roundCompleted ? currRound + 1 : currRound;
    final nextTurnsInRound = roundCompleted ? 0 : turnsInRound;

    bool isFinished = false;
    String? winnerId;
    String? winnerName;
    bool isTie = false;
    bool enterSuddenDeath = false;
    List<String> sdCandidates = [];

    if (state.modeType == 'fixed_rounds') {
      if (roundCompleted && currRound >= (state.totalRounds ?? 20)) {
        isFinished = true;
      }
    } else if (state.modeType == 'first_to_points') {
      final target = state.targetScore ?? 10;
      final reached = scores.values.any((s) => s >= target);
      if (reached && roundCompleted) {
        isFinished = true;
      }
    }

    String status = 'in_progress';
    String lastAct;

    if (isFinished) {
      final maxScore = scores.values.reduce(max);
      final topScorers = scores.entries.where((e) => e.value == maxScore).map((e) => e.key).toList();

      if (topScorers.length == 1) {
        winnerId = topScorers.first;
        winnerName = state.getPlayerName(winnerId);
        status = 'finished';
        lastAct = '${record.explanation} MATCH OVER! $winnerName wins with $maxScore points!';
      } else {
        status = 'sudden_death';
        enterSuddenDeath = true;
        sdCandidates = List.from(topScorers);
        lastAct = '${record.explanation} Tie with $maxScore points! Sudden Death begins!';
      }
    } else {
      final nextName = state.getPlayerName(nextTurnId);
      lastAct = '${record.explanation} Next turn: $nextName.';
    }

    return state.copyWith(
      currentPlayerIndex: enterSuddenDeath ? pIds.indexOf(sdCandidates.first) : nextPIdx,
      currentTurnPlayerId: enterSuddenDeath ? sdCandidates.first : nextTurnId,
      currentNumber: nextNumber,
      lastPrediction: record,
      scores: scores,
      attempts: attempts,
      correctCounts: correctCounts,
      tieCounts: tieCounts,
      streaks: streaks,
      maxStreaks: maxStreaks,
      roundNumber: nextRound,
      turnsTakenThisRound: nextTurnsInRound,
      status: status,
      suddenDeathCandidates: sdCandidates,
      suddenDeathRound: enterSuddenDeath ? 1 : 0,
      suddenDeathResults: const {},
      winnerId: winnerId,
      winnerName: winnerName,
      isTie: isTie,
      history: history,
      lastAction: lastAct,
    );
  }

  HigherOrLowerState _advanceSuddenDeath({
    required HigherOrLowerState state,
    required String playerId,
    required bool isCorrect,
    required int nextNumber,
    required PredictionRecord record,
    required Map<String, int> scores,
    required Map<String, int> attempts,
    required Map<String, int> correctCounts,
    required Map<String, int> tieCounts,
    required Map<String, int> streaks,
    required Map<String, int> maxStreaks,
    required List<PredictionRecord> history,
  }) {
    final candidates = List<String>.from(state.suddenDeathCandidates);
    final sdResults = Map<String, bool>.from(state.suddenDeathResults);
    final sdRound = state.suddenDeathRound;

    sdResults[playerId] = isCorrect;

    if (sdResults.length < candidates.length) {
      final currIdx = candidates.indexOf(playerId);
      final nextCand = candidates[currIdx + 1];
      final nextPIdx = state.playerIds.indexOf(nextCand);
      final nextName = state.getPlayerName(nextCand);

      return state.copyWith(
        currentPlayerIndex: nextPIdx,
        currentTurnPlayerId: nextCand,
        currentNumber: nextNumber,
        lastPrediction: record,
        scores: scores,
        attempts: attempts,
        correctCounts: correctCounts,
        tieCounts: tieCounts,
        streaks: streaks,
        maxStreaks: maxStreaks,
        status: 'sudden_death',
        suddenDeathCandidates: candidates,
        suddenDeathRound: sdRound,
        suddenDeathResults: sdResults,
        history: history,
        lastAction: '${record.explanation} [Sudden Death R$sdRound] $nextName to predict!',
      );
    }

    // All candidates completed their turn this sudden death cycle
    final winners = sdResults.entries.where((e) => e.value).map((e) => e.key).toList();

    if (winners.length == 1) {
      final wId = winners.first;
      final wName = state.getPlayerName(wId);
      return state.copyWith(
        currentNumber: nextNumber,
        lastPrediction: record,
        scores: scores,
        attempts: attempts,
        correctCounts: correctCounts,
        tieCounts: tieCounts,
        streaks: streaks,
        maxStreaks: maxStreaks,
        status: 'finished',
        winnerId: wId,
        winnerName: wName,
        history: history,
        lastAction: '${record.explanation} SUDDEN DEATH CHAMPION: $wName wins!',
      );
    }

    final newCandidates = (winners.length > 1 && winners.length < candidates.length)
        ? winners
        : candidates;

    final nextCand = newCandidates.first;
    final nextPIdx = state.playerIds.indexOf(nextCand);
    final nextName = state.getPlayerName(nextCand);
    final nextSdRound = sdRound + 1;

    return state.copyWith(
      currentPlayerIndex: nextPIdx,
      currentTurnPlayerId: nextCand,
      currentNumber: nextNumber,
      lastPrediction: record,
      scores: scores,
      attempts: attempts,
      correctCounts: correctCounts,
      tieCounts: tieCounts,
      streaks: streaks,
      maxStreaks: maxStreaks,
      status: 'sudden_death',
      suddenDeathCandidates: newCandidates,
      suddenDeathRound: nextSdRound,
      suddenDeathResults: const {},
      history: history,
      lastAction: '${record.explanation} Sudden Death tied! Next round: $nextName to predict!',
    );
  }
}
