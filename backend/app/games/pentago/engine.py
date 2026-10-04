from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

PENTAGO_METADATA = GameMetadata(
    id="pentago",
    name="Pentago",
    tagline="The Mind-Twisting 5-in-a-row game with a rotating twist.",
    description="Place a marble on a 6x6 grid, then twist any of the four 3x3 quadrants 90 degrees. Form 5-in-a-row horizontally, vertically, or diagonally to triumph in this fast Swedish strategy classic.",
    category="Board",
    min_players=2,
    max_players=2,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    estimated_duration_minutes=6,
    accent_color_hex="#48BB78",
    bg_color_hex="#13231A",
    icon_name="rotate_right",
    rules_summary=[
        "Played on a 6x6 board composed of four rotatable 3x3 quadrants.",
        "Each turn has two phases: (1) Place a marble in any empty cell, (2) Twist any 3x3 quadrant 90° clockwise or counter-clockwise.",
        "Form 5 of your marbles in a row (horizontal, vertical, or diagonal) to win.",
        "A win can be created either during the marble placement or after the twist.",
        "If a rotation creates 5-in-a-row for both players simultaneously, the game ends in a Draw."
    ]
)

class PentagoEngine(BaseGameEngine):
    BOARD_SIZE = 6

    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        player_ids = player_ids[:2]
        # Board: 6x6 array (empty: None, or player_id)
        board = [[None for _ in range(6)] for _ in range(6)]

        player_colors = {
            player_ids[0]: "#FFFFFF", # White / Light
            player_ids[1]: "#E5A93C"  # Gold / Dark
        } if len(player_ids) >= 2 else {}

        return {
            "game_id": "pentago",
            "board": board,
            "player_ids": player_ids,
            "player_names": player_names,
            "player_colors": player_colors,
            "current_turn_index": 0,
            "current_turn_player_id": player_ids[0] if player_ids else "",
            "phase": "place_marble", # place_marble -> rotate_quadrant
            "pending_placed_position": None,
            "status": "in_progress", # in_progress, won, draw
            "winner_id": None,
            "winner_name": None,
            "last_action": "Match started. Place your marble."
        }

    def _get_quadrant_bounds(self, quadrant: int) -> Tuple[int, int, int, int]:
        """Returns (r_start, r_end, c_start, c_end) for quadrant 0, 1, 2, 3."""
        # 0: TL, 1: TR, 2: BL, 3: BR
        if quadrant == 0:
            return 0, 3, 0, 3
        elif quadrant == 1:
            return 0, 3, 3, 6
        elif quadrant == 2:
            return 3, 6, 0, 3
        elif quadrant == 3:
            return 3, 6, 3, 6
        raise ValueError(f"Invalid quadrant index: {quadrant}. Must be 0, 1, 2, or 3.")

    def _rotate_quadrant(self, board: List[List[Optional[str]]], quadrant: int, direction: str) -> List[List[Optional[str]]]:
        """Rotates a 3x3 quadrant on the board 90 degrees CW or CCW."""
        r_start, r_end, c_start, c_end = self._get_quadrant_bounds(quadrant)
        new_board = [row[:] for row in board]

        # Extract 3x3 subgrid
        sub = [[board[r][c] for c in range(c_start, c_end)] for r in range(r_start, r_end)]

        # Rotate 3x3 subgrid
        rotated = [[None for _ in range(3)] for _ in range(3)]
        for r in range(3):
            for c in range(3):
                if direction == "cw":
                    rotated[c][2 - r] = sub[r][c]
                else: # ccw
                    rotated[2 - c][r] = sub[r][c]

        # Put back
        for r in range(3):
            for c in range(3):
                new_board[r_start + r][c_start + c] = rotated[r][c]

        return new_board

    def _check_5_in_a_row(self, board: List[List[Optional[str]]], player_id: str) -> bool:
        """Checks if player_id has 5 consecutive marbles horizontally, vertically, or diagonally."""
        # Horizontal
        for r in range(6):
            for c in range(2): # starts at col 0 or 1
                if all(board[r][c + i] == player_id for i in range(5)):
                    return True

        # Vertical
        for c in range(6):
            for r in range(2): # starts at row 0 or 1
                if all(board[r + i][c] == player_id for i in range(5)):
                    return True

        # Diagonal (\)
        for r in range(2):
            for c in range(2):
                if all(board[r + i][c + i] == player_id for i in range(5)):
                    return True

        # Anti-Diagonal (/)
        for r in range(2):
            for c in range(4, 6):
                if all(board[r + i][c - i] == player_id for i in range(5)):
                    return True

        return False

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> tuple[bool, Optional[str]]:
        if state.get("status") != "in_progress":
            return False, "Game is already finished."

        if state.get("current_turn_player_id") != player_id:
            return False, "It is not your turn."

        phase = state.get("phase", "place_marble")
        action = move.get("action")

        # Atomic move (both place + rotate in one payload) or two-phase move
        if action == "place_and_rotate":
            try:
                r = int(move.get("r"))
                c = int(move.get("c"))
                quad = int(move.get("quadrant"))
                direction = move.get("direction")
            except (ValueError, TypeError):
                return False, "Invalid parameters for place_and_rotate."

            if not (0 <= r < 6 and 0 <= c < 6):
                return False, f"Coordinates ({r}, {c}) out of bounds."

            if state["board"][r][c] is not None:
                return False, f"Cell ({r}, {c}) is already occupied."

            if quad not in (0, 1, 2, 3):
                return False, f"Quadrant must be 0, 1, 2, or 3."

            if direction not in ("cw", "ccw"):
                return False, "Direction must be 'cw' or 'ccw'."

            return True, None

        if phase == "place_marble":
            if action != "place_marble":
                return False, "Must place a marble first."
            try:
                r = int(move.get("r"))
                c = int(move.get("c"))
            except (ValueError, TypeError):
                return False, "Coordinates 'r' and 'c' must be integers."

            if not (0 <= r < 6 and 0 <= c < 6):
                return False, f"Coordinates ({r}, {c}) out of bounds."

            if state["board"][r][c] is not None:
                return False, f"Cell ({r}, {c}) is already occupied."

            return True, None

        elif phase == "rotate_quadrant":
            if action != "rotate_quadrant":
                return False, "Must rotate a quadrant now."
            try:
                quad = int(move.get("quadrant"))
                direction = move.get("direction")
            except (ValueError, TypeError):
                return False, "Invalid quadrant rotation parameters."

            if quad not in (0, 1, 2, 3):
                return False, f"Quadrant must be 0, 1, 2, or 3."

            if direction not in ("cw", "ccw"):
                return False, "Direction must be 'cw' or 'ccw'."

            return True, None

        return False, "Invalid action."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        new_state["board"] = [row[:] for row in state["board"]]
        pname = new_state["player_names"].get(player_id, "Player")
        action = move.get("action")

        if action == "place_and_rotate":
            r, c = int(move["r"]), int(move["c"])
            quad, direction = int(move["quadrant"]), move["direction"]

            new_state["board"][r][c] = player_id
            new_state["board"] = self._rotate_quadrant(new_state["board"], quad, direction)
            new_state["phase"] = "place_marble"
            new_state["pending_placed_position"] = None

            q_names = ["Top-Left", "Top-Right", "Bottom-Left", "Bottom-Right"]
            dir_str = "clockwise" if direction == "cw" else "counter-clockwise"
            new_state["last_action"] = f"{pname} placed marble at ({r},{c}) and rotated {q_names[quad]} {dir_str}."

            return self._evaluate_game_over(new_state, player_id)

        if state["phase"] == "place_marble":
            r, c = int(move["r"]), int(move["c"])
            new_state["board"][r][c] = player_id
            new_state["phase"] = "rotate_quadrant"
            new_state["pending_placed_position"] = (r, c)
            new_state["last_action"] = f"{pname} placed marble at ({r},{c}). Now choose a quadrant to rotate."
            return new_state

        elif state["phase"] == "rotate_quadrant":
            quad = int(move["quadrant"])
            direction = move["direction"]
            new_state["board"] = self._rotate_quadrant(new_state["board"], quad, direction)
            new_state["phase"] = "place_marble"
            new_state["pending_placed_position"] = None

            q_names = ["Top-Left", "Top-Right", "Bottom-Left", "Bottom-Right"]
            dir_str = "clockwise" if direction == "cw" else "counter-clockwise"
            new_state["last_action"] = f"{pname} rotated {q_names[quad]} quadrant {dir_str}."

            return self._evaluate_game_over(new_state, player_id)

        return new_state

    def _evaluate_game_over(self, state: Dict[str, Any], last_player_id: str) -> Dict[str, Any]:
        pids = state["player_ids"]
        p1 = pids[0] if len(pids) > 0 else None
        p2 = pids[1] if len(pids) > 1 else None

        p1_wins = self._check_5_in_a_row(state["board"], p1) if p1 else False
        p2_wins = self._check_5_in_a_row(state["board"], p2) if p2 else False

        if p1_wins and p2_wins:
            state["status"] = "draw"
            state["winner_id"] = None
            state["winner_name"] = "Draw"
            state["last_action"] = "Simultaneous 5-in-a-row achieved! Match is a Draw!"
            return state
        elif p1_wins:
            state["status"] = "won"
            state["winner_id"] = p1
            state["winner_name"] = state["player_names"].get(p1, "Player 1")
            state["last_action"] = f"Victory! {state['winner_name']} connected 5 in a row!"
            return state
        elif p2_wins:
            state["status"] = "won"
            state["winner_id"] = p2
            state["winner_name"] = state["player_names"].get(p2, "Player 2")
            state["last_action"] = f"Victory! {state['winner_name']} connected 5 in a row!"
            return state

        # Check full board draw
        is_full = all(state["board"][r][c] is not None for r in range(6) for c in range(6))
        if is_full:
            state["status"] = "draw"
            state["winner_id"] = None
            state["winner_name"] = "Draw"
            state["last_action"] = "Board is full with no 5-in-a-row! Match is a Draw!"
            return state

        # Advance turn
        cur_idx = state.get("current_turn_index", 0)
        next_idx = (cur_idx + 1) % len(pids)
        state["current_turn_index"] = next_idx
        state["current_turn_player_id"] = pids[next_idx]

        return state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        phase = state.get("phase", "place_marble")
        if phase == "place_marble":
            moves = []
            for r in range(6):
                for c in range(6):
                    if state["board"][r][c] is None:
                        moves.append({"action": "place_marble", "r": r, "c": c})
            return moves
        else:
            rotations = []
            for q in range(4):
                for d in ("cw", "ccw"):
                    rotations.append({"action": "rotate_quadrant", "quadrant": q, "direction": d})
            return rotations
