import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/platform/registry/game_registry.dart';

void main() {
  group('PlayNed Game Registry Tests', () {
    test('All 7 launch games are registered with complete metadata', () {
      final games = PlayNedGameRegistry.allGames;
      expect(games.length, 7);

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
    });
  });
}
