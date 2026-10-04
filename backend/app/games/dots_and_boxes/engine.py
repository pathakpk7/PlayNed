from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

DOTS_AND_BOXES_METADATA = GameMetadata(
    id="dots_and_boxes",
    name="Dots & Boxes",
    tagline="Classic territorial line-drawing strategy.",
    description="Connect adjacent dots with horizontal and vertical lines. Close the 4th wall of any box to claim it for points and earn an immediate extra turn!",
    category="Strategy",
    min_players=2,
    max_players=4,
    supports_local=True,
    supports_online=True,
    supports_teams=True,
    estimated_duration_minutes=5,
    accent_color_hex="#4E89FF",
    bg_color_hex="#0F1B2C",
    icon_name="grid_on",
    rules_summary=[
        "Take turns drawing one line between two adjacent dots.",
        "Horizontal and vertical segments can be placed anywhere on the grid.",
        "When you place the 4th closing line of a box, you capture it and score 1 point.",
        "Capturing a box gives you an immediate bonus turn!",
        "The player with the most captured boxes when the grid is full wins the match."
    ]
)

class DotsAndBoxesEngine(BaseGameEngine):
    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        options = options or {}
        # Grid size: customizable between 4x4 and 9x9 dots
        grid_rows = int(options.get("grid_rows", 4))
        grid_cols = int(options.get("grid_cols", 4))
        
        # Clamp between 4x4 (3x3 boxes) and 9x9 (8x8 boxes)
        grid_rows = max(4, min(9, grid_rows))
        grid_cols = max(4, min(9, grid_cols))

        box_rows = grid_rows - 1
        box_cols = grid_cols - 1
        total_boxes = box_rows * box_cols

        # Horizontal lines: grid_rows x (grid_cols - 1)
        # Vertical lines: (grid_rows - 1) x grid_cols
        # Represented as string keys: "h:r,c" and "v:r,c" -> player_id or None
        
        return {
            "game_id": "dots_and_boxes",
            "grid_rows": grid_rows,
            "grid_cols": grid_cols,
            "box_rows": box_rows,
            "box_cols": box_cols,
            "total_boxes": total_boxes,
            "boxes_claimed_count": 0,
            "horizontal_lines": {},  # "r,c": player_id
            "vertical_lines": {},    # "r,c": player_id
            "boxes": {},             # "r,c": player_id (claimed by)
            "scores": {pid: 0 for pid in player_ids},
            "player_ids": player_ids,
            "player_names": player_names,
            "current_turn_index": 0,
            "current_turn_player_id": player_ids[0] if player_ids else "",
            "status": "in_progress",  # in_progress, won, draw
            "winner_id": None,
            "winner_name": None,
            "last_action": "Match started. Connect dots to form boxes.",
            "bonus_turn": False
        }

    def _is_box_completed(self, h_lines: Dict[str, str], v_lines: Dict[str, str], r: int, c: int) -> bool:
        top = f"{r},{c}" in h_lines
        bottom = f"{r+1},{c}" in h_lines
        left = f"{r},{c}" in v_lines
        right = f"{r},{c+1}" in v_lines
        return top and bottom and left and right

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> tuple[bool, Optional[str]]:
        if state.get("status") != "in_progress":
            return False, "Game is already finished."

        if state.get("current_turn_player_id") != player_id:
            return False, "It is not your turn."

        line_type = move.get("type")  # 'h' or 'v'
        if line_type not in ('h', 'v'):
            return False, "Invalid line type: must be 'h' (horizontal) or 'v' (vertical)."

        try:
            r = int(move.get("r"))
            c = int(move.get("c"))
        except (ValueError, TypeError):
            return False, "Line coordinates 'r' and 'c' must be integers."

        grid_rows = state["grid_rows"]
        grid_cols = state["grid_cols"]

        if line_type == 'h':
            if not (0 <= r < grid_rows and 0 <= c < grid_cols - 1):
                return False, f"Horizontal line ({r}, {c}) out of bounds."
            if f"{r},{c}" in state.get("horizontal_lines", {}):
                return False, f"Horizontal line ({r}, {c}) is already occupied."
        else:
            if not (0 <= r < grid_rows - 1 and 0 <= c < grid_cols):
                return False, f"Vertical line ({r}, {c}) out of bounds."
            if f"{r},{c}" in state.get("vertical_lines", {}):
                return False, f"Vertical line ({r}, {c}) is already occupied."

        return True, None

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        new_state["horizontal_lines"] = dict(state.get("horizontal_lines", {}))
        new_state["vertical_lines"] = dict(state.get("vertical_lines", {}))
        new_state["boxes"] = dict(state.get("boxes", {}))
        new_state["scores"] = dict(state.get("scores", {}))

        line_type = move["type"]
        r = int(move["r"])
        c = int(move["c"])
        key = f"{r},{c}"

        if line_type == 'h':
            new_state["horizontal_lines"][key] = player_id
        else:
            new_state["vertical_lines"][key] = player_id

        # Check which boxes were completed by this move
        box_rows = new_state["box_rows"]
        box_cols = new_state["box_cols"]
        completed_boxes = []

        # A horizontal line at (r, c) can potentially complete box (r-1, c) and box (r, c)
        if line_type == 'h':
            candidate_boxes = [(r - 1, c), (r, c)]
        else:
            # A vertical line at (r, c) can potentially complete box (r, c-1) and box (r, c)
            candidate_boxes = [(r, c - 1), (r, c)]

        for br, bc in candidate_boxes:
            b_key = f"{br},{bc}"
            if 0 <= br < box_rows and 0 <= bc < box_cols:
                if b_key not in new_state["boxes"]:
                    if self._is_box_completed(new_state["horizontal_lines"], new_state["vertical_lines"], br, bc):
                        new_state["boxes"][b_key] = player_id
                        completed_boxes.append((br, bc))

        pname = new_state["player_names"].get(player_id, "Player")

        if completed_boxes:
            boxes_gained = len(completed_boxes)
            new_state["scores"][player_id] = new_state["scores"].get(player_id, 0) + boxes_gained
            new_state["boxes_claimed_count"] = len(new_state["boxes"])
            new_state["bonus_turn"] = True
            new_state["last_action"] = f"{pname} completed {boxes_gained} box{'es' if boxes_gained > 1 else ''}! Bonus turn awarded."
            # Current turn remains with player_id
        else:
            new_state["bonus_turn"] = False
            new_state["last_action"] = f"{pname} placed a {'horizontal' if line_type == 'h' else 'vertical'} line."
            # Advance turn
            player_ids = new_state["player_ids"]
            cur_idx = new_state.get("current_turn_index", 0)
            next_idx = (cur_idx + 1) % len(player_ids)
            new_state["current_turn_index"] = next_idx
            new_state["current_turn_player_id"] = player_ids[next_idx]

        # Check if all boxes are captured
        if len(new_state["boxes"]) >= new_state["total_boxes"]:
            new_state["status"] = "finished"
            # Determine winner
            scores = new_state["scores"]
            max_score = max(scores.values())
            top_players = [pid for pid, score in scores.items() if score == max_score]

            if len(top_players) == 1:
                winner_id = top_players[0]
                new_state["winner_id"] = winner_id
                new_state["winner_name"] = new_state["player_names"].get(winner_id, "Winner")
                new_state["last_action"] = f"Game over! {new_state['winner_name']} wins with {max_score} boxes!"
            else:
                new_state["winner_id"] = None
                new_state["winner_name"] = "Draw"
                new_state["status"] = "draw"
                new_state["last_action"] = f"Game over! Draw with {max_score} boxes each."

        return new_state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        moves = []
        grid_rows = state["grid_rows"]
        grid_cols = state["grid_cols"]

        h_lines = state.get("horizontal_lines", {})
        for r in range(grid_rows):
            for c in range(grid_cols - 1):
                if f"{r},{c}" not in h_lines:
                    moves.append({"type": "h", "r": r, "c": c})

        v_lines = state.get("vertical_lines", {})
        for r in range(grid_rows - 1):
            for c in range(grid_cols):
                if f"{r},{c}" not in v_lines:
                    moves.append({"type": "v", "r": r, "c": c})

        return moves
