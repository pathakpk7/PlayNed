import 'package:flutter/material.dart';

enum CardSuit {
  spades,
  hearts,
  diamonds,
  clubs;

  String get code {
    switch (this) {
      case CardSuit.spades:
        return 'S';
      case CardSuit.hearts:
        return 'H';
      case CardSuit.diamonds:
        return 'D';
      case CardSuit.clubs:
        return 'C';
    }
  }

  String get symbol {
    switch (this) {
      case CardSuit.spades:
        return '♠';
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
    }
  }

  String get displayName {
    switch (this) {
      case CardSuit.spades:
        return 'Spades';
      case CardSuit.hearts:
        return 'Hearts';
      case CardSuit.diamonds:
        return 'Diamonds';
      case CardSuit.clubs:
        return 'Clubs';
    }
  }

  Color get color {
    switch (this) {
      case CardSuit.spades:
      case CardSuit.clubs:
        return const Color(0xFFCBD5E1); // Slate / Silver-white
      case CardSuit.hearts:
      case CardSuit.diamonds:
        return const Color(0xFFEF4444); // Crimson Red
    }
  }

  static CardSuit fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'H':
        return CardSuit.hearts;
      case 'D':
        return CardSuit.diamonds;
      case 'C':
        return CardSuit.clubs;
      case 'S':
      default:
        return CardSuit.spades;
    }
  }
}

class PlayingCard {
  final String rawCode;
  final String rank;
  final CardSuit suit;

  const PlayingCard({
    required this.rawCode,
    required this.rank,
    required this.suit,
  });

  factory PlayingCard.fromString(String code) {
    final parts = code.split('_');
    final rank = parts.isNotEmpty ? parts[0] : 'A';
    final suitCode = parts.length > 1 ? parts[1] : 'S';
    return PlayingCard(
      rawCode: code,
      rank: rank,
      suit: CardSuit.fromCode(suitCode),
    );
  }

  String get displayName => '$rank${suit.symbol}';

  Color get suitColor => suit.color;

  String get suitSymbol => suit.symbol;

  int get rankIndex {
    const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    final idx = ranks.indexOf(rank);
    return idx >= 0 ? idx : 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard && runtimeType == other.runtimeType && rawCode == other.rawCode;

  @override
  int get hashCode => rawCode.hashCode;
}

enum BluffPhase {
  play,
  challenge,
  challengeReveal,
  gameOver;

  static BluffPhase fromString(String val) {
    switch (val.toUpperCase()) {
      case 'CHALLENGE':
        return BluffPhase.challenge;
      case 'CHALLENGE_REVEAL':
        return BluffPhase.challengeReveal;
      case 'GAME_OVER':
        return BluffPhase.gameOver;
      case 'PLAY':
      default:
        return BluffPhase.play;
    }
  }

  String toServerString() {
    switch (this) {
      case BluffPhase.play:
        return 'PLAY';
      case BluffPhase.challenge:
        return 'CHALLENGE';
      case BluffPhase.challengeReveal:
        return 'CHALLENGE_REVEAL';
      case BluffPhase.gameOver:
        return 'GAME_OVER';
    }
  }
}

class BluffLastPlay {
  final String playerId;
  final String playerName;
  final String declaredRank;
  final int cardCount;
  final List<PlayingCard>? actualCards;

  const BluffLastPlay({
    required this.playerId,
    required this.playerName,
    required this.declaredRank,
    required this.cardCount,
    this.actualCards,
  });

  factory BluffLastPlay.fromJson(Map<String, dynamic> json) {
    List<PlayingCard>? cards;
    if (json['actual_cards'] != null && json['actual_cards'] is List) {
      cards = (json['actual_cards'] as List)
          .map((c) => PlayingCard.fromString(c.toString()))
          .toList();
    }
    return BluffLastPlay(
      playerId: json['player_id']?.toString() ?? '',
      playerName: json['player_name']?.toString() ?? 'Player',
      declaredRank: json['declared_rank']?.toString() ?? 'A',
      cardCount: (json['card_count'] as num?)?.toInt() ?? 1,
      actualCards: cards,
    );
  }

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'player_name': playerName,
        'declared_rank': declaredRank,
        'card_count': cardCount,
        if (actualCards != null)
          'actual_cards': actualCards!.map((c) => c.rawCode).toList(),
      };
}

