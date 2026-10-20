import 'package:flutter/material.dart';

enum RajaMantriRole {
  raja,
  mantri,
  sipahi,
  chor;

  String get displayName {
    switch (this) {
      case RajaMantriRole.raja:
        return 'Raja';
      case RajaMantriRole.mantri:
        return 'Mantri';
      case RajaMantriRole.sipahi:
        return 'Sipahi';
      case RajaMantriRole.chor:
        return 'Chor';
    }
  }

  String get englishTitle {
    switch (this) {
      case RajaMantriRole.raja:
        return 'King';
      case RajaMantriRole.mantri:
        return 'Minister';
      case RajaMantriRole.sipahi:
        return 'Police';
      case RajaMantriRole.chor:
        return 'Thief';
    }
  }

  int get points {
    switch (this) {
      case RajaMantriRole.raja:
        return 1000;
      case RajaMantriRole.mantri:
        return 0;
      case RajaMantriRole.sipahi:
        return 500;
      case RajaMantriRole.chor:
        return 800;
    }
  }

  String get description {
    switch (this) {
      case RajaMantriRole.raja:
        return 'The Sovereign Crown. Demands to know who the royal Minister is.';
      case RajaMantriRole.mantri:
        return 'The Royal Strategist. Must deduce and apprehend the hidden Thief.';
      case RajaMantriRole.sipahi:
        return 'The Loyal Guard. Stands silent while the Minister deduces.';
      case RajaMantriRole.chor:
        return 'The Elusive Phantom. Must blend in and evade the Minister\'s accusation.';
    }
  }

  Color get color {
    switch (this) {
      case RajaMantriRole.raja:
        return const Color(0xFFEAB308); // Regal Saffron Gold
      case RajaMantriRole.mantri:
        return const Color(0xFF38BDF8); // Sapphire Blue
      case RajaMantriRole.sipahi:
        return const Color(0xFF10B981); // Emerald Green Guard
      case RajaMantriRole.chor:
        return const Color(0xFFF43F5E); // Crimson Rose Thief
    }
  }

  IconData get icon {
    switch (this) {
      case RajaMantriRole.raja:
        return Icons.workspace_premium; // Crown / Scepter
      case RajaMantriRole.mantri:
        return Icons.auto_stories; // Scroll of Wisdom
      case RajaMantriRole.sipahi:
        return Icons.shield; // Guard Shield
      case RajaMantriRole.chor:
        return Icons.masks; // Thief Mask
    }
  }

  static RajaMantriRole? fromString(String? val) {
    if (val == null) return null;
    switch (val.toLowerCase().trim()) {
      case 'raja':
        return RajaMantriRole.raja;
      case 'mantri':
        return RajaMantriRole.mantri;
      case 'sipahi':
        return RajaMantriRole.sipahi;
      case 'chor':
        return RajaMantriRole.chor;
      default:
        return null;
    }
  }
}

enum RajaMantriPhase {
  chitReveal,
  rajaReveal,
  mantriReveal,
  chorGuess,
  fullReveal,
  roundResults,
  matchResults;

  static RajaMantriPhase fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'RAJA_REVEAL':
        return RajaMantriPhase.rajaReveal;
      case 'MANTRI_REVEAL':
        return RajaMantriPhase.mantriReveal;
      case 'CHOR_GUESS':
        return RajaMantriPhase.chorGuess;
      case 'FULL_REVEAL':
        return RajaMantriPhase.fullReveal;
      case 'ROUND_RESULTS':
        return RajaMantriPhase.roundResults;
      case 'MATCH_RESULTS':
        return RajaMantriPhase.matchResults;
      default:
        return RajaMantriPhase.chitReveal;
    }
  }

  String toServerString() {
    switch (this) {
      case RajaMantriPhase.chitReveal:
        return 'CHIT_REVEAL';
      case RajaMantriPhase.rajaReveal:
        return 'RAJA_REVEAL';
      case RajaMantriPhase.mantriReveal:
        return 'MANTRI_REVEAL';
      case RajaMantriPhase.chorGuess:
        return 'CHOR_GUESS';
      case RajaMantriPhase.fullReveal:
        return 'FULL_REVEAL';
      case RajaMantriPhase.roundResults:
        return 'ROUND_RESULTS';
      case RajaMantriPhase.matchResults:
        return 'MATCH_RESULTS';
    }
  }
}

class RajaMantriState {
  final String gameId;
  final RajaMantriPhase phase;
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final int currentRound;
  final int totalRounds;

  // Roles
  final Map<String, RajaMantriRole> roleAssignments; // Local full map
  final Map<String, RajaMantriRole> revealedRoles;   // Publicly revealed roles
  final RajaMantriRole? myRole;                     // Private role for this client
  final String? rajaPlayerId;
  final String? mantriPlayerId;
  final String? sipahiPlayerId;
  final String? chorPlayerId;
  final List<String> eligibleSuspectIds;
  final List<String> acknowledgedPlayers;

  // Guess outcome
  final String? guessedChorPlayerId;
  final bool? guessCorrect;

  // Scores
  final Map<String, int> roundPoints;
  final Map<String, int> cumulativeScores;
  final List<Map<String, dynamic>> roundHistory;

