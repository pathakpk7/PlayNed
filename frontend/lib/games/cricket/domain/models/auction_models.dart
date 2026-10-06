import 'package:flutter/material.dart';

enum AuctionPhase {
  setup,
  marqueeDraft,
  retention,
  liveAuction,
  accelerated,
  squadReview,
  completed,
}

enum PlayerAuctionStatus {
  unauctioned,
  inAuction,
  sold,
  unsold,
  retained,
  marqueeDrafted,
}

enum AuctionCategory {
  marquee,
  batters,
  wicketkeepers,
  allRounders,
  fastBowlers,
  spinBowlers,
  uncapped,
  overseas,
  emerging;

  String get displayName {
    switch (this) {
      case AuctionCategory.marquee:
        return 'MARQUEE SET';
      case AuctionCategory.batters:
        return 'SPECIALIST BATTERS';
      case AuctionCategory.wicketkeepers:
        return 'WICKETKEEPERS';
      case AuctionCategory.allRounders:
        return 'ALL-ROUNDERS';
      case AuctionCategory.fastBowlers:
        return 'PACE BATTERY';
      case AuctionCategory.spinBowlers:
        return 'SPIN ATTACK';
      case AuctionCategory.uncapped:
        return 'UNCAPPED TALENT';
      case AuctionCategory.overseas:
        return 'OVERSEAS STARS';
      case AuctionCategory.emerging:
        return 'EMERGING PROSPECTS';
    }
  }
}

class AuctionPlayer {
  final String id;
  final String name;
  final String country;
  final String nationality;
  final String role; // 'Batter', 'Wicketkeeper', 'All-Rounder', 'Bowler'
  final String primaryRole;
  final String? secondaryRole;
  final String battingStyle;
  final String bowlingStyle;
  final String cappedStatus; // 'Capped', 'Uncapped'
  final bool isOverseas;
  final double basePrice; // in Crores, e.g. 2.0, 1.5, 0.5, 0.3
  final int battingRating;
  final int bowlingRating;
  final int fieldingRating;
  final int overallRating;
  final String currentForm; // 'Peak', 'Excellent', 'Good', 'Average'
  final int age;
  final String auctionYears; // e.g. '2024, 2025, 2026'
  final String shortDescription;
  final AuctionCategory category;
  final Color avatarColor;

  // Mutable auction runtime state
  PlayerAuctionStatus status;
  double? soldPrice;
  String? soldToTeamId;
  String? soldToTeamName;

  AuctionPlayer({
    required this.id,
    required this.name,
    required this.country,
    required this.nationality,
    required this.role,
    required this.primaryRole,
    this.secondaryRole,
    required this.battingStyle,
    required this.bowlingStyle,
    required this.cappedStatus,
    required this.isOverseas,
    required this.basePrice,
    required this.battingRating,
    required this.bowlingRating,
    required this.fieldingRating,
    required this.overallRating,
    required this.currentForm,
    required this.age,
    required this.auctionYears,
    required this.shortDescription,
    required this.category,
    required this.avatarColor,
    this.status = PlayerAuctionStatus.unauctioned,
    this.soldPrice,
    this.soldToTeamId,
    this.soldToTeamName,
  });

  AuctionPlayer copyWith({
    PlayerAuctionStatus? status,
    double? soldPrice,
    String? soldToTeamId,
    String? soldToTeamName,
  }) {
    return AuctionPlayer(
      id: id,
      name: name,
      country: country,
      nationality: nationality,
      role: role,
      primaryRole: primaryRole,
      secondaryRole: secondaryRole,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      cappedStatus: cappedStatus,
      isOverseas: isOverseas,
      basePrice: basePrice,
      battingRating: battingRating,
      bowlingRating: bowlingRating,
      fieldingRating: fieldingRating,
      overallRating: overallRating,
      currentForm: currentForm,
      age: age,
      auctionYears: auctionYears,
      shortDescription: shortDescription,
      category: category,
      avatarColor: avatarColor,
      status: status ?? this.status,
      soldPrice: soldPrice ?? this.soldPrice,
      soldToTeamId: soldToTeamId ?? this.soldToTeamId,
      soldToTeamName: soldToTeamName ?? this.soldToTeamName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'nationality': nationality,
        'role': role,
        'primaryRole': primaryRole,
        'secondaryRole': secondaryRole,
        'battingStyle': battingStyle,
        'bowlingStyle': bowlingStyle,
        'cappedStatus': cappedStatus,
        'isOverseas': isOverseas,
        'basePrice': basePrice,
        'battingRating': battingRating,
        'bowlingRating': bowlingRating,
        'fieldingRating': fieldingRating,
        'overallRating': overallRating,
        'currentForm': currentForm,
        'age': age,
        'auctionYears': auctionYears,
        'shortDescription': shortDescription,
        'category': category.name,
        'status': status.name,
        'soldPrice': soldPrice,
        'soldToTeamId': soldToTeamId,
        'soldToTeamName': soldToTeamName,
      };
}

class AIPersonality {
  final String name;
  final double aggression; // 0.0 to 1.0 (propensity to bid aggressively in bidding wars)
  final double starFocus; // 0.0 to 1.0 (preference for marquee & top-rated 90+ stars)
  final double paceBias; // 0.0 to 1.0 (priority on fast bowlers)
  final double spinBias; // 0.0 to 1.0 (priority on spinners)
  final double youthBias; // 0.0 to 1.0 (priority on uncapped / emerging players)
  final double purseDiscipline; // 0.0 to 1.0 (strictness regarding remaining purse per slot)