class BluffChallengeResult {
  final String challengerId;
  final String challengerName;
  final String blufferId;
  final String blufferName;
  final String declaredRank;
  final List<PlayingCard> revealedCards;
  final bool wasBluff;
  final String pileCollectorId;
  final String pileCollectorName;
  final int cardsCollectedCount;
  final String nextLeaderId;
  final String outcomeMsg;

  const BluffChallengeResult({
    required this.challengerId,
    required this.challengerName,
    required this.blufferId,
    required this.blufferName,
    required this.declaredRank,
    required this.revealedCards,
    required this.wasBluff,
    required this.pileCollectorId,
    required this.pileCollectorName,
    required this.cardsCollectedCount,
    required this.nextLeaderId,
    required this.outcomeMsg,
  });

  factory BluffChallengeResult.fromJson(Map<String, dynamic> json) {
    final rawCards = json['revealed_cards'] as List? ?? [];
    return BluffChallengeResult(
      challengerId: json['challenger_id']?.toString() ?? '',
      challengerName: json['challenger_name']?.toString() ?? 'Challenger',
      blufferId: json['bluffer_id']?.toString() ?? '',
      blufferName: json['bluffer_name']?.toString() ?? 'Player',
      declaredRank: json['declared_rank']?.toString() ?? 'A',
      revealedCards:
          rawCards.map((c) => PlayingCard.fromString(c.toString())).toList(),
      wasBluff: json['was_bluff'] == true,
      pileCollectorId: json['pile_collector_id']?.toString() ?? '',
      pileCollectorName: json['pile_collector_name']?.toString() ?? 'Player',
      cardsCollectedCount: (json['cards_collected_count'] as num?)?.toInt() ?? 0,
      nextLeaderId: json['next_leader_id']?.toString() ?? '',
      outcomeMsg: json['outcome_msg']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'challenger_id': challengerId,
        'challenger_name': challengerName,
        'bluffer_id': blufferId,
        'bluffer_name': blufferName,
        'declared_rank': declaredRank,
        'revealed_cards': revealedCards.map((c) => c.rawCode).toList(),
        'was_bluff': wasBluff,
        'pile_collector_id': pileCollectorId,
        'pile_collector_name': pileCollectorName,
        'cards_collected_count': cardsCollectedCount,
        'next_leader_id': nextLeaderId,
        'outcome_msg': outcomeMsg,
      };
}

class BluffState {
  final String gameId;
  final BluffPhase phase;
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final Map<String, List<PlayingCard>> hands; // Full hands in local mode
  final List<PlayingCard> myHand; // Private hand for this player
  final Map<String, int> cardCounts;
  final List<PlayingCard> pile; // Central pile cards (local)
  final int pileCount;
  final int currentPlayerIndex;
  final String currentPlayerId;
  final String requiredRank;
  final BluffLastPlay? lastPlay;
  final List<String> passes;
  final BluffChallengeResult? challengeResult;
  final String? winnerId;
  final String? winnerName;
  final List<String> roundHistory;
  final String lastAction;

  const BluffState({
    this.gameId = 'bluff',
    required this.phase,
    required this.playerIds,
    required this.playerNames,
    this.hands = const {},
    this.myHand = const [],
    this.cardCounts = const {},
    this.pile = const [],
    this.pileCount = 0,
    this.currentPlayerIndex = 0,
    required this.currentPlayerId,
    this.requiredRank = 'A',
    this.lastPlay,
    this.passes = const [],
    this.challengeResult,
    this.winnerId,
    this.winnerName,
    this.roundHistory = const [],
    this.lastAction = 'Game started! Play cards face-down.',
  });

