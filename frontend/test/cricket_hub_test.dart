import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/cricket/presentation/pages/cricket_hub_page.dart';

void main() {
  testWidgets('Cricket Hub displays IPL Mini Auction and other modes with equal height rows', (tester) async {
    // Set a wide screen size (1200 x 900) to trigger desktop grid mode
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CricketHubPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 5 mode titles are displayed
    expect(find.text('IPL MINI AUCTION'), findsOneWidget);
    expect(find.text('SUPER OVER DUEL'), findsOneWidget);
    expect(find.text('STAT CLASH'), findsOneWidget);
    expect(find.text('CRICKET DRAFT'), findsOneWidget);
    expect(find.text('CRICKET CHALLENGE HUB'), findsOneWidget);

    // Verify presence of IntrinsicHeight widgets ensuring equal card heights in desktop rows
    expect(find.byType(IntrinsicHeight), findsWidgets);
  });
}
