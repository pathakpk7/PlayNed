/// Higher or Lower: Numbers - Data Models & JSON Serialization for PlayNed.

enum PredictionDirection {
  higher,
  lower;

  static PredictionDirection fromString(String val) {
    return val.toUpperCase() == 'LOWER' ? PredictionDirection.lower : PredictionDirection.higher;
  }

  String toServerString() => name.toUpperCase();
}

enum PredictionOutcome {
  correct,
  incorrect,
  equal;

  static PredictionOutcome fromString(String val) {
    switch (val.toUpperCase()) {
      case 'CORRECT':
        return PredictionOutcome.correct;
      case 'INCORRECT':
        return PredictionOutcome.incorrect;
      case 'EQUAL':
      default:
        return PredictionOutcome.equal;
    }
  }
}

class PredictionRecord {
  final String playerId;
  final String playerName;
  final String direction; // HIGHER or LOWER
  final int previousNumber;
  final int revealedNumber;
  final String outcome; // CORRECT, INCORRECT, EQUAL
  final int pointsAwarded;
  final String explanation;
  final int round;

  const PredictionRecord({
    required this.playerId,
    required this.playerName,
    required this.direction,
    required this.previousNumber,
    required this.revealedNumber,
    required this.outcome,
    required this.pointsAwarded,
    required this.explanation,
    required this.round,
  });

  bool get isCorrect => outcome == 'CORRECT';
  bool get isEqual => outcome == 'EQUAL';

