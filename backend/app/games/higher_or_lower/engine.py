import random
from typing import Dict, Any, List, Optional, Tuple, Callable
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

MIN_NUMBER: int = 1
MAX_NUMBER: int = 100

HIGHER_OR_LOWER_METADATA = GameMetadata(
    id="higher_or_lower",
    name="Higher or Lower: Numbers",
    tagline="Predict whether the next secret number is higher or lower!",
    description="A fast-paced, addictive multiplayer number deduction game for 2 to 4 players. Predict whether the next randomly generated number (1 to 100) will be Higher or Lower than the current number to score points and outsmart your opponents.",
    category="Casual / Math / Party",
    min_players=2,
    max_players=4,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    supports_ai=True,
    estimated_duration_minutes=4,
    accent_color_hex="#F59E0B",
    bg_color_hex="#18150D",
    icon_name="swap_vert",
    rules_summary=[
        "Numbers range from 1 to 100, inclusive.",
        "On your turn, observe the current number and predict HIGHER or LOWER.",
        "A new random number is generated and revealed.",
        "HIGHER: Succeeds if next > current (+1 pt).",
        "LOWER: Succeeds if next < current (+1 pt).",
        "EQUAL: Numbers are identical! Results in a tie (0 pts).",
        "Modes: Quick Match (first to 10), Classic Match (20 rounds), or Extended (50 rounds).",
        "Sudden Death tiebreaker resolves ties if players finish with equal top scores."
    ]
)

