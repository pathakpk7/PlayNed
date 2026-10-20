import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/platform/registry/game_registry.dart';

void main() {
  group('PlayNed Game Registry Tests', () {
    test('All 11 launch games are registered with complete metadata', () {
      final games = PlayNedGameRegistry.allGames;
      expect(games.length, 11);

      final hangman = PlayNedGameRegistry.getGame('hangman');
      expect(hangman, isNotNull);
      expect(hangman!.name, 'Hangman Reimagined');
      expect(hangman.minPlayers, 1);
      expect(hangman.maxPlayers, 4);

      final dots = PlayNedGameRegistry.getGame('dots_and_boxes');
      expect(dots, isNotNull);
      expect(dots!.name, 'Dots & Boxes');
      expect(dots.category, 'Strategy');

      final quoridor = PlayNedGameRegistry.getGame('quoridor');
      expect(quoridor, isNotNull);
      expect(quoridor!.name, 'Quoridor');

      final pentago = PlayNedGameRegistry.getGame('pentago');
      expect(pentago, isNotNull);
      expect(pentago!.name, 'Pentago');
      expect(pentago.category, 'Board');

      final shutTheBox = PlayNedGameRegistry.getGame('shut_the_box');
      expect(shutTheBox, isNotNull);
      expect(shutTheBox!.name, 'Shut the Box');
      expect(shutTheBox.minPlayers, 1);
      expect(shutTheBox.maxPlayers, 4);

      final cricket = PlayNedGameRegistry.getGame('cricket');
      expect(cricket, isNotNull);
      expect(cricket!.name, 'Cricket Hub');
      expect(cricket.minPlayers, 1);
      expect(cricket.maxPlayers, 2);

      final reversi = PlayNedGameRegistry.getGame('reversi');
      expect(reversi, isNotNull);
      expect(reversi!.name, 'Reversi & Othello');
      expect(reversi.category, 'Strategy');
      expect(reversi.minPlayers, 1);
      expect(reversi.maxPlayers, 2);

      final uttt = PlayNedGameRegistry.getGame('ultimate_tic_tac_toe');
      expect(uttt, isNotNull);
      expect(uttt!.name, 'Ultimate Tic-Tac-Toe');
      expect(uttt.category, 'Strategy');
      expect(uttt.minPlayers, 2);
      expect(uttt.maxPlayers, 2);

      final bingo = PlayNedGameRegistry.getGame('bingo');
      expect(bingo, isNotNull);
      expect(bingo!.name, 'Bingo');
      expect(bingo.category, 'Casual / Luck / Puzzle');
      expect(bingo.minPlayers, 1);
      expect(bingo.maxPlayers, 2);

      final rm = PlayNedGameRegistry.getGame('raja_mantri_chor_sipahi');
      expect(rm, isNotNull);
      expect(rm!.name, 'Raja Mantri Chor Sipahi');
      expect(rm.category, 'Classic Indian Games / Party Games');
      expect(rm.minPlayers, 4);
      expect(rm.maxPlayers, 4);

      final bluff = PlayNedGameRegistry.getGame('bluff');
      expect(bluff, isNotNull);
      expect(bluff!.name, 'Bluff / Cheat');
      expect(bluff.category, 'Classic Card Games / Party Games');
      expect(bluff.minPlayers, 3);
      expect(bluff.maxPlayers, 6);
      expect(bluff.supportsLocal, isTrue);
      expect(bluff.supportsOnline, isTrue);
    });
  });
}