  const AIPersonality({
    required this.name,
    this.aggression = 0.5,
    this.starFocus = 0.5,
    this.paceBias = 0.5,
    this.spinBias = 0.5,
    this.youthBias = 0.5,
    this.purseDiscipline = 0.7,
  });

  static const balanced = AIPersonality(
    name: 'Balanced Pragmatist',
    aggression: 0.55,
    starFocus: 0.6,
    paceBias: 0.5,
    spinBias: 0.5,
    youthBias: 0.5,
    purseDiscipline: 0.75,
  );

  static const starHunter = AIPersonality(
    name: 'Marquee Hunter',
    aggression: 0.85,
    starFocus: 0.95,
    paceBias: 0.5,
    spinBias: 0.5,
    youthBias: 0.3,
    purseDiscipline: 0.45,
  );

  static const paceSpecialist = AIPersonality(
    name: 'Pace Battery Builder',
    aggression: 0.65,
    starFocus: 0.65,
    paceBias: 0.9,
    spinBias: 0.35,
    youthBias: 0.45,
    purseDiscipline: 0.7,
  );

  static const spinKing = AIPersonality(
    name: 'Spin Web Tactician',
    aggression: 0.6,
    starFocus: 0.6,
    paceBias: 0.35,
    spinBias: 0.95,
    youthBias: 0.5,
    purseDiscipline: 0.75,
  );

  static const moneyball = AIPersonality(
    name: 'Moneyball Analytics',
    aggression: 0.35,
    starFocus: 0.3,
    paceBias: 0.6,
    spinBias: 0.6,
    youthBias: 0.85,
    purseDiscipline: 0.9,
  );
}

class AuctionTeam {
  final String id;
  final String name;
  final String shortName;
  final String city;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String motto;
  final IconData logoIcon;
  final AIPersonality personality;
  bool isHuman;

  double purseRemaining; // in Crores
  final List<AuctionPlayer> squad;
  final List<AuctionPlayer> retentions;

  AuctionTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.city,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.motto,
    required this.logoIcon,
    this.personality = AIPersonality.balanced,
    this.isHuman = false,
    this.purseRemaining = 120.0,
    List<AuctionPlayer>? squad,
    List<AuctionPlayer>? retentions,
  })  : squad = squad ?? [],
        retentions = retentions ?? [];

  int get overseasCount => squad.where((p) => p.isOverseas).length;
  int get squadSize => squad.length;
  int get availableSlots => 25 - squadSize;
  int get slotsNeededForMinSquad => (18 - squadSize).clamp(0, 18);

  bool canBidFor(AuctionPlayer player, double nextBid, {double minSlotReserve = 0.20}) {
    // 1. Max squad cap check
    if (squadSize >= 25) return false;

    // 2. Overseas limit check (max 8)
    if (player.isOverseas && overseasCount >= 8) return false;

    // 3. Absolute purse check
    if (purseRemaining < nextBid) return false;

    // 4. Reserve buffer check: must keep at least 0.20 Cr for each slot to reach min squad (18)
    final slotsRemainingAfterThis = (18 - (squadSize + 1)).clamp(0, 18);
    final requiredPurseBuffer = slotsRemainingAfterThis * minSlotReserve;
    if ((purseRemaining - nextBid) < requiredPurseBuffer) return false;

    return true;
  }

  void addPlayer(AuctionPlayer player, double price) {
    purseRemaining -= price;
    squad.add(player);
  }

  void removePlayer(AuctionPlayer player) {
    squad.removeWhere((p) => p.id == player.id);
  }

  static bool isWicketkeeperPlayer(AuctionPlayer p) =>
      p.role == 'Wicketkeeper' ||
      p.category == AuctionCategory.wicketkeepers ||
      p.primaryRole.toLowerCase().contains('keeper') ||
      p.primaryRole.toLowerCase().contains('gloveman');

  static bool isSpinnerPlayer(AuctionPlayer p) {
    final s = p.bowlingStyle.toLowerCase();
    final r = p.primaryRole.toLowerCase();
    return p.category == AuctionCategory.spinBowlers ||
        s.contains('spin') ||
        s.contains('orthodox') ||
        s.contains('chinaman') ||
        r.contains('spin');
  }

  static bool isFastBowlerPlayer(AuctionPlayer p) {
    if (isSpinnerPlayer(p)) return false;
    final s = p.bowlingStyle.toLowerCase();
    final r = p.primaryRole.toLowerCase();
    return p.category == AuctionCategory.fastBowlers ||
        (p.role == 'Bowler' && !isSpinnerPlayer(p)) ||
        s.contains('fast') ||
        s.contains('pace') ||
        s.contains('medium') ||
        r.contains('fast') ||
        r.contains('pace') ||
        r.contains('seamer');
  }

  static bool isBatterPlayer(AuctionPlayer p) {
    if (isWicketkeeperPlayer(p)) return false;
    return p.role == 'Batter' || p.category == AuctionCategory.batters;
  }

  static bool isAllRounderPlayer(AuctionPlayer p) {
    if (isWicketkeeperPlayer(p)) return false;
    return p.role == 'All-Rounder' || p.category == AuctionCategory.allRounders;
  }

  List<AuctionPlayer> get batters => squad.where(isBatterPlayer).toList();
  List<AuctionPlayer> get wicketkeepers => squad.where(isWicketkeeperPlayer).toList();
  List<AuctionPlayer> get fastBowlers => squad.where(isFastBowlerPlayer).toList();
  List<AuctionPlayer> get spinners => squad.where(isSpinnerPlayer).toList();
  List<AuctionPlayer> get allRounders => squad.where(isAllRounderPlayer).toList();

  double get battingStrength {
    if (squad.isEmpty) return 0;
    final bats = squad.where((p) => p.role == 'Batter' || p.role == 'All-Rounder' || p.role == 'Wicketkeeper').toList();
    if (bats.isEmpty) return 0;
    bats.sort((a, b) => b.battingRating.compareTo(a.battingRating));
    final top = bats.take(6);
    return top.map((p) => p.battingRating).reduce((a, b) => a + b) / top.length;
  }

  double get bowlingStrength {
    if (squad.isEmpty) return 0;
    final bowls = squad.where((p) => p.role == 'Bowler' || p.role == 'All-Rounder').toList();
    if (bowls.isEmpty) return 0;
    bowls.sort((a, b) => b.bowlingRating.compareTo(a.bowlingRating));
    final top = bowls.take(5);
    return top.map((p) => p.bowlingRating).reduce((a, b) => a + b) / top.length;
  }

  double get overallSquadScore {
    if (squad.isEmpty) return 0;
    final bat = battingStrength;
    final bowl = bowlingStrength;
    final depthBonus = (squadSize >= 18 ? 5.0 : 0.0) + (squadSize >= 20 ? 3.0 : 0.0);
    final overseasBonus = (overseasCount >= 5 && overseasCount <= 8) ? 4.0 : 1.0;
    return (bat * 0.45 + bowl * 0.45 + depthBonus + overseasBonus).clamp(0, 99.9);
  }
}