  bool get isGameOver => phase == BluffPhase.gameOver;

  String getPlayerName(String pid) => playerNames[pid] ?? pid;

  int getPlayerCardCount(String pid) {
    if (cardCounts.containsKey(pid)) return cardCounts[pid]!;
    if (hands.containsKey(pid)) return hands[pid]!.length;
    return 0;
  }

  factory BluffState.fromJson(Map<String, dynamic> json) {
    final pIds = (json['player_ids'] as List? ?? []).map((e) => e.toString()).toList();
    final pNames = (json['player_names'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));

    // Hands mapping
    final handsMap = <String, List<PlayingCard>>{};
    if (json['hands'] is Map) {
      final rawHands = json['hands'] as Map<String, dynamic>;
      for (final entry in rawHands.entries) {
        if (entry.value is List) {
          handsMap[entry.key] = (entry.value as List)
              .map((c) => PlayingCard.fromString(c.toString()))
              .toList();
        }
      }
    }

    // my_hand
    final myHandList = <PlayingCard>[];
    if (json['my_hand'] is List) {
      for (final c in json['my_hand'] as List) {
        myHandList.add(PlayingCard.fromString(c.toString()));
      }
    }

    // Card counts
    final counts = <String, int>{};
    if (json['card_counts'] is Map) {
      final rawCounts = json['card_counts'] as Map<String, dynamic>;
      for (final entry in rawCounts.entries) {
        counts[entry.key] = (entry.value as num).toInt();
      }
    }

    // Central pile
    final pileList = <PlayingCard>[];
    if (json['pile'] is List) {
      for (final c in json['pile'] as List) {
        pileList.add(PlayingCard.fromString(c.toString()));
      }
    }

    return BluffState(
      gameId: json['game_id']?.toString() ?? 'bluff',
      phase: BluffPhase.fromString(json['phase']?.toString() ?? 'PLAY'),
      playerIds: pIds,
      playerNames: pNames,
      hands: handsMap,
      myHand: myHandList,
      cardCounts: counts,
      pile: pileList,
      pileCount: (json['pile_count'] as num?)?.toInt() ?? pileList.length,
      currentPlayerIndex: (json['current_player_index'] as num?)?.toInt() ?? 0,
      currentPlayerId: json['current_player_id']?.toString() ?? (pIds.isNotEmpty ? pIds[0] : ''),
      requiredRank: json['required_rank']?.toString() ?? 'A',
      lastPlay: json['last_play'] != null
          ? BluffLastPlay.fromJson(json['last_play'] as Map<String, dynamic>)
          : null,
      passes: (json['passes'] as List? ?? []).map((e) => e.toString()).toList(),
      challengeResult: json['challenge_result'] != null
          ? BluffChallengeResult.fromJson(json['challenge_result'] as Map<String, dynamic>)
          : null,
      winnerId: json['winner_id']?.toString(),
      winnerName: json['winner_name']?.toString(),
      roundHistory:
          (json['round_history'] as List? ?? []).map((e) => e.toString()).toList(),
      lastAction: json['last_action']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'game_id': gameId,
        'phase': phase.toServerString(),
        'player_ids': playerIds,
        'player_names': playerNames,
        'hands': hands.map((k, v) => MapEntry(k, v.map((c) => c.rawCode).toList())),
        'my_hand': myHand.map((c) => c.rawCode).toList(),
        'card_counts': cardCounts,
        'pile': pile.map((c) => c.rawCode).toList(),
        'pile_count': pileCount,
        'current_player_index': currentPlayerIndex,
        'current_player_id': currentPlayerId,
        'required_rank': requiredRank,
        if (lastPlay != null) 'last_play': lastPlay!.toJson(),
        'passes': passes,
        if (challengeResult != null) 'challenge_result': challengeResult!.toJson(),
        'winner_id': winnerId,
        'winner_name': winnerName,
        'round_history': roundHistory,
        'last_action': lastAction,
      };
}
