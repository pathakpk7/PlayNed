enum BingoPattern {
  classic,
  fourCorners,
  xPattern,
  blackout;

  String get displayName {
    switch (this) {
      case BingoPattern.classic:
        return 'Classic Line';
      case BingoPattern.fourCorners:
        return 'Four Corners';
      case BingoPattern.xPattern:
        return 'X Pattern';
      case BingoPattern.blackout:
        return 'Blackout';
    }
  }

  String get description {
    switch (this) {
      case BingoPattern.classic:
        return 'Any complete row, column, or diagonal';
      case BingoPattern.fourCorners:
        return 'All 4 corner squares of the card';
      case BingoPattern.xPattern:
        return 'Both main intersecting diagonal lines';
      case BingoPattern.blackout:
        return 'All 25 squares on the card marked';
    }
  }

  static BingoPattern fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'FOUR_CORNERS':
        return BingoPattern.fourCorners;
      case 'X':
      case 'X_PATTERN':
        return BingoPattern.xPattern;
      case 'BLACKOUT':
        return BingoPattern.blackout;
      default:
        return BingoPattern.classic;
    }
  }

  String toServerString() {
    switch (this) {
      case BingoPattern.classic:
        return 'CLASSIC';
      case BingoPattern.fourCorners:
        return 'FOUR_CORNERS';
      case BingoPattern.xPattern:
        return 'X';
      case BingoPattern.blackout:
        return 'BLACKOUT';
    }
  }
}

enum BingoDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case BingoDifficulty.easy:
        return 'Easy';
      case BingoDifficulty.medium:
        return 'Medium';
      case BingoDifficulty.hard:
        return 'Hard';
    }
  }

  Duration get reactionDelay {
    switch (this) {
      case BingoDifficulty.easy:
        return const Duration(milliseconds: 1000);
      case BingoDifficulty.medium:
        return const Duration(milliseconds: 550);
      case BingoDifficulty.hard:
        return const Duration(milliseconds: 200);
    }
  }
}

class BingoWinResult {
  final bool isWinner;
  final String? patternName;
  final List<int> winningCells;

  const BingoWinResult({
    required this.isWinner,
    this.patternName,
    this.winningCells = const [],
  });

  static const notWon = BingoWinResult(isWinner: false);
}

class BingoCard {
  final List<int> cells;
  final List<bool> marked;

  BingoCard({
    required this.cells,
    required this.marked,
  });

  bool isFree(int index) => index == 12;

  int getNumber(int index) => cells[index];

  bool isMarked(int index) => marked[index];

  int get markedCount => marked.where((m) => m).length;

  double get progressFraction => markedCount / 25.0;

  bool markNumber(int number) {
    bool didMark = false;
    for (int i = 0; i < cells.length; i++) {
      if (cells[i] == number && !marked[i]) {
        marked[i] = true;
        didMark = true;
      }
    }
    return didMark;
  }

  Map<String, dynamic> toJson() => {
        'cells': cells,
        'marked': marked,
      };

  factory BingoCard.fromJson(Map<String, dynamic> json) {
    return BingoCard(
      cells: List<int>.from(json['cells'] ?? List.filled(25, 0)),
      marked: List<bool>.from(json['marked'] ?? List.filled(25, false)),
    );
  }

  BingoCard copyWith({
    List<int>? cells,
    List<bool>? marked,
  }) {
    return BingoCard(
      cells: cells ?? List<int>.from(this.cells),
      marked: marked ?? List<bool>.from(this.marked),
    );
  }
}

class BingoGameState {
  final String gameId;
  final BingoPattern pattern;
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final Map<String, BingoCard> cards;
  final List<int> drawPool;
  final List<int> drawnNumbers;
  final int? currentNumber;
  final String? currentLetter;
  final int drawIndex;
  final bool isGameOver;
  final String? winnerId;
  final String? winnerName;
  final String? winningPattern;
  final List<int> winningCells;
  final String lastAction;
  final DateTime? startedAt;
  final DateTime? endedAt;

  BingoGameState({
    this.gameId = 'bingo',
    required this.pattern,
    required this.playerIds,
    required this.playerNames,
    required this.cards,
    required this.drawPool,
    required this.drawnNumbers,
    this.currentNumber,
    this.currentLetter,
    this.drawIndex = 0,
    this.isGameOver = false,
    this.winnerId,
    this.winnerName,
    this.winningPattern,
    this.winningCells = const [],
    this.lastAction = 'Ready for first number draw.',
    this.startedAt,
    this.endedAt,
  });

  factory BingoGameState.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'] as Map<String, dynamic>? ?? {};
    final parsedCards = <String, BingoCard>{};
    rawCards.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        parsedCards[k] = BingoCard.fromJson(v);
      }
    });

    final rawWinningCells = json['winning_cells'] as List<dynamic>? ?? [];

    return BingoGameState(
      gameId: json['game_id'] ?? 'bingo',
      pattern: BingoPattern.fromString(json['pattern']),
      playerIds: List<String>.from(json['player_ids'] ?? []),
      playerNames: Map<String, String>.from(json['player_names'] ?? {}),
      cards: parsedCards,
      drawPool: List<int>.from(json['draw_pool'] ?? []),
      drawnNumbers: List<int>.from(json['drawn_numbers'] ?? []),
      currentNumber: json['current_number'],
      currentLetter: json['current_letter'],
      drawIndex: json['draw_index'] ?? 0,
      isGameOver: json['status'] == 'finished' || json['status'] == 'draw' || json['is_game_over'] == true,
      winnerId: json['winner_id'],
      winnerName: json['winner_name'],
      winningPattern: json['winning_pattern'],
      winningCells: rawWinningCells.map((e) => (e as num).toInt()).toList(),
      lastAction: json['last_action'] ?? '',
      startedAt: json['started_at'] != null ? DateTime.fromMillisecondsSinceEpoch(((json['started_at'] as num) * 1000).toInt()) : null,
      endedAt: json['ended_at'] != null ? DateTime.fromMillisecondsSinceEpoch(((json['ended_at'] as num) * 1000).toInt()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'game_id': gameId,
        'pattern': pattern.toServerString(),
        'player_ids': playerIds,
        'player_names': playerNames,
        'cards': cards.map((k, v) => MapEntry(k, v.toJson())),
        'draw_pool': drawPool,
        'drawn_numbers': drawnNumbers,
        'current_number': currentNumber,
        'current_letter': currentLetter,
        'draw_index': drawIndex,
        'status': isGameOver ? 'finished' : 'in_progress',
        'winner_id': winnerId,
        'winner_name': winnerName,
        'winning_pattern': winningPattern,
        'winning_cells': winningCells,
        'last_action': lastAction,
      };
}
