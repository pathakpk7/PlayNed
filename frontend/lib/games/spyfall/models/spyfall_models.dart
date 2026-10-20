class SpyfallLocation {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> themes;

  const SpyfallLocation({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    this.themes = const [],
  });

  factory SpyfallLocation.fromJson(Map<String, dynamic> json) {
    return SpyfallLocation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      themes: (json['themes'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'themes': themes,
      };
}

enum SpyfallPhase {
  roleReveal,
  discussion,
  accusationVoting,
  spyGuess,
  roundResolution,
  matchResults;

  static SpyfallPhase fromString(String val) {
    switch (val.toUpperCase()) {
      case 'DISCUSSION':
        return SpyfallPhase.discussion;
      case 'ACCUSATION_VOTING':
        return SpyfallPhase.accusationVoting;
      case 'SPY_GUESS':
        return SpyfallPhase.spyGuess;
      case 'ROUND_RESOLUTION':
        return SpyfallPhase.roundResolution;
      case 'MATCH_RESULTS':
        return SpyfallPhase.matchResults;
      case 'ROLE_REVEAL':
      default:
        return SpyfallPhase.roleReveal;
    }
  }

  String toServerString() {
    switch (this) {
      case SpyfallPhase.roleReveal:
        return 'ROLE_REVEAL';
      case SpyfallPhase.discussion:
        return 'DISCUSSION';
      case SpyfallPhase.accusationVoting:
        return 'ACCUSATION_VOTING';
      case SpyfallPhase.spyGuess:
        return 'SPY_GUESS';
      case SpyfallPhase.roundResolution:
        return 'ROUND_RESOLUTION';
      case SpyfallPhase.matchResults:
        return 'MATCH_RESULTS';
    }
  }
}

class SpyfallState {
  final String gameId;
  final SpyfallPhase phase;
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final int currentRound;
  final int totalRounds;
  final int roundDurationMinutes;
  final String category;
  final bool allowSpyGuess;

  // Private Role info for active client view
  final String? myRole; // 'spy' or 'explorer'
  final String? myLocation; // null for spy
  final String? myLocationCategory;

  // Local full information (when in local pass & play)
  final String? spyPlayerId;
  final SpyfallLocation? secretLocation;
  final Map<String, String> roleAssignments;

  // Phase & timer tracking
  final List<String> acknowledgedPlayers;
  final int discussionDurationSeconds;
  final int remainingDiscussionSeconds;
  final double? discussionEndTime;
  final double? votingEndTime;

  // Accusation & Voting
  final String? accuserPlayerId;
  final String? accusedTargetId;
  final Map<String, String> votes; // {playerId: 'guilty'|'innocent'}
  final List<String> votedPlayerIds;

  // Spy Guess
  final int spyGuessesRemaining;
  final String? spyGuessedLocation;
  final bool? spyGuessCorrect;

  // Scoring & Outcomes
  final String? roundOutcome;
  final String? outcomeReason;
  final Map<String, int> roundPoints;
  final Map<String, int> cumulativeScores;
  final List<String> winnerPlayerIds;
  final List<String> roundHistory;
  final String lastAction;

  const SpyfallState({
    this.gameId = 'spyfall',
    required this.phase,
    required this.playerIds,
    required this.playerNames,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.roundDurationMinutes = 5,
    this.category = 'all',
    this.allowSpyGuess = true,
    this.myRole,
    this.myLocation,
    this.myLocationCategory,
    this.spyPlayerId,
    this.secretLocation,
    this.roleAssignments = const {},
    this.acknowledgedPlayers = const [],
    this.discussionDurationSeconds = 300,
    this.remainingDiscussionSeconds = 300,
    this.discussionEndTime,
    this.votingEndTime,
    this.accuserPlayerId,
    this.accusedTargetId,
    this.votes = const {},
    this.votedPlayerIds = const [],
    this.spyGuessesRemaining = 1,
    this.spyGuessedLocation,
    this.spyGuessCorrect,
    this.roundOutcome,
    this.outcomeReason,
    this.roundPoints = const {},
    this.cumulativeScores = const {},
    this.winnerPlayerIds = const [],
    this.roundHistory = const [],
    this.lastAction = 'Secret roles assigned. View your card privately.',
  });

  bool get isSpy => myRole == 'spy';
  bool get isGameOver => phase == SpyfallPhase.matchResults;

  // Convenience aliases for flexible UI and testing bindings
  Map<String, int> get scores => cumulativeScores;
  String? get lastOutcome => roundOutcome;
  String? get activeAccusedId => accusedTargetId;
  String? get activeAccuserId => accuserPlayerId;
  Map<String, String> get currentVotes => votes;
  Map<String, int> get lastRoundPoints => roundPoints;
  String? get lastSpyGuess => spyGuessedLocation;
  int get remainingSeconds => remainingDiscussionSeconds;
  bool get isTimerPaused =>
      phase == SpyfallPhase.accusationVoting ||
      phase == SpyfallPhase.spyGuess ||
      phase == SpyfallPhase.roundResolution ||
      phase == SpyfallPhase.matchResults;

  String getPlayerName(String pid) => playerNames[pid] ?? pid;
  int getPlayerScore(String pid) => cumulativeScores[pid] ?? 0;
  int getPlayerRoundPoints(String pid) => roundPoints[pid] ?? 0;

  SpyfallState copyWith({
    String? gameId,
    SpyfallPhase? phase,
    List<String>? playerIds,
    Map<String, String>? playerNames,
    int? currentRound,
    int? totalRounds,
    int? roundDurationMinutes,
    String? category,
    bool? allowSpyGuess,
    String? myRole,
    String? myLocation,
    String? myLocationCategory,
    String? spyPlayerId,
    SpyfallLocation? secretLocation,
    Map<String, String>? roleAssignments,
    List<String>? acknowledgedPlayers,
    int? discussionDurationSeconds,
    int? remainingDiscussionSeconds,
    int? remainingSeconds,
    double? discussionEndTime,
    double? votingEndTime,
    String? accuserPlayerId,
    String? accusedTargetId,
    Map<String, String>? votes,
    List<String>? votedPlayerIds,
    int? spyGuessesRemaining,
    String? spyGuessedLocation,
    bool? spyGuessCorrect,
    String? roundOutcome,
    String? outcomeReason,
    Map<String, int>? roundPoints,
    Map<String, int>? cumulativeScores,
    List<String>? winnerPlayerIds,
    List<String>? roundHistory,
    String? lastAction,
  }) {
    return SpyfallState(
      gameId: gameId ?? this.gameId,
      phase: phase ?? this.phase,
      playerIds: playerIds ?? this.playerIds,
      playerNames: playerNames ?? this.playerNames,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      roundDurationMinutes: roundDurationMinutes ?? this.roundDurationMinutes,
      category: category ?? this.category,
      allowSpyGuess: allowSpyGuess ?? this.allowSpyGuess,
      myRole: myRole ?? this.myRole,
      myLocation: myLocation ?? this.myLocation,
      myLocationCategory: myLocationCategory ?? this.myLocationCategory,
      spyPlayerId: spyPlayerId ?? this.spyPlayerId,
      secretLocation: secretLocation ?? this.secretLocation,
      roleAssignments: roleAssignments ?? this.roleAssignments,
      acknowledgedPlayers: acknowledgedPlayers ?? this.acknowledgedPlayers,
      discussionDurationSeconds: discussionDurationSeconds ?? this.discussionDurationSeconds,
      remainingDiscussionSeconds: remainingSeconds ?? remainingDiscussionSeconds ?? this.remainingDiscussionSeconds,
      discussionEndTime: discussionEndTime ?? this.discussionEndTime,
      votingEndTime: votingEndTime ?? this.votingEndTime,
      accuserPlayerId: accuserPlayerId ?? this.accuserPlayerId,
      accusedTargetId: accusedTargetId ?? this.accusedTargetId,
      votes: votes ?? this.votes,
      votedPlayerIds: votedPlayerIds ?? this.votedPlayerIds,
      spyGuessesRemaining: spyGuessesRemaining ?? this.spyGuessesRemaining,
      spyGuessedLocation: spyGuessedLocation ?? this.spyGuessedLocation,
      spyGuessCorrect: spyGuessCorrect ?? this.spyGuessCorrect,
      roundOutcome: roundOutcome ?? this.roundOutcome,
      outcomeReason: outcomeReason ?? this.outcomeReason,
      roundPoints: roundPoints ?? this.roundPoints,
      cumulativeScores: cumulativeScores ?? this.cumulativeScores,
      winnerPlayerIds: winnerPlayerIds ?? this.winnerPlayerIds,
      roundHistory: roundHistory ?? this.roundHistory,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  factory SpyfallState.fromJson(Map<String, dynamic> json) {
    final pIds = (json['player_ids'] as List? ?? []).map((e) => e.toString()).toList();
    final pNames = (json['player_names'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));

    final rawVotes = json['votes'] as Map<String, dynamic>? ?? {};
    final votesMap = rawVotes.map((k, v) => MapEntry(k, v.toString()));

    final rawRoles = json['role_assignments'] as Map<String, dynamic>? ?? {};
    final rolesMap = rawRoles.map((k, v) => MapEntry(k, v.toString()));

    final rawRoundPts = json['round_points'] as Map<String, dynamic>? ?? {};
    final rPts = rawRoundPts.map((k, v) => MapEntry(k, (v as num).toInt()));

    final rawCum = json['cumulative_scores'] as Map<String, dynamic>? ?? {};
    final cum = rawCum.map((k, v) => MapEntry(k, (v as num).toInt()));

    SpyfallLocation? secLoc;
    if (json['secret_location'] is Map) {
      secLoc = SpyfallLocation.fromJson(json['secret_location'] as Map<String, dynamic>);
    }

    return SpyfallState(
      gameId: json['game_id']?.toString() ?? 'spyfall',
      phase: SpyfallPhase.fromString(json['phase']?.toString() ?? 'ROLE_REVEAL'),
      playerIds: pIds,
      playerNames: pNames,
      currentRound: (json['current_round'] as num?)?.toInt() ?? 1,
      totalRounds: (json['total_rounds'] as num?)?.toInt() ?? 3,
      roundDurationMinutes: (json['round_duration_minutes'] as num?)?.toInt() ?? 5,
      category: json['category']?.toString() ?? 'all',
      allowSpyGuess: json['allow_spy_guess'] != false,
      myRole: json['my_role']?.toString(),
      myLocation: json['my_location']?.toString(),
      myLocationCategory: json['my_location_category']?.toString(),
      spyPlayerId: json['spy_player_id']?.toString(),
      secretLocation: secLoc,
      roleAssignments: rolesMap,
      acknowledgedPlayers: (json['acknowledged_players'] as List? ?? []).map((e) => e.toString()).toList(),
      discussionDurationSeconds: (json['discussion_duration_seconds'] as num?)?.toInt() ?? 300,
      remainingDiscussionSeconds: (json['remaining_discussion_seconds'] as num?)?.toInt() ?? 300,
      discussionEndTime: (json['discussion_end_time'] as num?)?.toDouble(),
      votingEndTime: (json['voting_end_time'] as num?)?.toDouble(),
      accuserPlayerId: json['accuser_player_id']?.toString(),
      accusedTargetId: json['accused_target_id']?.toString(),
      votes: votesMap,
      votedPlayerIds: (json['voted_player_ids'] as List? ?? []).map((e) => e.toString()).toList(),
      spyGuessesRemaining: (json['spy_guesses_remaining'] as num?)?.toInt() ?? 1,
      spyGuessedLocation: json['spy_guessed_location']?.toString(),
      spyGuessCorrect: json['spy_guess_correct'] as bool?,
      roundOutcome: json['round_outcome']?.toString(),
      outcomeReason: json['outcome_reason']?.toString(),
      roundPoints: rPts,
      cumulativeScores: cum,
      winnerPlayerIds: (json['winner_player_ids'] as List? ?? []).map((e) => e.toString()).toList(),
      roundHistory: (json['round_history'] as List? ?? []).map((e) => e.toString()).toList(),
      lastAction: json['last_action']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'game_id': gameId,
        'phase': phase.toServerString(),
        'player_ids': playerIds,
        'player_names': playerNames,
        'current_round': currentRound,
        'total_rounds': totalRounds,
        'round_duration_minutes': roundDurationMinutes,
        'category': category,
        'allow_spy_guess': allowSpyGuess,
        'my_role': myRole,
        'my_location': myLocation,
        'my_location_category': myLocationCategory,
        if (spyPlayerId != null) 'spy_player_id': spyPlayerId,
        if (secretLocation != null) 'secret_location': secretLocation!.toJson(),
        'role_assignments': roleAssignments,
        'acknowledged_players': acknowledgedPlayers,
        'discussion_duration_seconds': discussionDurationSeconds,
        'remaining_discussion_seconds': remainingDiscussionSeconds,
        'discussion_end_time': discussionEndTime,
        'voting_end_time': votingEndTime,
        'accuser_player_id': accuserPlayerId,
        'accused_target_id': accusedTargetId,
        'votes': votes,
        'voted_player_ids': votedPlayerIds,
        'spy_guesses_remaining': spyGuessesRemaining,
        'spy_guessed_location': spyGuessedLocation,
        'spy_guess_correct': spyGuessCorrect,
        'round_outcome': roundOutcome,
        'outcome_reason': outcomeReason,
        'round_points': roundPoints,
        'cumulative_scores': cumulativeScores,
        'winner_player_ids': winnerPlayerIds,
        'round_history': roundHistory,
        'last_action': lastAction,
      };
}
