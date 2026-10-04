from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

ULTIMATE_TIC_TAC_TOE_METADATA = GameMetadata(
    id="ultimate_tic_tac_toe",
    name="Ultimate Tic-Tac-Toe",
    tagline="Tic-Tac-Toe, but every move decides where your opponent plays next.",
    description="The recursive strategy masterwork. One 3x3 macro board containing 9 micro Tic-Tac-Toe boards. Each micro-cell you choose forces your opponent to play their next turn inside the corresponding micro-board. Win small boards to claim macro cells, and connect 3 macro boards in a row to win the ultimate match!",
    category="Strategy",
    min_players=2,
    max_players=2,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    estimated_duration_minutes=10,
    accent_color_hex="#F59E0B",
    bg_color_hex="#16120A",
    icon_name="grid_3x3",
    rules_summary=[
        "Macro Board: The game consists of a 3x3 macro grid of 9 smaller 3x3 Tic-Tac-Toe micro boards (81 cells total).",
        "Target Board Routing: The cell chosen within any micro board dictates the exact micro board the next player must play in (e.g. bottom-right cell sends opponent to bottom-right micro board).",
        "Free Move Rule: If you are sent to a micro board that has already been won or filled, you receive a Free Move and may play in ANY open micro board.",
        "Micro Victory: Form 3-in-a-row (horizontal, vertical, or diagonal) inside any micro board to claim that entire board with your symbol.",
        "Ultimate Victory: Claim 3 micro boards in a row on the macro grid to triumph and win the match!"
    ]
)

WINNING_LINES: List[Tuple[int, int, int]] = [
    (0, 1, 2), (3, 4, 5), (6, 7, 8),  # Horizontal rows
    (0, 3, 6), (1, 4, 7), (2, 5, 8),  # Vertical columns
    (0, 4, 8), (2, 4, 6)             # Diagonals
]

