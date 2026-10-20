import 'dart:math';
import '../models/bingo_models.dart';

class BingoEngine {
  static const Map<int, List<int>> columnRanges = {
    0: [1, 15],   // B
    1: [16, 30],  // I
    2: [31, 45],  // N
    3: [46, 60],  // G
    4: [61, 75],  // O
  };

  static const List<String> columnLetters = ['B', 'I', 'N', 'G', 'O'];

  static String getColumnLetter(int number) {
    if (number >= 1 && number <= 15) return 'B';
    if (number >= 16 && number <= 30) return 'I';
    if (number >= 31 && number <= 45) return 'N';
    if (number >= 46 && number <= 60) return 'G';
    if (number >= 61 && number <= 75) return 'O';
    return '';
  }

  static BingoCard generateCard({Random? rng}) {
    final random = rng ?? Random();
    final cells = List<int>.filled(25, 0);
    final marked = List<bool>.filled(25, false);

    for (int c = 0; c < 5; c++) {
      final range = columnRanges[c]!;
      final minVal = range[0];
      final maxVal = range[1];
      final pool = List<int>.generate(maxVal - minVal + 1, (i) => minVal + i);
      pool.shuffle(random);

      for (int r = 0; r < 5; r++) {
        final idx = r * 5 + c;
        if (idx == 12) {
          cells[idx] = 0; // FREE space
          marked[idx] = true;
        } else {
          cells[idx] = pool[r];
        }
      }
    }

    return BingoCard(cells: cells, marked: marked);
  }

  static List<int> generateDrawPool({Random? rng}) {
    final random = rng ?? Random();
    final pool = List<int>.generate(75, (i) => i + 1);
    pool.shuffle(random);
    return pool;
  }

  static BingoWinResult checkWinner(BingoCard card, BingoPattern pattern) {
    final marked = card.marked;

    switch (pattern) {
      case BingoPattern.fourCorners:
        const corners = [0, 4, 20, 24];
        if (corners.every((c) => marked[c])) {
          return const BingoWinResult(
            isWinner: true,
            patternName: 'Four Corners',
            winningCells: corners,
          );
        }
        break;

      case BingoPattern.xPattern:
        const xCells = [0, 6, 12, 18, 24, 4, 8, 16, 20];
        if (xCells.every((c) => marked[c])) {
          return const BingoWinResult(
            isWinner: true,
            patternName: 'X Pattern',
            winningCells: [0, 4, 6, 8, 12, 16, 18, 20, 24],
          );
        }
        break;

      case BingoPattern.blackout:
        if (marked.every((m) => m)) {
          return BingoWinResult(
            isWinner: true,
            patternName: 'Blackout',
            winningCells: List<int>.generate(25, (i) => i),
          );
        }
        break;

      case BingoPattern.classic:
        // 1. Check rows
        for (int r = 0; r < 5; r++) {
          final rowCells = [r * 5, r * 5 + 1, r * 5 + 2, r * 5 + 3, r * 5 + 4];
          if (rowCells.every((c) => marked[c])) {
            return BingoWinResult(
              isWinner: true,
              patternName: 'Row ${r + 1}',
              winningCells: rowCells,
            );
          }
        }

        // 2. Check columns
        for (int c = 0; c < 5; c++) {
          final colCells = [c, c + 5, c + 10, c + 15, c + 20];
          if (colCells.every((idx) => marked[idx])) {
            return BingoWinResult(
              isWinner: true,
              patternName: 'Column ${columnLetters[c]}',
              winningCells: colCells,
            );
          }
        }

        // 3. Main Diagonal
        const mainDiag = [0, 6, 12, 18, 24];
        if (mainDiag.every((c) => marked[c])) {
          return const BingoWinResult(
            isWinner: true,
            patternName: 'Main Diagonal',
            winningCells: mainDiag,
          );
        }

        // 4. Anti-Diagonal
        const antiDiag = [4, 8, 12, 16, 20];
        if (antiDiag.every((c) => marked[c])) {
          return const BingoWinResult(
            isWinner: true,
            patternName: 'Anti Diagonal',
            winningCells: antiDiag,
          );
        }
        break;
    }

    return BingoWinResult.notWon;
  }

  static bool validateBingoClaim(BingoCard card, BingoPattern pattern) {
    return checkWinner(card, pattern).isWinner;
  }

  static BingoGameState createInitialState({
    required List<String> playerIds,
    required Map<String, String> playerNames,
    BingoPattern pattern = BingoPattern.classic,
    Random? rng,
  }) {
    final cards = <String, BingoCard>{};
    for (final pid in playerIds) {
      cards[pid] = generateCard(rng: rng);
    }

    return BingoGameState(
      pattern: pattern,
      playerIds: playerIds,
      playerNames: playerNames,
      cards: cards,
      drawPool: generateDrawPool(rng: rng),
      drawnNumbers: [],
      drawIndex: 0,
      isGameOver: false,
      lastAction: 'Match started with ${pattern.displayName}. Ready for first draw.',
      startedAt: DateTime.now(),
    );
  }

  static BingoGameState drawNextNumber(BingoGameState state) {
    if (state.isGameOver || state.drawPool.isEmpty) {
      return state;
    }

    final newPool = List<int>.from(state.drawPool);
    final drawn = newPool.removeAt(0);
    final newDrawn = List<int>.from(state.drawnNumbers)..add(drawn);
    final letter = getColumnLetter(drawn);

    // Auto-mark cards
    final updatedCards = <String, BingoCard>{};
    state.cards.forEach((pid, card) {
      final copy = card.copyWith();
      copy.markNumber(drawn);
      updatedCards[pid] = copy;
    });

    // Check winners
    final winners = <String, BingoWinResult>{};
    for (final entry in updatedCards.entries) {
      final res = checkWinner(entry.value, state.pattern);
      if (res.isWinner) {
        winners[entry.key] = res;
      }
    }

    bool isGameOver = false;
    String? winnerId;
    String? winnerName;
    String? winPattern;
    List<int> winCells = [];
    String lastAction = '$letter-$drawn called.';

    if (winners.isNotEmpty) {
      isGameOver = true;
      if (winners.length > 1) {
        final names = winners.keys.map((k) => state.playerNames[k] ?? k).join(' & ');
        winnerId = 'tie';
        winnerName = names;
        winPattern = winners.values.first.patternName;
        winCells = winners.values.first.winningCells;
        lastAction = 'Simultaneous BINGO! $winnerName win!';
      } else {
        final entry = winners.entries.first;
        winnerId = entry.key;
        winnerName = state.playerNames[winnerId] ?? winnerId;
        winPattern = entry.value.patternName;
        winCells = entry.value.winningCells;
        lastAction = 'BINGO! $winnerName completes $winPattern!';
      }
    } else if (newPool.isEmpty) {
      isGameOver = true;
      lastAction = 'All 75 numbers drawn without a pattern completed.';
    }

    return BingoGameState(
      gameId: state.gameId,
      pattern: state.pattern,
      playerIds: state.playerIds,
      playerNames: state.playerNames,
      cards: updatedCards,
      drawPool: newPool,
      drawnNumbers: newDrawn,
      currentNumber: drawn,
      currentLetter: letter,
      drawIndex: newDrawn.length,
      isGameOver: isGameOver,
      winnerId: winnerId,
      winnerName: winnerName,
      winningPattern: winPattern,
      winningCells: winCells,
      lastAction: lastAction,
      startedAt: state.startedAt,
      endedAt: isGameOver ? DateTime.now() : null,
    );
  }
}