enum TradeMode {
  sameAmount,
  mutualDecision,
}

class TradeEvaluationResult {
  final bool isAccepted;
  final String reason;
  final double cashAdjustment;

  const TradeEvaluationResult({
    required this.isAccepted,
    required this.reason,
    this.cashAdjustment = 0.0,
  });
}

class AuctionBid {
  final String teamId;
  final String teamName;
  final double amount;
  final DateTime timestamp;

  const AuctionBid({
    required this.teamId,
    required this.teamName,
    required this.amount,
    required this.timestamp,
  });
}

class AuctionRulesConfig {
  final double initialPurse; // 120.0 Cr
  final int minSquad; // 18
  final int maxSquad; // 25
  final int maxOverseas; // 8
  final int maxPlayingXIOverseas; // 4
  final int maxRetentions; // 4 (marquee counts as 1)
  final List<double> retentionSlabs; // [18.0, 14.0, 11.0, 9.0]
  final double minReservePerSlot; // 0.20 Cr

  const AuctionRulesConfig({
    this.initialPurse = 120.0,
    this.minSquad = 18,
    this.maxSquad = 25,
    this.maxOverseas = 8,
    this.maxPlayingXIOverseas = 4,
    this.maxRetentions = 4,
    this.retentionSlabs = const [18.0, 14.0, 11.0, 9.0],
    this.minReservePerSlot = 0.20,
  });

  /// Standard IPL auction bid increment based on current price slabs
  static double getNextIncrement(double currentBid) {
    if (currentBid < 1.0) {
      return 0.20; // 20 Lakhs
    } else if (currentBid < 2.0) {
      return 0.25; // 25 Lakhs
    } else if (currentBid < 5.0) {
      return 0.50; // 50 Lakhs
    } else if (currentBid < 10.0) {
      return 0.50; // 50 Lakhs
    } else {
      return 1.00; // 1 Crore
    }
  }

  static double calculateNextBid(double currentBid) {
    return currentBid + getNextIncrement(currentBid);
  }
}

class PlayingXIResult {
  final List<AuctionPlayer> playingXI;
  final AuctionPlayer? impactPlayer;
  final List<AuctionPlayer> bench;
  final int overseasInXI;
  final double xiBattingRating;
  final double xiBowlingRating;

  const PlayingXIResult({
    required this.playingXI,
    this.impactPlayer,
    required this.bench,
    required this.overseasInXI,
    required this.xiBattingRating,
    required this.xiBowlingRating,
  });
}
