import 'dart:math';
import '../models/spyfall_models.dart';

const List<SpyfallLocation> kSpyfallDefaultLocations = [
  // Public Places
  SpyfallLocation(id: 'airport', name: 'Airport', category: 'Public Places', description: 'Busy terminal with gates and luggage.'),
  SpyfallLocation(id: 'train_station', name: 'Train Station', category: 'Public Places', description: 'Platform tracks, tickets, commuters.'),
  SpyfallLocation(id: 'bus_station', name: 'Bus Station', category: 'Public Places', description: 'City transit depot with coach lines.'),
  SpyfallLocation(id: 'shopping_mall', name: 'Shopping Mall', category: 'Public Places', description: 'Multi-level stores and food court.'),
  SpyfallLocation(id: 'supermarket', name: 'Supermarket', category: 'Public Places', description: 'Grocery aisles, carts, and scanners.'),
  SpyfallLocation(id: 'restaurant', name: 'Restaurant', category: 'Public Places', description: 'Fine dining, menus, and waitstaff.'),
  SpyfallLocation(id: 'hotel', name: 'Hotel', category: 'Public Places', description: 'Concierge, lobby, and room keys.'),
  SpyfallLocation(id: 'hospital', name: 'Hospital', category: 'Public Places', description: 'Doctors, nurses, and emergency ward.'),
  SpyfallLocation(id: 'university', name: 'University', category: 'Public Places', description: 'Lecture halls and campus quad.'),
  SpyfallLocation(id: 'library', name: 'Library', category: 'Public Places', description: 'Quiet shelves, books, and study desks.'),
  SpyfallLocation(id: 'museum', name: 'Museum', category: 'Public Places', description: 'Art, relics, and velvet ropes.'),
  SpyfallLocation(id: 'cinema', name: 'Cinema', category: 'Public Places', description: 'Movie screens, popcorn, and dark seats.'),
  SpyfallLocation(id: 'amusement_park', name: 'Amusement Park', category: 'Public Places', description: 'Roller coasters and carnival games.'),
  SpyfallLocation(id: 'zoo', name: 'Zoo', category: 'Public Places', description: 'Animal enclosures and safari paths.'),
  SpyfallLocation(id: 'aquarium', name: 'Aquarium', category: 'Public Places', description: 'Glass underwater tunnels and sharks.'),

  // Transport & Travel
  SpyfallLocation(id: 'airplane', name: 'Airplane', category: 'Transport & Travel', description: 'In-flight passenger cabin at 30,000 ft.'),
  SpyfallLocation(id: 'cruise_ship', name: 'Cruise Ship', category: 'Transport & Travel', description: 'Ocean liner with sun deck and bridge.'),
  SpyfallLocation(id: 'subway', name: 'Subway', category: 'Transport & Travel', description: 'Underground rail car with handrails.'),
  SpyfallLocation(id: 'taxi', name: 'Taxi', category: 'Transport & Travel', description: 'City cab with clicking taximeter.'),
  SpyfallLocation(id: 'space_station', name: 'Space Station', category: 'Transport & Travel', description: 'Zero-gravity orbital laboratory.'),
  SpyfallLocation(id: 'railway_platform', name: 'Railway Platform', category: 'Transport & Travel', description: 'Outdoor boarding tracks and benches.'),
  SpyfallLocation(id: 'ferry', name: 'Ferry', category: 'Transport & Travel', description: 'Car and passenger boat crossing water.'),
  SpyfallLocation(id: 'highway_rest_stop', name: 'Highway Rest Stop', category: 'Transport & Travel', description: 'Interstate travel plaza and pumps.'),
  SpyfallLocation(id: 'mountain_cable_car', name: 'Mountain Cable Car', category: 'Transport & Travel', description: 'Suspended gondola over snowy slopes.'),
  SpyfallLocation(id: 'camping_ground', name: 'Camping Ground', category: 'Transport & Travel', description: 'Tents, campfire, and pine forest.'),

  // Professional Environments
  SpyfallLocation(id: 'police_station', name: 'Police Station', category: 'Professional Environments', description: 'Badges, cells, and detective desks.'),
  SpyfallLocation(id: 'fire_station', name: 'Fire Station', category: 'Professional Environments', description: 'Poles, fire trucks, and heavy hoses.'),
  SpyfallLocation(id: 'courtroom', name: 'Courtroom', category: 'Professional Environments', description: 'Gavel, judge bench, and jury box.'),
  SpyfallLocation(id: 'bank', name: 'Bank', category: 'Professional Environments', description: 'Vault, tellers, and security guards.'),
  SpyfallLocation(id: 'office', name: 'Office', category: 'Professional Environments', description: 'Cubicles, water cooler, and computers.'),
  SpyfallLocation(id: 'construction_site', name: 'Construction Site', category: 'Professional Environments', description: 'Hard hats, cranes, and scaffolding.'),
  SpyfallLocation(id: 'factory', name: 'Factory', category: 'Professional Environments', description: 'Assembly line and conveyor belts.'),
  SpyfallLocation(id: 'newsroom', name: 'Newsroom', category: 'Professional Environments', description: 'Typewriters, headlines, deadline clock.'),
  SpyfallLocation(id: 'television_studio', name: 'Television Studio', category: 'Professional Environments', description: 'Cameras, green screen, on-air sign.'),
  SpyfallLocation(id: 'research_laboratory', name: 'Research Laboratory', category: 'Professional Environments', description: 'Petri dishes, microscopes, and lab coats.'),
  SpyfallLocation(id: 'embassy', name: 'Embassy', category: 'Professional Environments', description: 'Diplomats, visas, and foreign flags.'),
  SpyfallLocation(id: 'military_base', name: 'Military Base', category: 'Professional Environments', description: 'Barracks, camo, and guard towers.'),
  SpyfallLocation(id: 'secret_agent_hq', name: 'Secret Agent Headquarters', category: 'Professional Environments', description: 'Surveillance screens and classified dossiers.'),

  // Leisure & Entertainment
  SpyfallLocation(id: 'beach', name: 'Beach', category: 'Leisure & Entertainment', description: 'Sand dunes, surfboards, and ocean waves.'),
  SpyfallLocation(id: 'ski_resort', name: 'Ski Resort', category: 'Leisure & Entertainment', description: 'Powdery slopes, chairlifts, and lodge.'),
  SpyfallLocation(id: 'football_stadium', name: 'Football Stadium', category: 'Leisure & Entertainment', description: 'Floodlights, pitch, and cheering fans.'),
  SpyfallLocation(id: 'cricket_stadium', name: 'Cricket Stadium', category: 'Leisure & Entertainment', description: 'Wickets, boundary rope, and pavilion.'),
  SpyfallLocation(id: 'gym', name: 'Gym', category: 'Leisure & Entertainment', description: 'Barbells, treadmills, and lockers.'),
  SpyfallLocation(id: 'swimming_pool', name: 'Swimming Pool', category: 'Leisure & Entertainment', description: 'Lanes, diving board, and chlorine.'),
  SpyfallLocation(id: 'concert_venue', name: 'Concert Venue', category: 'Leisure & Entertainment', description: 'Amplifiers, stage lights, and live band.'),
  SpyfallLocation(id: 'casino', name: 'Casino', category: 'Leisure & Entertainment', description: 'Roulette, poker chips, and slot machines.'),
  SpyfallLocation(id: 'nightclub', name: 'Nightclub', category: 'Leisure & Entertainment', description: 'DJ booth, strobes, and crowded floor.'),
  SpyfallLocation(id: 'theme_park', name: 'Theme Park', category: 'Leisure & Entertainment', description: 'Mascots, themed lands, and parades.'),
  SpyfallLocation(id: 'bowling_alley', name: 'Bowling Alley', category: 'Leisure & Entertainment', description: 'Pins, bowling balls, and rental shoes.'),

  // Everyday & Unusual
  SpyfallLocation(id: 'school', name: 'School', category: 'Everyday & Unusual', description: 'Desks, blackboards, and recess bell.'),
  SpyfallLocation(id: 'wedding_venue', name: 'Wedding Venue', category: 'Everyday & Unusual', description: 'Floral arch, wedding cake, and vows.'),
  SpyfallLocation(id: 'prison', name: 'Prison', category: 'Everyday & Unusual', description: 'Iron bars, warden, and exercise yard.'),
  SpyfallLocation(id: 'farm', name: 'Farm', category: 'Everyday & Unusual', description: 'Red barn, tractor, and livestock.'),
  SpyfallLocation(id: 'fishing_boat', name: 'Fishing Boat', category: 'Everyday & Unusual', description: 'Trawler nets and salty deck.'),
  SpyfallLocation(id: 'lighthouse', name: 'Lighthouse', category: 'Everyday & Unusual', description: 'Revolving beacon and spiral stairs.'),
  SpyfallLocation(id: 'castle', name: 'Castle', category: 'Everyday & Unusual', description: 'Drawbridge, stone moat, and suits of armor.'),
  SpyfallLocation(id: 'desert', name: 'Desert', category: 'Everyday & Unusual', description: 'Sand dunes, camels, and mirage.'),
  SpyfallLocation(id: 'rainforest', name: 'Rainforest', category: 'Everyday & Unusual', description: 'Dense tropical canopy and rainfall.'),
  SpyfallLocation(id: 'arctic_research_station', name: 'Arctic Research Station', category: 'Everyday & Unusual', description: 'Snowmobiles, ice cores, and blizzards.'),
  SpyfallLocation(id: 'underwater_facility', name: 'Underwater Research Facility', category: 'Everyday & Unusual', description: 'Observation dome and diving airlocks.'),
  SpyfallLocation(id: 'ancient_temple', name: 'Ancient Temple', category: 'Everyday & Unusual', description: 'Mossy pillars, stone carvings, and torches.'),
  SpyfallLocation(id: 'space_observatory', name: 'Space Observatory', category: 'Everyday & Unusual', description: 'Telescope dome pointing at stars.'),
  SpyfallLocation(id: 'royal_palace', name: 'Royal Palace', category: 'Everyday & Unusual', description: 'Gold throne, red carpet, and royal guards.'),
  SpyfallLocation(id: 'film_set', name: 'Film Set', category: 'Everyday & Unusual', description: 'Clapperboard, boom mic, and director chair.'),
];

