import 'dart:math';
import '../models/auction_models.dart';
import '../../data/auction_dataset.dart';

class AuctionEngine {
  final AuctionRulesConfig config;
  final List<AuctionTeam> franchises;
  String humanTeamId;
  String aiDifficulty; // 'Easy', 'Normal', 'Hard'

  AuctionPhase phase = AuctionPhase.setup;
  final List<AuctionPlayer> allPlayers;
  final List<AuctionPlayer> marqueePool;
  final List<AuctionPlayer> auctionQueue = [];
  final List<AuctionPlayer> acceleratedQueue = [];
  final List<AuctionPlayer> soldPlayers = [];
  final List<AuctionPlayer> unsoldPlayers = [];

  AuctionPlayer? currentPlayer;
  double currentBid = 0.0;
  AuctionTeam? currentBidLeader;
  final List<AuctionBid> currentBidHistory = [];
  int hammerStage = 0; // 0: Live, 1: Going Once, 2: Going Twice, 3: Sold / Unsold
  bool humanPassedCurrentPlayer = false;

  final List<String> activityLog = [];
  final Random _rng = Random();

  AuctionEngine({
    AuctionRulesConfig? config,
    List<AuctionTeam>? franchises,
    this.humanTeamId = 'mumbai_mariners',
    this.aiDifficulty = 'Normal',
  })  : config = config ?? const AuctionRulesConfig(),
        franchises = franchises ?? AuctionDataset.getInitialFranchises(),
        allPlayers = AuctionDataset.getAllAuctionPlayers(),
        marqueePool = AuctionDataset.getAllAuctionPlayers()
            .where((p) => p.category == AuctionCategory.marquee)
            .toList();

  AuctionTeam get humanTeam =>
      franchises.firstWhere((t) => t.id == humanTeamId, orElse: () => franchises.first);

  void setHumanTeam(String teamId) {
    humanTeamId = teamId;
    for (var f in franchises) {
      f.isHuman = (f.id == teamId);
    }
    _log('Manager selected franchise: ${humanTeam.name}');
  }

  void _log(String message) {
    activityLog.insert(0, message);
    if (activityLog.length > 50) {
      activityLog.removeLast();
    }
  }

  // ==========================================
  // PHASE 1: MARQUEE DRAFT
  // ==========================================

  void startMarqueePhase() {
    phase = AuctionPhase.marqueeDraft;
    _log('Phase Started: Elite Marquee Player Selection');
  }

  bool selectHumanMarquee(AuctionPlayer player) {
    if (player.status != PlayerAuctionStatus.unauctioned) return false;
    if (humanTeam.squad.isNotEmpty) return false;

    const marqueePrice = 18.0; // Slab 1
    player.status = PlayerAuctionStatus.marqueeDrafted;
    player.soldPrice = marqueePrice;
    player.soldToTeamId = humanTeam.id;
    player.soldToTeamName = humanTeam.name;

    humanTeam.addPlayer(player, marqueePrice);
    humanTeam.retentions.add(player);
    soldPlayers.add(player);

    _log('${humanTeam.name} drafted Marquee Icon: ${player.name} for ₹${marqueePrice.toStringAsFixed(1)} Cr');

    // Simulate AI Marquee selections
    _simulateAIMarqueeSelections();
    phase = AuctionPhase.retention;
    _log('All 10 Franchises selected their Marquee Icon. Entering Retention Phase.');
    return true;
  }

