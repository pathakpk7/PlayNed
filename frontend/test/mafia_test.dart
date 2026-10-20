import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/mafia/models/mafia_models.dart';
import 'package:hangman_reimagined/games/mafia/services/mafia_engine.dart';

void main() {
  group('Mafia Engine & Gameplay Unit Tests', () {
    late MafiaLocalEngine engine;

    setUp(() {
      engine = MafiaLocalEngine();
    });

    test('Rejects player counts outside 5 to 12 range', () {
      expect(
        () => engine.createInitialState(
          playerIds: ['p1', 'p2', 'p3', 'p4'],
          playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
        ),
        throwsArgumentError,
      );

      final thirteenPlayers = List.generate(13, (i) => 'p${i + 1}');
      expect(
        () => engine.createInitialState(
          playerIds: thirteenPlayers,
          playerNames: {for (var id in thirteenPlayers) id: id},
        ),
        throwsArgumentError,
      );
    });

    test('Initializes 5-player game with standard distribution (1 Mafia, 1 Doctor, 1 Detective, 2 Villagers)', () {
      final pIds = ['p1', 'p2', 'p3', 'p4', 'p5'];
      final state = engine.createInitialState(
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: id},
      );

      expect(state.phase, MafiaPhase.roleReveal);
      expect(state.playerIds.length, 5);

      final roles = state.roleAssignments.values.toList();
      expect(roles.where((r) => r == 'mafia').length, 1);
      expect(roles.where((r) => r == 'doctor').length, 1);
      expect(roles.where((r) => r == 'detective').length, 1);
      expect(roles.where((r) => r == 'villager').length, 2);
    });

    test('Scales Mafia counts up to 2 for 6-9 players and 3 for 10-12 players', () {
      final eightIds = List.generate(8, (i) => 'p${i + 1}');
      final state8 = engine.createInitialState(
        playerIds: eightIds,
        playerNames: {for (var id in eightIds) id: id},
      );
      final roles8 = state8.roleAssignments.values.toList();
      expect(roles8.where((r) => r == 'mafia').length, 2);

      final elevenIds = List.generate(11, (i) => 'p${i + 1}');
      final state11 = engine.createInitialState(
        playerIds: elevenIds,
        playerNames: {for (var id in elevenIds) id: id},
      );
      final roles11 = state11.roleAssignments.values.toList();
      expect(roles11.where((r) => r == 'mafia').length, 3);
    });

    test('Privacy filtering masks role assignments and protects Mafia teammate secrecy', () {
      final pIds = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'];
      final state = engine.createInitialState(
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: id},
      );

      final mafiaIds = pIds.where((id) => state.roleAssignments[id] == 'mafia').toList();
      final townIds = pIds.where((id) => state.roleAssignments[id] != 'mafia').toList();

      expect(mafiaIds.length, 2);
      expect(townIds.isNotEmpty, isTrue);

      // Filtered for Townsperson
      final townFiltered = engine.filterStateForPlayer(state, townIds.first);
      expect(townFiltered.roleAssignments.isEmpty, isTrue);
      expect(townFiltered.mafiaTeammates.isEmpty, isTrue);
      expect(townFiltered.myRole, state.roleAssignments[townIds.first]);

      // Filtered for Mafia member
      final mafiaFiltered = engine.filterStateForPlayer(state, mafiaIds.first);
      expect(mafiaFiltered.roleAssignments.isEmpty, isTrue);
      expect(mafiaFiltered.mafiaTeammates.length, 2);
      expect(mafiaFiltered.mafiaTeammates.contains(mafiaIds[0]), isTrue);
      expect(mafiaFiltered.mafiaTeammates.contains(mafiaIds[1]), isTrue);
    });

    test('Night actions: Unprotected Mafia target is eliminated', () {
      final pIds = ['p1', 'p2', 'p3', 'p4', 'p5'];
      var state = MafiaState(
        phase: MafiaPhase.nightActions,
        roundNumber: 1,
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: id},
        aliveStatus: {for (var id in pIds) id: true},
        roleAssignments: {
          'p1': 'mafia',
          'p2': 'doctor',
          'p3': 'detective',
          'p4': 'villager',
          'p5': 'villager',
        },
      );

      // Mafia targets p4, Doctor heals p3, Detective investigates p1
      state = engine.submitNightAction(state, actorId: 'p1', targetId: 'p4');
      state = engine.submitNightAction(state, actorId: 'p2', targetId: 'p3');
      state = engine.submitNightAction(state, actorId: 'p3', targetId: 'p1');

      state = engine.resolveNight(state);

      expect(state.phase, MafiaPhase.dayAnnouncement);
      expect(state.lastNightCasualty, 'p4');
      expect(state.isAlive('p4'), isFalse);
      expect(state.isAlive('p3'), isTrue);
    });

    test('Doctor protection shields Mafia target from night elimination', () {
      final pIds = ['p1', 'p2', 'p3', 'p4', 'p5'];
      var state = MafiaState(
        phase: MafiaPhase.nightActions,
        roundNumber: 1,
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: id},
        aliveStatus: {for (var id in pIds) id: true},
        roleAssignments: {
          'p1': 'mafia',
          'p2': 'doctor',
          'p3': 'detective',
          'p4': 'villager',
          'p5': 'villager',
        },
      );

      // Mafia targets p4, Doctor correctly protects p4!
      state = engine.submitNightAction(state, actorId: 'p1', targetId: 'p4');
      state = engine.submitNightAction(state, actorId: 'p2', targetId: 'p4');

      state = engine.resolveNight(state);

      expect(state.phase, MafiaPhase.dayAnnouncement);
      expect(state.lastNightCasualty, isNull);
      expect(state.isAlive('p4'), isTrue);
    });

    test('Detective investigation logs correct verdict', () {
      final pIds = ['p1', 'p2', 'p3', 'p4', 'p5'];
      var state = MafiaState(
        phase: MafiaPhase.nightActions,
        roundNumber: 1,
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: 'Citizen $id'},
        aliveStatus: {for (var id in pIds) id: true},
        roleAssignments: {
          'p1': 'mafia',
          'p2': 'doctor',
          'p3': 'detective',
          'p4': 'villager',
          'p5': 'villager',
        },
      );

      state = engine.submitNightAction(state, actorId: 'p3', targetId: 'p1');
      state = engine.resolveNight(state);

      expect(state.myInvestigations.length, 1);
      final inv = state.myInvestigations.first;
      expect(inv.targetId, 'p1');
      expect(inv.isMafia, isTrue);
    });

    test('Voting eliminates highest voted player', () {
      final pIds = ['p1', 'p2', 'p3', 'p4', 'p5'];
      var state = MafiaState(
        phase: MafiaPhase.dayVoting,
        roundNumber: 1,
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: id},
        aliveStatus: {for (var id in pIds) id: true},
        roleAssignments: {
          'p1': 'mafia',
          'p2': 'doctor',
          'p3': 'detective',
          'p4': 'villager',
          'p5': 'villager',
        },
      );

      state = engine.castVote(state, voterId: 'p2', targetId: 'p1');
      state = engine.castVote(state, voterId: 'p3', targetId: 'p1');
      state = engine.castVote(state, voterId: 'p4', targetId: 'p1');
      state = engine.castVote(state, voterId: 'p1', targetId: 'p2');
      state = engine.castVote(state, voterId: 'p5', targetId: 'p2');

      expect(state.lastVotedOut, 'p1');
      expect(state.isAlive('p1'), isFalse);
      expect(state.phase, MafiaPhase.matchResults);
      // Because p1 was the sole mafia, town should win!
      expect(state.isGameOver, isTrue);
      expect(state.winningFaction, 'town');
    });

    test('Vote tie results in no elimination', () {
      final pIds = ['p1', 'p2', 'p3', 'p4'];
      var state = MafiaState(
        phase: MafiaPhase.dayVoting,
        roundNumber: 1,
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: id},
        aliveStatus: {for (var id in pIds) id: true},
        roleAssignments: {
          'p1': 'mafia',
          'p2': 'doctor',
          'p3': 'detective',
          'p4': 'villager',
        },
      );

      // p1 and p2 tie with 2 votes each
      state = engine.castVote(state, voterId: 'p1', targetId: 'p2');
      state = engine.castVote(state, voterId: 'p3', targetId: 'p2');
      state = engine.castVote(state, voterId: 'p2', targetId: 'p1');
      state = engine.castVote(state, voterId: 'p4', targetId: 'p1');

      state = engine.resolveVoting(state);

      expect(state.lastVotedOut, isNull);
      expect(state.isAlive('p1'), isTrue);
      expect(state.isAlive('p2'), isTrue);
      expect(state.isGameOver, isFalse);
    });

    test('Jester wins immediately if eliminated by public vote', () {
      final pIds = ['p1', 'p2', 'p3', 'p4', 'p5'];
      var state = MafiaState(
        phase: MafiaPhase.dayVoting,
        roundNumber: 1,
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: id},
        aliveStatus: {for (var id in pIds) id: true},
        includeJester: true,
        roleAssignments: {
          'p1': 'mafia',
          'p2': 'doctor',
          'p3': 'detective',
          'p4': 'villager',
          'p5': 'jester',
        },
      );

      // Everyone votes p5 (Jester)
      for (final voter in ['p1', 'p2', 'p3', 'p4']) {
        state = engine.castVote(state, voterId: voter, targetId: 'p5');
      }

      state = engine.resolveVoting(state);

      expect(state.lastVotedOut, 'p5');
      expect(state.isGameOver, isTrue);
      expect(state.winningFaction, 'jester');
      expect(state.winnerPlayerIds, ['p5']);
    });

    test('Mafia wins when living mafia count equals living town count', () {
      final pIds = ['p1', 'p2', 'p3', 'p4'];
      final state = MafiaState(
        phase: MafiaPhase.dayDiscussion,
        roundNumber: 2,
        playerIds: pIds,
        playerNames: {for (var id in pIds) id: id},
        aliveStatus: {
          'p1': true,  // mafia
          'p2': true,  // mafia
          'p3': true,  // doctor
          'p4': false, // villager dead
        },
        roleAssignments: {
          'p1': 'mafia',
          'p2': 'mafia',
          'p3': 'doctor',
          'p4': 'villager',
        },
      );

      final winner = engine.checkWinCondition(state);
      expect(winner, isNotNull);
      expect(winner!.winningFaction, 'mafia');
      expect(winner.winnerPlayerIds.toSet(), {'p1', 'p2'});
    });
  });
}
