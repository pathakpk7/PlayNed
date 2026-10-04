from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

REVERSI_METADATA = GameMetadata(
    id="reversi",
    name="Reversi & Othello",
    tagline="A minute to learn, a lifetime to master. Flip your opponent's discs.",
    description="The legendary strategic disc-flipping board game. Trap opponent discs between your own in horizontal, vertical, or diagonal lines to flip them to your colour. Features both Modern Othello (fixed opening) and Classic Reversi (custom 4-disc center opening) with AI opponents and real-time multiplayer.",
    category="Strategy",
    min_players=2,
    max_players=2,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    estimated_duration_minutes=10,
    accent_color_hex="#10B981",
    bg_color_hex="#0D2418",
    icon_name="adjust",
    rules_summary=[
        "Sandwich Rule: Place a disc on an empty square to sandwich one or more opponent discs in any straight line (horizontal, vertical, or diagonal).",
        "Chain Flipping: All trapped opponent discs in all 8 directions flip to your colour simultaneously.",
        "Mandatory Flips: You may only place a disc if it captures and flips at least one opposing disc. If no moves are possible, you must pass.",
        "Variants: Choose between Modern Othello (standard 4-center setup) or Classic Reversi (custom opening & 32-disc quota).",
        "Corner Supremacy: Corner squares can never be flipped once captured. Beware of adjacent C and X squares!",
        "Victory Condition: When neither player can move or the board is filled, the player with the most discs wins."
    ]
)