  void _simulateAIMarqueeSelections() {
    final availableMarquees = marqueePool
        .where((p) => p.status == PlayerAuctionStatus.unauctioned)
        .toList();

    for (var team in franchises) {
      if (team.isHuman || team.squad.isNotEmpty) continue;
      if (availableMarquees.isEmpty) break;

      // Pick best fitting marquee for personality
      availableMarquees.sort((a, b) {
        double scoreA = a.overallRating.toDouble();
        double scoreB = b.overallRating.toDouble();

        if (team.personality.paceBias > 0.7) {
          if (a.role == 'Bowler' && a.bowlingStyle.contains('fast')) scoreA += 5;
          if (b.role == 'Bowler' && b.bowlingStyle.contains('fast')) scoreB += 5;
        }
        if (team.personality.spinBias > 0.7) {
          if (a.bowlingStyle.contains('spin')) scoreA += 5;
          if (b.bowlingStyle.contains('spin')) scoreB += 5;
        }
        return scoreB.compareTo(scoreA);
      });

      final chosen = availableMarquees.removeAt(0);
      const marqueePrice = 18.0;
      chosen.status = PlayerAuctionStatus.marqueeDrafted;
      chosen.soldPrice = marqueePrice;
      chosen.soldToTeamId = team.id;
      chosen.soldToTeamName = team.name;

      team.addPlayer(chosen, marqueePrice);
      team.retentions.add(chosen);
      soldPlayers.add(chosen);
      _log('${team.name} drafted Marquee Icon: ${chosen.name} (₹18.0 Cr)');
    }
  }

  // ==========================================
  // PHASE 2: RETENTIONS (MAX 4 TOTAL INCL MARQUEE)
  // ==========================================

  List<AuctionPlayer> getAvailablePlayersForRetention() {
    return allPlayers
        .where((p) =>
            p.status == PlayerAuctionStatus.unauctioned &&
            p.category != AuctionCategory.marquee)
        .toList();
  }

  double getNextRetentionCost(AuctionTeam team) {
    final retentionCount = team.retentions.length;
    if (retentionCount >= config.maxRetentions) return 0.0;
    return config.retentionSlabs[retentionCount];
  }

  bool canRetainMore(AuctionTeam team) {
    if (team.retentions.length >= config.maxRetentions) return false;
    final cost = getNextRetentionCost(team);
    return team.canBidFor(
      allPlayers.first,
      cost,
      minSlotReserve: config.minReservePerSlot,
    );
  }

  bool retainPlayerForHuman(AuctionPlayer player) {
    if (!canRetainMore(humanTeam)) return false;
    if (player.status != PlayerAuctionStatus.unauctioned) return false;
    if (player.isOverseas && humanTeam.overseasCount >= config.maxOverseas) return false;

    final cost = getNextRetentionCost(humanTeam);
    player.status = PlayerAuctionStatus.retained;
    player.soldPrice = cost;
    player.soldToTeamId = humanTeam.id;
    player.soldToTeamName = humanTeam.name;

    humanTeam.addPlayer(player, cost);
    humanTeam.retentions.add(player);
    soldPlayers.add(player);

    _log('${humanTeam.name} retained ${player.name} for ₹${cost.toStringAsFixed(1)} Cr (Slot ${humanTeam.retentions.length}/4)');
    return true;
  }

  void finalizeRetentionsAndStartLiveAuction() {
    _simulateAIRetentions();
    _buildAuctionQueue();
    phase = AuctionPhase.liveAuction;
    nextPlayerInAuction();
  }

  void _simulateAIRetentions() {
    final candidates = getAvailablePlayersForRetention();

    for (var team in franchises) {
      if (team.isHuman) continue;

      // AI decides to retain 1 to 3 additional core players
      int targetRetentions = 2; // Default 3 total
      if (team.personality == AIPersonality.starHunter) targetRetentions = 3;
      if (team.personality == AIPersonality.moneyball) targetRetentions = 1;

      while (team.retentions.length < (targetRetentions + 1) && canRetainMore(team)) {
        candidates.sort((a, b) => b.overallRating.compareTo(a.overallRating));
        if (candidates.isEmpty) break;

        final chosen = candidates.removeAt(0);
        final cost = getNextRetentionCost(team);

        chosen.status = PlayerAuctionStatus.retained;
        chosen.soldPrice = cost;
        chosen.soldToTeamId = team.id;
        chosen.soldToTeamName = team.name;

        team.addPlayer(chosen, cost);
        team.retentions.add(chosen);
        soldPlayers.add(chosen);
        _log('${team.name} retained ${chosen.name} (₹${cost.toStringAsFixed(1)} Cr)');
      }
    }
  }

