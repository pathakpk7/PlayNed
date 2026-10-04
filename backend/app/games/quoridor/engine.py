from typing import Dict, Any, List, Optional, Tuple, Set
from collections import deque
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

QUORIDOR_METADATA = GameMetadata(
    id="quoridor",
    name="Quoridor",
    tagline="Mensa-awarded maze race and tactical wall blocking.",
    description="Navigate your pawn across a 9x9 board to the opposite goal line. On each turn, either advance your pawn or place a 2-space wall to obstruct and divert your opponents—without ever completely sealing off their escape path!",
    category="Strategy",
    min_players=2,
    max_players=4,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    estimated_duration_minutes=8,
    accent_color_hex="#E57373",
    bg_color_hex="#2A1414",
    icon_name="straighten",
    rules_summary=[
        "Start on your baseline. The goal is to reach any cell on the opposite side of the board first.",
        "On your turn, either move your pawn 1 square orthogonally OR place a 2-tile wall.",
        "Walls block passages between squares. They can be oriented horizontally or vertically.",
        "Walls cannot cross or overlap existing walls.",
        "Critical rule: You may NEVER completely block a player's path to their goal line.",
        "Pawn jumping: If an opponent is in an adjacent square, you can jump over them."
    ]
)

class QuoridorEngine(BaseGameEngine):
    BOARD_SIZE = 9

    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        num_players = len(player_ids)
        if num_players not in (2, 4):
            num_players = 2
            player_ids = player_ids[:2]

        walls_per_player = 10 if num_players == 2 else 5

        # Player spawn positions and goal definitions
        # 2 players: P1 at South (row 8, col 4), P2 at North (row 0, col 4)
        # 4 players: P1 (8,4), P2 (0,4), P3 (4,0), P4 (4,8)
        starting_positions = {
            player_ids[0]: {"r": 8, "c": 4, "goal_type": "row", "goal_val": 0, "color": "#4E89FF"},
            player_ids[1]: {"r": 0, "c": 4, "goal_type": "row", "goal_val": 8, "color": "#E57373"},
        }
        if num_players == 4:
            starting_positions[player_ids[2]] = {"r": 4, "c": 0, "goal_type": "col", "goal_val": 8, "color": "#81C784"}
            starting_positions[player_ids[3]] = {"r": 4, "c": 8, "goal_type": "col", "goal_val": 0, "color": "#FFD54F"}

        pawns = {}
        for pid in player_ids:
            pawns[pid] = {
                "r": starting_positions[pid]["r"],
                "c": starting_positions[pid]["c"],
                "goal_type": starting_positions[pid]["goal_type"],
                "goal_val": starting_positions[pid]["goal_val"],
                "walls_left": walls_per_player,
                "color": starting_positions[pid]["color"]
            }

        return {
            "game_id": "quoridor",
            "board_size": 9,
            "pawns": pawns,
            "horizontal_walls": [],  # list of {"r": int, "c": int, "placed_by": str}
            "vertical_walls": [],    # list of {"r": int, "c": int, "placed_by": str}
            "player_ids": player_ids,
            "player_names": player_names,
            "current_turn_index": 0,
            "current_turn_player_id": player_ids[0] if player_ids else "",
            "status": "in_progress",  # in_progress, won
            "winner_id": None,
            "winner_name": None,
            "last_action": "Match started. First player to reach opposite baseline wins."
        }

    def _is_wall_blocking(self, r1: int, c1: int, r2: int, c2: int, h_walls: List[Dict[str, Any]], v_walls: List[Dict[str, Any]]) -> bool:
        """Checks if moving between adjacent cells (r1, c1) and (r2, c2) is blocked by any wall."""
        # Moving vertically
        if c1 == c2:
            min_r = min(r1, r2)
            # Wall blocks if horizontal wall at (min_r, c1) or (min_r, c1 - 1)
            for w in h_walls:
                if w["r"] == min_r and (w["c"] == c1 or w["c"] == c1 - 1):
                    return True
        # Moving horizontally
        elif r1 == r2:
            min_c = min(c1, c2)
            # Wall blocks if vertical wall at (r1, min_c) or (r1 - 1, min_c)
            for w in v_walls:
                if w["c"] == min_c and (w["r"] == r1 or w["r"] == r1 - 1):
                    return True
        return False

    def _has_path_to_goal(self, start_r: int, start_c: int, goal_type: str, goal_val: int, h_walls: List[Dict[str, Any]], v_walls: List[Dict[str, Any]]) -> bool:
        """Uses BFS to verify whether a path exists to the goal."""
        queue = deque([(start_r, start_c)])
        visited = {(start_r, start_c)}

        while queue:
            curr_r, curr_c = queue.popleft()
            if goal_type == "row" and curr_r == goal_val:
                return True
            if goal_type == "col" and curr_c == goal_val:
                return True

            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = curr_r + dr, curr_c + dc
                if 0 <= nr < self.BOARD_SIZE and 0 <= nc < self.BOARD_SIZE:
                    if (nr, nc) not in visited:
                        if not self._is_wall_blocking(curr_r, curr_c, nr, nc, h_walls, v_walls):
                            visited.add((nr, nc))
                            queue.append((nr, nc))
        return False

    def _get_legal_pawn_moves(self, state: Dict[str, Any], player_id: str) -> List[Tuple[int, int]]:
        pawn = state["pawns"][player_id]
        pr, pc = pawn["r"], pawn["c"]
        h_walls = state["horizontal_walls"]
        v_walls = state["vertical_walls"]

        occupied_positions = {(p["r"], p["c"]): pid for pid, p in state["pawns"].items() if pid != player_id}

        legal_moves = []

        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = pr + dr, pc + dc
            if 0 <= nr < self.BOARD_SIZE and 0 <= nc < self.BOARD_SIZE:
                if not self._is_wall_blocking(pr, pc, nr, nc, h_walls, v_walls):
                    # If square is occupied by opponent pawn, attempt jump
                    if (nr, nc) in occupied_positions:
                        # Direct straight jump
                        jr, jc = nr + dr, nc + dc
                        if (0 <= jr < self.BOARD_SIZE and 0 <= jc < self.BOARD_SIZE and
                                not self._is_wall_blocking(nr, nc, jr, jc, h_walls, v_walls) and
                                (jr, jc) not in occupied_positions):
                            legal_moves.append((jr, jc))
                        else:
                            # Diagonal jumps if straight jump blocked by wall or board edge
                            side_dirs = [(dc, dr), (-dc, -dr)] if dr != 0 else [(dc, dr), (-dc, -dr)]
                            for sdr, sdc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                                if (sdr, sdc) != (dr, dc) and (sdr, sdc) != (-dr, -dc):
                                    dnr, dnc = nr + sdr, nc + sdc
                                    if (0 <= dnr < self.BOARD_SIZE and 0 <= dnc < self.BOARD_SIZE and
                                            not self._is_wall_blocking(nr, nc, dnr, dnc, h_walls, v_walls) and
                                            (dnr, dnc) not in occupied_positions):
                                        legal_moves.append((dnr, dnc))
                    else:
                        legal_moves.append((nr, nc))

        return legal_moves

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> tuple[bool, Optional[str]]:
        if state.get("status") != "in_progress":
            return False, "Game is already finished."

        if state.get("current_turn_player_id") != player_id:
            return False, "It is not your turn."

        action_type = move.get("action")  # 'move_pawn' or 'place_wall'
        if action_type not in ('move_pawn', 'place_wall'):
            return False, "Action must be 'move_pawn' or 'place_wall'."

        if action_type == 'move_pawn':
            try:
                target_r = int(move.get("r"))
                target_c = int(move.get("c"))
            except (ValueError, TypeError):
                return False, "Target coordinates 'r' and 'c' must be integers."

            legal_moves = self._get_legal_pawn_moves(state, player_id)
            if (target_r, target_c) not in legal_moves:
                return False, f"Illegal pawn move to ({target_r}, {target_c})."

            return True, None

        elif action_type == 'place_wall':
            pawn = state["pawns"][player_id]
            if pawn["walls_left"] <= 0:
                return False, "You have no walls remaining in inventory."

            wall_type = move.get("wall_type")  # 'h' or 'v'
            if wall_type not in ('h', 'v'):
                return False, "Wall orientation must be 'h' (horizontal) or 'v' (vertical)."

            try:
                wr = int(move.get("r"))
                wc = int(move.get("c"))
            except (ValueError, TypeError):
                return False, "Wall coordinates 'r' and 'c' must be integers."

            # Wall coordinates range from 0 to 7 (8x8 intersection grid)
            if not (0 <= wr < self.BOARD_SIZE - 1 and 0 <= wc < self.BOARD_SIZE - 1):
                return False, f"Wall position ({wr}, {wc}) is out of bounds (0-7 allowed)."

            h_walls = state["horizontal_walls"]
            v_walls = state["vertical_walls"]

            # Overlap & crossing check
            if wall_type == 'h':
                # Cannot cross vertical wall centered at (wr, wc)
                for vw in v_walls:
                    if vw["r"] == wr and vw["c"] == wc:
                        return False, "Cannot cross an intersecting vertical wall."
                # Cannot overlap existing horizontal wall
                for hw in h_walls:
                    if hw["r"] == wr and (hw["c"] == wc or hw["c"] == wc - 1 or hw["c"] == wc + 1):
                        return False, "Wall overlaps with an existing horizontal wall."
            else:
                # Cannot cross horizontal wall centered at (wr, wc)
                for hw in h_walls:
                    if hw["r"] == wr and hw["c"] == wc:
                        return False, "Cannot cross an intersecting horizontal wall."
                # Cannot overlap existing vertical wall
                for vw in v_walls:
                    if vw["c"] == wc and (vw["r"] == wr or vw["r"] == wr - 1 or vw["r"] == wr + 1):
                        return False, "Wall overlaps with an existing vertical wall."

            # Golden Rule: Path preservation check for every pawn
            test_h = list(h_walls) + ([{"r": wr, "c": wc, "placed_by": player_id}] if wall_type == 'h' else [])
            test_v = list(v_walls) + ([{"r": wr, "c": wc, "placed_by": player_id}] if wall_type == 'v' else [])

            for pid, p in state["pawns"].items():
                if not self._has_path_to_goal(p["r"], p["c"], p["goal_type"], p["goal_val"], test_h, test_v):
                    pname = state["player_names"].get(pid, "Player")
                    return False, f"Wall placement would completely trap {pname}. Every player must have a valid path."

            return True, None

        return False, "Unknown action."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        new_state["pawns"] = {pid: dict(p) for pid, p in state["pawns"].items()}
        new_state["horizontal_walls"] = list(state["horizontal_walls"])
        new_state["vertical_walls"] = list(state["vertical_walls"])

        action_type = move["action"]
        pname = new_state["player_names"].get(player_id, "Player")

        if action_type == 'move_pawn':
            tr, tc = int(move["r"]), int(move["c"])
            pawn = new_state["pawns"][player_id]
            pawn["r"] = tr
            pawn["c"] = tc
            new_state["last_action"] = f"{pname} moved pawn to ({tr}, {tc})."

            # Check win condition
            if (pawn["goal_type"] == "row" and pawn["r"] == pawn["goal_val"]) or \
               (pawn["goal_type"] == "col" and pawn["c"] == pawn["goal_val"]):
                new_state["status"] = "won"
                new_state["winner_id"] = player_id
                new_state["winner_name"] = pname
                new_state["last_action"] = f"Victory! {pname} reached the goal line!"
                return new_state

        elif action_type == 'place_wall':
            wr, wc = int(move["r"]), int(move["c"])
            wtype = move["wall_type"]
            wall_obj = {"r": wr, "c": wc, "placed_by": player_id}
            if wtype == 'h':
                new_state["horizontal_walls"].append(wall_obj)
            else:
                new_state["vertical_walls"].append(wall_obj)

            new_state["pawns"][player_id]["walls_left"] -= 1
            new_state["last_action"] = f"{pname} placed a {'horizontal' if wtype == 'h' else 'vertical'} wall at ({wr}, {wc})."

        # Advance turn
        player_ids = new_state["player_ids"]
        cur_idx = new_state.get("current_turn_index", 0)
        next_idx = (cur_idx + 1) % len(player_ids)
        new_state["current_turn_index"] = next_idx
        new_state["current_turn_player_id"] = player_ids[next_idx]

        return new_state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        pawn_moves = [{"action": "move_pawn", "r": r, "c": c} for r, c in self._get_legal_pawn_moves(state, player_id)]
        return pawn_moves
