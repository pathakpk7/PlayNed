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
  bool userHasBidOnCurrentPlayer = false;

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
            .toList() {
    for (var f in this.franchises) {
      f.isHuman = (f.id == humanTeamId);
    }
  }

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
      AuctionCategory.marquee,
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

    // Ensure all remaining players from the dataset are included
    final leftovers = remaining.where((p) => !auctionQueue.contains(p)).toList();
    if (leftovers.isNotEmpty) {
      leftovers.shuffle(_rng);
      auctionQueue.addAll(leftovers);
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
        _ensureAllFranchisesReachMinSquad();
        phase = AuctionPhase.squadReview;
        _log('All auction lots concluded! All 10 franchises have secured at least 20 players.');
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
    userHasBidOnCurrentPlayer = false;

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
    userHasBidOnCurrentPlayer = true;

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
    passAndResolveDirectly();
  }

  /// When user clicks Pass:
  /// 1. If user did not bid on this player, winning bid equals the actual real-life IPL bid of the previous year.
  /// 2. If user had bid earlier, resolve remaining AI bids directly.
  /// In both cases, the last bid is directly shown on screen without waiting.
  void passAndResolveDirectly() {
    humanPassedCurrentPlayer = true;
    if (currentPlayer == null) return;

    if (!userHasBidOnCurrentPlayer) {
      _resolveUncontestedLotWithRealLifeBid();
    } else {
      _fastForwardRemainingAIBidding();
    }
  }

  void _resolveUncontestedLotWithRealLifeBid() {
    if (currentPlayer == null) return;

    // Check if player had a real-life IPL winning bid
    if (currentPlayer!.realLifeSoldPrice != null && currentPlayer!.realLifeSoldPrice! > 0) {
      final realPrice = currentPlayer!.realLifeSoldPrice!;
      final candidates = franchises.where((t) => !t.isHuman).toList();
      final eligible = candidates.where((team) =>
        team.canBidFor(currentPlayer!, realPrice, minSlotReserve: config.minReservePerSlot)
      ).toList();

      if (eligible.isNotEmpty) {
        eligible.sort((a, b) {
          final countA = a.squad.where((p) => p.role == currentPlayer!.role).length;
          final countB = b.squad.where((p) => p.role == currentPlayer!.role).length;
          if (countA != countB) return countA.compareTo(countB);
          return b.purseRemaining.compareTo(a.purseRemaining);
        });

        final winner = eligible.first;
        currentBid = realPrice;
        currentBidLeader = winner;
        hammerStage = 3;

        final bid = AuctionBid(
          teamId: winner.id,
          teamName: winner.name,
          amount: realPrice,
          timestamp: DateTime.now(),
        );
        currentBidHistory.insert(0, bid);
        _finalizeCurrentPlayer();
        _log('SOLD! 🔨 ${currentPlayer!.name} sold to ${winner.name} for ₹${realPrice.toStringAsFixed(2)} Cr (Actual Real-Life IPL Bid)');
        return;
      }
    }

    // Player went unsold in real-life IPL or no AI franchise can accommodate:
    currentBidLeader = null;
    hammerStage = 3;
    _finalizeCurrentPlayer();
    _log('UNSOLD: ${currentPlayer!.name} finds no buyer (Real-Life IPL Unsold / Passed).');
  }

  void _fastForwardRemainingAIBidding() {
    int safetyLimit = 30;
    while (safetyLimit-- > 0) {
      final aiBidder = _findInterestedAITeam();
      if (aiBidder == null) break;
      final amount = nextBidAmount;
      currentBid = amount;
      currentBidLeader = aiBidder;
      final bid = AuctionBid(
        teamId: aiBidder.id,
        teamName: aiBidder.name,
        amount: amount,
        timestamp: DateTime.now(),
      );
      currentBidHistory.insert(0, bid);
      _log('BID: ${aiBidder.name} bids ₹${amount.toStringAsFixed(2)} Cr!');
    }
    hammerStage = 3;
    _finalizeCurrentPlayer();
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
    // 1. Hard reserve budget: team must have enough purse left to buy at least 20 players!
    final slotsRemaining = (config.minSquad - team.squadSize).clamp(1, config.minSquad);
    final reserveNeeded = (slotsRemaining - 1) * config.minReservePerSlot;
    final maxAffordable = max(player.basePrice, team.purseRemaining - reserveNeeded);

    double valuation;

    // 2. Realistic price anchor: if player has a real-life IPL price, anchor to it!
    if (player.realLifeSoldPrice != null && player.realLifeSoldPrice! > 0) {
      final realPrice = player.realLifeSoldPrice!;
      double factor = 1.0;
      if (team.personality.starFocus > 0.8 && player.overallRating >= 90) factor += 0.05;
      if (team.personality == AIPersonality.moneyball) factor -= 0.10;
      valuation = realPrice * factor;
    } else {
      // Domestic / uncapped players without real-life sold price:
      // STRICTLY do not overprice! Keep price disciplined and affordable.
      double base = player.basePrice;
      double bonus = ((player.overallRating - 75).clamp(0, 15) * 0.10);
      valuation = base + bonus;
    }

    // Modest role need adjustment
    final roleCount = team.squad.where((p) => p.role == player.role).length;
    if (roleCount < 3) {
      valuation *= 1.05;
    } else if (roleCount >= 6) {
      valuation *= 0.85;
    }

    return valuation.clamp(player.basePrice, maxAffordable);
  }

  void _ensureAllFranchisesReachMinSquad() {
    final available = allPlayers
        .where((p) => p.status == PlayerAuctionStatus.unauctioned || p.status == PlayerAuctionStatus.unsold)
        .toList();

    for (var team in franchises) {
      while (team.squadSize < config.minSquad && available.isNotEmpty) {
        final p = available.firstWhere(
          (cand) => !cand.isOverseas || team.overseasCount < config.maxOverseas,
          orElse: () => available.first,
        );
        available.remove(p);

        final price = min(p.basePrice, max(0.20, team.purseRemaining));
        p.status = PlayerAuctionStatus.sold;
        p.soldPrice = price;
        p.soldToTeamId = team.id;
        p.soldToTeamName = team.name;

        team.addPlayer(p, price);
        if (!soldPlayers.contains(p)) soldPlayers.add(p);
        unsoldPlayers.removeWhere((u) => u.id == p.id);
        _log('${team.name} signed ${p.name} (₹${price.toStringAsFixed(2)} Cr) to meet minimum squad rule of 20 players.');
      }
    }
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

  // ==========================================
  // SLOT TARGETING & DISCOVERY
  // ==========================================

  final Set<String> targetedPlayerIds = {};

  void togglePlayerTarget(String playerId) {
    if (targetedPlayerIds.contains(playerId)) {
      targetedPlayerIds.remove(playerId);
    } else {
      targetedPlayerIds.add(playerId);
    }
  }

  bool isPlayerTargeted(String playerId) => targetedPlayerIds.contains(playerId);

  List<AuctionPlayer> getPlayersInSlot(AuctionCategory category) {
    return allPlayers.where((p) => p.category == category).toList();
  }

  List<AuctionPlayer> getCurrentSlotPlayers() {
    if (currentPlayer == null) return [];
    return getPlayersInSlot(currentPlayer!.category);
  }

  // ==========================================
  // POST-AUCTION TRADING WINDOW (MAX 2 TRADES)
  // ==========================================

  int tradesCompleted = 0;
  static const int maxTradesAllowed = 2;
  int get remainingTrades => (maxTradesAllowed - tradesCompleted).clamp(0, maxTradesAllowed);

  TradeEvaluationResult evaluateTradeProposal({
    required AuctionTeam humanTeam,
    required AuctionPlayer humanPlayer,
    required AuctionTeam targetTeam,
    required AuctionPlayer targetPlayer,
    required TradeMode mode,
    double cashOffered = 0.0,
  }) {
    if (tradesCompleted >= maxTradesAllowed) {
      return const TradeEvaluationResult(
        isAccepted: false,
        reason: 'Maximum trade limit reached: only 2 player exchanges are permitted per franchise.',
      );
    }

    if (!humanTeam.squad.any((p) => p.id == humanPlayer.id)) {
      return const TradeEvaluationResult(
        isAccepted: false,
        reason: 'The offered player is not in your squad roster.',
      );
    }

    if (!targetTeam.squad.any((p) => p.id == targetPlayer.id)) {
      return TradeEvaluationResult(
        isAccepted: false,
        reason: 'The requested player is not in ${targetTeam.name}\'s squad roster.',
      );
    }

    // 1. Overseas cap check
    final humanOsCount = humanTeam.overseasCount -
        (humanPlayer.isOverseas ? 1 : 0) +
        (targetPlayer.isOverseas ? 1 : 0);
    if (humanOsCount > config.maxOverseas) {
      return TradeEvaluationResult(
        isAccepted: false,
        reason: 'Trade would exceed the limit of ${config.maxOverseas} overseas players for ${humanTeam.name}.',
      );
    }

    final targetOsCount = targetTeam.overseasCount -
        (targetPlayer.isOverseas ? 1 : 0) +
        (humanPlayer.isOverseas ? 1 : 0);
    if (targetOsCount > config.maxOverseas) {
      return TradeEvaluationResult(
        isAccepted: false,
        reason: 'Trade would exceed the limit of ${config.maxOverseas} overseas players for ${targetTeam.name}.',
      );
    }

    if (mode == TradeMode.sameAmount) {
      // Pick-price parity swap
      final humanPrice = humanPlayer.soldPrice ?? humanPlayer.basePrice;
      final targetPrice = targetPlayer.soldPrice ?? targetPlayer.basePrice;
      final priceDiff = targetPrice - humanPrice;

      if (priceDiff > 0 && humanTeam.purseRemaining < priceDiff) {
        return TradeEvaluationResult(
          isAccepted: false,
          reason: 'Insufficient purse balance. You need ₹${priceDiff.toStringAsFixed(2)} Cr more to cover the pick amount difference.',
        );
      }

      if (priceDiff < 0 && targetTeam.purseRemaining < -priceDiff) {
        return TradeEvaluationResult(
          isAccepted: false,
          reason: '${targetTeam.name} has insufficient purse (needs ₹${(-priceDiff).toStringAsFixed(2)} Cr) to cover the pick amount difference.',
        );
      }

      return TradeEvaluationResult(
        isAccepted: true,
        reason: 'Trade agreed at pick-price parity. Difference of ₹${priceDiff.abs().toStringAsFixed(2)} Cr adjusted via franchise purse balances.',
        cashAdjustment: priceDiff,
      );
    } else {
      // Mutual Decision (Player + Money)
      if (cashOffered > humanTeam.purseRemaining) {
        return TradeEvaluationResult(
          isAccepted: false,
          reason: 'Cannot offer ₹${cashOffered.toStringAsFixed(2)} Cr. Your purse only has ₹${humanTeam.purseRemaining.toStringAsFixed(2)} Cr remaining.',
        );
      }

      if (cashOffered < 0 && (-cashOffered) > targetTeam.purseRemaining) {
        return TradeEvaluationResult(
          isAccepted: false,
          reason: '${targetTeam.name} does not have sufficient purse to pay ₹${(-cashOffered).toStringAsFixed(2)} Cr.',
        );
      }

      // Valuation based on player ratings and AI personality
      final ratingDelta = (humanPlayer.overallRating - targetPlayer.overallRating).toDouble();
      double ratingValue = ratingDelta * 1.5;

      // Top star protection: AI franchises are reluctant to let go of 92+ rating icons
      if (targetPlayer.overallRating >= 92) {
        ratingValue -= 3.0;
      }
      if (humanPlayer.overallRating >= 90) {
        ratingValue += 2.0;
      }

      // Role scarcity check
      final targetRoleCount = targetTeam.squad.where((p) => p.role == targetPlayer.role).length;
      if (targetRoleCount <= 2) {
        ratingValue -= 2.5;
      }

      final netValuation = ratingValue + cashOffered;

      if (netValuation < -0.25) {
        final deficit = ((-netValuation) * 1.0).clamp(0.5, 25.0);
        return TradeEvaluationResult(
          isAccepted: false,
          reason: '${targetTeam.name} declined this offer. They value ${targetPlayer.name} higher. Add at least ₹${deficit.toStringAsFixed(1)} Cr in purse cash to reach mutual agreement.',
        );
      }

      return TradeEvaluationResult(
        isAccepted: true,
        reason: 'Mutual agreement reached! Both franchises agree to the swap with a ₹${cashOffered.abs().toStringAsFixed(2)} Cr purse adjustment.',
        cashAdjustment: cashOffered,
      );
    }
  }

  bool executeTrade({
    required AuctionTeam humanTeam,
    required AuctionPlayer humanPlayer,
    required AuctionTeam targetTeam,
    required AuctionPlayer targetPlayer,
    required TradeMode mode,
    double cashOffered = 0.0,
  }) {
    final eval = evaluateTradeProposal(
      humanTeam: humanTeam,
      humanPlayer: humanPlayer,
      targetTeam: targetTeam,
      targetPlayer: targetPlayer,
      mode: mode,
      cashOffered: cashOffered,
    );

    if (!eval.isAccepted) return false;

    // Swap players in squads
    humanTeam.removePlayer(humanPlayer);
    targetTeam.removePlayer(targetPlayer);

    humanPlayer.soldToTeamId = targetTeam.id;
    humanPlayer.soldToTeamName = targetTeam.name;

    targetPlayer.soldToTeamId = humanTeam.id;
    targetPlayer.soldToTeamName = humanTeam.name;

    humanTeam.squad.add(targetPlayer);
    targetTeam.squad.add(humanPlayer);

    // Adjust purses
    humanTeam.purseRemaining -= eval.cashAdjustment;
    targetTeam.purseRemaining += eval.cashAdjustment;

    tradesCompleted++;

    _log('TRADE COMPLETED: ${humanTeam.name} exchanged ${humanPlayer.name} with ${targetTeam.name} for ${targetPlayer.name} (${eval.reason})');
    return true;
  }
}
