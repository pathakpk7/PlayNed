/// Mafia / Werewolf Data Models & Serialization for PlayNed.

enum MafiaFaction {
  town,
  mafia,
  neutral;

  static MafiaFaction fromString(String val) {
    switch (val.toLowerCase()) {
      case 'mafia':
        return MafiaFaction.mafia;
      case 'neutral':
        return MafiaFaction.neutral;
      case 'town':
      default:
        return MafiaFaction.town;
    }
  }

  String toServerString() => name;
}

enum MafiaRoleType {
  villager,
  doctor,
  detective,
  mafia,
  bodyguard,
  jester;

  static MafiaRoleType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'doctor':
        return MafiaRoleType.doctor;
      case 'detective':
        return MafiaRoleType.detective;
      case 'mafia':
      case 'werewolf':
        return MafiaRoleType.mafia;
      case 'bodyguard':
        return MafiaRoleType.bodyguard;
      case 'jester':
        return MafiaRoleType.jester;
      case 'villager':
      default:
        return MafiaRoleType.villager;
    }
  }

  String get displayName {
    switch (this) {
      case MafiaRoleType.villager:
        return 'Villager';
      case MafiaRoleType.doctor:
        return 'Doctor';
      case MafiaRoleType.detective:
        return 'Detective';
      case MafiaRoleType.mafia:
        return 'Mafia';
      case MafiaRoleType.bodyguard:
        return 'Bodyguard';
      case MafiaRoleType.jester:
        return 'Jester';
    }
  }

  MafiaFaction get faction {
    switch (this) {
      case MafiaRoleType.mafia:
        return MafiaFaction.mafia;
      case MafiaRoleType.jester:
        return MafiaFaction.neutral;
      case MafiaRoleType.villager:
      case MafiaRoleType.doctor:
      case MafiaRoleType.detective:
      case MafiaRoleType.bodyguard:
      default:
        return MafiaFaction.town;
    }
  }

  String toServerString() => name;
}

enum MafiaPhase {
  roleReveal,
  nightActions,
  nightResolution,
  dayAnnouncement,
  dayDiscussion,
  dayVoting,
  voteResolution,
  matchResults;

  static MafiaPhase fromString(String val) {
    switch (val.toUpperCase()) {
      case 'NIGHT_ACTIONS':
        return MafiaPhase.nightActions;
      case 'NIGHT_RESOLUTION':
        return MafiaPhase.nightResolution;
      case 'DAY_ANNOUNCEMENT':
        return MafiaPhase.dayAnnouncement;
      case 'DAY_DISCUSSION':
        return MafiaPhase.dayDiscussion;
      case 'DAY_VOTING':
        return MafiaPhase.dayVoting;
      case 'VOTE_RESOLUTION':
        return MafiaPhase.voteResolution;
      case 'MATCH_RESULTS':
        return MafiaPhase.matchResults;
      case 'ROLE_REVEAL':
      default:
        return MafiaPhase.roleReveal;
    }
  }

  String toServerString() {
    switch (this) {
      case MafiaPhase.roleReveal:
        return 'ROLE_REVEAL';
      case MafiaPhase.nightActions:
        return 'NIGHT_ACTIONS';
      case MafiaPhase.nightResolution:
        return 'NIGHT_RESOLUTION';
      case MafiaPhase.dayAnnouncement:
        return 'DAY_ANNOUNCEMENT';
      case MafiaPhase.dayDiscussion:
        return 'DAY_DISCUSSION';
      case MafiaPhase.dayVoting:
        return 'DAY_VOTING';
      case MafiaPhase.voteResolution:
        return 'VOTE_RESOLUTION';
      case MafiaPhase.matchResults:
        return 'MATCH_RESULTS';
    }
  }
}

class InvestigationResult {
  final int round;
  final String targetId;
  final String targetName;
  final bool isMafia;

  const InvestigationResult({
    required this.round,
    required this.targetId,
    required this.targetName,
    required this.isMafia,
  });

