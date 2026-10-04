import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/ultimate_tic_tac_toe/models/ultimate_tic_tac_toe_state.dart';
import 'package:hangman_reimagined/games/ultimate_tic_tac_toe/presentation/pages/ultimate_tic_tac_toe_game_page.dart';
import 'package:hangman_reimagined/platform/registry/game_registry.dart';

void main() {
  group('Ultimate Tic-Tac-Toe Unit & State Model Tests', () {
    test('Game is correctly registered in PlayNedGameRegistry', () {
      final game = PlayNedGameRegistry.getGame('ultimate_tic_tac_toe');
      expect(game, isNotNull);
      expect(game!.id, 'ultimate_tic_tac_toe');
      expect(game.name, 'Ultimate Tic-Tac-Toe');
      expect(game.category, 'Strategy');
      expect(game.minPlayers, 2);
      expect(game.maxPlayers, 2);
      expect(game.supportsOnline, true);
      expect(game.supportsLocal, true);
    });

    test('Initial State is clean and offers full Free Move (boards 0..8)', () {
      final state = UltimateTicTacToeState.initial(
        p1Id: 'p1',
        p2Id: 'p2',
        p1Name: 'Player 1',
        p2Name: 'Player 2',
      );

      expect(state.boards.length, 9);
      expect(state.macroBoard.length, 9);
      expect(state.isFreeMove, isTrue);
      expect(state.validBoards, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect(state.currentSymbol, 'X');
      expect(state.currentTurnPlayerId, 'p1');
      expect(state.status, 'in_progress');
    });

    test('Targeted Next Board restricts validBoards to exactly that index', () {
      final state = UltimateTicTacToeState(
        playerIds: ['p1', 'p2'],
        playerNames: {'p1': 'Player 1', 'p2': 'Player 2'},
        playerSymbols: {'p1': 'X', 'p2': 'O'},
        boards: List.generate(9, (i) => MicroBoardState.initial(i)),
        macroBoard: List.filled(9, null),
        nextBoard: 4, // Center board
        currentTurnIndex: 1,
        currentTurnPlayerId: 'p2',
        currentSymbol: 'O',
        moveHistory: [],
        turnNumber: 1,
        status: 'in_progress',
        xBoardsWon: 0,
        oBoardsWon: 0,
        lastAction: 'Move made',
      );

      expect(state.isFreeMove, isFalse);
      expect(state.validBoards, [4]);
    });

    test('Targeted Next Board that is already won results in Free Move', () {
      final boards = List.generate(9, (i) => MicroBoardState.initial(i));
      // Board 4 is won by X
      boards[4] = MicroBoardState(
        index: 4,
        cells: ['X', 'X', 'X', null, null, null, null, null, null],
        winner: 'X',
        status: 'won',
      );

      final state = UltimateTicTacToeState(
        playerIds: ['p1', 'p2'],
        playerNames: {'p1': 'Player 1', 'p2': 'Player 2'},
        playerSymbols: {'p1': 'X', 'p2': 'O'},
        boards: boards,
        macroBoard: [null, null, null, null, 'X', null, null, null, null],
        nextBoard: 4, // Sent to won board 4
        currentTurnIndex: 1,
        currentTurnPlayerId: 'p2',
        currentSymbol: 'O',
        moveHistory: [],
        turnNumber: 1,
        status: 'in_progress',
        xBoardsWon: 1,
        oBoardsWon: 0,
        lastAction: 'X won board 4',
      );

      // Since board 4 is completed, validBoards should exclude 4 and allow all other open boards
      expect(state.validBoards, [0, 1, 2, 3, 5, 6, 7, 8]);
      expect(state.validBoards.contains(4), isFalse);
    });

    test('JSON Serialization round-trip preserves state integrity', () {
      final original = UltimateTicTacToeState(
        playerIds: ['p1', 'p2'],
        playerNames: {'p1': 'Player 1', 'p2': 'Player 2'},
        playerSymbols: {'p1': 'X', 'p2': 'O'},
        boards: [
          MicroBoardState(
            index: 0,
            cells: ['X', 'O', 'X', 'O', 'X', 'O', 'X', 'O', 'X'],
            winner: 'X',
            status: 'won',
          ),
          ...List.generate(8, (i) => MicroBoardState.initial(i + 1)),
        ],
        macroBoard: ['X', null, null, null, null, null, null, null, null],
        nextBoard: 2,
        currentTurnIndex: 1,
        currentTurnPlayerId: 'p2',
        currentSymbol: 'O',
        moveHistory: [
          {'board': 0, 'cell': 2, 'player': 'X', 'player_id': 'p1'}
        ],
        turnNumber: 1,
        status: 'in_progress',
        xBoardsWon: 1,
        oBoardsWon: 0,
        lastMove: {'board': 0, 'cell': 2, 'player': 'X'},
        lastAction: 'Player 1 placed X',
      );

      final json = original.toJson();
      final deserialized = UltimateTicTacToeState.fromJson(json);

      expect(deserialized.boards[0].winner, 'X');
      expect(deserialized.boards[0].isCompleted, isTrue);
      expect(deserialized.macroBoard[0], 'X');
      expect(deserialized.nextBoard, 2);
      expect(deserialized.currentSymbol, 'O');
      expect(deserialized.turnNumber, 1);
      expect(deserialized.lastMove?['player'], 'X');
    });
  });

  group('Ultimate Tic-Tac-Toe Widget & UI Integration Tests', () {
    testWidgets('Renders UltimateTicTacToeGamePage in local mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UltimateTicTacToeGamePage(mode: 'local'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify page title and header
      expect(find.text('ULTIMATE'), findsOneWidget);
      expect(find.text('Tic-Tac-Toe'), findsOneWidget);

      // Verify Free Move initial status
      expect(find.textContaining('FREE MOVE'), findsOneWidget);

      // Verify Player X and Player O headers
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);

      // Verify Match stats
      expect(find.text('MATCH STATS'), findsOneWidget);
    });
  });
}
