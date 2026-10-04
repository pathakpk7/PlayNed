import 'package:flutter/material.dart';
import '../models/game_model.dart';

class PlayNedGameRegistry {
  static final List<GameMetadata> allGames = [
    const GameMetadata(
      id: 'hangman',
      name: 'Hangman Reimagined',
      tagline: 'A modern, strategic word discovery deduction game.',
      description:
          'Decipher hidden vocabulary words letter-by-letter with word DNA analytics, progressive hints, dynamic combos, 100 level tiers, and 1v1 turn-based duels.',
      category: 'Word / Puzzle',
      minPlayers: 1,
      maxPlayers: 4,
      supportsLocal: true,
      supportsOnline: true,
      supportsTeams: true,
      estimatedDurationMinutes: 3,
      accentColor: Color(0xFFD5A84B),
      backgroundColor: Color(0xFF1E1912),
      icon: Icons.spellcheck,
      rulesSummary: [
        'Guess secret letters one-by-one to reveal the hidden word.',
        'Incorrect letter guesses cost one heart out of 5 total.',
        'Gain multiplier bonuses for consecutive correct letter guesses.',
        'Inspect Word DNA metrics (length, vowel/consonant count, repeated letters).',
        'Progress through 100 escalating difficulty tiers or battle in 1v1 duels.',
      ],
    ),
    const GameMetadata(
      id: 'dots_and_boxes',
      name: 'Dots & Boxes',
      tagline: 'Classic territorial line-drawing strategy.',
      description:
          'Connect adjacent dots with horizontal and vertical lines. Close the 4th wall of any box to claim it for points and earn an immediate extra turn!',
      category: 'Strategy',
      minPlayers: 2,
      maxPlayers: 4,
      supportsLocal: true,
      supportsOnline: true,
      supportsTeams: true,
      estimatedDurationMinutes: 5,
      accentColor: Color(0xFF4E89FF),
      backgroundColor: Color(0xFF0F1B2C),
      icon: Icons.grid_on,
      rulesSummary: [
        'Take turns drawing one line between two adjacent dots.',
        'Horizontal and vertical segments can be placed anywhere on the grid.',
        'When you place the 4th closing line of a box, you capture it and score 1 point.',
        'Capturing a box gives you an immediate bonus turn!',
        'The player with the most captured boxes when the grid is full wins the match.',
      ],
    ),
    const GameMetadata(
      id: 'quoridor',
      name: 'Quoridor',
      tagline: 'Mensa-awarded maze race and tactical wall blocking.',
      description:
          'Navigate your pawn across a 9x9 board to the opposite goal line. On each turn, either advance your pawn or place a 2-space wall to obstruct and divert your opponents—without ever completely sealing off their escape path!',
      category: 'Strategy',
      minPlayers: 2,
      maxPlayers: 4,
      supportsLocal: true,
      supportsOnline: true,
      supportsTeams: false,
      estimatedDurationMinutes: 8,
      accentColor: Color(0xFFE57373),
      backgroundColor: Color(0xFF2A1414),
      icon: Icons.view_quilt,
      rulesSummary: [
        'Start on your baseline. The goal is to reach any cell on the opposite side of the board first.',
        'On your turn, either move your pawn 1 square orthogonally OR place a 2-tile wall.',
        'Walls block passages between squares. They can be oriented horizontally or vertically.',
        'Walls cannot cross or overlap existing walls.',
        'Critical rule: You may NEVER completely block a player\'s path to their goal line.',
        'Pawn jumping: If an opponent is in an adjacent square, you can jump over them.',
      ],
    ),
    const GameMetadata(
      id: 'pentago',
      name: 'Pentago',
      tagline: 'The Mind-Twisting 5-in-a-row game with a rotating twist.',
      description:
          'Place a marble on a 6x6 grid, then twist any of the four 3x3 quadrants 90 degrees. Form 5-in-a-row horizontally, vertically, or diagonally to triumph in this fast Swedish strategy classic.',
      category: 'Board',
      minPlayers: 2,
      maxPlayers: 2,
      supportsLocal: true,
      supportsOnline: true,
      supportsTeams: false,
      estimatedDurationMinutes: 6,
      accentColor: Color(0xFF48BB78),
      backgroundColor: Color(0xFF13231A),
      icon: Icons.rotate_right,
      rulesSummary: [
        'Played on a 6x6 board composed of four rotatable 3x3 quadrants.',
        'Each turn has two phases: (1) Place a marble in any empty cell, (2) Twist any 3x3 quadrant 90° clockwise or counter-clockwise.',
        'Form 5 of your marbles in a row (horizontal, vertical, or diagonal) to win.',
        'A win can be created either during the marble placement or after the twist.',
        'If a rotation creates 5-in-a-row for both players simultaneously, the game ends in a Draw.',
      ],
    ),
    const GameMetadata(
      id: 'shut_the_box',
      name: 'Shut the Box',
      tagline: 'Roll the dice, shut the tiles, and aim for zero penalty points.',
      description:
          'A classic traditional pub and strategy game of dice, math, and risk. Roll the dice and flip down open numbered tiles matching your dice sum. Can you shut the entire box?',
      category: 'Casual / Math',
      minPlayers: 1,
      maxPlayers: 4,
      supportsLocal: true,
      supportsOnline: true,
      supportsTeams: false,
      estimatedDurationMinutes: 4,
      accentColor: Color(0xFFE5A93C),
      backgroundColor: Color(0xFF1D180F),
      icon: Icons.casino,
      rulesSummary: [
        'Numbered tiles (1 to 9) start upright in the open position.',
        'On your turn, roll the dice to get a target sum (e.g. 3 + 5 = 8).',
        'Select any combination of open tiles that add up exactly to the dice sum (e.g. 8, or 1+7, or 3+5, or 1+2+5).',
        'Flipped tiles remain shut for the remainder of your round.',
        'If remaining open tiles sum to 6 or less, you may choose to roll only 1 die.',
        'When no open tiles can equal your dice sum, your turn ends. Your penalty score is the sum of remaining open tiles.',
        'Lowest penalty score wins! Shutting all 9 tiles scores a perfect 0 (Grand Slam Victory)!',
      ],
    ),
    const GameMetadata(
      id: 'cricket',
      name: 'Cricket Hub',
      tagline: 'Super Over duels, tactical Stat Clashes, and trivia challenges.',
      description:
          'The ultimate PlayNed cricket arena. Play fast-paced 6-ball Super Over duels with authentic batsman-bowler tactical matchups, test your cricketing intellect in Stat Clash squad drafting, and conquer the Cricket Challenge Hub with trivia, timelines, and higher/lower battles.',
      category: 'Sports / Strategy',
      minPlayers: 1,
      maxPlayers: 2,
      supportsLocal: true,
      supportsOnline: true,
      supportsTeams: false,
      estimatedDurationMinutes: 5,
      accentColor: Color(0xFFE5A93C),
      backgroundColor: Color(0xFF0C1914),
      icon: Icons.sports_cricket,
      rulesSummary: [
        'Super Over Duel: Pick 2 batters and 1 bowler. Battle in a 6-ball innings. Batters choose shots (Defend, Normal, Attack, Loft) while bowlers pick deliveries (Yorker, Bouncer, Good Length, Full, Slower). Highest score wins.',
        'Stat Clash: Draft a squad of 5 real cricket legends to get closest to the target statistic without busting!',
        'Cricket Challenge Hub: Test your knowledge in Who Am I?, Higher/Lower, Stat or Fiction, and Guess The Legend mini-games.',
      ],
    ),
  ];

  static GameMetadata? getGame(String id) {
    try {
      return allGames.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