  void _buildAuctionQueue() {
    auctionQueue.clear();
    final remaining = allPlayers
        .where((p) => p.status == PlayerAuctionStatus.unauctioned)
        .toList();

    // Group into Sets progressively
    final categories = [
      AuctionCategory.batters,
      AuctionCategory.wicketkeepers,
      AuctionCategory.allRounders,
      AuctionCategory.fastBowlers,
      AuctionCategory.spinBowlers,
      AuctionCategory.uncapped,
      AuctionCategory.overseas,
      AuctionCategory.emerging,
    ];

    for (var cat in categories) {
      final inCat = remaining.where((p) => p.category == cat).toList();
      inCat.shuffle(_rng);
      auctionQueue.addAll(inCat);
    }
  }

  // ==========================================
  // PHASE 3: LIVE AUCTION & BIDDING
  // ==========================================

  bool nextPlayerInAuction() {
    if (auctionQueue.isEmpty) {
      if (acceleratedQueue.isNotEmpty && phase != AuctionPhase.accelerated) {
        phase = AuctionPhase.accelerated;
        auctionQueue.addAll(acceleratedQueue);
        acceleratedQueue.clear();
        _log('Entering ACCELERATED AUCTION ROUND for unsold players.');
      } else {
        phase = AuctionPhase.squadReview;
        _log('All auction lots concluded! Proceeding to Squad Analysis.');
        return false;
      }
    }

    currentPlayer = auctionQueue.removeAt(0);
    currentPlayer!.status = PlayerAuctionStatus.inAuction;
    currentBid = currentPlayer!.basePrice;
    currentBidLeader = null;
    currentBidHistory.clear();
    hammerStage = 0;
    humanPassedCurrentPlayer = false;

    _log('Lot #${soldPlayers.length + unsoldPlayers.length + 1}: ${currentPlayer!.name} (${currentPlayer!.role}, Base: ₹${currentBid.toStringAsFixed(2)} Cr)');
    return true;
  }

  double get nextBidAmount {
    if (currentBidLeader == null) {
      return currentPlayer?.basePrice ?? 0.20;
    }
    return AuctionRulesConfig.calculateNextBid(currentBid);
  }

  bool canHumanBid() {
    if (currentPlayer == null || humanPassedCurrentPlayer) return false;
    if (currentBidLeader?.id == humanTeam.id) return false;
    return humanTeam.canBidFor(
      currentPlayer!,
      nextBidAmount,
      minSlotReserve: config.minReservePerSlot,
    );
  }

  bool placeHumanBid() {
    if (!canHumanBid()) return false;
    final amount = nextBidAmount;

    currentBid = amount;
    currentBidLeader = humanTeam;
    hammerStage = 0;

    final bid = AuctionBid(
      teamId: humanTeam.id,
      teamName: humanTeam.name,
      amount: amount,
      timestamp: DateTime.now(),
    );
    currentBidHistory.insert(0, bid);

    _log('BID: ${humanTeam.name} bids ₹${amount.toStringAsFixed(2)} Cr!');
    return true;
  }

  void humanPass() {
    humanPassedCurrentPlayer = true;
    _log('${humanTeam.name} passed on ${currentPlayer?.name}');
  }

  /// Evaluates whether an AI team wants to outbid
  AuctionTeam? _findInterestedAITeam() {
    if (currentPlayer == null) return null;
    final targetBid = nextBidAmount;

    final candidates = franchises.where((t) => !t.isHuman).toList()..shuffle(_rng);

    for (var team in candidates) {
      if (team.id == currentBidLeader?.id) continue;
      if (!team.canBidFor(currentPlayer!, targetBid, minSlotReserve: config.minReservePerSlot)) {
        continue;
      }

      // Valuation formula
      double maxValuation = _calculateValuation(team, currentPlayer!);

      // Difficulty modifier
      if (aiDifficulty == 'Easy') {
        maxValuation *= 0.85;
      } else if (aiDifficulty == 'Hard') {
        maxValuation *= 1.15;
      }

      if (targetBid <= maxValuation) {
        return team;
      }
    }
    return null;
  }