class SpyfallLocalEngine {
  static SpyfallLocation pickRandomLocation([int? seed]) {
    final rng = seed != null ? Random(seed) : Random();
    return kSpyfallDefaultLocations[rng.nextInt(kSpyfallDefaultLocations.length)];
  }

  static String pickRandomSpy(List<String> playerIds, [int? seed]) {
    final rng = seed != null ? Random(seed) : Random();
    return playerIds[rng.nextInt(playerIds.length)];
  }

  SpyfallState createInitialState({
    required List<String> playerIds,
    required Map<String, String> playerNames,
    int? seed,
    int totalRounds = 3,
    int roundDurationMinutes = 5,
    String category = 'All',
    bool allowSpyGuess = true,
  }) {
    if (playerIds.length < 3 || playerIds.length > 8) {
      throw ArgumentError('Spyfall requires between 3 and 8 players.');
    }

    final spyId = pickRandomSpy(playerIds, seed);
    final location = pickRandomLocation(seed != null ? seed + 1 : null);
    final roles = {for (var pid in playerIds) pid: pid == spyId ? 'spy' : 'explorer'};
    final durationSeconds = roundDurationMinutes * 60;

    return SpyfallState(
      phase: SpyfallPhase.roleReveal,
      playerIds: List.from(playerIds),
      playerNames: Map.from(playerNames),
      currentRound: 1,
      totalRounds: totalRounds,
      roundDurationMinutes: roundDurationMinutes,
      category: category,
      allowSpyGuess: allowSpyGuess,
      spyPlayerId: spyId,
      secretLocation: location,
      roleAssignments: roles,
      discussionDurationSeconds: durationSeconds,
      remainingDiscussionSeconds: durationSeconds,
      roundPoints: {for (var pid in playerIds) pid: 0},
      cumulativeScores: {for (var pid in playerIds) pid: 0},
      roundHistory: ['Round 1 began! Secret roles and location assigned.'],
      lastAction: 'Round 1 started! View your secret role card privately.',
    );
  }