class HigherOrLowerEngine(BaseGameEngine):
    def __init__(self, rng: Optional[Any] = None):
        """
        rng can be an instance of random.Random, or any object/function with
        randint(a, b) -> int to enable deterministic testing.
        """
        self.rng = rng or random.Random()

    def _generate_number(self, min_val: int = MIN_NUMBER, max_val: int = MAX_NUMBER) -> int:
        if hasattr(self.rng, "randint"):
            return self.rng.randint(min_val, max_val)
        if callable(self.rng):
            return self.rng(min_val, max_val)
        return random.randint(min_val, max_val)

    def create_initial_state(
        self,
        player_ids: List[str],
        player_names: Dict[str, str],
        options: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        options = options or {}
        player_ids = list(player_ids)
        if len(player_ids) < 2 or len(player_ids) > 4:
            raise ValueError(f"Higher or Lower requires 2 to 4 players. Received {len(player_ids)}.")

        # Match length configuration
        match_mode = str(options.get("match_mode", "classic")).lower()
        if match_mode == "quick":
            mode_type = "first_to_points"
            target_score = int(options.get("target_score", 10))
            total_rounds = None
        elif match_mode == "extended":
            mode_type = "fixed_rounds"
            total_rounds = int(options.get("total_rounds", 50))
            target_score = None
        elif match_mode == "custom":
            custom_type = str(options.get("custom_type", "fixed_rounds")).lower()
            if custom_type == "first_to_points":
                mode_type = "first_to_points"
                target_score = int(options.get("target_score", 15))
                total_rounds = None
            else:
                mode_type = "fixed_rounds"
                total_rounds = int(options.get("total_rounds", 30))
                target_score = None
        else:  # classic default
            match_mode = "classic"
            mode_type = "fixed_rounds"
            total_rounds = int(options.get("total_rounds", 20))
            target_score = None

        min_val = int(options.get("min_number", MIN_NUMBER))
        max_val = int(options.get("max_number", MAX_NUMBER))
        if min_val >= max_val:
            min_val, max_val = MIN_NUMBER, MAX_NUMBER

        # Generate initial starting number
        initial_number = options.get("initial_number")
        if initial_number is None or not (min_val <= int(initial_number) <= max_val):
            initial_number = self._generate_number(min_val, max_val)
        else:
            initial_number = int(initial_number)

        first_player = player_ids[0]
        first_name = player_names.get(first_player, first_player)

        return {
            "game_id": "higher_or_lower",
            "min_number": min_val,
            "max_number": max_val,
            "player_ids": player_ids,
            "player_names": player_names,
            "current_player_index": 0,
            "current_turn_player_id": first_player,
            "current_number": initial_number,
            "last_prediction": None,
            "scores": {pid: 0 for pid in player_ids},
            "attempts": {pid: 0 for pid in player_ids},
            "correct_counts": {pid: 0 for pid in player_ids},
            "tie_counts": {pid: 0 for pid in player_ids},
            "streaks": {pid: 0 for pid in player_ids},
            "max_streaks": {pid: 0 for pid in player_ids},
            "round_number": 1,
            "turns_taken_this_round": 0,
            "total_rounds": total_rounds,
            "target_score": target_score,
            "mode_type": mode_type,
            "match_mode": match_mode,
            "status": "in_progress",  # in_progress, sudden_death, finished
            "sudden_death_candidates": [],
            "sudden_death_round": 0,
            "sudden_death_results": {},
            "winner_id": None,
            "winner_name": None,
            "is_tie": False,
            "history": [],
            "last_action": f"Match started with initial number {initial_number}. It is {first_name}'s turn to predict!"
        }

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        if state.get("status") == "finished":
            return False, "Match is already finished."

        action = move.get("action")
        if action == "rematch":
            return True, None

        if action != "predict":
            return False, f"Unknown action: '{action}'. Expected 'predict' or 'rematch'."

        current_turn = state.get("current_turn_player_id")
        if player_id != current_turn:
            return False, f"It is not player {player_id}'s turn. Current turn: {current_turn}."

        direction = str(move.get("direction", "")).upper()
        if direction not in ("HIGHER", "LOWER"):
            return False, f"Invalid prediction direction: '{direction}'. Expected 'HIGHER' or 'LOWER'."

        return True, None

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        is_valid, error = self.validate_move(state, player_id, move)
        if not is_valid:
            raise ValueError(error)

        action = move.get("action")
        if action == "rematch":
            return self.create_initial_state(
                player_ids=state["player_ids"],
                player_names=state["player_names"],
                options={
                    "match_mode": state.get("match_mode", "classic"),
                    "total_rounds": state.get("total_rounds"),
                    "target_score": state.get("target_score"),
                    "min_number": state.get("min_number", MIN_NUMBER),
                    "max_number": state.get("max_number", MAX_NUMBER),
                }
            )

        direction = str(move["direction"]).upper()
        current_num = state["current_number"]

        # Deterministic override from move if provided (for strict test mocks), else generated
        if "override_next_number" in move:
            next_num = int(move["override_next_number"])
        else:
            next_num = self._generate_number(state["min_number"], state["max_number"])

        # Determine outcome
        p_name = state["player_names"].get(player_id, player_id)
        if next_num == current_num:
            outcome = "EQUAL"
            points = 0
            is_correct = False
            explanation = f"Numbers are identical ({next_num} == {current_num}). Tied prediction: 0 points awarded."
        elif (direction == "HIGHER" and next_num > current_num) or (direction == "LOWER" and next_num < current_num):
            outcome = "CORRECT"
            points = 1
            is_correct = True
            comp = "higher than" if next_num > current_num else "lower than"
            explanation = f"Correct! {next_num} is {comp} {current_num}. (+1 point)"
        else:
            outcome = "INCORRECT"
            points = 0
            is_correct = False
            comp = "higher than" if next_num > current_num else "lower than"
            explanation = f"Incorrect. {next_num} is {comp} {current_num}. (0 points)"

        # Copy state maps
        scores = dict(state["scores"])
        attempts = dict(state["attempts"])
        correct_counts = dict(state["correct_counts"])
        tie_counts = dict(state["tie_counts"])
        streaks = dict(state["streaks"])
        max_streaks = dict(state["max_streaks"])

        scores[player_id] = scores.get(player_id, 0) + points
        attempts[player_id] = attempts.get(player_id, 0) + 1

        if outcome == "CORRECT":
            correct_counts[player_id] = correct_counts.get(player_id, 0) + 1
            curr_streak = streaks.get(player_id, 0) + 1
            streaks[player_id] = curr_streak
            if curr_streak > max_streaks.get(player_id, 0):
                max_streaks[player_id] = curr_streak
        elif outcome == "EQUAL":
            tie_counts[player_id] = tie_counts.get(player_id, 0) + 1
            streaks[player_id] = 0
        else:
            streaks[player_id] = 0

        pred_record = {
            "player_id": player_id,
            "player_name": p_name,
            "direction": direction,
            "previous_number": current_num,
            "revealed_number": next_num,
            "outcome": outcome,
            "points_awarded": points,
            "explanation": explanation,
            "round": state["round_number"],
        }

        history = list(state.get("history", []))
        history.append(pred_record)
        if len(history) > 30:
            history = history[-30:]

        is_sudden_death = state.get("status") == "sudden_death"

        if is_sudden_death:
            return self._advance_sudden_death(
                state=state,
                player_id=player_id,
                is_correct=is_correct,
                next_number=next_num,
                pred_record=pred_record,
                scores=scores,
                attempts=attempts,
                correct_counts=correct_counts,
                tie_counts=tie_counts,
                streaks=streaks,
                max_streaks=max_streaks,
                history=history,
            )
        else:
            return self._advance_regular_match(
                state=state,
                player_id=player_id,
                next_number=next_num,
                pred_record=pred_record,
                scores=scores,
                attempts=attempts,
                correct_counts=correct_counts,
                tie_counts=tie_counts,
                streaks=streaks,
                max_streaks=max_streaks,
                history=history,
            )

    def _advance_regular_match(
        self,
        state: Dict[str, Any],
        player_id: str,
        next_number: int,
        pred_record: Dict[str, Any],
        scores: Dict[str, int],
        attempts: Dict[str, int],
        correct_counts: Dict[str, int],
        tie_counts: Dict[str, int],
        streaks: Dict[str, int],
        max_streaks: Dict[str, int],
        history: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        p_ids = state["player_ids"]
        p_idx = state["current_player_index"]
        turns_in_round = state.get("turns_taken_this_round", 0) + 1
        curr_round = state["round_number"]

        round_completed = turns_in_round >= len(p_ids)
        next_p_idx = (p_idx + 1) % len(p_ids)
        next_turn_id = p_ids[next_p_idx]
        next_round = curr_round + 1 if round_completed else curr_round
        next_turns_in_round = 0 if round_completed else turns_in_round

        # Check win/completion conditions
        is_finished = False
        winner_id = None
        winner_name = None
        is_tie = False
        sudden_death = False
        sd_candidates: List[str] = []

        mode_type = state["mode_type"]

        if mode_type == "fixed_rounds":
            total_rounds = state["total_rounds"]
            if round_completed and curr_round >= total_rounds:
                is_finished = True
        elif mode_type == "first_to_points":
            target = state["target_score"]
            # To ensure fairness, we allow all players to complete the round so everyone has equal turns
            anyone_reached = any(s >= target for s in scores.values())
            if anyone_reached and round_completed:
                is_finished = True

        if is_finished:
            max_score = max(scores.values())
            top_scorers = [pid for pid, s in scores.items() if s == max_score]

            if len(top_scorers) == 1:
                winner_id = top_scorers[0]
                winner_name = state["player_names"].get(winner_id, winner_id)
                status = "finished"
                last_act = f"{pred_record['explanation']} MATCH OVER! {winner_name} wins with {max_score} points!"
            else:
                # Enter sudden death between tied top scorers
                status = "sudden_death"
                sudden_death = True
                sd_candidates = list(top_scorers)
                next_turn_id = sd_candidates[0]
                next_p_idx = p_ids.index(next_turn_id)
                last_act = f"{pred_record['explanation']} Tie for 1st with {max_score} points! Entering SUDDEN DEATH between {', '.join(state['player_names'].get(p, p) for p in sd_candidates)}!"
        else:
            status = "in_progress"
            next_name = state["player_names"].get(next_turn_id, next_turn_id)
            last_act = f"{pred_record['explanation']} Next turn: {next_name}."

        return {
            **state,
            "current_player_index": next_p_idx,
            "current_turn_player_id": next_turn_id,
            "current_number": next_number,
            "last_prediction": pred_record,
            "scores": scores,
            "attempts": attempts,
            "correct_counts": correct_counts,
            "tie_counts": tie_counts,
            "streaks": streaks,
            "max_streaks": max_streaks,
            "round_number": next_round,
            "turns_taken_this_round": next_turns_in_round,
            "status": status,
            "sudden_death_candidates": sd_candidates,
            "sudden_death_round": 1 if sudden_death else 0,
            "sudden_death_results": {},
            "winner_id": winner_id,
            "winner_name": winner_name,
            "is_tie": is_tie,
            "history": history,
            "last_action": last_act,
        }

    def _advance_sudden_death(
        self,
        state: Dict[str, Any],
        player_id: str,
        is_correct: bool,
        next_number: int,
        pred_record: Dict[str, Any],
        scores: Dict[str, int],
        attempts: Dict[str, int],
        correct_counts: Dict[str, int],
        tie_counts: Dict[str, int],
        streaks: Dict[str, int],
        max_streaks: Dict[str, int],
        history: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        candidates = list(state.get("sudden_death_candidates", []))
        sd_results = dict(state.get("sudden_death_results", {}))
        sd_round = state.get("sudden_death_round", 1)

        sd_results[player_id] = is_correct

        # Check if all sudden death candidates have completed their prediction this cycle
        if len(sd_results) < len(candidates):
            # Advance to next candidate
            curr_cand_idx = candidates.index(player_id)
            next_cand = candidates[curr_cand_idx + 1]
            next_p_idx = state["player_ids"].index(next_cand)
            next_name = state["player_names"].get(next_cand, next_cand)
            last_act = f"{pred_record['explanation']} [Sudden Death R{sd_round}] {next_name} to predict!"

            return {
                **state,
                "current_player_index": next_p_idx,
                "current_turn_player_id": next_cand,
                "current_number": next_number,
                "last_prediction": pred_record,
                "scores": scores,
                "attempts": attempts,
                "correct_counts": correct_counts,
                "tie_counts": tie_counts,
                "streaks": streaks,
                "max_streaks": max_streaks,
                "status": "sudden_death",
                "sudden_death_candidates": candidates,
                "sudden_death_round": sd_round,
                "sudden_death_results": sd_results,
                "winner_id": None,
                "winner_name": None,
                "is_tie": False,
                "history": history,
                "last_action": last_act,
            }

        # All candidates have made their prediction in this sudden death cycle!
        correct_candidates = [c for c, ok in sd_results.items() if ok]

        if len(correct_candidates) == 1:
            # Exactly one player got it right -> Champion!
            winner_id = correct_candidates[0]
            winner_name = state["player_names"].get(winner_id, winner_id)
            last_act = f"{pred_record['explanation']} SUDDEN DEATH RESOLVED! {winner_name} was the only player to predict correctly and wins the match!"

            return {
                **state,
                "current_number": next_number,
                "last_prediction": pred_record,
                "scores": scores,
                "attempts": attempts,
                "correct_counts": correct_counts,
                "tie_counts": tie_counts,
                "streaks": streaks,
                "max_streaks": max_streaks,
                "status": "finished",
                "sudden_death_candidates": candidates,
                "sudden_death_round": sd_round,
                "sudden_death_results": sd_results,
                "winner_id": winner_id,
                "winner_name": winner_name,
                "is_tie": False,
                "history": history,
                "last_action": last_act,
            }

        # If a subset (>1, <len(candidates)) got it right, narrow down the candidates
        if 1 < len(correct_candidates) < len(candidates):
            new_candidates = correct_candidates
        else:
            # Either all got it right or all failed -> all candidates continue to next sudden death round
            new_candidates = candidates

        next_cand = new_candidates[0]
        next_p_idx = state["player_ids"].index(next_cand)
        next_name = state["player_names"].get(next_cand, next_cand)
        next_sd_round = sd_round + 1
        last_act = f"{pred_record['explanation']} Sudden Death Round {sd_round} tied! Proceeding to Sudden Death Round {next_sd_round}. {next_name} to predict!"

        return {
            **state,
            "current_player_index": next_p_idx,
            "current_turn_player_id": next_cand,
            "current_number": next_number,
            "last_prediction": pred_record,
            "scores": scores,
            "attempts": attempts,
            "correct_counts": correct_counts,
            "tie_counts": tie_counts,
            "streaks": streaks,
            "max_streaks": max_streaks,
            "status": "sudden_death",
            "sudden_death_candidates": new_candidates,
            "sudden_death_round": next_sd_round,
            "sudden_death_results": {},
            "winner_id": None,
            "winner_name": None,
            "is_tie": False,
            "history": history,
            "last_action": last_act,
        }

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        if state.get("status") == "finished":
            return [{"action": "rematch"}]
        if player_id != state.get("current_turn_player_id"):
            return []
        return [
            {"action": "predict", "direction": "HIGHER"},
            {"action": "predict", "direction": "LOWER"},
        ]

    def filter_state_for_player(self, state: Dict[str, Any], player_id: str) -> Dict[str, Any]:
        """
        Ensures client receives no unrevealed future numbers.
        Since next_number is only generated upon applying a prediction, state is inherently clean.
        We return a full copy of the authoritative state with player-specific perspective indicators.
        """
        filtered = dict(state)
        filtered["is_my_turn"] = (player_id == state.get("current_turn_player_id"))
        return filtered

    @staticmethod
    def calculate_accuracy(correct: int, attempts: int, ties: int = 0) -> float:
        """
        Calculates accuracy percentage from resolved non-tied predictions.
        Returns float between 0.0 and 100.0.
        """
        valid_attempts = attempts - ties
        if valid_attempts <= 0:
            return 0.0
        return round((correct / valid_attempts) * 100.0, 1)
