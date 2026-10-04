import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/reversi/models/reversi_game_state.dart';

void main() {
  group('Reversi & Othello Game State & Rules', () {
    test('Othello initial board has 4 center discs (2 Black, 2 White)', () {
      final state = ReversiGameState.initial(variant: ReversiVariant.othello);
      expect(state.blackCount, 2);
      expect(state.whiteCount, 2);
      expect(state.currentTurnColor, 1);
      expect(state.isGameOver, false);

      // Verify standard 4-disc setup
      expect(state.board[3][3], 2); // White
      expect(state.board[3][4], 1); // Black
      expect(state.board[4][3], 1); // Black
      expect(state.board[4][4], 2); // White

      // Black should have 4 opening legal moves: (2,3), (3,2), (4,5), (5,4)
      final legal = state.currentLegalMoves;
      expect(legal.length, 4);
      expect(legal.containsKey(const ReversiCoord(2, 3)), true);
      expect(legal.containsKey(const ReversiCoord(3, 2)), true);
      expect(legal.containsKey(const ReversiCoord(4, 5)), true);
      expect(legal.containsKey(const ReversiCoord(5, 4)), true);
    });

    test('Sandwich Rule: Move flips trapped opposing discs to current color', () {
      final state = ReversiGameState.initial(variant: ReversiVariant.othello);
      // Black plays at (2, 3) sandwiching (3, 3) with (4, 3)
      final nextState = state.applyMove(2, 3);

      expect(nextState.board[2][3], 1);
      expect(nextState.board[3][3], 1); // flipped from White to Black!
      expect(nextState.blackCount, 4);
      expect(nextState.whiteCount, 1);
      expect(nextState.currentTurnColor, 2); // Now White's turn
    });

    test('Multi-Directional Sandwich Chain Reaction Flips', () {
      final board = List.generate(8, (_) => List<int>.filled(8, 0));
      // Setup: Black at (0, 0), White at (0, 1), (0, 2); White at (1, 3), (2, 3); Black at (3, 3)
      // If Black plays at (0, 3):
      // Row sandwich: (0, 3) <-> (0, 0) traps (0, 1) and (0, 2)
      // Col sandwich: (0, 3) <-> (3, 3) traps (1, 3) and (2, 3)
      board[0][0] = 1;
      board[0][1] = 2;
      board[0][2] = 2;
      board[1][3] = 2;
      board[2][3] = 2;
      board[3][3] = 1;

      final state = ReversiGameState(
        board: board,
        currentTurnColor: 1,
        variant: ReversiVariant.othello,
        blackCount: 2,
        whiteCount: 4,
        blackReserves: 30,
        whiteReserves: 30,
        consecutivePasses: 0,
        isGameOver: false,
        winnerColor: null,
        statusMessage: "",
      );

      final flips = state.currentLegalMoves[const ReversiCoord(0, 3)];
      expect(flips, isNotNull);
      expect(flips!.length, 4);
      expect(flips.contains(const ReversiCoord(0, 1)), true);
      expect(flips.contains(const ReversiCoord(0, 2)), true);
      expect(flips.contains(const ReversiCoord(1, 3)), true);
      expect(flips.contains(const ReversiCoord(2, 3)), true);

      final nextState = state.applyMove(0, 3);
      expect(nextState.board[0][1], 1);
      expect(nextState.board[0][2], 1);
      expect(nextState.board[1][3], 1);
      expect(nextState.board[2][3], 1);
    });

    test('Tactician AI prioritizes Corner Control over naive flip count', () {
      final board = List.generate(8, (_) => List<int>.filled(8, 0));
      // Setup corner capture opportunity for White at (0, 0)
      board[0][1] = 1;
      board[0][2] = 2;

      // Anchor piece for Black so Black is not wiped out
      board[7][7] = 1;

      // Also setup a center move with 2 flips at (4, 4)
      board[4][1] = 2;
      board[4][2] = 1;
      board[4][3] = 1;
      board[4][4] = 0;

      final state = ReversiGameState(
        board: board,
        currentTurnColor: 2, // White to move
        variant: ReversiVariant.othello,
        blackCount: 4,
        whiteCount: 2,
        blackReserves: 30,
        whiteReserves: 30,
        consecutivePasses: 0,
        isGameOver: false,
        winnerColor: null,
        statusMessage: "",
      );

      final tacticianMove = ReversiAI.selectMove(state, ReversiDifficulty.tactician);
      // Tactician should seize the corner (0, 0) due to massive corner bonus (+200)
      expect(tacticianMove, const ReversiCoord(0, 0));
    });
  });
}