  SpyfallState filterStateForPlayer(SpyfallState state, String playerId) {
    final isSpy = state.spyPlayerId == playerId;
    final isOver = state.phase == SpyfallPhase.roundResolution || state.phase == SpyfallPhase.matchResults;

    if (!isOver) {
      return SpyfallState(
        gameId: state.gameId,
        phase: state.phase,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        currentRound: state.currentRound,
        totalRounds: state.totalRounds,
        roundDurationMinutes: state.roundDurationMinutes,
        category: state.category,
        allowSpyGuess: state.allowSpyGuess,
        myRole: isSpy ? 'spy' : 'explorer',
        myLocation: isSpy ? null : state.secretLocation?.name,
        myLocationCategory: isSpy ? null : state.secretLocation?.category,
        spyPlayerId: null,
        secretLocation: null,
        roleAssignments: const {},
        acknowledgedPlayers: state.acknowledgedPlayers,
        discussionDurationSeconds: state.discussionDurationSeconds,
        remainingDiscussionSeconds: state.remainingDiscussionSeconds,
        discussionEndTime: state.discussionEndTime,
        votingEndTime: state.votingEndTime,
        accuserPlayerId: state.accuserPlayerId,
        accusedTargetId: state.accusedTargetId,
        votes: state.votes,
        votedPlayerIds: state.votedPlayerIds,
        spyGuessesRemaining: state.spyGuessesRemaining,
        roundOutcome: state.roundOutcome,
        outcomeReason: state.outcomeReason,
        roundPoints: state.roundPoints,
        cumulativeScores: state.cumulativeScores,
        winnerPlayerIds: state.winnerPlayerIds,
        roundHistory: state.roundHistory,
        lastAction: state.lastAction,
      );
    } else {
      return SpyfallState(
        gameId: state.gameId,
        phase: state.phase,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        currentRound: state.currentRound,
        totalRounds: state.totalRounds,
        roundDurationMinutes: state.roundDurationMinutes,
        category: state.category,
        allowSpyGuess: state.allowSpyGuess,
        myRole: isSpy ? 'spy' : 'explorer',
        myLocation: state.secretLocation?.name,
        myLocationCategory: state.secretLocation?.category,
        spyPlayerId: state.spyPlayerId,
        secretLocation: state.secretLocation,
        roleAssignments: state.roleAssignments,
        acknowledgedPlayers: state.acknowledgedPlayers,
        discussionDurationSeconds: state.discussionDurationSeconds,
        remainingDiscussionSeconds: state.remainingDiscussionSeconds,
        discussionEndTime: state.discussionEndTime,
        votingEndTime: state.votingEndTime,
        accuserPlayerId: state.accuserPlayerId,
        accusedTargetId: state.accusedTargetId,
        votes: state.votes,
        votedPlayerIds: state.votedPlayerIds,
        spyGuessesRemaining: state.spyGuessesRemaining,
        roundOutcome: state.roundOutcome,
        outcomeReason: state.outcomeReason,
        roundPoints: state.roundPoints,
        cumulativeScores: state.cumulativeScores,
        winnerPlayerIds: state.winnerPlayerIds,
        roundHistory: state.roundHistory,
        lastAction: state.lastAction,
      );
    }
  }