  factory PredictionRecord.fromJson(Map<String, dynamic> json) {
    return PredictionRecord(
      playerId: json['player_id']?.toString() ?? '',
      playerName: json['player_name']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'HIGHER',
      previousNumber: (json['previous_number'] as num?)?.toInt() ?? 0,
      revealedNumber: (json['revealed_number'] as num?)?.toInt() ?? 0,
      outcome: json['outcome']?.toString() ?? 'EQUAL',
      pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
      explanation: json['explanation']?.toString() ?? '',
      round: (json['round'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'player_name': playerName,
        'direction': direction,
        'previous_number': previousNumber,
        'revealed_number': revealedNumber,
        'outcome': outcome,
        'points_awarded': pointsAwarded,
        'explanation': explanation,
        'round': round,
      };
}

class HigherOrLowerState {
  final String gameId;
  final int minNumber;
  final int maxNumber;
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final int currentPlayerIndex;
  final String currentTurnPlayerId;
  final int currentNumber;
  final PredictionRecord? lastPrediction;
  final Map<String, int> scores;
  final Map<String, int> attempts;
  final Map<String, int> correctCounts;
  final Map<String, int> tieCounts;
  final Map<String, int> streaks;
  final Map<String, int> maxStreaks;
  final int roundNumber;
  final int turnsTakenThisRound;
  final int? totalRounds;
  final int? targetScore;
  final String modeType; // fixed_rounds or first_to_points
  final String matchMode; // quick, classic, extended, custom
  final String status; // in_progress, sudden_death, finished
  final List<String> suddenDeathCandidates;
  final int suddenDeathRound;
  final Map<String, bool> suddenDeathResults;
  final String? winnerId;
  final String? winnerName;
  final bool isTie;
  final List<PredictionRecord> history;
  final String lastAction;

  const HigherOrLowerState({
    this.gameId = 'higher_or_lower',
    this.minNumber = 1,
    this.maxNumber = 100,
    required this.playerIds,
    required this.playerNames,
    this.currentPlayerIndex = 0,
    required this.currentTurnPlayerId,
    required this.currentNumber,
    this.lastPrediction,
    this.scores = const {},
    this.attempts = const {},
    this.correctCounts = const {},
    this.tieCounts = const {},
    this.streaks = const {},
    this.maxStreaks = const {},
    this.roundNumber = 1,
    this.turnsTakenThisRound = 0,
    this.totalRounds = 20,
    this.targetScore,
    this.modeType = 'fixed_rounds',
    this.matchMode = 'classic',
    this.status = 'in_progress',
    this.suddenDeathCandidates = const [],
    this.suddenDeathRound = 0,
    this.suddenDeathResults = const {},
    this.winnerId,
    this.winnerName,
    this.isTie = false,
    this.history = const [],
    this.lastAction = '',
  });

  bool get isFinished => status == 'finished';
  bool get isSuddenDeath => status == 'sudden_death';

  String getPlayerName(String pid) => playerNames[pid] ?? pid;
  int getScore(String pid) => scores[pid] ?? 0;
  int getStreak(String pid) => streaks[pid] ?? 0;

  double getAccuracy(String pid) {
    final att = attempts[pid] ?? 0;
    final ties = tieCounts[pid] ?? 0;
    final valid = att - ties;
    if (valid <= 0) return 0.0;
    final corr = correctCounts[pid] ?? 0;
    return double.parse(((corr / valid) * 100.0).toStringAsFixed(1));
  }

  HigherOrLowerState copyWith({
    String? gameId,
    int? minNumber,
    int? maxNumber,
    List<String>? playerIds,
    Map<String, String>? playerNames,
    int? currentPlayerIndex,
    String? currentTurnPlayerId,
    int? currentNumber,
    PredictionRecord? lastPrediction,
    Map<String, int>? scores,
    Map<String, int>? attempts,
    Map<String, int>? correctCounts,
    Map<String, int>? tieCounts,
    Map<String, int>? streaks,
    Map<String, int>? maxStreaks,
    int? roundNumber,
    int? turnsTakenThisRound,
    int? totalRounds,
    int? targetScore,
    String? modeType,
    String? matchMode,
    String? status,
    List<String>? suddenDeathCandidates,
    int? suddenDeathRound,
    Map<String, bool>? suddenDeathResults,
    String? winnerId,
    String? winnerName,
    bool? isTie,
    List<PredictionRecord>? history,
    String? lastAction,
  }) {
    return HigherOrLowerState(
      gameId: gameId ?? this.gameId,
      minNumber: minNumber ?? this.minNumber,
      maxNumber: maxNumber ?? this.maxNumber,
      playerIds: playerIds ?? this.playerIds,
      playerNames: playerNames ?? this.playerNames,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      currentNumber: currentNumber ?? this.currentNumber,
      lastPrediction: lastPrediction ?? this.lastPrediction,
      scores: scores ?? this.scores,
      attempts: attempts ?? this.attempts,
      correctCounts: correctCounts ?? this.correctCounts,
      tieCounts: tieCounts ?? this.tieCounts,
      streaks: streaks ?? this.streaks,
      maxStreaks: maxStreaks ?? this.maxStreaks,
      roundNumber: roundNumber ?? this.roundNumber,
      turnsTakenThisRound: turnsTakenThisRound ?? this.turnsTakenThisRound,
      totalRounds: totalRounds ?? this.totalRounds,
      targetScore: targetScore ?? this.targetScore,
      modeType: modeType ?? this.modeType,
      matchMode: matchMode ?? this.matchMode,
      status: status ?? this.status,
      suddenDeathCandidates: suddenDeathCandidates ?? this.suddenDeathCandidates,
      suddenDeathRound: suddenDeathRound ?? this.suddenDeathRound,
      suddenDeathResults: suddenDeathResults ?? this.suddenDeathResults,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      isTie: isTie ?? this.isTie,
      history: history ?? this.history,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  factory HigherOrLowerState.fromJson(Map<String, dynamic> json) {
    final pIds = (json['player_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final pNames = (json['player_names'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {};

    Map<String, int> parseMap(dynamic mapObj) {
      if (mapObj is! Map) return {};
      return mapObj.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    final histRaw = json['history'] as List?;
    final hist = histRaw != null
        ? histRaw.map((e) => PredictionRecord.fromJson(e as Map<String, dynamic>)).toList()
        : <PredictionRecord>[];

    return HigherOrLowerState(
      gameId: json['game_id']?.toString() ?? 'higher_or_lower',
      minNumber: (json['min_number'] as num?)?.toInt() ?? 1,
      maxNumber: (json['max_number'] as num?)?.toInt() ?? 100,
      playerIds: pIds,
      playerNames: pNames,
      currentPlayerIndex: (json['current_player_index'] as num?)?.toInt() ?? 0,
      currentTurnPlayerId: json['current_turn_player_id']?.toString() ?? (pIds.isNotEmpty ? pIds[0] : 'p1'),
      currentNumber: (json['current_number'] as num?)?.toInt() ?? 50,
      lastPrediction: json['last_prediction'] != null
          ? PredictionRecord.fromJson(json['last_prediction'] as Map<String, dynamic>)
          : null,
      scores: parseMap(json['scores']),
      attempts: parseMap(json['attempts']),
      correctCounts: parseMap(json['correct_counts']),
      tieCounts: parseMap(json['tie_counts']),
      streaks: parseMap(json['streaks']),
      maxStreaks: parseMap(json['max_streaks']),
      roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
      turnsTakenThisRound: (json['turns_taken_this_round'] as num?)?.toInt() ?? 0,
      totalRounds: (json['total_rounds'] as num?)?.toInt(),
      targetScore: (json['target_score'] as num?)?.toInt(),
      modeType: json['mode_type']?.toString() ?? 'fixed_rounds',
      matchMode: json['match_mode']?.toString() ?? 'classic',
      status: json['status']?.toString() ?? 'in_progress',
      suddenDeathCandidates: (json['sudden_death_candidates'] as List?)?.map((e) => e.toString()).toList() ?? [],
      suddenDeathRound: (json['sudden_death_round'] as num?)?.toInt() ?? 0,
      suddenDeathResults: (json['sudden_death_results'] as Map?)?.map((k, v) => MapEntry(k.toString(), v == true)) ?? {},
      winnerId: json['winner_id']?.toString(),
      winnerName: json['winner_name']?.toString(),
      isTie: json['is_tie'] == true,
      history: hist,
      lastAction: json['last_action']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'game_id': gameId,
        'min_number': minNumber,
        'max_number': maxNumber,
        'player_ids': playerIds,
        'player_names': playerNames,
        'current_player_index': currentPlayerIndex,
        'current_turn_player_id': currentTurnPlayerId,
        'current_number': currentNumber,
        'last_prediction': lastPrediction?.toJson(),
        'scores': scores,
        'attempts': attempts,
        'correct_counts': correctCounts,
        'tie_counts': tieCounts,
        'streaks': streaks,
        'max_streaks': maxStreaks,
        'round_number': roundNumber,
        'turns_taken_this_round': turnsTakenThisRound,
        'total_rounds': totalRounds,
        'target_score': targetScore,
        'mode_type': modeType,
        'match_mode': matchMode,
        'status': status,
        'sudden_death_candidates': suddenDeathCandidates,
        'sudden_death_round': suddenDeathRound,
        'sudden_death_results': suddenDeathResults,
        'winner_id': winnerId,
        'winner_name': winnerName,
        'is_tie': isTie,
        'history': history.map((e) => e.toJson()).toList(),
        'last_action': lastAction,
      };
}