  // Match outcome
  final String status;
  final String lastAction;
  final List<String> winnerPlayerIds;
  final bool isTie;

  RajaMantriState({
    this.gameId = 'raja_mantri_chor_sipahi',
    required this.phase,
    required this.playerIds,
    required this.playerNames,
    this.currentRound = 1,
    this.totalRounds = 5,
    this.roleAssignments = const {},
    this.revealedRoles = const {},
    this.myRole,
    this.rajaPlayerId,
    this.mantriPlayerId,
    this.sipahiPlayerId,
    this.chorPlayerId,
    this.eligibleSuspectIds = const [],
    this.acknowledgedPlayers = const [],
    this.guessedChorPlayerId,
    this.guessCorrect,
    this.roundPoints = const {},
    this.cumulativeScores = const {},
    this.roundHistory = const [],
    this.status = 'in_progress',
    this.lastAction = 'Chits shuffled. Each player must secretly view their role.',
    this.winnerPlayerIds = const [],
    this.isTie = false,
  });

  bool get isGameOver => phase == RajaMantriPhase.matchResults || status == 'finished';

  String getPlayerName(String pid) => playerNames[pid] ?? pid;

  int getPlayerScore(String pid) => cumulativeScores[pid] ?? 0;

  int getPlayerRoundPoints(String pid) => roundPoints[pid] ?? 0;

  RajaMantriRole? getPlayerRole(String pid) {
    if (revealedRoles.containsKey(pid)) return revealedRoles[pid];
    if (roleAssignments.containsKey(pid)) return roleAssignments[pid];
    return null;
  }

  factory RajaMantriState.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['role_assignments'] as Map<String, dynamic>? ?? {};
    final parsedRoles = <String, RajaMantriRole>{};
    rawRoles.forEach((k, v) {
      final role = RajaMantriRole.fromString(v?.toString());
      if (role != null) parsedRoles[k] = role;
    });

    final rawRevealed = json['revealed_roles'] as Map<String, dynamic>? ?? {};
    final parsedRevealed = <String, RajaMantriRole>{};
    rawRevealed.forEach((k, v) {
      final role = RajaMantriRole.fromString(v?.toString());
      if (role != null) parsedRevealed[k] = role;
    });

    final rawPts = json['round_points'] as Map<String, dynamic>? ?? {};
    final parsedPts = <String, int>{};
    rawPts.forEach((k, v) => parsedPts[k] = (v as num).toInt());

    final rawCum = json['cumulative_scores'] as Map<String, dynamic>? ?? {};
    final parsedCum = <String, int>{};
    rawCum.forEach((k, v) => parsedCum[k] = (v as num).toInt());

    return RajaMantriState(
      gameId: json['game_id'] ?? 'raja_mantri_chor_sipahi',
      phase: RajaMantriPhase.fromString(json['phase']),
      playerIds: List<String>.from(json['player_ids'] ?? []),
      playerNames: Map<String, String>.from(json['player_names'] ?? {}),
      currentRound: json['current_round'] ?? 1,
      totalRounds: json['total_rounds'] ?? 5,
      roleAssignments: parsedRoles,
      revealedRoles: parsedRevealed,
      myRole: RajaMantriRole.fromString(json['my_role']?.toString()),
      rajaPlayerId: json['raja_player_id'],
      mantriPlayerId: json['mantri_player_id'],
      sipahiPlayerId: json['sipahi_player_id'],
      chorPlayerId: json['chor_player_id'],
      eligibleSuspectIds: List<String>.from(json['eligible_suspect_ids'] ?? []),
      acknowledgedPlayers: List<String>.from(json['acknowledged_players'] ?? []),
      guessedChorPlayerId: json['guessed_chor_player_id'],
      guessCorrect: json['guess_correct'],
      roundPoints: parsedPts,
      cumulativeScores: parsedCum,
      roundHistory: List<Map<String, dynamic>>.from(json['round_history'] ?? []),
      status: json['status'] ?? 'in_progress',
      lastAction: json['last_action'] ?? '',
      winnerPlayerIds: List<String>.from(json['winner_player_ids'] ?? []),
      isTie: json['is_tie'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'game_id': gameId,
    'phase': phase.toServerString(),
    'player_ids': playerIds,
    'player_names': playerNames,
    'current_round': currentRound,
    'total_rounds': totalRounds,
    'role_assignments': roleAssignments.map((k, v) => MapEntry(k, v.displayName)),
    'revealed_roles': revealedRoles.map((k, v) => MapEntry(k, v.displayName)),
    'my_role': myRole?.displayName,
    'raja_player_id': rajaPlayerId,
    'mantri_player_id': mantriPlayerId,
    'sipahi_player_id': sipahiPlayerId,
    'chor_player_id': chorPlayerId,
    'eligible_suspect_ids': eligibleSuspectIds,
    'acknowledged_players': acknowledgedPlayers,
    'guessed_chor_player_id': guessedChorPlayerId,
    'guess_correct': guessCorrect,
    'round_points': roundPoints,
    'cumulative_scores': cumulativeScores,
    'round_history': roundHistory,
    'status': status,
    'last_action': lastAction,
    'winner_player_ids': winnerPlayerIds,
    'is_tie': isTie,
  };
}