  factory InvestigationResult.fromJson(Map<String, dynamic> json) {
    return InvestigationResult(
      round: (json['round'] as num?)?.toInt() ?? 1,
      targetId: json['target_id']?.toString() ?? '',
      targetName: json['target_name']?.toString() ?? '',
      isMafia: json['is_mafia'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'round': round,
        'target_id': targetId,
        'target_name': targetName,
        'is_mafia': isMafia,
      };
}

class MafiaState {
  final String gameId;
  final MafiaPhase phase;
  final int roundNumber;
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final Map<String, bool> aliveStatus;
  final List<String> acknowledgedPlayers;

  // Private Role info for local/online player perspective
  final String? myRole;
  final List<String> mafiaTeammates;
  final List<InvestigationResult> myInvestigations;

  // Authoritative server roles (only populated in local pass & play or match end)
  final Map<String, String> roleAssignments;

  // Night phase targets & results
  final Map<String, String> mafiaVotes;
  final String? doctorTarget;
  final String? detectiveTarget;
  final String? bodyguardTarget;
  final String? lastNightCasualty;
  final String? lastVotedOut;

  // Day Discussion & Voting
  final int discussionDurationSeconds;
  final double? discussionEndTime;
  final double? votingEndTime;
  final Map<String, String> votes;
  final List<String> votedPlayerIds;

  // Rules Configuration
  final bool allowSelfHeal;
  final bool revealRoleOnDeath;
  final bool includeJester;
  final bool includeBodyguard;

  // Win State
  final String? winningFaction; // "town", "mafia", "jester"
  final List<String> winnerPlayerIds;
  final List<String> log;
  final String lastAction;

  const MafiaState({
    this.gameId = 'mafia',
    required this.phase,
    this.roundNumber = 1,
    required this.playerIds,
    required this.playerNames,
    this.aliveStatus = const {},
    this.acknowledgedPlayers = const [],
    this.myRole,
    this.mafiaTeammates = const [],
    this.myInvestigations = const [],
    this.roleAssignments = const {},
    this.mafiaVotes = const {},
    this.doctorTarget,
    this.detectiveTarget,
    this.bodyguardTarget,
    this.lastNightCasualty,
    this.lastVotedOut,
    this.discussionDurationSeconds = 120,
    this.discussionEndTime,
    this.votingEndTime,
    this.votes = const {},
    this.votedPlayerIds = const [],
    this.allowSelfHeal = false,
    this.revealRoleOnDeath = true,
    this.includeJester = false,
    this.includeBodyguard = false,
    this.winningFaction,
    this.winnerPlayerIds = const [],
    this.log = const [],
    this.lastAction = '',
  });

  bool isAlive(String pid) => aliveStatus[pid] ?? true;
  String getPlayerName(String pid) => playerNames[pid] ?? pid;

  bool get isGameOver => phase == MafiaPhase.matchResults;
  bool isPlayerMafia(String pid) => mafiaTeammates.contains(pid) || roleAssignments[pid] == 'mafia';

  int get livingTownCount {
    return playerIds.where((pid) {
      if (!isAlive(pid)) return false;
      final r = roleAssignments[pid];
      return r != null && r != 'mafia';
    }).length;
  }

  int get livingMafiaCount {
    return playerIds.where((pid) {
      if (!isAlive(pid)) return false;
      final r = roleAssignments[pid];
      return r == 'mafia';
    }).length;
  }

  factory MafiaState.fromJson(Map<String, dynamic> json) {
    final pIds = (json['player_ids'] as List? ?? []).map((e) => e.toString()).toList();
    final pNames = (json['player_names'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));

    final aliveMap = (json['alive_status'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v == true));

    final rawRoles = (json['role_assignments'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));

    final night = json['night_actions'] as Map<String, dynamic>? ?? {};
    final rawMafiaVotes = (night['mafia_votes'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));

    final rawInvs = (json['my_investigations'] as List? ?? [])
        .map((e) => InvestigationResult.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawVotes = (json['votes'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));

    return MafiaState(
      gameId: json['game_id']?.toString() ?? 'mafia',
      phase: MafiaPhase.fromString(json['phase']?.toString() ?? 'ROLE_REVEAL'),
      roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
      playerIds: pIds,
      playerNames: pNames,
      aliveStatus: aliveMap,
      acknowledgedPlayers: (json['acknowledged_players'] as List? ?? []).map((e) => e.toString()).toList(),
      myRole: json['my_role']?.toString(),
      mafiaTeammates: (json['mafia_teammates'] as List? ?? []).map((e) => e.toString()).toList(),
      myInvestigations: rawInvs,
      roleAssignments: rawRoles,
      mafiaVotes: rawMafiaVotes,
      doctorTarget: night['doctor_target']?.toString(),
      detectiveTarget: night['detective_target']?.toString(),
      bodyguardTarget: night['bodyguard_target']?.toString(),
      lastNightCasualty: json['last_night_casualty']?.toString(),
      lastVotedOut: json['last_voted_out']?.toString(),
      discussionDurationSeconds: (json['discussion_duration_seconds'] as num?)?.toInt() ?? 120,
      discussionEndTime: (json['discussion_end_time'] as num?)?.toDouble(),
      votingEndTime: (json['voting_end_time'] as num?)?.toDouble(),
      votes: rawVotes,
      votedPlayerIds: (json['voted_player_ids'] as List? ?? []).map((e) => e.toString()).toList(),
      allowSelfHeal: json['allow_self_heal'] == true,
      revealRoleOnDeath: json['reveal_role_on_death'] != false,
      includeJester: json['include_jester'] == true,
      includeBodyguard: json['include_bodyguard'] == true,
      winningFaction: json['winning_faction']?.toString(),
      winnerPlayerIds: (json['winner_player_ids'] as List? ?? []).map((e) => e.toString()).toList(),
      log: (json['log'] as List? ?? []).map((e) => e.toString()).toList(),
      lastAction: json['last_action']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'game_id': gameId,
        'phase': phase.toServerString(),
        'round_number': roundNumber,
        'player_ids': playerIds,
        'player_names': playerNames,
        'alive_status': aliveStatus,
        'acknowledged_players': acknowledgedPlayers,
        if (myRole != null) 'my_role': myRole,
        'mafia_teammates': mafiaTeammates,
        'my_investigations': myInvestigations.map((e) => e.toJson()).toList(),
        if (roleAssignments.isNotEmpty) 'role_assignments': roleAssignments,
        'night_actions': {
          'mafia_votes': mafiaVotes,
          'doctor_target': doctorTarget,
          'detective_target': detectiveTarget,
          'bodyguard_target': bodyguardTarget,
        },
        'last_night_casualty': lastNightCasualty,
        'last_voted_out': lastVotedOut,
        'discussion_duration_seconds': discussionDurationSeconds,
        'discussion_end_time': discussionEndTime,
        'voting_end_time': votingEndTime,
        'votes': votes,
        'voted_player_ids': votedPlayerIds,
        'allow_self_heal': allowSelfHeal,
        'reveal_role_on_death': revealRoleOnDeath,
        'include_jester': includeJester,
        'include_bodyguard': includeBodyguard,
        'winning_faction': winningFaction,
        'winner_player_ids': winnerPlayerIds,
        'log': log,
        'last_action': lastAction,
      };

  MafiaState copyWith({
    String? gameId,
    MafiaPhase? phase,
    int? roundNumber,
    List<String>? playerIds,
    Map<String, String>? playerNames,
    Map<String, bool>? aliveStatus,
    List<String>? acknowledgedPlayers,
    String? myRole,
    List<String>? mafiaTeammates,
    List<InvestigationResult>? myInvestigations,
    Map<String, String>? roleAssignments,
    Map<String, String>? mafiaVotes,
    String? doctorTarget,
    String? detectiveTarget,
    String? bodyguardTarget,
    String? lastNightCasualty,
    String? lastVotedOut,
    int? discussionDurationSeconds,
    double? discussionEndTime,
    double? votingEndTime,
    Map<String, String>? votes,
    List<String>? votedPlayerIds,
    bool? allowSelfHeal,
    bool? revealRoleOnDeath,
    bool? includeJester,
    bool? includeBodyguard,
    String? winningFaction,
    List<String>? winnerPlayerIds,
    List<String>? log,
    String? lastAction,
  }) {
    return MafiaState(
      gameId: gameId ?? this.gameId,
      phase: phase ?? this.phase,
      roundNumber: roundNumber ?? this.roundNumber,
      playerIds: playerIds ?? this.playerIds,
      playerNames: playerNames ?? this.playerNames,
      aliveStatus: aliveStatus ?? this.aliveStatus,
      acknowledgedPlayers: acknowledgedPlayers ?? this.acknowledgedPlayers,
      myRole: myRole ?? this.myRole,
      mafiaTeammates: mafiaTeammates ?? this.mafiaTeammates,
      myInvestigations: myInvestigations ?? this.myInvestigations,
      roleAssignments: roleAssignments ?? this.roleAssignments,
      mafiaVotes: mafiaVotes ?? this.mafiaVotes,
      doctorTarget: doctorTarget ?? this.doctorTarget,
      detectiveTarget: detectiveTarget ?? this.detectiveTarget,
      bodyguardTarget: bodyguardTarget ?? this.bodyguardTarget,
      lastNightCasualty: lastNightCasualty ?? this.lastNightCasualty,
      lastVotedOut: lastVotedOut ?? this.lastVotedOut,
      discussionDurationSeconds: discussionDurationSeconds ?? this.discussionDurationSeconds,
      discussionEndTime: discussionEndTime ?? this.discussionEndTime,
      votingEndTime: votingEndTime ?? this.votingEndTime,
      votes: votes ?? this.votes,
      votedPlayerIds: votedPlayerIds ?? this.votedPlayerIds,
      allowSelfHeal: allowSelfHeal ?? this.allowSelfHeal,
      revealRoleOnDeath: revealRoleOnDeath ?? this.revealRoleOnDeath,
      includeJester: includeJester ?? this.includeJester,
      includeBodyguard: includeBodyguard ?? this.includeBodyguard,
      winningFaction: winningFaction ?? this.winningFaction,
      winnerPlayerIds: winnerPlayerIds ?? this.winnerPlayerIds,
      log: log ?? this.log,
      lastAction: lastAction ?? this.lastAction,
    );
  }
}
