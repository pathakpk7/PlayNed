import random
from itertools import combinations
from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

SHUT_THE_BOX_METADATA = GameMetadata(
    id="shut_the_box",
    name="Shut the Box",
    tagline="Roll the dice, shut the tiles, and aim for zero penalty points.",
    description="A classic traditional pub and strategy game of dice, math, and risk. Roll the dice and flip down open numbered tiles matching your dice sum. Can you shut the entire box?",
    category="Casual / Math",
    min_players=1,
    max_players=4,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    estimated_duration_minutes=4,
    accent_color_hex="#E5A93C",
    bg_color_hex="#1D180F",
    icon_name="casino",
    rules_summary=[
        "Numbered tiles (1 to 9) start upright in the open position.",
        "On your turn, roll the dice to get a target sum (e.g. 3 + 5 = 8).",
        "Select any combination of open tiles that add up exactly to the dice sum (e.g. 8, or 1+7, or 3+5, or 1+2+5).",
        "Flipped tiles remain shut for the remainder of your round.",
        "If remaining open tiles sum to 6 or less, you may choose to roll only 1 die.",
        "When no open tiles can equal your dice sum, your turn ends. Your penalty score is the sum of remaining open tiles.",
        "Lowest penalty score wins! Shutting all 9 tiles scores a perfect 0 (Grand Slam Victory)!"
    ]
)

