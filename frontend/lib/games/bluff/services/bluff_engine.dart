import 'dart:math';
import '../models/bluff_models.dart';

const List<String> kBluffRanks = [
  'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'
];
const List<String> kBluffSuits = ['S', 'H', 'D', 'C'];

String getNextSequentialRank(String currentRank) {
  final idx = kBluffRanks.indexOf(currentRank);
  if (idx < 0) return 'A';
  return kBluffRanks[(idx + 1) % kBluffRanks.length];
}

List<PlayingCard> createFullDeck() {
  final deck = <PlayingCard>[];
  for (final r in kBluffRanks) {
    for (final s in kBluffSuits) {
      deck.add(PlayingCard.fromString('${r}_$s'));
    }
  }
  return deck;
}

List<PlayingCard> sortCards(List<PlayingCard> cards) {
  final sorted = List<PlayingCard>.from(cards);
  sorted.sort((a, b) {
    final rankCmp = a.rankIndex.compareTo(b.rankIndex);
    if (rankCmp != 0) return rankCmp;
    return a.suit.index.compareTo(b.suit.index);
  });
  return sorted;
}

class BluffLocalEngine {
  static Map<String, List<PlayingCard>> dealDeck(List<String> playerIds, [int? seed]) {
    final deck = createFullDeck();
    final random = seed != null ? Random(seed) : Random();
    deck.shuffle(random);

    final hands = <String, List<PlayingCard>>{for (var pid in playerIds) pid: []};
    for (var i = 0; i < deck.length; i++) {
      final pid = playerIds[i % playerIds.length];
      hands[pid]!.add(deck[i]);
    }

    for (var pid in playerIds) {
      hands[pid] = sortCards(hands[pid]!);
    }
    return hands;
  }

  BluffState createInitialState({
    required List<String> playerIds,
    required Map<String, String> playerNames,
    int? seed,
  }) {
    if (playerIds.length < 3 || playerIds.length > 6) {
      throw ArgumentError('Bluff requires between 3 and 6 players.');
    }

    final hands = dealDeck(playerIds, seed);
    final cardCounts = {for (var pid in playerIds) pid: hands[pid]!.length};
    final startRank = 'A';
    final starterId = playerIds[0];
    final starterName = playerNames[starterId] ?? 'Player 1';

    return BluffState(
      phase: BluffPhase.play,
      playerIds: List.from(playerIds),
      playerNames: Map.from(playerNames),
      hands: hands,
      cardCounts: cardCounts,
      pile: const [],
      pileCount: 0,
      currentPlayerIndex: 0,
      currentPlayerId: starterId,
      requiredRank: startRank,
      lastPlay: null,
      passes: const [],
      challengeResult: null,
      winnerId: null,
      winnerName: null,
      roundHistory: ['Game started! $starterName must play ${startRank}s.'],
      lastAction: 'Match began! $starterName\'s turn to play ${startRank}s.',
    );
  }

  bool validateMove(BluffState state, String playerId, Map<String, dynamic> move) {
    final action = move['action'];
    if (!state.playerIds.contains(playerId)) return false;

    if (action == 'play_cards') {
      if (state.phase != BluffPhase.play) return false;
      if (state.currentPlayerId != playerId) return false;
      final cards = move['cards'] as List?;
      if (cards == null || cards.isEmpty) return false;
      final playerHand = state.hands[playerId] ?? [];
      final handCodes = playerHand.map((c) => c.rawCode).toList();
      for (final c in cards) {
        final code = c is PlayingCard ? c.rawCode : c.toString();
        if (!handCodes.remove(code)) return false;
      }
      return true;
    } else if (action == 'challenge') {
      if (state.phase != BluffPhase.challenge) return false;
      final lastPlay = state.lastPlay;
      if (lastPlay == null) return false;
      if (lastPlay.playerId == playerId) return false;
      return true;
    } else if (action == 'pass') {
      if (state.phase != BluffPhase.challenge) return false;
      final lastPlay = state.lastPlay;
      if (lastPlay == null) return false;
      if (lastPlay.playerId == playerId) return false;
      return true;
    } else if (action == 'continue_after_challenge') {
      return state.phase == BluffPhase.challengeReveal;
    } else if (action == 'rematch') {
      return state.phase == BluffPhase.gameOver;
    }
    return false;
  }

