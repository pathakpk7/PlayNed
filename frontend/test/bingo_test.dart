import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/bingo/models/bingo_models.dart';
import 'package:hangman_reimagined/games/bingo/services/bingo_engine.dart';

void main() {
  group('Bingo Card Generation Tests', () {
    test('Generates valid 5x5 card with correct column ranges and FREE center', () {
      final card = BingoEngine.generateCard(rng: Random(42));

      expect(card.cells.length, 25);
      expect(card.marked.length, 25);

      // Check center square (index 12, row 2, col 2)
      expect(card.isFree(12), isTrue);
      expect(card.isMarked(12), isTrue);
      expect(card.getNumber(12), 0);

      // Check all columns adhere to B-I-N-G-O ranges
      final bCol = [card.cells[0], card.cells[5], card.cells[10], card.cells[15], card.cells[20]];
      final iCol = [card.cells[1], card.cells[6], card.cells[11], card.cells[16], card.cells[21]];
      final nCol = [card.cells[2], card.cells[7], card.cells[17], card.cells[22]]; // skipping center 12
      final gCol = [card.cells[3], card.cells[8], card.cells[13], card.cells[18], card.cells[23]];
      final oCol = [card.cells[4], card.cells[9], card.cells[14], card.cells[19], card.cells[24]];

      for (final num in bCol) {
        expect(num, inInclusiveRange(1, 15));
      }
      for (final num in iCol) {
        expect(num, inInclusiveRange(16, 30));
      }
      for (final num in nCol) {
        expect(num, inInclusiveRange(31, 45));
      }
      for (final num in gCol) {
        expect(num, inInclusiveRange(46, 60));
      }
      for (final num in oCol) {
        expect(num, inInclusiveRange(61, 75));
      }

      // Check uniqueness of numbers (24 distinct positive numbers)
      final nonFreeNumbers = card.cells.where((n) => n > 0).toSet();
      expect(nonFreeNumbers.length, 24);
    });

    test('Deterministic generation with same Random seed produces identical card', () {
      final card1 = BingoEngine.generateCard(rng: Random(12345));
      final card2 = BingoEngine.generateCard(rng: Random(12345));

      for (int i = 0; i < 25; i++) {
        expect(card1.cells[i], card2.cells[i]);
      }
    });

    test('Different Random seeds produce different cards', () {
      final card1 = BingoEngine.generateCard(rng: Random(100));
      final card2 = BingoEngine.generateCard(rng: Random(200));

      final diffCount = List.generate(25, (i) => card1.cells[i] != card2.cells[i])
          .where((diff) => diff)
          .length;
      expect(diffCount, greaterThan(0));
    });
  });

  group('Bingo Engine Drawing and Marking Tests', () {
    test('Initializes state with full 75-number draw pool', () {
      final state = BingoEngine.createInitialState(
        playerIds: ['p1', 'p2'],
        playerNames: {'p1': 'Player 1', 'p2': 'Player 2'},
        pattern: BingoPattern.classic,
      );

      expect(state.drawPool.length, 75);
      expect(state.drawnNumbers.isEmpty, isTrue);
      expect(state.currentNumber, isNull);
      expect(state.isGameOver, isFalse);
      expect(state.winnerId, isNull);
    });

    test('Drawing removes number from pool and marks cards', () {
      final state0 = BingoEngine.createInitialState(
        playerIds: ['p1', 'p2'],
        playerNames: {'p1': 'Player 1', 'p2': 'Player 2'},
        rng: Random(42),
      );

      final nextToDraw = state0.drawPool.first;
      final state1 = BingoEngine.drawNextNumber(state0);

      expect(state1.currentNumber, nextToDraw);
      expect(state1.drawnNumbers, [nextToDraw]);
      expect(state1.drawPool.contains(nextToDraw), isFalse);
      expect(state1.drawPool.length, 74);

      // Check if either card contained that number, it is now marked
      for (final pid in ['p1', 'p2']) {
        final card = state1.cards[pid]!;
        for (int i = 0; i < 25; i++) {
          if (card.cells[i] == nextToDraw) {
            expect(card.marked[i], isTrue);
          }
        }
      }
    });

    test('Draw pool exhausts properly without duplicates', () {
      var state = BingoEngine.createInitialState(
        playerIds: ['p1', 'p2'],
        playerNames: {'p1': 'Player 1', 'p2': 'Player 2'},
        rng: Random(99),
      );

      final drawnSet = <int>{};
      for (int i = 0; i < 75; i++) {
        if (state.isGameOver) break;
        state = BingoEngine.drawNextNumber(state);
        expect(state.currentNumber, isNotNull);
        expect(drawnSet.contains(state.currentNumber), isFalse);
        drawnSet.add(state.currentNumber!);
      }

      expect(drawnSet.length, state.drawnNumbers.length);
    });
  });

  group('Bingo Win Pattern Detection Tests', () {
    test('Classic row win', () {
      final card = BingoEngine.generateCard(rng: Random(1));
      // Mark top row: indices 0, 1, 2, 3, 4
      final newMarked = List<bool>.from(card.marked);
      for (final idx in [0, 1, 2, 3, 4]) {
        newMarked[idx] = true;
      }
      final modifiedCard = card.copyWith(marked: newMarked);

      final win = BingoEngine.checkWinner(modifiedCard, BingoPattern.classic);
      expect(win.isWinner, isTrue);
      expect(win.patternName, contains('Row 1'));
      expect(win.winningCells, containsAll([0, 1, 2, 3, 4]));
    });

    test('Classic column win with FREE space in column N (index 2)', () {
      final card = BingoEngine.generateCard(rng: Random(2));
      // Mark column N: indices 2, 7, 12 (FREE), 17, 22
      final newMarked = List<bool>.from(card.marked);
      for (final idx in [2, 7, 17, 22]) {
        newMarked[idx] = true;
      }
      final modifiedCard = card.copyWith(marked: newMarked);

      final win = BingoEngine.checkWinner(modifiedCard, BingoPattern.classic);
      expect(win.isWinner, isTrue);
      expect(win.patternName, contains('Column N'));
      expect(win.winningCells, containsAll([2, 7, 12, 17, 22]));
    });

    test('Classic diagonal win (top-left to bottom-right)', () {
      final card = BingoEngine.generateCard(rng: Random(3));
      // Diagonal 1: indices 0, 6, 12, 18, 24
      final newMarked = List<bool>.from(card.marked);
      for (final idx in [0, 6, 18, 24]) {
        newMarked[idx] = true;
      }
      final modifiedCard = card.copyWith(marked: newMarked);

      final win = BingoEngine.checkWinner(modifiedCard, BingoPattern.classic);
      expect(win.isWinner, isTrue);
      expect(win.patternName, contains('Diagonal'));
      expect(win.winningCells, containsAll([0, 6, 12, 18, 24]));
    });

    test('Four Corners pattern win', () {
      final card = BingoEngine.generateCard(rng: Random(4));
      // Mark 4 corners: 0, 4, 20, 24
      final newMarked = List<bool>.from(card.marked);
      for (final idx in [0, 4, 20, 24]) {
        newMarked[idx] = true;
      }
      final modifiedCard = card.copyWith(marked: newMarked);

      final win = BingoEngine.checkWinner(modifiedCard, BingoPattern.fourCorners);
      expect(win.isWinner, isTrue);
      expect(win.patternName, 'Four Corners');
      expect(win.winningCells, containsAll([0, 4, 20, 24]));

      // Missing 1 corner should not win
      final incompleteMarked = List<bool>.from(card.marked);
      incompleteMarked[0] = true;
      incompleteMarked[4] = true;
      incompleteMarked[20] = true;
      final incompleteCard = card.copyWith(marked: incompleteMarked);
      expect(BingoEngine.checkWinner(incompleteCard, BingoPattern.fourCorners).isWinner, isFalse);
    });

    test('X Pattern win', () {
      final card = BingoEngine.generateCard(rng: Random(5));
      // Diag 1: 0, 6, 12, 18, 24
      // Diag 2: 4, 8, 12, 16, 20
      final newMarked = List<bool>.from(card.marked);
      final xIndices = [0, 6, 18, 24, 4, 8, 16, 20];
      for (final idx in xIndices) {
        newMarked[idx] = true;
      }
      final modifiedCard = card.copyWith(marked: newMarked);

      final win = BingoEngine.checkWinner(modifiedCard, BingoPattern.xPattern);
      expect(win.isWinner, isTrue);
      expect(win.patternName, 'X Pattern');
      expect(win.winningCells.length, 9);

      // Incomplete X should not win
      final incompleteMarked = List<bool>.from(card.marked);
      incompleteMarked[0] = true;
      incompleteMarked[6] = true;
      final incompleteCard = card.copyWith(marked: incompleteMarked);
      expect(BingoEngine.checkWinner(incompleteCard, BingoPattern.xPattern).isWinner, isFalse);
    });

    test('Blackout pattern win', () {
      final card = BingoEngine.generateCard(rng: Random(6));
      final allMarked = List<bool>.filled(25, true);
      final blackoutCard = card.copyWith(marked: allMarked);

      final win = BingoEngine.checkWinner(blackoutCard, BingoPattern.blackout);
      expect(win.isWinner, isTrue);
      expect(win.patternName, 'Blackout');
      expect(win.winningCells.length, 25);

      // 24 marked cells (1 missing) is not Blackout
      final almostMarked = List<bool>.filled(25, true);
      almostMarked[24] = false;
      final almostCard = card.copyWith(marked: almostMarked);
      expect(BingoEngine.checkWinner(almostCard, BingoPattern.blackout).isWinner, isFalse);
    });
  });
}