class UltimateTicTacToeEngine(BaseGameEngine):
    """
    Authoritative Engine for Ultimate Tic-Tac-Toe.
    
    Board Layout (Macro 0..8 and Micro 0..8):
    0 | 1 | 2
    ---------
    3 | 4 | 5
    ---------
    6 | 7 | 8
    
    Symbols:
      "X" = Player 1 (moves first)
      "O" = Player 2
    """

    def create_initial_state(
        self,
        player_ids: List[str],
        player_names: Dict[str, str],
        options: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        options = options or {}
        p1 = player_ids[0] if player_ids else "p1"
        p2 = player_ids[1] if len(player_ids) > 1 else (f"{p1}_opp" if p1 != "p2" else "p2")
        active_pids = [p1, p2]

        # 9 micro boards, each with 9 empty cells
        boards = []
        for i in range(9):
            boards.append({
                "index": i,
                "cells": [None] * 9,
                "winner": None,       # None, "X", "O", "draw"
                "status": "active",   # "active", "won", "draw"
                "winning_line": None  # list of 3 cell indices if won
            })

        state = {
            "game_id": "ultimate_tic_tac_toe",
            "player_ids": active_pids,
            "player_names": player_names,
            "player_symbols": {
                p1: "X",
                p2: "O"
            },
            "boards": boards,
            "macro_board": [None] * 9,       # None, "X", "O", "draw" for each macro cell
            "macro_winning_line": None,      # list of 3 board indices if macro won
            "current_turn_index": 0,
            "current_turn_player_id": p1,
            "current_symbol": "X",
            "next_board": None,              # None means FREE MOVE anywhere, or 0..8
            "move_history": [],
            "turn_number": 0,
            "status": "in_progress",         # "in_progress", "won", "draw"
            "winner_id": None,
            "winner_name": None,
            "winner_symbol": None,           # "X", "O", "draw"
            "x_boards_won": 0,
            "o_boards_won": 0,
            "last_move": None,
            "last_action": f"Match started. {player_names.get(p1, 'Player X')} (X) has Free Move to play in any board."
        }
        return state

    @staticmethod
    def check_micro_winner(cells: List[Optional[str]]) -> Tuple[Optional[str], Optional[List[int]]]:
        for a, b, c in WINNING_LINES:
            if cells[a] is not None and cells[a] == cells[b] == cells[c]:
                return cells[a], [a, b, c]
        if all(cell is not None for cell in cells):
            return "draw", None
        return None, None

    @staticmethod
    def check_macro_winner(macro_board: List[Optional[str]]) -> Tuple[Optional[str], Optional[List[int]]]:
        for a, b, c in WINNING_LINES:
            if macro_board[a] in ("X", "O") and macro_board[a] == macro_board[b] == macro_board[c]:
                return macro_board[a], [a, b, c]
        # Check if all 9 macro cells are completed (won or drawn)
        if all(cell is not None for cell in macro_board):
            return "draw", None
        return None, None

    @staticmethod
    def is_board_completed(board: Dict[str, Any]) -> bool:
        if board["winner"] is not None:
            return True
        return all(c is not None for c in board["cells"])

    def get_valid_boards(self, state: Dict[str, Any]) -> List[int]:
        if state.get("status") != "in_progress":
            return []
        
        next_board = state.get("next_board")
        boards = state.get("boards", [])

        # If next_board is specified and that board is NOT completed, player must play there
        if next_board is not None and 0 <= next_board < 9:
            if not self.is_board_completed(boards[next_board]):
                return [next_board]

        # Free move: Any board that is NOT completed
        return [i for i, b in enumerate(boards) if not self.is_board_completed(b)]

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        if state.get("status") != "in_progress":
            return False, "Game is already finished."

        expected_pid = state.get("current_turn_player_id")
        if player_id != expected_pid:
            return False, "Not your turn."

        board_idx = move.get("board")
        cell_idx = move.get("cell")

        if board_idx is None or cell_idx is None:
            return False, "Move must specify both 'board' (0..8) and 'cell' (0..8)."

        if not (0 <= board_idx <= 8) or not (0 <= cell_idx <= 8):
            return False, "Invalid board or cell index. Must be between 0 and 8."

        valid_boards = self.get_valid_boards(state)
        if board_idx not in valid_boards:
            if state.get("next_board") is not None:
                return False, f"Illegal move: You must play in Board {state['next_board']}."
            else:
                return False, f"Illegal move: Board {board_idx} is already completed."

        target_board = state["boards"][board_idx]
        if target_board["cells"][cell_idx] is not None:
            return False, f"Illegal move: Cell {cell_idx} in Board {board_idx} is already occupied."

        return True, None

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        if state.get("status") != "in_progress" or player_id != state.get("current_turn_player_id"):
            return []
        
        valid_boards = self.get_valid_boards(state)
        moves = []
        for b_idx in valid_boards:
            board = state["boards"][b_idx]
            for c_idx, cell in enumerate(board["cells"]):
                if cell is None:
                    moves.append({"board": b_idx, "cell": c_idx})
        return moves

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        is_valid, err_msg = self.validate_move(state, player_id, move)
        if not is_valid:
            raise ValueError(err_msg)

        board_idx = move["board"]
        cell_idx = move["cell"]

        target_board = state["boards"][board_idx]

        # Apply mark
        current_symbol = state["current_symbol"]
        target_board["cells"][cell_idx] = current_symbol

        # Check if this move wins or draws the micro board
        micro_winner, winning_line = self.check_micro_winner(target_board["cells"])
        micro_won = False
        if micro_winner is not None:
            target_board["winner"] = micro_winner
            target_board["status"] = "won" if micro_winner in ("X", "O") else "draw"
            target_board["winning_line"] = winning_line
            state["macro_board"][board_idx] = micro_winner
            if micro_winner == "X":
                state["x_boards_won"] = state.get("x_boards_won", 0) + 1
                micro_won = True
            elif micro_winner == "O":
                state["o_boards_won"] = state.get("o_boards_won", 0) + 1
                micro_won = True

        # Check if this wins or draws the entire macro board
        macro_winner, macro_line = self.check_macro_winner(state["macro_board"])
        p_names = state.get("player_names", {})

        if macro_winner in ("X", "O"):
            state["status"] = "won"
            state["macro_winner"] = macro_winner
            state["macro_winning_line"] = macro_line
            state["winner_symbol"] = macro_winner
            state["winner_id"] = player_id
            state["winner_name"] = p_names.get(player_id, f"Player {macro_winner}")
            state["next_board"] = None
            action_desc = f"VICTORY! {state['winner_name']} ({macro_winner}) connected 3 macro boards to win Ultimate Tic-Tac-Toe!"
        elif macro_winner == "draw":
            state["status"] = "draw"
            state["macro_winner"] = "draw"
            state["winner_symbol"] = "draw"
            state["next_board"] = None
            action_desc = "MATCH DRAW! All micro-boards completed with no macro 3-in-a-row."
        else:
            # Game continues -> calculate next_board for opponent
            dest_board_idx = cell_idx
            dest_board = state["boards"][dest_board_idx]
            
            if self.is_board_completed(dest_board):
                # Target board is completed -> FREE MOVE
                state["next_board"] = None
                free_note = "Target board is complete -> ⭐ FREE MOVE granted!"
            else:
                state["next_board"] = dest_board_idx
                free_note = f"Next turn in Board {dest_board_idx}."

            # Switch players
            next_turn_idx = 1 - state["current_turn_index"]
            state["current_turn_index"] = next_turn_idx
            next_pid = state["player_ids"][next_turn_idx]
            state["current_turn_player_id"] = next_pid
            state["current_symbol"] = "O" if current_symbol == "X" else "X"
            
            p_curr_name = p_names.get(player_id, f"Player {current_symbol}")
            action_desc = f"{p_curr_name} played Board {board_idx}, Cell {cell_idx}. {free_note}"

        # Update metadata
        state["turn_number"] = state.get("turn_number", 0) + 1
        state["last_move"] = {
            "board": board_idx,
            "cell": cell_idx,
            "player_id": player_id,
            "symbol": current_symbol,
            "micro_won": micro_won
        }
        state["move_history"].append(state["last_move"])
        state["last_action"] = action_desc

        return state