  BluffState applyMove(BluffState state, String playerId, Map<String, dynamic> move) {
    if (!validateMove(state, playerId, move)) {
      throw ArgumentError('Illegal move: $move for player $playerId');
    }

    final action = move['action'];
    final hands = <String, List<PlayingCard>>{};
    for (final e in state.hands.entries) {
      hands[e.key] = List.from(e.value);
    }
    final pile = List<PlayingCard>.from(state.pile);
    final history = List<String>.from(state.roundHistory);

    if (action == 'play_cards') {
      final rawCards = move['cards'] as List;
      final playedCards = rawCards.map((c) {
        return c is PlayingCard ? c : PlayingCard.fromString(c.toString());
      }).toList();

      final currentHand = hands[playerId]!;
      for (final pc in playedCards) {
        currentHand.removeWhere((c) => c.rawCode == pc.rawCode);
      }
      hands[playerId] = sortCards(currentHand);
      pile.addAll(playedCards);

      final cardCounts = Map<String, int>.from(state.cardCounts);
      cardCounts[playerId] = currentHand.length;

      final pName = state.getPlayerName(playerId);
      final count = playedCards.length;
      final s = count > 1 ? 's' : '';
      final actionText = currentHand.isEmpty
          ? '$pName played $count card$s claiming ${state.requiredRank}$s (HAND EMPTY! Awaiting challenge).'
          : '$pName played $count card$s claiming ${state.requiredRank}$s.';
      history.add(actionText);

      return BluffState(
        gameId: state.gameId,
        phase: BluffPhase.challenge,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        hands: hands,
        cardCounts: cardCounts,
        pile: pile,
        pileCount: pile.length,
        currentPlayerIndex: state.currentPlayerIndex,
        currentPlayerId: state.currentPlayerId,
        requiredRank: state.requiredRank,
        lastPlay: BluffLastPlay(
          playerId: playerId,
          playerName: pName,
          declaredRank: state.requiredRank,
          cardCount: count,
          actualCards: playedCards,
        ),
        passes: const [],
        challengeResult: null,
        winnerId: null,
        winnerName: null,
        roundHistory: history,
        lastAction: actionText,
      );
    } else if (action == 'challenge') {
      final lastPlay = state.lastPlay!;
      final blufferId = lastPlay.playerId;
      final blufferName = state.getPlayerName(blufferId);
      final challengerName = state.getPlayerName(playerId);
      final actualCards = lastPlay.actualCards ?? [];
      final declaredRank = lastPlay.declaredRank;

      final wasBluff = actualCards.any((c) => c.rank != declaredRank);
      final pileCount = pile.length;

      String pileCollectorId;
      String pileCollectorName;
      String nextLeaderId;
      String msg;

      if (wasBluff) {
        pileCollectorId = blufferId;
        pileCollectorName = blufferName;
        nextLeaderId = playerId;
        msg = 'BLUFF CAUGHT! $challengerName challenged $blufferName. '
            'Cards were ${actualCards.map((c) => c.displayName).join(", ")}. '
            '$blufferName picks up all $pileCount cards!';
      } else {
        pileCollectorId = playerId;
        pileCollectorName = challengerName;
        nextLeaderId = blufferId;
        msg = 'TRUTHFUL! $challengerName challenged $blufferName, but cards were ${actualCards.map((c) => c.displayName).join(", ")}. '
            '$challengerName picks up all $pileCount cards!';
      }

      hands[pileCollectorId]!.addAll(pile);
      hands[pileCollectorId] = sortCards(hands[pileCollectorId]!);
      pile.clear();

      final cardCounts = <String, int>{for (var pid in state.playerIds) pid: hands[pid]!.length};
      history.add(msg);

      final challengeRes = BluffChallengeResult(
        challengerId: playerId,
        challengerName: challengerName,
        blufferId: blufferId,
        blufferName: blufferName,
        declaredRank: declaredRank,
        revealedCards: actualCards,
        wasBluff: wasBluff,
        pileCollectorId: pileCollectorId,
        pileCollectorName: pileCollectorName,
        cardsCollectedCount: pileCount,
        nextLeaderId: nextLeaderId,
        outcomeMsg: msg,
      );

      return BluffState(
        gameId: state.gameId,
        phase: BluffPhase.challengeReveal,
        playerIds: state.playerIds,
        playerNames: state.playerNames,
        hands: hands,
        cardCounts: cardCounts,
        pile: pile,
        pileCount: 0,
        currentPlayerIndex: state.currentPlayerIndex,
        currentPlayerId: state.currentPlayerId,
        requiredRank: state.requiredRank,
        lastPlay: lastPlay,
        passes: state.passes,
        challengeResult: challengeRes,
        winnerId: null,
        winnerName: null,
        roundHistory: history,
        lastAction: msg,
      );
    } else if (action == 'pass') {
      final passes = List<String>.from(state.passes);
      if (!passes.contains(playerId)) passes.add(playerId);

      final lastPlay = state.lastPlay!;
      final otherPlayers = state.playerIds.where((p) => p != lastPlay.playerId).toList();
      final shouldAdvance = move['force_advance'] == true || (passes.length >= otherPlayers.length);

      if (shouldAdvance) {
        // Check if player who played has 0 cards left
        if (hands[lastPlay.playerId]!.isEmpty) {
          final wName = state.getPlayerName(lastPlay.playerId);
          final winMsg = '$wName successfully emptied their hand unchallenged and WINS THE MATCH!';
          history.add(winMsg);
          return BluffState(
            gameId: state.gameId,
            phase: BluffPhase.gameOver,
            playerIds: state.playerIds,
            playerNames: state.playerNames,
            hands: hands,
            cardCounts: {for (var pid in state.playerIds) pid: hands[pid]!.length},
            pile: pile,
            pileCount: pile.length,
            currentPlayerIndex: state.currentPlayerIndex,
            currentPlayerId: state.currentPlayerId,
            requiredRank: state.requiredRank,
            lastPlay: lastPlay,
            passes: const [],
            challengeResult: null,
            winnerId: lastPlay.playerId,
            winnerName: wName,
            roundHistory: history,
            lastAction: winMsg,
          );
        } else {
          final lastIdx = state.playerIds.indexOf(lastPlay.playerId);
          final nextIdx = (lastIdx + 1) % state.playerIds.length;
          final nextPid = state.playerIds[nextIdx];
          final nextName = state.getPlayerName(nextPid);
          final nextRank = getNextSequentialRank(lastPlay.declaredRank);
          final turnMsg = 'No challenge. $nextName\'s turn to play ${nextRank}s.';
          history.add(turnMsg);

          return BluffState(
            gameId: state.gameId,
            phase: BluffPhase.play,
            playerIds: state.playerIds,
            playerNames: state.playerNames,
            hands: hands,
            cardCounts: {for (var pid in state.playerIds) pid: hands[pid]!.length},
            pile: pile,
            pileCount: pile.length,
            currentPlayerIndex: nextIdx,
            currentPlayerId: nextPid,
            requiredRank: nextRank,
            lastPlay: lastPlay,
            passes: const [],
            challengeResult: null,
            winnerId: null,
            winnerName: null,
            roundHistory: history,
            lastAction: turnMsg,
          );
        }
      } else {
        return BluffState(
          gameId: state.gameId,
          phase: state.phase,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          hands: hands,
          cardCounts: state.cardCounts,
          pile: pile,
          pileCount: pile.length,
          currentPlayerIndex: state.currentPlayerIndex,
          currentPlayerId: state.currentPlayerId,
          requiredRank: state.requiredRank,
          lastPlay: lastPlay,
          passes: passes,
          challengeResult: null,
          winnerId: null,
          winnerName: null,
          roundHistory: history,
          lastAction: '${state.getPlayerName(playerId)} passed.',
        );
      }
    } else if (action == 'continue_after_challenge') {
      final res = state.challengeResult!;
      final lastPlay = state.lastPlay!;
      final blufferId = lastPlay.playerId;

      // Check if bluffer had 0 cards and survived (challenger took pile)
      if (hands[blufferId]!.isEmpty) {
        final wName = state.getPlayerName(blufferId);
        final winMsg = '$wName survived the challenge with 0 cards and WINS THE MATCH!';
        history.add(winMsg);
        return BluffState(
          gameId: state.gameId,
          phase: BluffPhase.gameOver,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          hands: hands,
          cardCounts: {for (var pid in state.playerIds) pid: hands[pid]!.length},
          pile: pile,
          pileCount: 0,
          currentPlayerIndex: state.currentPlayerIndex,
          currentPlayerId: state.currentPlayerId,
          requiredRank: state.requiredRank,
          lastPlay: lastPlay,
          passes: const [],
          challengeResult: null,
          winnerId: blufferId,
          winnerName: wName,
          roundHistory: history,
          lastAction: winMsg,
        );
      } else {
        final nextLeaderId = res.nextLeaderId;
        final nextIdx = state.playerIds.indexOf(nextLeaderId);
        final nextName = state.getPlayerName(nextLeaderId);
        final nextRank = getNextSequentialRank(lastPlay.declaredRank);
        final leadMsg = '$nextName takes the lead to play ${nextRank}s.';
        history.add(leadMsg);

        return BluffState(
          gameId: state.gameId,
          phase: BluffPhase.play,
          playerIds: state.playerIds,
          playerNames: state.playerNames,
          hands: hands,
          cardCounts: {for (var pid in state.playerIds) pid: hands[pid]!.length},
          pile: pile,
          pileCount: 0,
          currentPlayerIndex: nextIdx,
          currentPlayerId: nextLeaderId,
          requiredRank: nextRank,
          lastPlay: null,
          passes: const [],
          challengeResult: null,
          winnerId: null,
          winnerName: null,
          roundHistory: history,
          lastAction: leadMsg,
        );
      }
    } else if (action == 'rematch') {
      return createInitialState(
        playerIds: state.playerIds,
        playerNames: state.playerNames,
      );
    }

    return state;
  }
}