  bool validateMove(SpyfallState state, String playerId, Map<String, dynamic> move) {
    final action = move['action'];
    if (!state.playerIds.contains(playerId)) return false;

    if (action == 'acknowledge_role') {
      return state.phase == SpyfallPhase.roleReveal;
    } else if (action == 'accuse' || action == 'accuse_player') {
      if (state.phase != SpyfallPhase.discussion) return false;
      final target = move['accused_id'] ?? move['target_player_id'];
      if (target == null || !state.playerIds.contains(target) || target == playerId) {
        return false;
      }
      return true;
    } else if (action == 'vote' || action == 'cast_vote') {
      if (state.phase != SpyfallPhase.accusationVoting) return false;
      final v = move['choice'] ?? move['vote'];
      return v == 'guilty' || v == 'innocent';
    } else if (action == 'spy_guess' || action == 'spy_guess_location') {
      if (state.phase != SpyfallPhase.discussion &&
          state.phase != SpyfallPhase.spyGuess &&
          state.phase != SpyfallPhase.accusationVoting) {
        return false;
      }
      if (playerId != state.spyPlayerId) return false;
      if (state.spyGuessesRemaining <= 0) return false;
      final guess = (move['location'] ?? move['guessed_location'])?.toString().trim();
      return guess != null && guess.isNotEmpty;
    } else if (action == 'time_expired' || action == 'timer_expired') {
      return state.phase == SpyfallPhase.discussion || state.phase == SpyfallPhase.accusationVoting;
    } else if (action == 'next_round') {
      return state.phase == SpyfallPhase.roundResolution;
    } else if (action == 'rematch') {
      return state.phase == SpyfallPhase.matchResults || state.phase == SpyfallPhase.roundResolution;
    }
    return false;
  }

