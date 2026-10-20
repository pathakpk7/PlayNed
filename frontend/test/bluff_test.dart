import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/bluff/models/bluff_models.dart';
import 'package:hangman_reimagined/games/bluff/services/bluff_engine.dart';
import 'package:hangman_reimagined/platform/registry/game_registry.dart';

void main() {
  group('Bluff / Cheat Game Tests', () {
    test('Game is registered in PlayNed registry with 3-6 players', () {
      final meta = PlayNedGameRegistry.getGame('bluff');
      expect(meta, isNotNull);
      expect(meta!.name, 'Bluff / Cheat');
      expect(meta.minPlayers, 3);
      expect(meta.maxPlayers, 6);
      expect(meta.supportsLocal, isTrue);
      expect(meta.supportsOnline, isTrue);
    });

    test('Standard 52-card deck is complete and rank progression wraps K to A', () {
      final deck = createFullDeck();
      expect(deck.length, 52);
      expect(deck.map((c) => c.rawCode).toSet().length, 52);

      expect(getNextSequentialRank('A'), '2');
      expect(getNextSequentialRank('2'), '3');
      expect(getNextSequentialRank('10'), 'J');
      expect(getNextSequentialRank('J'), 'Q');
      expect(getNextSequentialRank('Q'), 'K');
      expect(getNextSequentialRank('K'), 'A'); // Wraps
    });

    test('Fair card distribution across 3 to 6 players', () {
      // 3 players: 52 / 3 = 17 remainder 1
      final hands3 = BluffLocalEngine.dealDeck(['p1', 'p2', 'p3'], 42);
      expect(hands3.values.fold<int>(0, (sum, h) => sum + h.length), 52);
      final lengths3 = hands3.values.map((h) => h.length).toList()..sort();
      expect(lengths3, [17, 17, 18]);

      // 4 players: exactly 13 each
      final hands4 = BluffLocalEngine.dealDeck(['p1', 'p2', 'p3', 'p4'], 42);
      expect(hands4.values.every((h) => h.length == 13), isTrue);

      // 6 players: 52 / 6 = 8 remainder 4
      final hands6 = BluffLocalEngine.dealDeck(['p1', 'p2', 'p3', 'p4', 'p5', 'p6'], 42);
      expect(hands6.values.fold<int>(0, (sum, h) => sum + h.length), 52);
    });

    test('Truthful play followed by failed challenge: challenger collects pile', () {
      final engine = BluffLocalEngine();
      final pIds = ['p1', 'p2', 'p3'];
      final pNames = {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Charlie'};

      var state = engine.createInitialState(playerIds: pIds, playerNames: pNames, seed: 100);
      expect(state.phase, BluffPhase.play);
      expect(state.requiredRank, 'A');

      // Alice plays an Ace truthfully
      final aceCard = PlayingCard.fromString('A_S');
      state = BluffState(
        phase: state.phase,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        hands: {
          'p1': [aceCard, PlayingCard.fromString('5_H')],
          'p2': [PlayingCard.fromString('2_C'), PlayingCard.fromString('3_D')],
          'p3': [PlayingCard.fromString('7_S')],
        },
        cardCounts: {'p1': 2, 'p2': 2, 'p3': 1},
        pile: const [],
        pileCount: 0,
        currentPlayerIndex: 0,
        currentPlayerId: 'p1',
        requiredRank: 'A',
      );

      // Alice plays 1 Ace
      state = engine.applyMove(state, 'p1', {
        'action': 'play_cards',
        'cards': [aceCard],
      });

      expect(state.phase, BluffPhase.challenge);
      expect(state.pileCount, 1);
      expect(state.lastPlay!.declaredRank, 'A');

      // Bob challenges Alice
      state = engine.applyMove(state, 'p2', {
        'action': 'challenge',
      });

      expect(state.phase, BluffPhase.challengeReveal);
      final res = state.challengeResult!;
      expect(res.wasBluff, isFalse);
      expect(res.pileCollectorId, 'p2'); // Bob took the pile!
      expect(state.pileCount, 0);

      // Continue after challenge
      state = engine.applyMove(state, 'p1', {
        'action': 'continue_after_challenge',
      });
      expect(state.phase, BluffPhase.play);
      expect(state.requiredRank, '2'); // Advances to 2
    });

    test('Caught bluff: bluffer collects pile and challenger leads next', () {
      final engine = BluffLocalEngine();
      final pIds = ['p1', 'p2', 'p3'];
      final pNames = {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Charlie'};

      final kingCard = PlayingCard.fromString('K_S');
      var state = BluffState(
        phase: BluffPhase.play,
        playerIds: pIds,
        playerNames: pNames,
        hands: {
          'p1': [kingCard, PlayingCard.fromString('4_H')],
          'p2': [PlayingCard.fromString('2_C')],
          'p3': [PlayingCard.fromString('7_S')],
        },
        cardCounts: {'p1': 2, 'p2': 1, 'p3': 1},
        pile: [PlayingCard.fromString('9_D'), PlayingCard.fromString('10_C')],
        pileCount: 2,
        currentPlayerIndex: 0,
        currentPlayerId: 'p1',
        requiredRank: 'A', // Requires Ace, but Alice plays King
      );

      // Alice bluffs with King
      state = engine.applyMove(state, 'p1', {
        'action': 'play_cards',
        'cards': [kingCard],
      });
      expect(state.phase, BluffPhase.challenge);
      expect(state.pileCount, 3);

      // Charlie challenges Alice
      state = engine.applyMove(state, 'p3', {
        'action': 'challenge',
      });

      expect(state.phase, BluffPhase.challengeReveal);
      final res = state.challengeResult!;
      expect(res.wasBluff, isTrue);
      expect(res.pileCollectorId, 'p1'); // Alice caught, picks up pile
      expect(state.hands['p1']!.length, 1 + 3); // 1 remaining + 3 from pile = 4
      expect(state.pileCount, 0);

      // Charlie caught the bluff, so Charlie leads next
      state = engine.applyMove(state, 'p3', {
        'action': 'continue_after_challenge',
      });
      expect(state.phase, BluffPhase.play);
      expect(state.currentPlayerId, 'p3');
      expect(state.requiredRank, '2');
    });

    test('Unchallenged play with passing advances turn clockwise', () {
      final engine = BluffLocalEngine();
      final pIds = ['p1', 'p2', 'p3'];
      final pNames = {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Charlie'};

      var state = engine.createInitialState(playerIds: pIds, playerNames: pNames, seed: 123);
      final card = state.hands['p1']!.first;

      state = engine.applyMove(state, 'p1', {
        'action': 'play_cards',
        'cards': [card],
      });
      expect(state.phase, BluffPhase.challenge);

      // Opponents pass
      state = engine.applyMove(state, 'p2', {'action': 'pass'});
      expect(state.phase, BluffPhase.challenge);
      state = engine.applyMove(state, 'p3', {'action': 'pass'});

      // All passed -> Turn passes to p2, rank advances to 2
      expect(state.phase, BluffPhase.play);
      expect(state.currentPlayerId, 'p2');
      expect(state.requiredRank, '2');
    });

    test('Emptying hand and surviving challenge wins match', () {
      final engine = BluffLocalEngine();
      final pIds = ['p1', 'p2', 'p3'];
      final pNames = {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Charlie'};

      final aceCard = PlayingCard.fromString('A_D');
      var state = BluffState(
        phase: BluffPhase.play,
        playerIds: pIds,
        playerNames: pNames,
        hands: {
          'p1': [aceCard],
          'p2': [PlayingCard.fromString('2_C')],
          'p3': [PlayingCard.fromString('7_S')],
        },
        cardCounts: {'p1': 1, 'p2': 1, 'p3': 1},
        pile: const [],
        pileCount: 0,
        currentPlayerIndex: 0,
        currentPlayerId: 'p1',
        requiredRank: 'A',
      );

      // Alice plays her last card
      state = engine.applyMove(state, 'p1', {
        'action': 'play_cards',
        'cards': [aceCard],
      });
      expect(state.phase, BluffPhase.challenge);
      expect(state.hands['p1']!.isEmpty, isTrue);
      expect(state.winnerId, isNull); // Cannot win prematurely!

      // Bob challenges
      state = engine.applyMove(state, 'p2', {'action': 'challenge'});
      expect(state.phase, BluffPhase.challengeReveal);
      expect(state.challengeResult!.wasBluff, isFalse);

      // Alice survived!
      state = engine.applyMove(state, 'p1', {'action': 'continue_after_challenge'});
      expect(state.phase, BluffPhase.gameOver);
      expect(state.winnerId, 'p1');
      expect(state.winnerName, 'Alice');
    });

    test('JSON serialization round-trip maintains complete fidelity', () {
      final card = PlayingCard.fromString('K_H');
      expect(card.rank, 'K');
      expect(card.suit, CardSuit.hearts);
      expect(card.displayName, 'K♥');

      final lastPlay = BluffLastPlay(
        playerId: 'p1',
        playerName: 'Alice',
        declaredRank: 'A',
        cardCount: 2,
        actualCards: [PlayingCard.fromString('A_S'), PlayingCard.fromString('A_C')],
      );
      final json = lastPlay.toJson();
      final reconstructed = BluffLastPlay.fromJson(json);
      expect(reconstructed.playerName, 'Alice');
      expect(reconstructed.declaredRank, 'A');
      expect(reconstructed.actualCards!.length, 2);
    });
  });
}
