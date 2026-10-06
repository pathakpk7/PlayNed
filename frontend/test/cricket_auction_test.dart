import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangman_reimagined/games/cricket/data/auction_dataset.dart';
import 'package:hangman_reimagined/games/cricket/domain/models/auction_models.dart';
import 'package:hangman_reimagined/games/cricket/domain/services/auction_engine.dart';

void main() {
  group('IPL Mini Auction Domain & Engine Tests', () {
    test('Initializes with 10 fictional franchises and ₹120.0 Cr purse each', () {
      final engine = AuctionEngine();
      expect(engine.franchises.length, equals(10));
      for (final team in engine.franchises) {
        expect(team.purseRemaining, equals(120.0));
        expect(team.squad.isEmpty, isTrue);
        expect(team.retentions.isEmpty, isTrue);
        expect(team.overseasCount, equals(0));
      }
    });

    test('Curated auction pool contains marquee players and active IPL stars', () {
      final players = AuctionDataset.getAllAuctionPlayers();
      expect(players.length, greaterThanOrEqualTo(30));

      final marquee = players.where((p) => p.category == AuctionCategory.marquee).toList();
      expect(marquee.length, greaterThanOrEqualTo(10));

      // Key stars exist with valid active stats
      final kohli = players.firstWhere((p) => p.id == 'shreyas_iyer');
      expect(kohli.name, equals('Shreyas Iyer'));
      expect(kohli.isOverseas, isFalse);
      expect(kohli.cappedStatus, equals('Capped'));
      expect(kohli.basePrice, equals(2.0));

      final bumrah = players.firstWhere((p) => p.id == 'mohammad_shami');
      expect(bumrah.bowlingRating, greaterThanOrEqualTo(85));

      final klaasen = players.firstWhere((p) => p.id == 'jos_buttler');
      expect(klaasen.isOverseas, isTrue);
    });

    test('Marquee Phase: Selection costs ₹18.0 Cr and AI franchises pick 1 marquee icon each', () {
      final engine = AuctionEngine();
      engine.setHumanTeam('mumbai_mariners');
      engine.startMarqueePhase();

      final kohli = engine.marqueePool.firstWhere((p) => p.id == 'shreyas_iyer');
      final selected = engine.selectHumanMarquee(kohli);
      expect(selected, isTrue);

      // Human team check
      final human = engine.humanTeam;
      expect(human.squad.length, equals(1));
      expect(human.retentions.length, equals(1));
      expect(human.purseRemaining, equals(102.0)); // 120 - 18
      expect(human.squad.first.name, equals('Shreyas Iyer'));

      // All 10 teams must have drafted exactly 1 marquee player
      for (final team in engine.franchises) {
        expect(team.squad.length, equals(1));
        expect(team.retentions.length, equals(1));
        expect(team.purseRemaining, equals(102.0));
      }
    });

    test('Retention Phase: Maximum 4 players total (marquee counts as #1)', () {
      final engine = AuctionEngine();
      engine.setHumanTeam('mumbai_mariners');
      engine.startMarqueePhase();
      final kohli = engine.marqueePool.firstWhere((p) => p.id == 'shreyas_iyer');
      engine.selectHumanMarquee(kohli);

      // Next retention cost should be Slab 2: ₹14.0 Cr
      expect(engine.getNextRetentionCost(engine.humanTeam), equals(14.0));

      final available = engine.getAvailablePlayersForRetention();
      final p1 = available[0];
      final r1 = engine.retainPlayerForHuman(p1);
      expect(r1, isTrue);
      expect(engine.humanTeam.retentions.length, equals(2));
      expect(engine.humanTeam.purseRemaining, equals(102.0 - 14.0)); // 88.0 Cr

      // Next retention cost should be Slab 3: ₹11.0 Cr
      expect(engine.getNextRetentionCost(engine.humanTeam), equals(11.0));
      final p2 = available[1];
      engine.retainPlayerForHuman(p2);
      expect(engine.humanTeam.retentions.length, equals(3));
      expect(engine.humanTeam.purseRemaining, equals(88.0 - 11.0)); // 77.0 Cr

      // Next retention cost should be Slab 4: ₹9.0 Cr
      expect(engine.getNextRetentionCost(engine.humanTeam), equals(9.0));
      final p3 = available[2];
      engine.retainPlayerForHuman(p3);
      expect(engine.humanTeam.retentions.length, equals(4));
      expect(engine.humanTeam.purseRemaining, equals(77.0 - 9.0)); // 68.0 Cr

      // 5th retention MUST be rejected
      expect(engine.canRetainMore(engine.humanTeam), isFalse);
      final p4 = available[3];
      final r4 = engine.retainPlayerForHuman(p4);
      expect(r4, isFalse);
    });

    test('Bidding increments follow standard slabs', () {
      expect(AuctionRulesConfig.getNextIncrement(0.50), equals(0.20));
      expect(AuctionRulesConfig.getNextIncrement(1.50), equals(0.25));
      expect(AuctionRulesConfig.getNextIncrement(3.00), equals(0.50));
      expect(AuctionRulesConfig.getNextIncrement(8.00), equals(0.50));
      expect(AuctionRulesConfig.getNextIncrement(12.00), equals(1.00));
    });

    test('Purse reserve protection prevents teams from becoming unable to fill min squad (18)', () {
      final team = AuctionTeam(
        id: 'test_team',
        name: 'Test Team',
        shortName: 'TT',
        city: 'Test',
        primaryColor: const Color(0xFF000000),
        secondaryColor: const Color(0xFFFFFFFF),
        accentColor: const Color(0xFF000000),
        motto: 'Test Motto',
        logoIcon: const IconData(0),
        purseRemaining: 5.0, // only 5 Cr left
      );
      // Team currently has only 2 players. Needs 16 more slots to reach 18.
      // 16 slots * 0.20 Cr = 3.20 Cr reserve required!
      // Bidding 3.0 Cr would leave 2.0 Cr < 3.20 Cr -> should be rejected!
      final player = AuctionPlayer(
        id: 'test_p',
        name: 'Test Star',
        country: 'India',
        nationality: 'Indian',
        role: 'Batter',
        primaryRole: 'Batter',
        battingStyle: 'Right-hand',
        bowlingStyle: 'None',
        cappedStatus: 'Capped',
        isOverseas: false,
        basePrice: 2.0,
        battingRating: 90,
        bowlingRating: 40,
        fieldingRating: 80,
        overallRating: 88,
        currentForm: 'Good',
        age: 28,
        auctionYears: '2024',
        shortDescription: 'Test',
        category: AuctionCategory.batters,
        avatarColor: const Color(0xFF000000),
      );

      expect(team.canBidFor(player, 3.5), isFalse);
      // Bidding 1.0 Cr leaves 4.0 Cr > 3.0 Cr reserve -> should be allowed
      expect(team.canBidFor(player, 1.0), isTrue);
    });

    test('Overseas rule enforces max 8 in squad', () {
      final team = AuctionTeam(
        id: 'test_team',
        name: 'Test Team',
        shortName: 'TT',
        city: 'Test',
        primaryColor: const Color(0xFF000000),
        secondaryColor: const Color(0xFFFFFFFF),
        accentColor: const Color(0xFF000000),
        motto: 'Test Motto',
        logoIcon: const IconData(0),
        purseRemaining: 80.0,
      );

      final osPlayer = AuctionPlayer(
        id: 'os_p',
        name: 'OS Star',
        country: 'Australia',
        nationality: 'Overseas',
        role: 'Batter',
        primaryRole: 'Batter',
        battingStyle: 'Right-hand',
        bowlingStyle: 'None',
        cappedStatus: 'Capped',
        isOverseas: true,
        basePrice: 2.0,
        battingRating: 90,
        bowlingRating: 40,
        fieldingRating: 80,
        overallRating: 88,
        currentForm: 'Good',
        age: 28,
        auctionYears: '2024',
        shortDescription: 'Test',
        category: AuctionCategory.batters,
        avatarColor: const Color(0xFF000000),
      );

      // Add 8 overseas players
      for (int i = 0; i < 8; i++) {
        team.addPlayer(osPlayer, 2.0);
      }
      expect(team.overseasCount, equals(8));

      // 9th overseas bid must be rejected
      expect(team.canBidFor(osPlayer, 2.0), isFalse);
    });

    test('Playing XI generator selects maximum 4 overseas and 1 impact player', () {
      final engine = AuctionEngine();
      final team = engine.humanTeam;

      // Add a mix of 18 players
      for (final p in engine.allPlayers.take(18)) {
        team.addPlayer(p, p.basePrice);
      }

      final xiResult = engine.selectBestPlayingXI(team);
      expect(xiResult.playingXI.length, equals(11));
      expect(xiResult.overseasInXI, lessThanOrEqualTo(4));
      expect(xiResult.impactPlayer, isNotNull);
      expect(xiResult.xiBattingRating, greaterThan(0));
      expect(xiResult.xiBowlingRating, greaterThan(0));
    });

    test('Slot player retrieval and bookmarking targets', () {
      final engine = AuctionEngine();
      final batterSlot = engine.getPlayersInSlot(AuctionCategory.batters);
      expect(batterSlot, isNotEmpty);
      for (final p in batterSlot) {
        expect(p.category, equals(AuctionCategory.batters));
      }

      final p = batterSlot.first;
      expect(engine.isPlayerTargeted(p.id), isFalse);
      engine.togglePlayerTarget(p.id);
      expect(engine.isPlayerTargeted(p.id), isTrue);
      engine.togglePlayerTarget(p.id);
      expect(engine.isPlayerTargeted(p.id), isFalse);
    });

    test('Categorized squad building correctly groups batters, bowlers, spinners, and WK', () {
      final engine = AuctionEngine();
      final team = engine.humanTeam;

      final kohli = engine.allPlayers.firstWhere((p) => p.id == 'shreyas_iyer'); // Batter
      final bumrah = engine.allPlayers.firstWhere((p) => p.id == 'mohammad_shami'); // Fast Bowler
      final chahal = engine.allPlayers.firstWhere((p) => p.id == 'yuzvendra_chahal'); // Spinner
      final klaasen = engine.allPlayers.firstWhere((p) => p.id == 'jos_buttler'); // WK

      team.addPlayer(kohli, 18.0);
      team.addPlayer(bumrah, 14.0);
      team.addPlayer(chahal, 10.0);
      team.addPlayer(klaasen, 12.0);

      expect(team.batters.any((p) => p.id == 'shreyas_iyer'), isTrue);
      expect(team.fastBowlers.any((p) => p.id == 'mohammad_shami'), isTrue);
      expect(team.spinners.any((p) => p.id == 'yuzvendra_chahal'), isTrue);
      expect(team.wicketkeepers.any((p) => p.id == 'jos_buttler'), isTrue);
    });

    test('Post-Auction Trading: Direct Swap (Same Pick Amount)', () {
      final engine = AuctionEngine();
      final human = engine.humanTeam;
      final targetTeam = engine.franchises.firstWhere((t) => t.id != human.id);

      final p1 = engine.allPlayers.firstWhere((p) => p.id == 'shreyas_iyer');
      p1.soldPrice = 18.0;
      human.addPlayer(p1, 18.0);

      final p2 = engine.allPlayers.firstWhere((p) => p.id == 'rishabh_pant');
      p2.soldPrice = 16.0;
      targetTeam.addPlayer(p2, 16.0);

      final eval = engine.evaluateTradeProposal(
        humanTeam: human,
        humanPlayer: p1,
        targetTeam: targetTeam,
        targetPlayer: p2,
        mode: TradeMode.sameAmount,
      );

      expect(eval.isAccepted, isTrue);
      expect(eval.cashAdjustment, equals(-2.0)); // 16 - 18 = -2.0 (human receives 2.0 Cr difference)

      final success = engine.executeTrade(
        humanTeam: human,
        humanPlayer: p1,
        targetTeam: targetTeam,
        targetPlayer: p2,
        mode: TradeMode.sameAmount,
      );

      expect(success, isTrue);
      expect(engine.tradesCompleted, equals(1));
      expect(engine.remainingTrades, equals(1));
      expect(human.squad.any((p) => p.id == 'rishabh_pant'), isTrue);
      expect(human.squad.any((p) => p.id == 'shreyas_iyer'), isFalse);
      expect(targetTeam.squad.any((p) => p.id == 'shreyas_iyer'), isTrue);
    });

    test('Post-Auction Trading: Mutual Decision with Cash Sweetener and max 2 trades limit', () {
      final engine = AuctionEngine();
      final human = engine.humanTeam;
      final targetTeam = engine.franchises.firstWhere((t) => t.id != human.id);

      // Trade 1: Low rated player for top star without cash -> AI declines
      final sortedIndian = List<AuctionPlayer>.from(engine.allPlayers.where((p) => !p.isOverseas))
        ..sort((a, b) => a.overallRating.compareTo(b.overallRating));
      final lowPlayer = sortedIndian.firstWhere((p) => p.overallRating >= 90);
      final starPlayer = sortedIndian.firstWhere((p) => p.overallRating >= 93 && p.id != lowPlayer.id);

      human.addPlayer(lowPlayer, 10.0);
      targetTeam.addPlayer(starPlayer, 14.0);

      final unfairEval = engine.evaluateTradeProposal(
        humanTeam: human,
        humanPlayer: lowPlayer,
        targetTeam: targetTeam,
        targetPlayer: starPlayer,
        mode: TradeMode.mutualDecision,
        cashOffered: 0.0,
      );
      expect(unfairEval.isAccepted, isFalse);

      // Offer ₹10.0 Cr cash sweetener -> AI agrees
      final fairEval = engine.evaluateTradeProposal(
        humanTeam: human,
        humanPlayer: lowPlayer,
        targetTeam: targetTeam,
        targetPlayer: starPlayer,
        mode: TradeMode.mutualDecision,
        cashOffered: 10.0,
      );
      expect(fairEval.isAccepted, isTrue);

      // Execute Trade 1
      engine.executeTrade(
        humanTeam: human,
        humanPlayer: lowPlayer,
        targetTeam: targetTeam,
        targetPlayer: starPlayer,
        mode: TradeMode.mutualDecision,
        cashOffered: 10.0,
      );
      expect(engine.tradesCompleted, equals(1));
      expect(engine.remainingTrades, equals(1));

      // Execute Trade 2
      final pA = engine.allPlayers.firstWhere((p) => p.id == 'mohammad_shami');
      final pB = engine.allPlayers.firstWhere((p) => p.id == 'pat_cummins');
      human.addPlayer(pA, 14.0);
      targetTeam.addPlayer(pB, 14.0);

      engine.executeTrade(
        humanTeam: human,
        humanPlayer: pA,
        targetTeam: targetTeam,
        targetPlayer: pB,
        mode: TradeMode.sameAmount,
      );
      expect(engine.tradesCompleted, equals(2));
      expect(engine.remainingTrades, equals(0));

      // Attempt Trade 3 -> Must be rejected due to max 2 trades cap
      final extraEval = engine.evaluateTradeProposal(
        humanTeam: human,
        humanPlayer: starPlayer,
        targetTeam: targetTeam,
        targetPlayer: lowPlayer,
        mode: TradeMode.sameAmount,
      );
      expect(extraEval.isAccepted, isFalse);
      expect(extraEval.reason.contains('Maximum trade limit reached'), isTrue);
    });
  });
}