  SpyfallState applyMove(SpyfallState state, String playerId, Map<String, dynamic> move) {
    if (!validateMove(state, playerId, move)) {
      throw ArgumentError('Illegal move: $move for player $playerId');
    }

    final action = move['action'];
    final history = List<String>.from(state.roundHistory);

    if (action == 'acknowledge_role') {
      final ack = List<String>.from(state.acknowledgedPlayers);
      if (!ack.contains(playerId)) ack.add(playerId);

      if (ack.length >= state.playerIds.length || move['force_advance'] == true) {
        final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
        final duration = state.discussionDurationSeconds;
        final msg = 'Discussion begins! Ask tactical questions to locate the Spy (${state.roundDurationMinutes} min timer).';
        history.add(msg);

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.discussion,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: ack,
          discussionDurationSeconds: duration,
          remainingDiscussionSeconds: duration,
          discussionEndTime: now + duration,
          votingEndTime: null,
          accuserPlayerId: null,
          accusedTargetId: null,
          votes: const {},
          votedPlayerIds: const [],
          spyGuessesRemaining: state.spyGuessesRemaining,
          roundOutcome: null,
          outcomeReason: null,
          roundPoints: state.roundPoints,
          cumulativeScores: state.cumulativeScores,
          winnerPlayerIds: state.winnerPlayerIds,
          roundHistory: history,
          lastAction: msg,
        );
      } else {
        return SpyfallState(
          gameId: state.gameId,
          phase: state.phase,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: ack,
          discussionDurationSeconds: state.discussionDurationSeconds,
          remainingDiscussionSeconds: state.remainingDiscussionSeconds,
          discussionEndTime: state.discussionEndTime,
          votingEndTime: state.votingEndTime,
          accuserPlayerId: state.accuserPlayerId,
          accusedTargetId: state.accusedTargetId,
          votes: state.votes,
          votedPlayerIds: state.votedPlayerIds,
          spyGuessesRemaining: state.spyGuessesRemaining,
          roundOutcome: state.roundOutcome,
          outcomeReason: state.outcomeReason,
          roundPoints: state.roundPoints,
          cumulativeScores: state.cumulativeScores,
          winnerPlayerIds: state.winnerPlayerIds,
          roundHistory: history,
          lastAction: '${state.getPlayerName(playerId)} viewed their secret card.',
        );
      }
    } else if (action == 'accuse' || action == 'accuse_player') {
      final targetId = (move['accused_id'] ?? move['target_player_id']) as String;
      final accuserName = state.getPlayerName(playerId);
      final targetName = state.getPlayerName(targetId);

      final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final end = state.discussionEndTime ?? (now + 60);
      final remaining = max(0, (end - now).toInt());

      final msg = '$accuserName formally accused $targetName of being the SPY! Cast your votes.';
      history.add(msg);

      return SpyfallState(
        gameId: state.gameId,
        phase: SpyfallPhase.accusationVoting,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        currentRound: state.currentRound,
        totalRounds: state.totalRounds,
        roundDurationMinutes: state.roundDurationMinutes,
        category: state.category,
        allowSpyGuess: state.allowSpyGuess,
        myRole: state.myRole,
        myLocation: state.myLocation,
        myLocationCategory: state.myLocationCategory,
        spyPlayerId: state.spyPlayerId,
        secretLocation: state.secretLocation,
        roleAssignments: state.roleAssignments,
        acknowledgedPlayers: state.acknowledgedPlayers,
        discussionDurationSeconds: state.discussionDurationSeconds,
        remainingDiscussionSeconds: remaining,
        discussionEndTime: state.discussionEndTime,
        votingEndTime: now + 45.0,
        accuserPlayerId: playerId,
        accusedTargetId: targetId,
        votes: {playerId: 'guilty'},
        votedPlayerIds: [playerId],
        spyGuessesRemaining: state.spyGuessesRemaining,
        roundOutcome: null,
        outcomeReason: null,
        roundPoints: state.roundPoints,
        cumulativeScores: state.cumulativeScores,
        winnerPlayerIds: state.winnerPlayerIds,
        roundHistory: history,
        lastAction: msg,
      );
    } else if (action == 'vote' || action == 'cast_vote') {
      final votes = Map<String, String>.from(state.votes);
      final choice = (move['choice'] ?? move['vote']) as String;
      votes[playerId] = choice;
      final votedPids = List<String>.from(state.votedPlayerIds);
      if (!votedPids.contains(playerId)) votedPids.add(playerId);

      final eligibleVotersCount = state.playerIds.where((pid) => pid != state.accusedTargetId).length;
      final shouldResolve = move['force_resolve'] == true || votes.length >= eligibleVotersCount;

      final updatedState = SpyfallState(
        gameId: state.gameId,
        phase: state.phase,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        currentRound: state.currentRound,
        totalRounds: state.totalRounds,
        roundDurationMinutes: state.roundDurationMinutes,
        category: state.category,
        allowSpyGuess: state.allowSpyGuess,
        myRole: state.myRole,
        myLocation: state.myLocation,
        myLocationCategory: state.myLocationCategory,
        spyPlayerId: state.spyPlayerId,
        secretLocation: state.secretLocation,
        roleAssignments: state.roleAssignments,
        acknowledgedPlayers: state.acknowledgedPlayers,
        discussionDurationSeconds: state.discussionDurationSeconds,
        remainingDiscussionSeconds: state.remainingDiscussionSeconds,
        discussionEndTime: state.discussionEndTime,
        votingEndTime: state.votingEndTime,
        accuserPlayerId: state.accuserPlayerId,
        accusedTargetId: state.accusedTargetId,
        votes: votes,
        votedPlayerIds: votedPids,
        spyGuessesRemaining: state.spyGuessesRemaining,
        roundOutcome: state.roundOutcome,
        outcomeReason: state.outcomeReason,
        roundPoints: state.roundPoints,
        cumulativeScores: state.cumulativeScores,
        winnerPlayerIds: state.winnerPlayerIds,
        roundHistory: history,
        lastAction: '${state.getPlayerName(playerId)} cast their vote.',
      );

      if (shouldResolve) {
        return _resolveVotes(updatedState);
      }
      return updatedState;
    } else if (action == 'spy_guess' || action == 'spy_guess_location') {
      final guess = (move['location'] ?? move['guessed_location']).toString().trim();
      final actualLoc = state.secretLocation?.name ?? '';
      final isCorrect = guess.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
          actualLoc.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      final spyName = state.getPlayerName(state.spyPlayerId!);

      if (isCorrect) {
        final msg = 'SPY WINS! $spyName correctly guessed the secret location: \'$actualLoc\'!';
        history.add(msg);
        final rPts = <String, int>{for (var pid in state.playerIds) pid: pid == state.spyPlayerId ? 3 : 0};
        final cum = Map<String, int>.from(state.cumulativeScores);
        for (var e in rPts.entries) {
          cum[e.key] = (cum[e.key] ?? 0) + e.value;
        }

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.roundResolution,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: state.acknowledgedPlayers,
          discussionDurationSeconds: state.discussionDurationSeconds,
          remainingDiscussionSeconds: state.remainingDiscussionSeconds,
          discussionEndTime: state.discussionEndTime,
          votingEndTime: null,
          accuserPlayerId: state.accuserPlayerId,
          accusedTargetId: state.accusedTargetId,
          votes: state.votes,
          votedPlayerIds: state.votedPlayerIds,
          spyGuessesRemaining: 0,
          spyGuessedLocation: guess,
          spyGuessCorrect: true,
          roundOutcome: 'SPY_GUESSED_LOCATION',
          outcomeReason: msg,
          roundPoints: rPts,
          cumulativeScores: cum,
          winnerPlayerIds: state.winnerPlayerIds,
          roundHistory: history,
          lastAction: msg,
        );
      } else {
        final msg = '$spyName guessed \'$guess\', which is INCORRECT!';
        history.add(msg);

        final winMsg = 'NON-SPIES WIN! $spyName failed the location guess (Location was \'$actualLoc\').';
        history.add(winMsg);

        final rPts = <String, int>{
          for (var pid in state.playerIds)
            pid: pid == state.spyPlayerId ? 0 : 2
        };
        final cum = Map<String, int>.from(state.cumulativeScores);
        for (var e in rPts.entries) {
          cum[e.key] = (cum[e.key] ?? 0) + e.value;
        }

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.roundResolution,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: state.acknowledgedPlayers,
          discussionDurationSeconds: state.discussionDurationSeconds,
          remainingDiscussionSeconds: state.remainingDiscussionSeconds,
          discussionEndTime: state.discussionEndTime,
          votingEndTime: null,
          accuserPlayerId: state.accuserPlayerId,
          accusedTargetId: state.accusedTargetId,
          votes: state.votes,
          votedPlayerIds: state.votedPlayerIds,
          spyGuessesRemaining: 0,
          spyGuessedLocation: guess,
          spyGuessCorrect: false,
          roundOutcome: 'SPY_GUESS_FAILED',
          outcomeReason: winMsg,
          roundPoints: rPts,
          cumulativeScores: cum,
          winnerPlayerIds: state.winnerPlayerIds,
          roundHistory: history,
          lastAction: winMsg,
        );
      }
    } else if (action == 'time_expired' || action == 'timer_expired') {
      if (state.phase == SpyfallPhase.accusationVoting) {
        return _resolveVotes(state);
      } else {
        final spyName = state.getPlayerName(state.spyPlayerId!);
        final locName = state.secretLocation?.name ?? 'Unknown';
        final msg = 'TIME EXPIRED! $spyName survived undetected! (Location was \'$locName\').';
        history.add(msg);

        final rPts = <String, int>{
          for (var pid in state.playerIds) pid: pid == state.spyPlayerId ? 2 : 1
        };
        final cum = Map<String, int>.from(state.cumulativeScores);
        for (var e in rPts.entries) {
          cum[e.key] = (cum[e.key] ?? 0) + e.value;
        }

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.roundResolution,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: state.acknowledgedPlayers,
          discussionDurationSeconds: state.discussionDurationSeconds,
          remainingDiscussionSeconds: 0,
          discussionEndTime: null,
          votingEndTime: null,
          accuserPlayerId: state.accuserPlayerId,
          accusedTargetId: state.accusedTargetId,
          votes: state.votes,
          votedPlayerIds: state.votedPlayerIds,
          spyGuessesRemaining: state.spyGuessesRemaining,
          roundOutcome: 'SPY_SURVIVED_TIME',
          outcomeReason: msg,
          roundPoints: rPts,
          cumulativeScores: cum,
          winnerPlayerIds: state.winnerPlayerIds,
          roundHistory: history,
          lastAction: msg,
        );
      }
    } else if (action == 'next_round') {
      if (state.currentRound >= state.totalRounds) {
        final cum = state.cumulativeScores;
        final maxPts = cum.isNotEmpty ? cum.values.reduce(max) : 0;
        final winners = cum.entries.where((e) => e.value == maxPts).map((e) => e.key).toList();
        final winnerNames = winners.map((w) => state.getPlayerName(w)).join(', ');
        final endMsg = 'Match finished! Winner(s): $winnerNames ($maxPts pts)!';
        history.add(endMsg);

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.matchResults,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: state.acknowledgedPlayers,
          discussionDurationSeconds: state.discussionDurationSeconds,
          remainingDiscussionSeconds: 0,
          discussionEndTime: null,
          votingEndTime: null,
          accuserPlayerId: null,
          accusedTargetId: null,
          votes: const {},
          votedPlayerIds: const [],
          spyGuessesRemaining: 0,
          roundOutcome: state.roundOutcome,
          outcomeReason: state.outcomeReason,
          roundPoints: state.roundPoints,
          cumulativeScores: state.cumulativeScores,
          winnerPlayerIds: winners,
          roundHistory: history,
          lastAction: endMsg,
        );
      } else {
        final nextRound = state.currentRound + 1;
        final newSpyId = pickRandomSpy(state.playerIds);
        final newLoc = pickRandomLocation();
        final newRoles = {for (var pid in state.playerIds) pid: pid == newSpyId ? 'spy' : 'explorer'};
        final duration = state.discussionDurationSeconds;
        final msg = 'Round $nextRound began! Secret roles and location assigned.';
        history.add(msg);

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.roleReveal,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: nextRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: null,
          myLocation: null,
          myLocationCategory: null,
          spyPlayerId: newSpyId,
          secretLocation: newLoc,
          roleAssignments: newRoles,
          acknowledgedPlayers: const [],
          discussionDurationSeconds: duration,
          remainingDiscussionSeconds: duration,
          discussionEndTime: null,
          votingEndTime: null,
          accuserPlayerId: null,
          accusedTargetId: null,
          votes: const {},
          votedPlayerIds: const [],
          spyGuessesRemaining: state.allowSpyGuess ? 1 : 0,
          roundOutcome: null,
          outcomeReason: null,
          roundPoints: {for (var pid in state.playerIds) pid: 0},
          cumulativeScores: state.cumulativeScores,
          winnerPlayerIds: const [],
          roundHistory: history,
          lastAction: msg,
        );
      }
    } else if (action == 'rematch') {
      return createInitialState(
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        totalRounds: state.totalRounds,
        roundDurationMinutes: state.roundDurationMinutes,
        allowSpyGuess: state.allowSpyGuess,
      );
    }

    return state;
  }

  SpyfallState _resolveVotes(SpyfallState state) {
    final votes = state.votes;
    final targetId = state.accusedTargetId!;
    final targetName = state.getPlayerName(targetId);
    final spyId = state.spyPlayerId!;
    final spyName = state.getPlayerName(spyId);
    final locName = state.secretLocation?.name ?? 'Unknown';
    final history = List<String>.from(state.roundHistory);

    final guiltyCount = votes.values.where((v) => v == 'guilty').length;
    final eligibleVoters = state.playerIds.where((id) => id != targetId).length;
    final strictMajority = (eligibleVoters ~/ 2) + 1;

    if (guiltyCount >= strictMajority) {
      final tallyMsg = 'VOTE PASSED ($guiltyCount/${votes.length} votes)! $targetName was CONVICTED!';
      history.add(tallyMsg);

      if (targetId == spyId) {
        if (state.allowSpyGuess && state.spyGuessesRemaining > 0) {
          final guessPrompt = '$spyName was caught! The Spy has 1 final chance to guess the location.';
          history.add(guessPrompt);

          return SpyfallState(
            gameId: state.gameId,
            phase: SpyfallPhase.spyGuess,
            playerIds: state.playerIds,
            playerNames: state.playerNames,
            currentRound: state.currentRound,
            totalRounds: state.totalRounds,
            roundDurationMinutes: state.roundDurationMinutes,
            category: state.category,
            allowSpyGuess: state.allowSpyGuess,
            myRole: state.myRole,
            myLocation: state.myLocation,
            myLocationCategory: state.myLocationCategory,
            spyPlayerId: state.spyPlayerId,
            secretLocation: state.secretLocation,
            roleAssignments: state.roleAssignments,
            acknowledgedPlayers: state.acknowledgedPlayers,
            discussionDurationSeconds: state.discussionDurationSeconds,
            remainingDiscussionSeconds: state.remainingDiscussionSeconds,
            discussionEndTime: null,
            votingEndTime: null,
            accuserPlayerId: state.accuserPlayerId,
            accusedTargetId: state.accusedTargetId,
            votes: state.votes,
            votedPlayerIds: state.votedPlayerIds,
            spyGuessesRemaining: state.spyGuessesRemaining,
            roundOutcome: null,
            outcomeReason: null,
            roundPoints: state.roundPoints,
            cumulativeScores: state.cumulativeScores,
            winnerPlayerIds: state.winnerPlayerIds,
            roundHistory: history,
            lastAction: guessPrompt,
          );
        } else {
          final winMsg = 'NON-SPIES WIN! $spyName was caught! (Location was \'$locName\').';
          history.add(winMsg);

          final rPts = <String, int>{
            for (var pid in state.playerIds)
              pid: pid == spyId ? 0 : 2
          };
          final cum = Map<String, int>.from(state.cumulativeScores);
          for (var e in rPts.entries) {
            cum[e.key] = (cum[e.key] ?? 0) + e.value;
          }

          return SpyfallState(
            gameId: state.gameId,
            phase: SpyfallPhase.roundResolution,
            playerIds: state.playerIds,
            playerNames: state.playerNames,
            currentRound: state.currentRound,
            totalRounds: state.totalRounds,
            roundDurationMinutes: state.roundDurationMinutes,
            category: state.category,
            allowSpyGuess: state.allowSpyGuess,
            myRole: state.myRole,
            myLocation: state.myLocation,
            myLocationCategory: state.myLocationCategory,
            spyPlayerId: state.spyPlayerId,
            secretLocation: state.secretLocation,
            roleAssignments: state.roleAssignments,
            acknowledgedPlayers: state.acknowledgedPlayers,
            discussionDurationSeconds: state.discussionDurationSeconds,
            remainingDiscussionSeconds: state.remainingDiscussionSeconds,
            discussionEndTime: null,
            votingEndTime: null,
            accuserPlayerId: state.accuserPlayerId,
            accusedTargetId: state.accusedTargetId,
            votes: state.votes,
            votedPlayerIds: state.votedPlayerIds,
            spyGuessesRemaining: 0,
            roundOutcome: 'SPY_CONVICTED',
            outcomeReason: winMsg,
            roundPoints: rPts,
            cumulativeScores: cum,
            winnerPlayerIds: state.winnerPlayerIds,
            roundHistory: history,
            lastAction: winMsg,
          );
        }
      } else {
        // Innocent convicted -> Spy wins!
        final msg = 'SPY WINS! $targetName was innocent! The true Spy was $spyName (Location was \'$locName\').';
        history.add(msg);

        final rPts = <String, int>{for (var pid in state.playerIds) pid: pid == spyId ? 2 : 0};
        final cum = Map<String, int>.from(state.cumulativeScores);
        for (var e in rPts.entries) {
          cum[e.key] = (cum[e.key] ?? 0) + e.value;
        }

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.roundResolution,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: state.acknowledgedPlayers,
          discussionDurationSeconds: state.discussionDurationSeconds,
          remainingDiscussionSeconds: state.remainingDiscussionSeconds,
          discussionEndTime: null,
          votingEndTime: null,
          accuserPlayerId: state.accuserPlayerId,
          accusedTargetId: state.accusedTargetId,
          votes: state.votes,
          votedPlayerIds: state.votedPlayerIds,
          spyGuessesRemaining: 0,
          roundOutcome: 'INNOCENT_CONVICTED',
          outcomeReason: msg,
          roundPoints: rPts,
          cumulativeScores: cum,
          winnerPlayerIds: state.winnerPlayerIds,
          roundHistory: history,
          lastAction: msg,
        );
      }
    } else {
      // Failed vote
      final tallyMsg = 'VOTE FAILED ($guiltyCount/${votes.length} guilty). $targetName was NOT convicted.';
      history.add(tallyMsg);

      final rem = state.remainingDiscussionSeconds;
      if (rem > 0) {
        final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
        final resumeMsg = 'Accusation dismissed. Discussion resumes (${rem}s remaining).';
        history.add(resumeMsg);

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.discussion,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: state.acknowledgedPlayers,
          discussionDurationSeconds: state.discussionDurationSeconds,
          remainingDiscussionSeconds: rem,
          discussionEndTime: now + rem,
          votingEndTime: null,
          accuserPlayerId: null,
          accusedTargetId: null,
          votes: const {},
          votedPlayerIds: const [],
          spyGuessesRemaining: state.spyGuessesRemaining,
          roundOutcome: null,
          outcomeReason: null,
          roundPoints: state.roundPoints,
          cumulativeScores: state.cumulativeScores,
          winnerPlayerIds: state.winnerPlayerIds,
          roundHistory: history,
          lastAction: resumeMsg,
        );
      } else {
        final msg = 'TIME EXPIRED! $spyName survived undetected! (Location was \'$locName\').';
        history.add(msg);
        final rPts = <String, int>{for (var pid in state.playerIds) pid: pid == spyId ? 2 : 1};
        final cum = Map<String, int>.from(state.cumulativeScores);
        for (var e in rPts.entries) {
          cum[e.key] = (cum[e.key] ?? 0) + e.value;
        }

        return SpyfallState(
          gameId: state.gameId,
          phase: SpyfallPhase.roundResolution,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          currentRound: state.currentRound,
          totalRounds: state.totalRounds,
          roundDurationMinutes: state.roundDurationMinutes,
          category: state.category,
          allowSpyGuess: state.allowSpyGuess,
          myRole: state.myRole,
          myLocation: state.myLocation,
          myLocationCategory: state.myLocationCategory,
          spyPlayerId: state.spyPlayerId,
          secretLocation: state.secretLocation,
          roleAssignments: state.roleAssignments,
          acknowledgedPlayers: state.acknowledgedPlayers,
          discussionDurationSeconds: state.discussionDurationSeconds,
          remainingDiscussionSeconds: 0,
          discussionEndTime: null,
          votingEndTime: null,
          accuserPlayerId: state.accuserPlayerId,
          accusedTargetId: state.accusedTargetId,
          votes: state.votes,
          votedPlayerIds: state.votedPlayerIds,
          spyGuessesRemaining: state.spyGuessesRemaining,
          roundOutcome: 'SPY_SURVIVED_TIME',
          outcomeReason: msg,
          roundPoints: rPts,
          cumulativeScores: cum,
          winnerPlayerIds: state.winnerPlayerIds,
          roundHistory: history,
          lastAction: msg,
        );
      }
    }
  }
}