  double _calculateValuation(AuctionTeam team, AuctionPlayer player) {
    double base = player.basePrice;
    double ratingMultiplier = (player.overallRating - 75).clamp(1, 25).toDouble();

    // Star player price ceiling
    double valuation = base + (ratingMultiplier * 0.7);

    if (player.overallRating >= 95) valuation += 6.0;
    else if (player.overallRating >= 90) valuation += 3.5;
    else if (player.overallRating >= 85) valuation += 1.5;

    // AI personality modifiers
    if (team.personality.starFocus > 0.8 && player.overallRating >= 90) {
      valuation *= 1.25;
    }
    if (team.personality.paceBias > 0.8 && player.bowlingStyle.contains('fast')) {
      valuation *= 1.20;
    }
    if (team.personality.spinBias > 0.8 && player.bowlingStyle.contains('spin')) {
      valuation *= 1.20;
    }
    if (team.personality.youthBias > 0.8 && player.cappedStatus == 'Uncapped') {
      valuation *= 1.30;
    }

    // Role need check
    final roleCount = team.squad.where((p) => p.role == player.role).length;
    if (roleCount < 3) {
      valuation *= 1.15; // In urgent need of this role
    } else if (roleCount >= 6) {
      valuation *= 0.70; // Surplus
    }

    // Purse discipline
    final purseRatio = team.purseRemaining / 120.0;
    valuation *= (0.7 + (purseRatio * 0.5));

    return valuation.clamp(player.basePrice, team.purseRemaining);
  }

  /// Advance the auction hammer or accept AI bid
  /// Returns false if lot ended (sold/unsold), true if still in bidding
  bool tickAuctionTimer() {
    if (currentPlayer == null) return false;

    // First check if an AI team bids
    final aiBidder = _findInterestedAITeam();
    if (aiBidder != null) {
      final amount = nextBidAmount;
      currentBid = amount;
      currentBidLeader = aiBidder;
      hammerStage = 0; // Reset hammer

      final bid = AuctionBid(
        teamId: aiBidder.id,
        teamName: aiBidder.name,
        amount: amount,
        timestamp: DateTime.now(),
      );
      currentBidHistory.insert(0, bid);

      _log('BID: ${aiBidder.name} bids ₹${amount.toStringAsFixed(2)} Cr!');
      return true;
    }

    // No one placed a new bid; advance hammer
    hammerStage++;

    if (hammerStage == 1) {
      _log('Going ONCE at ₹${currentBid.toStringAsFixed(2)} Cr...');
      return true;
    } else if (hammerStage == 2) {
      _log('Going TWICE at ₹${currentBid.toStringAsFixed(2)} Cr...');
      return true;
    } else {
      // Hammer falls!
      _finalizeCurrentPlayer();
      return false;
    }
  }

  void _finalizeCurrentPlayer() {
    if (currentPlayer == null) return;

    if (currentBidLeader != null) {
      // SOLD!
      final winner = currentBidLeader!;
      currentPlayer!.status = PlayerAuctionStatus.sold;
      currentPlayer!.soldPrice = currentBid;
      currentPlayer!.soldToTeamId = winner.id;
      currentPlayer!.soldToTeamName = winner.name;

      winner.addPlayer(currentPlayer!, currentBid);
      soldPlayers.add(currentPlayer!);

      _log('SOLD! 🔨 ${currentPlayer!.name} sold to ${winner.name} for ₹${currentBid.toStringAsFixed(2)} Cr!');
    } else {
      // UNSOLD
      currentPlayer!.status = PlayerAuctionStatus.unsold;
      unsoldPlayers.add(currentPlayer!);
      if (phase != AuctionPhase.accelerated) {
        acceleratedQueue.add(currentPlayer!);
      }
      _log('UNSOLD: ${currentPlayer!.name} finds no buyer at ₹${currentBid.toStringAsFixed(2)} Cr.');
    }
  }

  // ==========================================
  // PHASE 4: SQUAD SUMMARY & PLAYING XI
  // ==========================================

