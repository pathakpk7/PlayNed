import 'dart:math';

enum ReversiVariant { othello, reversiClassic }

enum ReversiDifficulty { novice, tactician, grandmaster }

enum SquareType { normal, corner, cSquare, xSquare, edge }

class ReversiCoord {
  final int r;
  final int c;

  const ReversiCoord(this.r, this.c);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReversiCoord && runtimeType == other.runtimeType && r == other.r && c == other.c;

  @override
  int get hashCode => r.hashCode ^ c.hashCode;

  String get notation {
    final colChar = String.fromCharCode('a'.codeUnitAt(0) + c);
    final rowChar = '${r + 1}';
    return '$colChar$rowChar';
  }
}

class ReversiMove {
  final ReversiCoord coord;
  final List<ReversiCoord> flipped;

  const ReversiMove({required this.coord, required this.flipped});

  int get flipCount => flipped.length;
}

class ReversiGameState {
  static const int size = 8;
  static const List<List<int>> directions = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1]
  ];

  // 0 = Empty, 1 = Black (P1), 2 = White (P2)
  final List<List<int>> board;
  final int currentTurnColor; // 1 or 2
  final ReversiVariant variant;
  final int blackCount;
  final int whiteCount;
  final int blackReserves;
  final int whiteReserves;
  final int consecutivePasses;
  final bool isGameOver;
  final int? winnerColor; // 1 = Black, 2 = White, 0 = Draw, null = in progress
  final ReversiCoord? lastMoveCoord;
  final String statusMessage;

  const ReversiGameState({
    required this.board,
    required this.currentTurnColor,
    required this.variant,
    required this.blackCount,
    required this.whiteCount,
    required this.blackReserves,
    required this.whiteReserves,
    required this.consecutivePasses,
    required this.isGameOver,
    required this.winnerColor,
    this.lastMoveCoord,
    required this.statusMessage,
  });

  factory ReversiGameState.initial({ReversiVariant variant = ReversiVariant.othello}) {
    final b = List.generate(size, (_) => List.filled(size, 0));

    // Initial 4 center discs
    // (3,3)=White, (3,4)=Black, (4,3)=Black, (4,4)=White
    b[3][3] = 2;
    b[3][4] = 1;
    b[4][3] = 1;
    b[4][4] = 2;

    return ReversiGameState(
      board: b,
      currentTurnColor: 1, // Black starts
      variant: variant,
      blackCount: 2,
      whiteCount: 2,
      blackReserves: 30,
      whiteReserves: 30,
      consecutivePasses: 0,
      isGameOver: false,
      winnerColor: null,
      lastMoveCoord: null,
      statusMessage: variant == ReversiVariant.othello
          ? "Standard Othello. Black (⚫) moves first. Trap opponent discs to flip them."
          : "Classic Reversi. Black (⚫) moves first with 30 reserve discs.",
    );
  }

  static SquareType classifySquare(int r, int c) {
    if ((r == 0 || r == 7) && (c == 0 || c == 7)) return SquareType.corner;
    if ((r == 1 || r == 6) && (c == 1 || c == 6)) return SquareType.xSquare;
    if ((r == 0 || r == 7) && (c == 1 || c == 6)) return SquareType.cSquare;
    if ((r == 1 || r == 6) && (c == 0 || c == 7)) return SquareType.cSquare;
    if (r == 0 || r == 7 || c == 0 || c == 7) return SquareType.edge;
    return SquareType.normal;
  }

  List<ReversiCoord> getFlippedDiscsForMove(int r, int c, int discColor) {
    if (board[r][c] != 0) return [];
    final opponent = discColor == 1 ? 2 : 1;
    final flipped = <ReversiCoord>[];

    for (final dir in directions) {
      int dr = dir[0];
      int dc = dir[1];
      int curR = r + dr;
      int curC = c + dc;
      final line = <ReversiCoord>[];

      while (curR >= 0 && curR < size && curC >= 0 && curC < size && board[curR][curC] == opponent) {
        line.add(ReversiCoord(curR, curC));
        curR += dr;
        curC += dc;
      }

      if (curR >= 0 && curR < size && curC >= 0 && curC < size && board[curR][curC] == discColor && line.isNotEmpty) {
        flipped.addAll(line);
      }
    }

    return flipped;
  }

  Map<ReversiCoord, List<ReversiCoord>> getLegalMovesForColor(int discColor) {
    final map = <ReversiCoord, List<ReversiCoord>>{};
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final flips = getFlippedDiscsForMove(r, c, discColor);
        if (flips.isNotEmpty) {
          map[ReversiCoord(r, c)] = flips;
        }
      }
    }
    return map;
  }

  Map<ReversiCoord, List<ReversiCoord>> get currentLegalMoves => getLegalMovesForColor(currentTurnColor);

  ReversiGameState applyMove(int r, int c) {
    final flips = getFlippedDiscsForMove(r, c, currentTurnColor);
    if (flips.isEmpty) return this;

    final newBoard = List.generate(size, (row) => List<int>.from(board[row]));
    newBoard[r][c] = currentTurnColor;
    for (final f in flips) {
      newBoard[f.r][f.c] = currentTurnColor;
    }

    int newBCount = 0;
    int newWCount = 0;
    int emptyCount = 0;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (newBoard[row][col] == 1) newBCount++;
        if (newBoard[row][col] == 2) newWCount++;
        if (newBoard[row][col] == 0) emptyCount++;
      }
    }

    final newBReserves = currentTurnColor == 1 ? max(0, blackReserves - 1) : blackReserves;
    final newWReserves = currentTurnColor == 2 ? max(0, whiteReserves - 1) : whiteReserves;

    final nextColor = currentTurnColor == 1 ? 2 : 1;
    final nextStateTemp = ReversiGameState(
      board: newBoard,
      currentTurnColor: nextColor,
      variant: variant,
      blackCount: newBCount,
      whiteCount: newWCount,
      blackReserves: newBReserves,
      whiteReserves: newWReserves,
      consecutivePasses: 0,
      isGameOver: false,
      winnerColor: null,
      lastMoveCoord: ReversiCoord(r, c),
      statusMessage: "",
    );

    final nextLegal = nextStateTemp.getLegalMovesForColor(nextColor);
    final currLegal = nextStateTemp.getLegalMovesForColor(currentTurnColor);

    // End conditions
    if (emptyCount == 0 || newBCount == 0 || newWCount == 0 || (nextLegal.isEmpty && currLegal.isEmpty)) {
      int? winner;
      if (newBCount > newWCount) winner = 1;
      if (newWCount > newBCount) winner = 2;
      if (newBCount == newWCount) winner = 0;

      final winMsg = winner == 1
          ? "Victory! Black (⚫) wins ($newBCount - $newWCount)!"
          : (winner == 2
              ? "Victory! White (⚪) wins ($newWCount - $newBCount)!"
              : "Game Drawn ($newBCount - $newWCount)!");

      return ReversiGameState(
        board: newBoard,
        currentTurnColor: nextColor,
        variant: variant,
        blackCount: newBCount,
        whiteCount: newWCount,
        blackReserves: newBReserves,
        whiteReserves: newWReserves,
        consecutivePasses: 0,
        isGameOver: true,
        winnerColor: winner,
        lastMoveCoord: ReversiCoord(r, c),
        statusMessage: winMsg,
      );
    }

    // Auto-pass if next player has no legal moves
    if (nextLegal.isEmpty) {
      final playerName = nextColor == 1 ? "Black (⚫)" : "White (⚪)";
      return ReversiGameState(
        board: newBoard,
        currentTurnColor: currentTurnColor, // remains with current player
        variant: variant,
        blackCount: newBCount,
        whiteCount: newWCount,
        blackReserves: newBReserves,
        whiteReserves: newWReserves,
        consecutivePasses: 1,
        isGameOver: false,
        winnerColor: null,
        lastMoveCoord: ReversiCoord(r, c),
        statusMessage: "$playerName had no legal moves and passed. Your turn again!",
      );
    }

    final activeName = nextColor == 1 ? "Black (⚫)" : "White (⚪)";
    return ReversiGameState(
      board: newBoard,
      currentTurnColor: nextColor,
      variant: variant,
      blackCount: newBCount,
      whiteCount: newWCount,
      blackReserves: newBReserves,
      whiteReserves: newWReserves,
      consecutivePasses: 0,
      isGameOver: false,
      winnerColor: null,
      lastMoveCoord: ReversiCoord(r, c),
      statusMessage: "$activeName's turn (${nextLegal.length} legal moves available).",
    );
  }
}

