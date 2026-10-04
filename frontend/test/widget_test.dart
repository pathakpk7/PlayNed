import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/main.dart';
import 'package:hangman_reimagined/platform/registry/game_registry.dart';

void main() {
  testWidgets('PlayNed App renders platform shell and game cards', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HangmanApp()));
    await tester.pumpAndSettle();

    // Verify PlayNed branding & hero headline is rendered
    expect(find.text('PLAYNED'), findsWidgets);
    expect(find.text('ONE PLATFORM.\nMANY WAYS TO PLAY.'), findsOneWidget);

    // Verify all 6 launch games are in the registry
    expect(PlayNedGameRegistry.allGames.length, 6);
    expect(find.text('Hangman Reimagined'), findsWidgets);
    expect(find.text('Dots & Boxes'), findsWidgets);
    expect(find.text('Quoridor'), findsWidgets);
    expect(find.text('Pentago'), findsWidgets);
    expect(find.text('Shut the Box'), findsWidgets);
    expect(find.text('Cricket Hub'), findsWidgets);
  });
}