class ShutTheBoxEngine(BaseGameEngine):
    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        options = options or {}
        max_tile = int(options.get("max_tile", 9))
        if max_tile not in (9, 12):
            max_tile = 9

        player_ids = player_ids if player_ids else ["p1"]
        player_scores = {pid: 0 for pid in player_ids}
        player_rounds_completed = {pid: False for pid in player_ids}
        initial_tiles = list(range(1, max_tile + 1))

        player_colors = {
            player_ids[0]: "#E5A93C",
            player_ids[1] if len(player_ids) > 1 else "p2": "#48BB78",
            player_ids[2] if len(player_ids) > 2 else "p3": "#4299E1",
            player_ids[3] if len(player_ids) > 3 else "p4": "#ED8936",
        }

        first_player = player_ids[0]

        return {
            "game_id": "shut_the_box",
            "max_tile": max_tile,
            "player_ids": player_ids,
            "player_names": player_names,
            "player_colors": player_colors,
            "current_player_index": 0,
            "current_turn_player_id": first_player,
            "open_tiles": initial_tiles,
            "shut_tiles": [],
            "dice": [0, 0],
            "dice_sum": 0,
            "dice_rolled": False,
            "can_roll_one_die": False,
            "player_scores": player_scores,
            "player_rounds_completed": player_rounds_completed,
            "status": "in_progress", # in_progress, finished
            "winner_id": None,
            "winner_name": None,
            "last_action": f"Match started. {player_names.get(first_player, 'Player 1')} to roll the dice."
        }

    @staticmethod
    def find_valid_combinations(open_tiles: List[int], target_sum: int) -> List[List[int]]:
        """Returns all subsets of open_tiles that add up to target_sum."""
        valid_combos = []
        for r in range(1, len(open_tiles) + 1):
            for combo in combinations(open_tiles, r):
                if sum(combo) == target_sum:
                    valid_combos.append(list(combo))
        return valid_combos

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        if state.get("status") != "in_progress":
            return False, "Game is already finished."

        if state.get("current_turn_player_id") != player_id:
            return False, "It is not your turn."

        action = move.get("action")

        if action == "roll_dice":
            if state.get("dice_rolled") and self.find_valid_combinations(state.get("open_tiles", []), state.get("dice_sum", 0)):
                return False, "You must shut tiles for your current roll before rolling again."
            
            use_one_die = bool(move.get("one_die", False))
            open_sum = sum(state.get("open_tiles", []))
            if use_one_die and open_sum > 6:
                return False, "Can only roll 1 die when the sum of remaining open tiles is 6 or less."

            return True, None

        elif action == "shut_tiles":
            if not state.get("dice_rolled"):
                return False, "You must roll the dice first."

            tiles_to_shut = move.get("tiles", [])
            if not isinstance(tiles_to_shut, list) or not tiles_to_shut:
                return False, "Must provide a non-empty list of tiles to shut."

            open_tiles = state.get("open_tiles", [])
            # Check all tiles are unique and currently open
            if len(set(tiles_to_shut)) != len(tiles_to_shut):
                return False, "Cannot select duplicate tiles."

            for t in tiles_to_shut:
                if t not in open_tiles:
                    return False, f"Tile {t} is already shut or invalid."

            if sum(tiles_to_shut) != state.get("dice_sum"):
                return False, f"Sum of selected tiles ({sum(tiles_to_shut)}) does not match dice sum ({state.get('dice_sum')})."

            return True, None

        elif action == "end_turn":
            # Can end turn if dice were rolled and no valid combinations exist
            if not state.get("dice_rolled"):
                return False, "You have not rolled the dice."

            valid_combos = self.find_valid_combinations(state.get("open_tiles", []), state.get("dice_sum", 0))
            if valid_combos:
                return False, "Valid combinations exist. You must shut tiles matching your roll."

            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        new_state["open_tiles"] = list(state["open_tiles"])
        new_state["shut_tiles"] = list(state["shut_tiles"])
        new_state["player_scores"] = dict(state["player_scores"])
        new_state["player_rounds_completed"] = dict(state["player_rounds_completed"])

        action = move.get("action")
        pname = new_state["player_names"].get(player_id, "Player")

        if action == "roll_dice":
            use_one_die = bool(move.get("one_die", False))
            open_sum = sum(new_state["open_tiles"])

            if use_one_die and open_sum <= 6:
                d1 = random.randint(1, 6)
                new_state["dice"] = [d1, 0]
                new_state["dice_sum"] = d1
                new_state["last_action"] = f"{pname} rolled a {d1}."
            else:
                d1 = random.randint(1, 6)
                d2 = random.randint(1, 6)
                new_state["dice"] = [d1, d2]
                new_state["dice_sum"] = d1 + d2
                new_state["last_action"] = f"{pname} rolled {d1} + {d2} = {d1 + d2}."

            new_state["dice_rolled"] = True
            new_state["can_roll_one_die"] = sum(new_state["open_tiles"]) <= 6

            # Check if any combinations are possible
            valid_combos = self.find_valid_combinations(new_state["open_tiles"], new_state["dice_sum"])
            if not valid_combos:
                new_state["last_action"] += " No valid moves available! Round over."
                return self._advance_player_round(new_state, player_id)

            return new_state

        elif action == "shut_tiles":
            tiles_to_shut = move["tiles"]
            for t in tiles_to_shut:
                new_state["open_tiles"].remove(t)
                new_state["shut_tiles"].append(t)
                new_state["shut_tiles"].sort()

            tiles_str = " + ".join(str(t) for t in sorted(tiles_to_shut))
            new_state["last_action"] = f"{pname} shut tile(s): [{tiles_str}]."

            # Check if player shut the entire box! (0 penalty)
            if not new_state["open_tiles"]:
                new_state["last_action"] += " SHUT THE BOX! Perfect 0 penalty score!"
                new_state["player_scores"][player_id] = 0
                return self._advance_player_round(new_state, player_id, shut_box=True)

            # Ready for next roll
            new_state["dice_rolled"] = False
            new_state["can_roll_one_die"] = sum(new_state["open_tiles"]) <= 6
            return new_state

        elif action == "end_turn":
            return self._advance_player_round(new_state, player_id)

        return new_state

    def _advance_player_round(self, state: Dict[str, Any], player_id: str, shut_box: bool = False) -> Dict[str, Any]:
        if not shut_box:
            penalty = sum(state["open_tiles"])
            state["player_scores"][player_id] = penalty

        state["player_rounds_completed"][player_id] = True
        pids = state["player_ids"]

        # Check if all players completed their rounds
        if all(state["player_rounds_completed"].get(pid, False) for pid in pids):
            state["status"] = "finished"
            # Winner has lowest score
            scores = state["player_scores"]
            min_score = min(scores.values())
            best_players = [pid for pid, sc in scores.items() if sc == min_score]

            if len(best_players) == 1:
                winner = best_players[0]
                state["winner_id"] = winner
                state["winner_name"] = state["player_names"].get(winner, "Player")
                state["last_action"] = f"Game Over! {state['winner_name']} wins with lowest penalty score of {min_score}!"
            else:
                state["winner_id"] = None
                state["winner_name"] = "Tie"
                tie_names = ", ".join(state["player_names"].get(p, p) for p in best_players)
                state["last_action"] = f"Game Over! Tie between {tie_names} with score {min_score}!"
            return state

        # Move to next player who hasn't completed round
        cur_idx = state["current_player_index"]
        next_idx = (cur_idx + 1) % len(pids)
        while state["player_rounds_completed"].get(pids[next_idx], False):
            next_idx = (next_idx + 1) % len(pids)

        next_player = pids[next_idx]
        state["current_player_index"] = next_idx
        state["current_turn_player_id"] = next_player
        state["open_tiles"] = list(range(1, state["max_tile"] + 1))
        state["shut_tiles"] = []
        state["dice"] = [0, 0]
        state["dice_sum"] = 0
        state["dice_rolled"] = False
        state["can_roll_one_die"] = False
        state["last_action"] += f" Next up: {state['player_names'].get(next_player, 'Player')}."

        return state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        if state.get("status") != "in_progress" or state.get("current_turn_player_id") != player_id:
            return []

        if not state.get("dice_rolled"):
            moves = [{"action": "roll_dice", "one_die": False}]
            if state.get("can_roll_one_die"):
                moves.append({"action": "roll_dice", "one_die": True})
            return moves

        combos = self.find_valid_combinations(state.get("open_tiles", []), state.get("dice_sum", 0))
        if not combos:
            return [{"action": "end_turn"}]

        return [{"action": "shut_tiles", "tiles": combo} for combo in combos]