/// Advanced Strategic AI for Reversi & Othello
class ReversiAI {
  static const List<List<int>> positionalWeights = [
    [ 100, -20,  10,   5,   5,  10, -20,  100],
    [-20,  -50,  -2,  -2,  -2,  -2, -50,  -20],
    [  10,  -2,  -1,  -1,  -1,  -1,  -2,   10],
    [   5,  -2,  -1,   0,   0,  -1,  -2,    5],
    [   5,  -2,  -1,   0,   0,  -1,  -2,    5],
    [  10,  -2,  -1,  -1,  -1,  -1,  -2,   10],
    [-20,  -50,  -2,  -2,  -2,  -2, -50,  -20],
    [ 100, -20,  10,   5,   5,  10, -20,  100],
  ];

  static ReversiCoord? selectMove(ReversiGameState state, ReversiDifficulty difficulty) {
    final legalMoves = state.currentLegalMoves;
    if (legalMoves.isEmpty) return null;

    switch (difficulty) {
      case ReversiDifficulty.novice:
        return _selectNoviceMove(legalMoves);
      case ReversiDifficulty.tactician:
        return _selectTacticianMove(state, legalMoves);
      case ReversiDifficulty.grandmaster:
        return _selectGrandmasterMove(state, legalMoves);
    }
  }