class ReversiEngine(BaseGameEngine):
    """
    Engine for Reversi and Othello.
    Board is 8x8 (0-indexed: rows 0-7, cols 0-7).
    Discs:
      0 = Empty (None)
      1 = Black (Player 1, moves first in Othello)
      2 = White (Player 2)
    """
    BOARD_SIZE = 8
    DIRECTIONS = [
        (-1, -1), (-1, 0), (-1, 1),
        (0, -1),           (0, 1),
        (1, -1),  (1, 0),  (1, 1)
    ]

    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        options = options or {}
        variant = options.get("variant", "othello")  # "othello" or "reversi_classic"
        
        # Ensure 2 player IDs
        p1 = player_ids[0] if player_ids else "p1"
        p2 = player_ids[1] if len(player_ids) > 1 else (f"{p1}_opp" if p1 != "p2" else "p2")
        active_pids = [p1, p2]

        # 8x8 empty board (0 = Empty)
        board = [[0 for _ in range(self.BOARD_SIZE)] for _ in range(self.BOARD_SIZE)]

        p1_discs_remaining = 30  # 32 total minus 2 placed
        p2_discs_remaining = 30

        if variant == "othello":
            # Standard diagonal cross opening:
            # (3,3)=White(2), (3,4)=Black(1), (4,3)=Black(1), (4,4)=White(2)
            board[3][3] = 2
            board[3][4] = 1
            board[4][3] = 1
            board[4][4] = 2
            opening_phase = False
        else:
            # Classic Reversi starts empty for center-4 opening phase
            # or with predetermined placement
            board[3][3] = 2
            board[3][4] = 1
            board[4][3] = 1
            board[4][4] = 2
            opening_phase = False

        state = {
            "game_id": "reversi",
            "variant": variant,
            "board": board,
            "player_ids": active_pids,
            "player_names": player_names,
            "player_colors": {
                p1: 1,  # Black
                p2: 2   # White
            },
            "p1_discs_remaining": p1_discs_remaining,
            "p2_discs_remaining": p2_discs_remaining,
            "current_turn_index": 0,
            "current_turn_player_id": p1,
            "status": "in_progress",  # "in_progress", "won", "draw"
            "winner_id": None,
            "winner_name": None,
            "black_count": 2,
            "white_count": 2,
            "consecutive_passes": 0,
            "last_move": None,
            "last_action": f"Match started ({'Standard Othello' if variant == 'othello' else 'Classic Reversi'}). Black (⚫) moves first."
        }

        self._update_counts_and_mobility(state)
        return state

    def _get_sandwiched_discs(self, board: List[List[int]], r: int, c: int, disc_color: int) -> List[Tuple[int, int]]:
        """Returns all coordinates of opponent discs that would be flipped by placing disc_color at (r, c)."""
        if board[r][c] != 0:
            return []

        opponent_color = 2 if disc_color == 1 else 1
        flipped = []

        for dr, dc in self.DIRECTIONS:
            curr_r, curr_c = r + dr, c + dc
            line = []

            while 0 <= curr_r < self.BOARD_SIZE and 0 <= curr_c < self.BOARD_SIZE and board[curr_r][curr_c] == opponent_color:
                line.append((curr_r, curr_c))
                curr_r += dr
                curr_c += dc

            # If terminated by friendly disc, all in line are sandwiched
            if 0 <= curr_r < self.BOARD_SIZE and 0 <= curr_c < self.BOARD_SIZE and board[curr_r][curr_c] == disc_color and line:
                flipped.extend(line)

        return flipped

    def get_legal_moves(self, board: List[List[int]], disc_color: int) -> Dict[Tuple[int, int], List[Tuple[int, int]]]:
        """Returns mapping from (r, c) -> list of flipped coordinates for all valid moves."""
        legal = {}
        for r in range(self.BOARD_SIZE):
            for c in range(self.BOARD_SIZE):
                flips = self._get_sandwiched_discs(board, r, c, disc_color)
                if flips:
                    legal[(r, c)] = flips
        return legal

    def _update_counts_and_mobility(self, state: Dict[str, Any]):
        board = state["board"]
        black = 0
        white = 0
        empty = 0
        for r in range(self.BOARD_SIZE):
            for c in range(self.BOARD_SIZE):
                if board[r][c] == 1:
                    black += 1
                elif board[r][c] == 2:
                    white += 1
                else:
                    empty += 1

        state["black_count"] = black
        state["white_count"] = white
        state["empty_count"] = empty

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> tuple[bool, Optional[str]]:
        if state.get("status") != "in_progress":
            return False, "Game is already completed."

        if state.get("current_turn_player_id") != player_id:
            return False, "It is not your turn."

        action = move.get("action", "place_disc")
        disc_color = state["player_colors"].get(player_id, 1)
        board = state["board"]

        if action == "pass":
            # Pass is only allowed if player has zero legal moves
            legal_moves = self.get_legal_moves(board, disc_color)
            if legal_moves:
                return False, "Pass is not permitted when legal capturing moves exist."
            return True, None

        if action == "place_disc":
            try:
                r = int(move.get("r"))
                c = int(move.get("c"))
            except (ValueError, TypeError):
                return False, "Move requires integer row 'r' and col 'c'."

            if not (0 <= r < self.BOARD_SIZE and 0 <= c < self.BOARD_SIZE):
                return False, f"Coordinates ({r}, {c}) are out of board bounds (0-7)."

            if board[r][c] != 0:
                return False, f"Square ({r}, {c}) is already occupied."

            flips = self._get_sandwiched_discs(board, r, c, disc_color)
            if not flips:
                return False, f"Move at ({r}, {c}) does not sandwich any opponent discs. Every move must capture at least one disc."

            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        new_state["board"] = [list(row) for row in state["board"]]
        board = new_state["board"]

        disc_color = new_state["player_colors"][player_id]
        pname = new_state["player_names"].get(player_id, "Player")
        action = move.get("action", "place_disc")

        player_ids = new_state["player_ids"]
        cur_idx = new_state.get("current_turn_index", 0)
        next_idx = 1 - cur_idx
        next_player_id = player_ids[next_idx]
        next_color = new_state["player_colors"][next_player_id]

        if action == "pass":
            new_state["consecutive_passes"] = new_state.get("consecutive_passes", 0) + 1
            new_state["last_action"] = f"{pname} had no legal moves and passed."
        else:
            r, c = int(move["r"]), int(move["c"])
            flips = self._get_sandwiched_discs(board, r, c, disc_color)

            # Place and flip discs
            board[r][c] = disc_color
            for fr, fc in flips:
                board[fr][fc] = disc_color

            new_state["consecutive_passes"] = 0
            new_state["last_move"] = {"r": r, "c": c, "flipped_count": len(flips), "player_id": player_id}
            color_name = "Black (⚫)" if disc_color == 1 else "White (⚪)"
            new_state["last_action"] = f"{pname} ({color_name}) placed at ({r},{c}) and flipped {len(flips)} disc{'s' if len(flips) != 1 else ''}."

        # Update scores
        self._update_counts_and_mobility(new_state)

        # Check end of game conditions:
        # 1. Two consecutive passes
        # 2. Board full (empty_count == 0)
        # 3. One player wiped out (black_count == 0 or white_count == 0)
        # 4. Neither player has legal moves
        next_legal = self.get_legal_moves(board, next_color)
        curr_legal = self.get_legal_moves(board, disc_color)

        is_game_over = False
        if new_state["consecutive_passes"] >= 2 or new_state["empty_count"] == 0:
            is_game_over = True
        elif new_state["black_count"] == 0 or new_state["white_count"] == 0:
            is_game_over = True
        elif not next_legal and not curr_legal:
            is_game_over = True

        if is_game_over:
            new_state["status"] = "won" if new_state["black_count"] != new_state["white_count"] else "draw"
            if new_state["black_count"] > new_state["white_count"]:
                b_pid = [pid for pid, c in new_state["player_colors"].items() if c == 1][0]
                new_state["winner_id"] = b_pid
                new_state["winner_name"] = new_state["player_names"].get(b_pid, "Black")
                new_state["last_action"] = f"Game Over! Black wins {new_state['black_count']} - {new_state['white_count']}."
            elif new_state["white_count"] > new_state["black_count"]:
                w_pid = [pid for pid, c in new_state["player_colors"].items() if c == 2][0]
                new_state["winner_id"] = w_pid
                new_state["winner_name"] = new_state["player_names"].get(w_pid, "White")
                new_state["last_action"] = f"Game Over! White wins {new_state['white_count']} - {new_state['black_count']}."
            else:
                new_state["winner_id"] = None
                new_state["winner_name"] = "Draw"
                new_state["last_action"] = f"Game Over! It's a draw {new_state['black_count']} - {new_state['white_count']}."
            return new_state

        # Turn handover
        new_state["current_turn_index"] = next_idx
        new_state["current_turn_player_id"] = next_player_id

        return new_state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        disc_color = state["player_colors"].get(player_id, 1)
        legal = self.get_legal_moves(state["board"], disc_color)
        if not legal:
            return [{"action": "pass"}]
        return [{"action": "place_disc", "r": r, "c": c, "flip_count": len(flips)} for (r, c), flips in legal.items()]