  PlayingXIResult selectBestPlayingXI(AuctionTeam team) {
    final squad = List<AuctionPlayer>.from(team.squad);
    final playingXI = <AuctionPlayer>[];
    final bench = <AuctionPlayer>[];

    int overseasCount = 0;

    // 1. Pick primary Wicketkeeper
    final keepers = squad.where((p) => p.role == 'Wicketkeeper').toList();
    keepers.sort((a, b) => b.battingRating.compareTo(a.battingRating));

    if (keepers.isNotEmpty) {
      final wk = keepers.first;
      playingXI.add(wk);
      squad.remove(wk);
      if (wk.isOverseas) overseasCount++;
    }

    // 2. Pick top 4 batters
    final batters = squad.where((p) => p.role == 'Batter').toList();
    batters.sort((a, b) => b.battingRating.compareTo(a.battingRating));

    for (var b in batters) {
      if (playingXI.where((p) => p.role == 'Batter').length >= 4) break;
      if (b.isOverseas && overseasCount >= 4) continue;
      playingXI.add(b);
      squad.remove(b);
      if (b.isOverseas) overseasCount++;
    }

    // 3. Pick top 2 all-rounders
    final allRounders = squad.where((p) => p.role == 'All-Rounder').toList();
    allRounders.sort((a, b) => (b.battingRating + b.bowlingRating).compareTo(a.battingRating + a.bowlingRating));

    for (var ar in allRounders) {
      if (playingXI.where((p) => p.role == 'All-Rounder').length >= 2) break;
      if (ar.isOverseas && overseasCount >= 4) continue;
      playingXI.add(ar);
      squad.remove(ar);
      if (ar.isOverseas) overseasCount++;
    }

    // 4. Pick top 4 bowlers
    final bowlers = squad.where((p) => p.role == 'Bowler').toList();
    bowlers.sort((a, b) => b.bowlingRating.compareTo(a.bowlingRating));

    for (var bowl in bowlers) {
      if (playingXI.where((p) => p.role == 'Bowler').length >= 4) break;
      if (bowl.isOverseas && overseasCount >= 4) continue;
      playingXI.add(bowl);
      squad.remove(bowl);
      if (bowl.isOverseas) overseasCount++;
    }

    // Fill remaining spots up to 11 if any category fell short
    squad.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    for (var p in List<AuctionPlayer>.from(squad)) {
      if (playingXI.length >= 11) break;
      if (p.isOverseas && overseasCount >= 4) continue;
      playingXI.add(p);
      squad.remove(p);
      if (p.isOverseas) overseasCount++;
    }

    // Impact Player: highest overall player remaining on bench
    AuctionPlayer? impactPlayer;
    if (squad.isNotEmpty) {
      impactPlayer = squad.first;
      squad.removeAt(0);
    }
    bench.addAll(squad);

    final xiBatRating = playingXI.isEmpty
        ? 0.0
        : playingXI.map((p) => p.battingRating).reduce((a, b) => a + b) / playingXI.length;
    final xiBowlRating = playingXI.isEmpty
        ? 0.0
        : playingXI.map((p) => p.bowlingRating).reduce((a, b) => a + b) / playingXI.length;

    return PlayingXIResult(
      playingXI: playingXI,
      impactPlayer: impactPlayer,
      bench: bench,
      overseasInXI: overseasCount,
      xiBattingRating: xiBatRating,
      xiBowlingRating: xiBowlRating,
    );
  }

  Map<String, dynamic> generateAuctionAwards() {
    if (soldPlayers.isEmpty) return {};

    final sortedByPrice = List<AuctionPlayer>.from(soldPlayers)
      ..sort((a, b) => (b.soldPrice ?? 0).compareTo(a.soldPrice ?? 0));

    final highestBuy = sortedByPrice.first;

    // Value steal: highest rating per crore
    final steals = List<AuctionPlayer>.from(soldPlayers)
      ..sort((a, b) {
        double valA = a.overallRating / (a.soldPrice ?? 1.0);
        double valB = b.overallRating / (b.soldPrice ?? 1.0);
        return valB.compareTo(valA);
      });
    final biggestSteal = steals.first;

    // Best squad: highest overall score
    final sortedTeams = List<AuctionTeam>.from(franchises)
      ..sort((a, b) => b.overallSquadScore.compareTo(a.overallSquadScore));

    return {
      'highestBuy': highestBuy,
      'biggestSteal': biggestSteal,
      'championSquad': sortedTeams.first,
      'mostPurseLeft': (List<AuctionTeam>.from(franchises)..sort((a, b) => b.purseRemaining.compareTo(a.purseRemaining))).first,
    };
  }
}
