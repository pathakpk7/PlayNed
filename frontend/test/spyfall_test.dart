import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/spyfall/models/spyfall_models.dart';
import 'package:hangman_reimagined/games/spyfall/services/spyfall_engine.dart';

void main() {
  group('Spyfall Engine & Gameplay Unit Tests', () {
    late SpyfallLocalEngine engine;

    setUp(() {
      engine = SpyfallLocalEngine();
    });

    test('Rejects player counts outside 3 to 8 range', () {
      expect(
        () => engine.createInitialState(
          playerIds: ['p1', 'p2'],
          playerNames: {'p1': 'Agent 1', 'p2': 'Agent 2'},
        ),
        throwsArgumentError,
      );

      final ninePlayers = List.generate(9, (i) => 'p${i + 1}');
      expect(
        () => engine.createInitialState(
          playerIds: ninePlayers,
          playerNames: {for (var id in ninePlayers) id: id},
        ),
        throwsArgumentError,
      );
    });

    test('Initializes 4-player game with exactly 1 spy and valid location', () {
      final state = engine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {
          'p1': 'Alice',
          'p2': 'Bob',
          'p3': 'Charlie',
          'p4': 'Dave',
        },
        roundDurationMinutes: 8,
        totalRounds: 3,
      );

      expect(state.phase, SpyfallPhase.roleReveal);
      expect(state.playerIds.length, 4);
      expect(state.secretLocation, isNotNull);
      expect(state.secretLocation!.name.isNotEmpty, isTrue);
      expect(state.spyPlayerId, isNotNull);
      expect(state.playerIds.contains(state.spyPlayerId), isTrue);

      // Verify role assignments
      final spyCount = state.roleAssignments.values.where((r) => r == 'spy').length;
      final explorerCount = state.roleAssignments.values.where((r) => r == 'explorer').length;
      expect(spyCount, 1);
      expect(explorerCount, 3);
    });

    test('Authoritative privacy filtering hides location and spy identity from spy', () {
      final state = engine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
      );

      final spyId = state.spyPlayerId!;
      final nonSpyId = state.playerIds.firstWhere((id) => id != spyId);

      // Filtered for SPY:
      final spyFiltered = engine.filterStateForPlayer(state, spyId);
      expect(spyFiltered.myRole, 'spy');
      expect(spyFiltered.myLocation, isNull);
      expect(spyFiltered.secretLocation, isNull);
      expect(spyFiltered.spyPlayerId, isNull);

      // Filtered for NON-SPY:
      final nonSpyFiltered = engine.filterStateForPlayer(state, nonSpyId);
      expect(nonSpyFiltered.myRole, 'explorer');
      expect(nonSpyFiltered.myLocation, state.secretLocation!.name);
      expect(nonSpyFiltered.spyPlayerId, isNull);
    });

    test('Role acknowledgement advances to DISCUSSION phase', () {
      var state = engine.createInitialState(
        playerIds: ['p1', 'p2', 'p3'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3'},
        roundDurationMinutes: 8,
      );

      expect(state.phase, SpyfallPhase.roleReveal);

      state = engine.applyMove(state, 'p1', {'action': 'acknowledge_role'});
      state = engine.applyMove(state, 'p2', {'action': 'acknowledge_role'});
      state = engine.applyMove(state, 'p3', {'action': 'acknowledge_role'});

      expect(state.phase, SpyfallPhase.discussion);
      expect(state.isTimerPaused, isFalse);
      expect(state.remainingSeconds, 8 * 60);
    });

    test('Accusation requires strict majority (>50%) to convict', () {
      var state = engine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
      );

      // Advance to discussion
      for (var pid in state.playerIds) {
        state = engine.applyMove(state, pid, {'action': 'acknowledge_role'});
      }

      final spyId = state.spyPlayerId!;
      final nonSpy1 = state.playerIds.firstWhere((id) => id != spyId);

      // nonSpy1 accuses spyId
      state = engine.applyMove(state, nonSpy1, {
        'action': 'accuse',
        'accused_id': spyId,
      });

      expect(state.phase, SpyfallPhase.accusationVoting);
      expect(state.isTimerPaused, isTrue);
      expect(state.activeAccusedId, spyId);

      // 3 eligible voters: all non-spies.
      final voters = state.playerIds.where((id) => id != spyId).toList();

      // Case 1: Acquittal test (1 guilty, 2 innocent) -> strict majority fails
      var acquittalState = engine.applyMove(state, voters[0], {'action': 'vote', 'choice': 'guilty'});
      acquittalState = engine.applyMove(acquittalState, voters[1], {'action': 'vote', 'choice': 'innocent'});
      acquittalState = engine.applyMove(acquittalState, voters[2], {'action': 'vote', 'choice': 'innocent'});

      expect(acquittalState.phase, SpyfallPhase.discussion);
      expect(acquittalState.activeAccusedId, isNull);
      expect(acquittalState.isTimerPaused, isFalse);

      // Case 2: Conviction test (2 guilty out of 3 = 66.7% > 50%) -> Conviction!
      var convictionState = engine.applyMove(state, voters[0], {'action': 'vote', 'choice': 'guilty'});
      convictionState = engine.applyMove(convictionState, voters[1], {'action': 'vote', 'choice': 'guilty'});
      convictionState = engine.applyMove(convictionState, voters[2], {'action': 'vote', 'choice': 'innocent'});

      // Accused was spy -> spy gets location guess
      expect(convictionState.phase, SpyfallPhase.spyGuess);
    });

    test('Convicting an innocent player immediately gives victory to Spy', () {
      var state = engine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
      );

      for (var pid in state.playerIds) {
        state = engine.applyMove(state, pid, {'action': 'acknowledge_role'});
      }

      final spyId = state.spyPlayerId!;
      final innocentId = state.playerIds.firstWhere((id) => id != spyId);
      final accuserId = state.playerIds.firstWhere((id) => id != spyId && id != innocentId);

      state = engine.applyMove(state, accuserId, {
        'action': 'accuse',
        'accused_id': innocentId,
      });

      // All eligible voters vote guilty
      final voters = state.playerIds.where((id) => id != innocentId).toList();
      for (var v in voters) {
        state = engine.applyMove(state, v, {'action': 'vote', 'choice': 'guilty'});
      }

      expect(state.phase, SpyfallPhase.roundResolution);
      expect(state.lastOutcome, 'INNOCENT_CONVICTED');
      // Spy gets +2 points
      expect(state.scores[spyId], 2);
      expect(state.scores[innocentId], 0);
    });

    test('Spy location guess: correct guess awards +3 points to Spy', () {
      var state = engine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
      );

      for (var pid in state.playerIds) {
        state = engine.applyMove(state, pid, {'action': 'acknowledge_role'});
      }

      final spyId = state.spyPlayerId!;
      final trueLocationName = state.secretLocation!.name;

      // Spy calls guess
      state = engine.applyMove(state, spyId, {
        'action': 'spy_guess',
        'location': trueLocationName,
      });

      expect(state.phase, SpyfallPhase.roundResolution);
      expect(state.lastOutcome, 'SPY_GUESSED_LOCATION');
      expect(state.scores[spyId], 3);
      for (var id in state.playerIds) {
        if (id != spyId) {
          expect(state.scores[id], 0);
        }
      }
    });

    test('Spy location guess: incorrect guess awards +2 points to non-spies', () {
      var state = engine.createInitialState(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerNames: {'p1': 'P1', 'p2': 'P2', 'p3': 'P3', 'p4': 'P4'},
      );

      for (var pid in state.playerIds) {
        state = engine.applyMove(state, pid, {'action': 'acknowledge_role'});
      }

      final spyId = state.spyPlayerId!;

      // Spy calls wrong guess
      state = engine.applyMove(state, spyId, {
        'action': 'spy_guess',
        'location': 'Completely Imaginary Place Never on the Map',
      });

      expect(state.phase, SpyfallPhase.roundResolution);
      expect(state.lastOutcome, 'SPY_GUESS_FAILED');
      expect(state.scores[spyId], 0);
      for (var id in state.playerIds) {
        if (id != spyId) {
          expect(state.scores[id], 2);
        }
      }
    });
  });
}
