import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/main.dart';
import 'package:hangman_reimagined/platform/registry/game_registry.dart';
import 'package:hangman_reimagined/platform/presentation/pages/platform_home_page.dart';

void main() {
  testWidgets('PlayNed App renders platform shell and game cards', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HangmanApp()));
    await tester.pumpAndSettle();

    // Verify PlayNed branding is rendered
    expect(find.text('PLAYNED'), findsWidgets);
    expect(find.text('Play something.'), findsOneWidget);

    // Verify all 6 games are in the registry
    expect(PlayNedGameRegistry.allGames.length, 6);
    expect(find.text('Hangman Reimagined'), findsWidgets);
    expect(find.text('Dots & Boxes'), findsWidgets);
    expect(find.text('Quoridor'), findsWidgets);
    expect(find.text('Pentago'), findsWidgets);
    expect(find.text('Shut the Box'), findsWidgets);
    expect(find.text('Cricket Hub'), findsWidgets);
  });
}
