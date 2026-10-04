import 'package:flutter/material.dart';

class CricketPlayer {
  final String id;
  final String name;
  final String country;
  final String role; // Batter, Bowler, All-Rounder, Wicket-Keeper
  final String battingStyle;
  final String bowlingStyle;
  final int draftCost; // Price in credits for 100 budget draft
  
  final int battingRating;
  final int timing;
  final int power;
  final int consistency;
  
  final int bowlingRating;
  final int pace;
  final int variation;
  final int accuracy;

  // Test Cricket Statistics
  final int testRuns;
  final int testWickets;
  final int testMatches;
  final double testAverage;
  final String testHighScore;
  final int testCenturies;
  final int testFiveWickets;

  // ODI Cricket Statistics
  final int odiRuns;
  final int odiWickets;
  final int odiMatches;
  final double odiAverage;
  final double odiStrikeRate;
  final int odiCenturies;
  final int odiFifties;
  final String odiBestBowling;
  final double odiEconomy;

  // T20I Cricket Statistics
  final int t20iRuns;
  final int t20iWickets;
  final int t20iMatches;
  final double t20iAverage;
  final double t20iStrikeRate;
  final double t20iEconomy;

  // Career Totals & Extras
  final int internationalRuns;
  final int internationalWickets;
  final int internationalCenturies;
  final int internationalSixes;
  final int internationalCatches;
  final int wkDismissals;
  final int wkStumpings;
  final int captaincyMatches;
  final int captaincyWins;
  final String careerSpan;
  final Color avatarColor;

  const CricketPlayer({
    required this.id,
    required this.name,
    required this.country,
    required this.role,
    required this.battingStyle,
    required this.bowlingStyle,
    this.draftCost = 20,
    required this.battingRating,
    required this.timing,
    required this.power,
    required this.consistency,
    required this.bowlingRating,
    required this.pace,
    required this.variation,
    required this.accuracy,
    this.testRuns = 0,
    this.testWickets = 0,
    this.testMatches = 0,
    this.testAverage = 0.0,
    this.testHighScore = '0',
    this.testCenturies = 0,
    this.testFiveWickets = 0,
    this.odiRuns = 0,
    this.odiWickets = 0,
    this.odiMatches = 0,
    this.odiAverage = 0.0,
    this.odiStrikeRate = 0.0,
    this.odiCenturies = 0,
    this.odiFifties = 0,
    this.odiBestBowling = '0/0',
    this.odiEconomy = 0.0,
    this.t20iRuns = 0,
    this.t20iWickets = 0,
    this.t20iMatches = 0,
    this.t20iAverage = 0.0,
    this.t20iStrikeRate = 0.0,
    this.t20iEconomy = 0.0,
    this.internationalRuns = 0,
    this.internationalWickets = 0,
    this.internationalCenturies = 0,
    this.internationalSixes = 0,
    this.internationalCatches = 0,
    this.wkDismissals = 0,
    this.wkStumpings = 0,
    this.captaincyMatches = 0,
    this.captaincyWins = 0,
    required this.careerSpan,
    required this.avatarColor,
  });

  int getStatValue(String key) {
    switch (key) {
      case 'odi_runs':
        return odiRuns;
      case 'odi_wickets':
        return odiWickets;
      case 'odi_centuries':
        return odiCenturies;
      case 'odi_fifties':
        return odiFifties;
      case 'odi_matches':
        return odiMatches;
      case 'test_runs':
        return testRuns;
      case 'test_wickets':
        return testWickets;
      case 'test_centuries':
        return testCenturies;
      case 'test_matches':
        return testMatches;
      case 'test_five_wickets':
        return testFiveWickets;
      case 't20i_runs':
        return t20iRuns;
      case 't20i_wickets':
        return t20iWickets;
      case 't20i_matches':
        return t20iMatches;
      case 'international_runs':
        return internationalRuns;
      case 'international_wickets':
        return internationalWickets;
      case 'international_centuries':
        return internationalCenturies;
      case 'international_sixes':
        return internationalSixes;
      case 'international_catches':
        return internationalCatches;
      case 'wk_dismissals':
        return wkDismissals;
      case 'wk_stumpings':
        return wkStumpings;
      case 'captaincy_matches':
        return captaincyMatches;
      case 'captaincy_wins':
        return captaincyWins;
      case 'batting_rating':
        return battingRating;
      case 'bowling_rating':
        return bowlingRating;
      case 'draft_cost':
        return draftCost;
      default:
        return 0;
    }
  }
}

class DeliveryRecord {
  final int ballNumber;
  final String bowlerId;
  final String batterId;
  final String deliveryType;
  final String shotType;
  final int runs;
  final bool isWicket;
  final String outcome;
  final String commentary;

  const DeliveryRecord({
    required this.ballNumber,
    required this.bowlerId,
    required this.batterId,
    required this.deliveryType,
    required this.shotType,
    required this.runs,
    required this.isWicket,
    required this.outcome,
    required this.commentary,
  });

  factory DeliveryRecord.fromJson(Map<String, dynamic> json) {
    return DeliveryRecord(
      ballNumber: json['ball_number'] as int? ?? 1,
      bowlerId: json['bowler_id'] as String? ?? '',
      batterId: json['batter_id'] as String? ?? '',
      deliveryType: json['delivery_type'] as String? ?? 'GOOD_LENGTH',
      shotType: json['shot_type'] as String? ?? 'NORMAL',
      runs: json['runs'] as int? ?? 0,
      isWicket: json['is_wicket'] as bool? ?? false,
      outcome: json['outcome'] as String? ?? '0',
      commentary: json['commentary'] as String? ?? '',
    );
  }
}
