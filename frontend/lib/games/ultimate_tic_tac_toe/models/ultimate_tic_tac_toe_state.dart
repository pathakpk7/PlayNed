class MicroBoardState {
  final int index;
  final List<String?> cells;
  final String? winner; // null, "X", "O", "draw"
  final String status; // "active", "won", "draw"
  final List<int>? winningLine;

  const MicroBoardState({
    required this.index,
    required this.cells,
    this.winner,
    this.status = 'active',
    this.winningLine,
  });

  bool get isCompleted => winner != null || cells.every((c) => c != null);

  factory MicroBoardState.initial(int index) {
    return MicroBoardState(
      index: index,
      cells: List.generate(9, (_) => null),
      winner: null,
      status: 'active',
      winningLine: null,
    );
  }

  factory MicroBoardState.fromJson(Map<String, dynamic> json) {
    final rawCells = json['cells'] as List<dynamic>? ?? [];
    return MicroBoardState(
      index: json['index'] ?? 0,
      cells: rawCells.map((c) => c?.toString()).toList(),
      winner: json['winner']?.toString(),
      status: json['status']?.toString() ?? 'active',
      winningLine: (json['winning_line'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'cells': cells,
      'winner': winner,
      'status': status,
      'winning_line': winningLine,
    };
  }

  MicroBoardState copyWith({
    int? index,
    List<String?>? cells,
    String? winner,
    String? status,
    List<int>? winningLine,
  }) {
    return MicroBoardState(
      index: index ?? this.index,
      cells: cells ?? List<String?>.from(this.cells),
      winner: winner ?? this.winner,
      status: status ?? this.status,
      winningLine: winningLine ?? this.winningLine,
    );
  }
}

class UltimateTicTacToeState {
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final Map<String, String> playerSymbols;
  final List<MicroBoardState> boards;
  final List<String?> macroBoard;
  final List<int>? macroWinningLine;
  final int currentTurnIndex;
  final String currentTurnPlayerId;
  final String currentSymbol;
  final int? nextBoard; // null = FREE MOVE, 0..8 = forced board
  final List<Map<String, dynamic>> moveHistory;
  final int turnNumber;
  final String status; // "in_progress", "won", "draw"
  final String? winnerId;
  final String? winnerName;
  final String? winnerSymbol;
  final int xBoardsWon;
  final int oBoardsWon;
  final Map<String, dynamic>? lastMove;
  final String lastAction;

  const UltimateTicTacToeState({
    required this.playerIds,
    required this.playerNames,
    required this.playerSymbols,
    required this.boards,
    required this.macroBoard,
    this.macroWinningLine,
    required this.currentTurnIndex,
    required this.currentTurnPlayerId,
    required this.currentSymbol,
    this.nextBoard,
    required this.moveHistory,
    required this.turnNumber,
    required this.status,
    this.winnerId,
    this.winnerName,
    this.winnerSymbol,
    required this.xBoardsWon,
    required this.oBoardsWon,
    this.lastMove,
    required this.lastAction,
  });

  bool get isFreeMove => nextBoard == null;

  List<int> get validBoards {
    if (status != 'in_progress') return [];
    if (nextBoard != null && nextBoard! >= 0 && nextBoard! < 9) {
      if (!boards[nextBoard!].isCompleted) {
        return [nextBoard!];
      }
    }
    return [
      for (int i = 0; i < 9; i++)
        if (!boards[i].isCompleted) i
    ];
  }

  factory UltimateTicTacToeState.initial({
    String p1Id = 'p1',
    String p2Id = 'p2',
    String p1Name = 'Player X',
    String p2Name = 'Player O',
  }) {
    return UltimateTicTacToeState(
      playerIds: [p1Id, p2Id],
      playerNames: {p1Id: p1Name, p2Id: p2Name},
      playerSymbols: {p1Id: 'X', p2Id: 'O'},
      boards: List.generate(9, (i) => MicroBoardState.initial(i)),
      macroBoard: List.generate(9, (_) => null),
      macroWinningLine: null,
      currentTurnIndex: 0,
      currentTurnPlayerId: p1Id,
      currentSymbol: 'X',
      nextBoard: null, // Free Move to start anywhere
      moveHistory: [],
      turnNumber: 0,
      status: 'in_progress',
      winnerId: null,
      winnerName: null,
      winnerSymbol: null,
      xBoardsWon: 0,
      oBoardsWon: 0,
      lastMove: null,
      lastAction: 'Match started. $p1Name (X) has Free Move to start anywhere.',
    );
  }

  factory UltimateTicTacToeState.fromJson(Map<String, dynamic> json) {
    final rawBoards = json['boards'] as List<dynamic>? ?? [];
    final rawMacro = json['macro_board'] as List<dynamic>? ?? [];
    final rawHistory = json['move_history'] as List<dynamic>? ?? [];

    return UltimateTicTacToeState(
      playerIds: List<String>.from(json['player_ids'] ?? ['p1', 'p2']),
      playerNames: Map<String, String>.from(json['player_names'] ?? {}),
      playerSymbols: Map<String, String>.from(json['player_symbols'] ?? {}),
      boards: rawBoards
          .map((b) => MicroBoardState.fromJson(b as Map<String, dynamic>))
          .toList(),
      macroBoard: rawMacro.map((m) => m?.toString()).toList(),
      macroWinningLine: (json['macro_winning_line'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      currentTurnIndex: json['current_turn_index'] ?? 0,
      currentTurnPlayerId: json['current_turn_player_id'] ?? 'p1',
      currentSymbol: json['current_symbol'] ?? 'X',
      nextBoard: json['next_board'] != null ? (json['next_board'] as num).toInt() : null,
      moveHistory: rawHistory.map((h) => Map<String, dynamic>.from(h as Map)).toList(),
      turnNumber: json['turn_number'] ?? 0,
      status: json['status'] ?? 'in_progress',
      winnerId: json['winner_id']?.toString(),
      winnerName: json['winner_name']?.toString(),
      winnerSymbol: json['winner_symbol']?.toString(),
      xBoardsWon: json['x_boards_won'] ?? 0,
      oBoardsWon: json['o_boards_won'] ?? 0,
      lastMove: json['last_move'] != null ? Map<String, dynamic>.from(json['last_move'] as Map) : null,
      lastAction: json['last_action'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_ids': playerIds,
      'player_names': playerNames,
      'player_symbols': playerSymbols,
      'boards': boards.map((b) => b.toJson()).toList(),
      'macro_board': macroBoard,
      'macro_winning_line': macroWinningLine,
      'current_turn_index': currentTurnIndex,
      'current_turn_player_id': currentTurnPlayerId,
      'current_symbol': currentSymbol,
      'next_board': nextBoard,
      'move_history': moveHistory,
      'turn_number': turnNumber,
      'status': status,
      'winner_id': winnerId,
      'winner_name': winnerName,
      'winner_symbol': winnerSymbol,
      'x_boards_won': xBoardsWon,
      'o_boards_won': oBoardsWon,
      'last_move': lastMove,
      'last_action': lastAction,
    };
  }
}