  static ReversiCoord _selectNoviceMove(Map<ReversiCoord, List<ReversiCoord>> moves) {
    final random = Random();
    final keys = moves.keys.toList();
    return keys[random.nextInt(keys.length)];
  }

  static ReversiCoord _selectTacticianMove(ReversiGameState state, Map<ReversiCoord, List<ReversiCoord>> moves) {
    ReversiCoord? bestMove;
    int bestScore = -999999;

    for (final entry in moves.entries) {
      final coord = entry.key;
      final flips = entry.value;

      // Base weight from positional table
      int score = positionalWeights[coord.r][coord.c];

      // Corner capture is overwhelmingly good
      if (ReversiGameState.classifySquare(coord.r, coord.c) == SquareType.corner) {
        score += 200;
      }

      // If corner is already taken by friendly disc, C-Square and X-Square are safe
      if (ReversiGameState.classifySquare(coord.r, coord.c) == SquareType.cSquare ||
          ReversiGameState.classifySquare(coord.r, coord.c) == SquareType.xSquare) {
        score -= 40;
      }

      // Factor flips slightly
      score += flips.length * 2;

      if (score > bestScore) {
        bestScore = score;
        bestMove = coord;
      }
    }

    return bestMove ?? moves.keys.first;
  }

  static ReversiCoord _selectGrandmasterMove(ReversiGameState state, Map<ReversiCoord, List<ReversiCoord>> moves) {
    ReversiCoord? bestMove;
    int bestValue = -999999;

    final myColor = state.currentTurnColor;

    for (final entry in moves.entries) {
      final coord = entry.key;
      final nextState = state.applyMove(coord.r, coord.c);

      // Minimax evaluation with depth 3
      final val = _minimax(nextState, depth: 3, alpha: -999999, beta: 999999, originalColor: myColor);

      if (val > bestValue) {
        bestValue = val;
        bestMove = coord;
      }
    }

    return bestMove ?? _selectTacticianMove(state, moves);
  }

  static int _minimax(ReversiGameState state, {
    required int depth,
    required int alpha,
    required int beta,
    required int originalColor,
  }) {
    if (depth == 0 || state.isGameOver) {
      return _evaluateState(state, originalColor);
    }

    final legalMoves = state.currentLegalMoves;
    if (legalMoves.isEmpty) {
      return _evaluateState(state, originalColor);
    }

    final isMaximizing = state.currentTurnColor == originalColor;

    if (isMaximizing) {
      int maxEval = -999999;
      for (final move in legalMoves.keys) {
        final next = state.applyMove(move.r, move.c);
        final eval = _minimax(next, depth: depth - 1, alpha: alpha, beta: beta, originalColor: originalColor);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (final move in legalMoves.keys) {
        final next = state.applyMove(move.r, move.c);
        final eval = _minimax(next, depth: depth - 1, alpha: alpha, beta: beta, originalColor: originalColor);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  static int _evaluateState(ReversiGameState state, int originalColor) {
    final opponentColor = originalColor == 1 ? 2 : 1;

    if (state.isGameOver) {
      if (state.winnerColor == originalColor) return 50000;
      if (state.winnerColor == opponentColor) return -50000;
      return 0;
    }

    int positionalScore = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final disc = state.board[r][c];
        if (disc == originalColor) {
          positionalScore += positionalWeights[r][c];
        } else if (disc == opponentColor) {
          positionalScore -= positionalWeights[r][c];
        }
      }
    }

    // Mobility advantage (number of legal moves)
    final myMoves = state.getLegalMovesForColor(originalColor).length;
    final oppMoves = state.getLegalMovesForColor(opponentColor).length;
    final mobilityScore = (myMoves - oppMoves) * 15;

    // Disc Count (in early/mid game, keeping lower piece count is advantageous)
    final totalDiscs = state.blackCount + state.whiteCount;
    int discScore = 0;
    if (totalDiscs > 50) {
      // Endgame: grab maximum discs
      final myCount = originalColor == 1 ? state.blackCount : state.whiteCount;
      final oppCount = originalColor == 1 ? state.whiteCount : state.blackCount;
      discScore = (myCount - oppCount) * 10;
    }

    return positionalScore + mobilityScore + discScore;
  }
}
