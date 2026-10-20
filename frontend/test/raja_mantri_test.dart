import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/raja_mantri_chor_sipahi/models/raja_mantri_models.dart';
import 'package:hangman_reimagined/games/raja_mantri_chor_sipahi/services/raja_mantri_engine.dart';
import 'package:hangman_reimagined/platform/registry/game_registry.dart';

void main() {
  group('Raja Mantri Chor Sipahi Metadata Tests', () {
    test('Game is registered in PlayNedGameRegistry with 4 players and party category', () {
      final meta = PlayNedGameRegistry.getGame('raja_mantri_chor_sipahi');
      expect(meta, isNotNull);
      expect(meta!.name, 'Raja Mantri Chor Sipahi');
      expect(meta.minPlayers, 4);
      expect(meta.maxPlayers, 4);
      expect(meta.category, 'Classic Indian Games / Party Games');
      expect(meta.supportsLocal, isTrue);
      expect(meta.supportsOnline, isTrue);
    });

    test('Exact Scoring Constants match rules specification strictly', () {
      // Must follow Section 2 exactly: Raja=1000, Mantri=0, Sipahi=500, Chor=800
      expect(RajaMantriRole.raja.points, 1000);
      expect(RajaMantriRole.mantri.points, 0);
      expect(RajaMantriRole.sipahi.points, 500);
      expect(RajaMantriRole.chor.points, 800);

      // Verify Mantri and Chor are not using conventional values
      expect(RajaMantriRole.mantri.points, isNot(800));
      expect(RajaMantriRole.chor.points, isNot(0));
    });
  });

  group('Chit Shuffling & Initialization Tests', () {
    test('Fairly assigns exactly one unique role to each of 4 players', () {
      final players = ['p1', 'p2', 'p3', 'p4'];
      final assignments = RajaMantriLocalEngine.shuffleChits(players, rng: Random(42));

      expect(assignments.length, 4);
      final assignedRoles = assignments.values.toSet();
      expect(assignedRoles.length, 4);
      expect(assignedRoles, containsAll(RajaMantriRole.values));
    });

    test('Rejects if player count is not exactly 4', () {
      expect(
        () => RajaMantriLocalEngine.shuffleChits(['p1', 'p2', 'p3']),
        throwsArgumentError,
      );
      expect(
        () => RajaMantriLocalEngine.shuffleChits(['p1', 'p2', 'p3', 'p4', 'p5']),
        throwsArgumentError,
      );
    });

    test('Initializes state in CHIT_REVEAL with zero cumulative scores', () {
      final state = RajaMantriLocalEngine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Charlie', 'p4': 'Dave'},
        totalRounds: 5,
        rng: Random(101),
      );

      expect(state.phase, RajaMantriPhase.chitReveal);
      expect(state.currentRound, 1);
      expect(state.totalRounds, 5);
      expect(state.revealedRoles.isEmpty, isTrue);
      expect(state.acknowledgedPlayers.isEmpty, isTrue);
      expect(state.rajaPlayerId, isNotNull);
      expect(state.mantriPlayerId, isNotNull);
      expect(state.sipahiPlayerId, isNotNull);
      expect(state.chorPlayerId, isNotNull);
      expect(state.eligibleSuspectIds.length, 2);
      expect(state.eligibleSuspectIds, contains(state.sipahiPlayerId));
      expect(state.eligibleSuspectIds, contains(state.chorPlayerId));

      for (final pid in ['p1', 'p2', 'p3', 'p4']) {
        expect(state.getPlayerScore(pid), 0);
      }
    });
  });

  group('Round Phase Progression & Guessing Tests', () {
    test('Full round progression with correct Chor guess', () {
      var state = RajaMantriLocalEngine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Charlie', 'p4': 'Dave'},
        totalRounds: 3,
        rng: Random(77),
      );

      final rajaPid = state.rajaPlayerId!;
      final mantriPid = state.mantriPlayerId!;
      final sipahiPid = state.sipahiPlayerId!;
      final chorPid = state.chorPlayerId!;

      // 1. Private Acknowledgements -> RAJA_REVEAL
      for (final p in ['p1', 'p2', 'p3', 'p4']) {
        state = RajaMantriLocalEngine.acknowledgeChit(state, p);
      }
      expect(state.phase, RajaMantriPhase.rajaReveal);
      expect(state.revealedRoles[rajaPid], RajaMantriRole.raja);

      // 2. Call Mantri -> MANTRI_REVEAL
      state = RajaMantriLocalEngine.callMantri(state);
      expect(state.phase, RajaMantriPhase.mantriReveal);
      expect(state.revealedRoles[mantriPid], RajaMantriRole.mantri);

      // 3. Step Forward -> CHOR_GUESS
      state = RajaMantriLocalEngine.stepForward(state);
      expect(state.phase, RajaMantriPhase.chorGuess);

      // 4. Submit Guess (Correct: picks chorPid)
      state = RajaMantriLocalEngine.submitGuess(state, chorPid);
      expect(state.phase, RajaMantriPhase.fullReveal);
      expect(state.guessCorrect, isTrue);
      expect(state.guessedChorPlayerId, chorPid);

      // 5. Verify Fixed Role Points Awarded
      expect(state.getPlayerRoundPoints(rajaPid), 1000);
      expect(state.getPlayerRoundPoints(mantriPid), 0);
      expect(state.getPlayerRoundPoints(sipahiPid), 500);
      expect(state.getPlayerRoundPoints(chorPid), 800);

      expect(state.getPlayerScore(rajaPid), 1000);
      expect(state.getPlayerScore(mantriPid), 0);
      expect(state.getPlayerScore(sipahiPid), 500);
      expect(state.getPlayerScore(chorPid), 800);
    });

    test('Incorrect Chor guess does not modify fixed role points', () {
      var state = RajaMantriLocalEngine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Charlie', 'p4': 'Dave'},
        rng: Random(88),
      );

      final rajaPid = state.rajaPlayerId!;
      final mantriPid = state.mantriPlayerId!;
      final sipahiPid = state.sipahiPlayerId!;
      final chorPid = state.chorPlayerId!;

      state = RajaMantriLocalEngine.acknowledgeChit(state, 'p1', forceAdvance: true);
      state = RajaMantriLocalEngine.callMantri(state);
      state = RajaMantriLocalEngine.stepForward(state);

      // Mantri wrongly guesses Sipahi as the Chor
      state = RajaMantriLocalEngine.submitGuess(state, sipahiPid);
      expect(state.phase, RajaMantriPhase.fullReveal);
      expect(state.guessCorrect, isFalse);
      expect(state.guessedChorPlayerId, sipahiPid);

      // Role points MUST remain fixed: Raja=1000, Mantri=0, Sipahi=500, Chor=800
      expect(state.getPlayerRoundPoints(rajaPid), 1000);
      expect(state.getPlayerRoundPoints(mantriPid), 0);
      expect(state.getPlayerRoundPoints(sipahiPid), 500);
      expect(state.getPlayerRoundPoints(chorPid), 800);
    });

    test('Mantri cannot guess themselves or the Raja', () {
      final state = RajaMantriLocalEngine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
      );

      final mantriPid = state.mantriPlayerId!;
      final rajaPid = state.rajaPlayerId!;

      var guessPhaseState = RajaMantriState(
        phase: RajaMantriPhase.chorGuess,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        roleAssignments: state.roleAssignments,
        rajaPlayerId: rajaPid,
        mantriPlayerId: mantriPid,
        sipahiPlayerId: state.sipahiPlayerId,
        chorPlayerId: state.chorPlayerId,
        eligibleSuspectIds: state.eligibleSuspectIds,
      );

      // Guessing oneself is ignored
      final selfGuess = RajaMantriLocalEngine.submitGuess(guessPhaseState, mantriPid);
      expect(selfGuess.phase, RajaMantriPhase.chorGuess);

      // Guessing Raja is ignored
      final rajaGuess = RajaMantriLocalEngine.submitGuess(guessPhaseState, rajaPid);
      expect(rajaGuess.phase, RajaMantriPhase.chorGuess);
    });
  });

  group('Multi-Round & Match Results Tests', () {
    test('Cumulative score tracking across multiple rounds and completion', () {
      var state = RajaMantriLocalEngine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
        totalRounds: 2,
        rng: Random(1),
      );

      // Play Round 1
      state = RajaMantriLocalEngine.acknowledgeChit(state, 'p1', forceAdvance: true);
      state = RajaMantriLocalEngine.callMantri(state);
      state = RajaMantriLocalEngine.stepForward(state);
      state = RajaMantriLocalEngine.submitGuess(state, state.eligibleSuspectIds.first);
      expect(state.phase, RajaMantriPhase.fullReveal);
      final r1Scores = Map<String, int>.from(state.cumulativeScores);

      // Advance to Round 2
      state = RajaMantriLocalEngine.nextRound(state, rng: Random(2));
      expect(state.phase, RajaMantriPhase.chitReveal);
      expect(state.currentRound, 2);

      // Play Round 2
      state = RajaMantriLocalEngine.acknowledgeChit(state, 'p1', forceAdvance: true);
      state = RajaMantriLocalEngine.callMantri(state);
      state = RajaMantriLocalEngine.stepForward(state);
      state = RajaMantriLocalEngine.submitGuess(state, state.eligibleSuspectIds.first);
      expect(state.phase, RajaMantriPhase.fullReveal);

      for (final pid in ['p1', 'p2', 'p3', 'p4']) {
        expect(state.cumulativeScores[pid], greaterThanOrEqualTo(r1Scores[pid]!));
      }

      // Finish match
      state = RajaMantriLocalEngine.nextRound(state);
      expect(state.phase, RajaMantriPhase.matchResults);
      expect(state.isGameOver, isTrue);
      expect(state.winnerPlayerIds.isNotEmpty, isTrue);
    });

    test('Handles tie cleanly without arbitrary winner selection', () {
      final state = RajaMantriState(
        phase: RajaMantriPhase.fullReveal,
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
        currentRound: 2,
        totalRounds: 2,
        cumulativeScores: {'p1': 1500, 'p2': 1500, 'p3': 800, 'p4': 500},
      );

      final endState = RajaMantriLocalEngine.nextRound(state);
      expect(endState.phase, RajaMantriPhase.matchResults);
      expect(endState.isTie, isTrue);
      expect(endState.winnerPlayerIds, containsAll(['p1', 'p2']));
      expect(endState.winnerPlayerIds.length, 2);
    });
  });

  group('State JSON Serialization Tests', () {
    test('State cleanly serializes and deserializes', () {
      final state = RajaMantriState(
        phase: RajaMantriPhase.chorGuess,
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Charlie', 'p4': 'Dave'},
        currentRound: 3,
        totalRounds: 5,
        roleAssignments: {
          'p1': RajaMantriRole.raja,
          'p2': RajaMantriRole.mantri,
          'p3': RajaMantriRole.sipahi,
          'p4': RajaMantriRole.chor,
        },
        revealedRoles: {
          'p1': RajaMantriRole.raja,
          'p2': RajaMantriRole.mantri,
        },
        rajaPlayerId: 'p1',
        mantriPlayerId: 'p2',
        sipahiPlayerId: 'p3',
        chorPlayerId: 'p4',
        eligibleSuspectIds: ['p3', 'p4'],
        cumulativeScores: {'p1': 2000, 'p2': 0, 'p3': 1000, 'p4': 1600},
      );

      final json = state.toJson();
      final revived = RajaMantriState.fromJson(json);

      expect(revived.gameId, 'raja_mantri_chor_sipahi');
      expect(revived.phase, RajaMantriPhase.chorGuess);
      expect(revived.currentRound, 3);
      expect(revived.totalRounds, 5);
      expect(revived.rajaPlayerId, 'p1');
      expect(revived.mantriPlayerId, 'p2');
      expect(revived.revealedRoles['p1'], RajaMantriRole.raja);
      expect(revived.revealedRoles['p2'], RajaMantriRole.mantri);
      expect(revived.cumulativeScores['p1'], 2000);
      expect(revived.cumulativeScores['p4'], 1600);
    });
  });
}
