import random
import time
from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata
from backend.app.games.spyfall.locations import (
    get_all_locations,
    get_locations_by_category,
    get_location_names,
    match_location_guess,
)
from backend.app.games.spyfall.scoring import calculate_round_points

SPYFALL_METADATA = GameMetadata(
    id="spyfall",
    name="Spyfall",
    tagline="One location. One hidden spy. Can you deduce who it is?",
    description=(
        "Social deduction party game for 3–8 players. Everyone receives the same secret "
        "location—except the Spy. Ask tactical questions, bluff your knowledge, vote out "
        "the suspect, or guess the location before you're exposed!"
    ),
    category="Social Deduction / Party Games",
    min_players=3,
    max_players=8,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    supports_ai=False,
    estimated_duration_minutes=6,
    accent_color_hex="#E11D48",
    bg_color_hex="#140F18",
    icon_name="visibility",
    rules_summary=[
        "3 to 8 players join a room. One player is secretly designated as the SPY.",
        "All other players receive the exact same secret location. The Spy has NO location.",
        "During the discussion timer, players ask each other questions to deduce who doesn't belong.",
        "Any player can initiate an accusation against a suspected Spy. A strict majority vote is required to convict.",
        "The Spy can guess the secret location at any time to steal an immediate victory!",
        "Scoring: Spy earns 3 pts for a correct location guess, 2 pts for surviving. Non-spies earn 2 pts for convicting the Spy.",
    ],
)


class SpyfallEngine(BaseGameEngine):
    @staticmethod
    def select_random_spy_and_location(
        player_ids: List[str], category: Optional[str] = None, seed: Optional[int] = None
    ) -> Tuple[str, Dict[str, Any]]:
        rng = random.Random(seed)
        spy_id = rng.choice(player_ids)
        eligible_locations = get_locations_by_category(category)
        if not eligible_locations:
            eligible_locations = get_all_locations()
        location = rng.choice(eligible_locations)
        return spy_id, location

    def create_initial_state(
        self,
        player_ids: List[str],
        player_names: Dict[str, str],
        options: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        n = len(player_ids)
        if n < 3 or n > 8:
            raise ValueError(f"Spyfall requires between 3 and 8 players (got {n}).")

        opts = options or {}
        category = opts.get("category", "all")
        round_duration_minutes = opts.get("round_duration_minutes", 5)
        total_rounds = opts.get("total_rounds", 3)
        allow_spy_guess = opts.get("allow_spy_guess", True)

        spy_id, location = self.select_random_spy_and_location(player_ids, category)

        role_assignments = {
            pid: ("spy" if pid == spy_id else "explorer") for pid in player_ids
        }

        duration_seconds = int(round_duration_minutes * 60)

        state: Dict[str, Any] = {
            "game_id": "spyfall",
            "player_ids": list(player_ids),
            "player_names": dict(player_names),
            "current_round": 1,
            "total_rounds": total_rounds,
            "round_duration_minutes": round_duration_minutes,
            "category": category,
            "allow_spy_guess": allow_spy_guess,
            # Authoritative secret data
            "spy_player_id": spy_id,
            "secret_location": location,
            "role_assignments": role_assignments,
            # Phase management
            "phase": "ROLE_REVEAL",  # ROLE_REVEAL, DISCUSSION, ACCUSATION_VOTING, SPY_GUESS, ROUND_RESOLUTION, MATCH_RESULTS
            "acknowledged_players": [],
            # Timers
            "discussion_duration_seconds": duration_seconds,
            "remaining_discussion_seconds": duration_seconds,
            "discussion_end_time": None,
            "voting_end_time": None,
            # Accusation & Voting
            "accuser_player_id": None,
            "accused_target_id": None,
            "votes": {},  # {player_id: "guilty"|"innocent"}
            # Spy Guess
            "spy_guesses_remaining": 1 if allow_spy_guess else 0,
            "spy_guessed_location": None,
            "spy_guess_correct": None,
            # Scoring & Outcomes
            "round_outcome": None,
            "outcome_reason": None,
            "round_points": {pid: 0 for pid in player_ids},
            "cumulative_scores": {pid: 0 for pid in player_ids},
            "round_history": [f"Round 1 began! Secret roles and location assigned."],
            "last_action": "Round 1 started! View your secret role card privately.",
            "created_at": time.time(),
            "updated_at": time.time(),
        }
        return state

    def validate_move(
        self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]
    ) -> Tuple[bool, Optional[str]]:
        action = move.get("action")
        phase = state.get("phase")
        player_ids = state.get("player_ids", [])

        if player_id not in player_ids:
            return False, "Player is not part of this match."

        if action == "acknowledge_role":
            if phase != "ROLE_REVEAL":
                return False, f"Cannot acknowledge role in phase '{phase}'."
            return True, None

        elif action == "accuse_player":
            if phase != "DISCUSSION":
                return False, f"Cannot accuse players in phase '{phase}'."
            target_id = move.get("target_player_id")
            if not target_id or target_id not in player_ids:
                return False, "Invalid accused player target."
            if target_id == player_id:
                return False, "You cannot accuse yourself."
            return True, None

        elif action == "cast_vote":
            if phase != "ACCUSATION_VOTING":
                return False, f"Cannot vote in phase '{phase}'."
            vote_val = move.get("vote")
            if vote_val not in ("guilty", "innocent"):
                return False, "Vote must be either 'guilty' or 'innocent'."
            return True, None

        elif action == "spy_guess_location":
            if phase not in ("DISCUSSION", "SPY_GUESS", "ACCUSATION_VOTING"):
                return False, f"Cannot guess location in phase '{phase}'."
            if player_id != state.get("spy_player_id"):
                return False, "Only the Spy can submit a location guess."
            if state.get("spy_guesses_remaining", 0) <= 0:
                return False, "No location guesses remaining."
            guess = move.get("guessed_location")
            if not guess or not isinstance(guess, str) or not guess.strip():
                return False, "Must provide a non-empty location guess."
            return True, None

        elif action == "timer_expired":
            if phase not in ("DISCUSSION", "ACCUSATION_VOTING"):
                return False, f"Timer expired is not valid in phase '{phase}'."
            return True, None

        elif action == "next_round":
            if phase != "ROUND_RESOLUTION":
                return False, f"Cannot advance round from phase '{phase}'."
            return True, None

        elif action == "rematch":
            if phase not in ("ROUND_RESOLUTION", "MATCH_RESULTS"):
                return False, f"Cannot rematch in phase '{phase}'."
            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(
        self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]
    ) -> Dict[str, Any]:
        is_valid, err = self.validate_move(state, player_id, move)
        if not is_valid:
            raise ValueError(err)

        new_state = {
            k: [dict(item) if isinstance(item, dict) else item for item in v]
            if isinstance(v, list)
            else (dict(v) if isinstance(v, dict) else v)
            for k, v in state.items()
        }

        action = move["action"]
        player_ids: List[str] = new_state["player_ids"]
        player_names: Dict[str, str] = new_state["player_names"]
        spy_id: str = new_state["spy_player_id"]
        secret_loc: Dict[str, Any] = new_state["secret_location"]
        history: List[str] = new_state["round_history"]

        if action == "acknowledge_role":
            ack = list(new_state.get("acknowledged_players", []))
            if player_id not in ack:
                ack.append(player_id)
            new_state["acknowledged_players"] = ack

            # When all players acknowledged (or force_advance), begin discussion
            if len(ack) >= len(player_ids) or move.get("force_advance", False):
                now = time.time()
                duration = new_state["discussion_duration_seconds"]
                new_state["phase"] = "DISCUSSION"
                new_state["discussion_end_time"] = now + duration
                new_state["remaining_discussion_seconds"] = duration
                msg = f"Discussion begins! Ask tactical questions to locate the Spy ({new_state['round_duration_minutes']} min timer)."
                new_state["last_action"] = msg
                history.append(msg)

        elif action == "accuse_player":
            target_id = move["target_player_id"]
            accuser_name = player_names.get(player_id, "Player")
            target_name = player_names.get(target_id, "Player")

            # Pause discussion timer
            now = time.time()
            end_time = new_state.get("discussion_end_time") or (now + 60)
            remaining = max(0, int(end_time - now))
            new_state["remaining_discussion_seconds"] = remaining

            new_state["phase"] = "ACCUSATION_VOTING"
            new_state["accuser_player_id"] = player_id
            new_state["accused_target_id"] = target_id
            new_state["votes"] = {player_id: "guilty"}  # Accuser automatically votes guilty
            new_state["voting_end_time"] = now + 45.0  # 45-second voting window

            msg = f"{accuser_name} formally accused {target_name} of being the SPY! Cast your votes."
            new_state["last_action"] = msg
            history.append(msg)

        elif action == "cast_vote":
            votes = dict(new_state.get("votes", {}))
            votes[player_id] = move["vote"]
            new_state["votes"] = votes

            # Check if all players (or all players except accused) have voted
            eligible_voters = list(player_ids)
            if len(votes) >= len(eligible_voters) or move.get("force_resolve", False):
                new_state = self._resolve_votes(new_state)

        elif action == "spy_guess_location":
            guess = move["guessed_location"].strip()
            is_correct = match_location_guess(guess, secret_loc["name"])
            new_state["spy_guessed_location"] = guess
            new_state["spy_guess_correct"] = is_correct
            new_state["spy_guesses_remaining"] = 0

            spy_name = player_names.get(spy_id, "The Spy")
            loc_name = secret_loc["name"]

            if is_correct:
                # Spy steals the win!
                new_state["phase"] = "ROUND_RESOLUTION"
                new_state["round_outcome"] = "SPY_GUESSED_LOCATION"
                msg = f"SPY WINS! {spy_name} correctly guessed the secret location: '{loc_name}'!"
                new_state["outcome_reason"] = msg
                new_state["last_action"] = msg
                history.append(msg)

                # Apply scoring
                round_pts = calculate_round_points(
                    player_ids, spy_id, "SPY_GUESSED_LOCATION", new_state.get("votes", {})
                )
                new_state["round_points"] = round_pts
                cum = dict(new_state.get("cumulative_scores", {}))
                for pid, p in round_pts.items():
                    cum[pid] = cum.get(pid, 0) + p
                new_state["cumulative_scores"] = cum
            else:
                # Incorrect guess
                msg = f"{spy_name} guessed '{guess}', which is INCORRECT!"
                history.append(msg)
                new_state["last_action"] = msg

                current_phase = new_state.get("phase")
                if current_phase == "SPY_GUESS":
                    # Spy had a final guess after being accused and missed -> Non-spies win!
                    new_state["phase"] = "ROUND_RESOLUTION"
                    new_state["round_outcome"] = "SPY_CAUGHT"
                    win_msg = f"NON-SPIES WIN! {spy_name} was caught and failed the location guess (Location was '{loc_name}')."
                    new_state["outcome_reason"] = win_msg
                    new_state["last_action"] = win_msg
                    history.append(win_msg)

                    round_pts = calculate_round_points(
                        player_ids, spy_id, "SPY_CAUGHT", new_state.get("votes", {})
                    )
                    new_state["round_points"] = round_pts
                    cum = dict(new_state.get("cumulative_scores", {}))
                    for pid, p in round_pts.items():
                        cum[pid] = cum.get(pid, 0) + p
                    new_state["cumulative_scores"] = cum
                else:
                    # Guessed incorrectly during discussion -> resume discussion
                    rem = new_state.get("remaining_discussion_seconds", 30)
                    now = time.time()
                    new_state["phase"] = "DISCUSSION"
                    new_state["discussion_end_time"] = now + rem

        elif action == "timer_expired":
            current_phase = new_state.get("phase")
            if current_phase == "ACCUSATION_VOTING":
                # Resolve whatever votes have been cast
                new_state = self._resolve_votes(new_state)
            elif current_phase == "DISCUSSION":
                # Discussion timer ran out! Spy survives without identification
                spy_name = player_names.get(spy_id, "The Spy")
                loc_name = secret_loc["name"]
                new_state["phase"] = "ROUND_RESOLUTION"
                new_state["round_outcome"] = "SPY_SURVIVED_TIME"
                msg = f"TIME EXPIRED! {spy_name} successfully blended in undetected! (Location was '{loc_name}')."
                new_state["outcome_reason"] = msg
                new_state["last_action"] = msg
                history.append(msg)

                round_pts = calculate_round_points(
                    player_ids, spy_id, "SPY_SURVIVED_TIME", new_state.get("votes", {})
                )
                new_state["round_points"] = round_pts
                cum = dict(new_state.get("cumulative_scores", {}))
                for pid, p in round_pts.items():
                    cum[pid] = cum.get(pid, 0) + p
                new_state["cumulative_scores"] = cum

        elif action == "next_round":
            curr_round = new_state["current_round"]
            tot_rounds = new_state["total_rounds"]

            if curr_round >= tot_rounds:
                # Match Over!
                new_state["phase"] = "MATCH_RESULTS"
                # Determine overall winner(s)
                cum = new_state.get("cumulative_scores", {})
                max_pts = max(cum.values()) if cum else 0
                winners = [pid for pid, pts in cum.items() if pts == max_pts]
                new_state["winner_player_ids"] = winners
                winner_names = [player_names.get(w, "Player") for w in winners]
                end_msg = f"Match finished! Winner(s): {', '.join(winner_names)} ({max_pts} pts)!"
                new_state["last_action"] = end_msg
                history.append(end_msg)
            else:
                # Prepare fresh round
                next_round_num = curr_round + 1
                cat = new_state.get("category", "all")
                new_spy_id, new_loc = self.select_random_spy_and_location(player_ids, cat)

                new_roles = {
                    pid: ("spy" if pid == new_spy_id else "explorer") for pid in player_ids
                }
                duration = new_state["discussion_duration_seconds"]

                new_state["current_round"] = next_round_num
                new_state["spy_player_id"] = new_spy_id
                new_state["secret_location"] = new_loc
                new_state["role_assignments"] = new_roles
                new_state["phase"] = "ROLE_REVEAL"
                new_state["acknowledged_players"] = []
                new_state["remaining_discussion_seconds"] = duration
                new_state["discussion_end_time"] = None
                new_state["voting_end_time"] = None
                new_state["accuser_player_id"] = None
                new_state["accused_target_id"] = None
                new_state["votes"] = {}
                new_state["spy_guesses_remaining"] = 1 if new_state["allow_spy_guess"] else 0
                new_state["spy_guessed_location"] = None
                new_state["spy_guess_correct"] = None
                new_state["round_outcome"] = None
                new_state["outcome_reason"] = None
                new_state["round_points"] = {pid: 0 for pid in player_ids}

                msg = f"Round {next_round_num} began! Secret roles and location assigned."
                new_state["last_action"] = msg
                history.append(msg)

        elif action == "rematch":
            # Start fresh match from Round 1 with 0 scores
            new_state = self.create_initial_state(
                player_ids,
                player_names,
                {
                    "category": new_state.get("category", "all"),
                    "round_duration_minutes": new_state.get("round_duration_minutes", 5),
                    "total_rounds": new_state.get("total_rounds", 3),
                    "allow_spy_guess": new_state.get("allow_spy_guess", True),
                },
            )
            new_state["last_action"] = "Rematch initiated! Round 1 begins."

        new_state["updated_at"] = time.time()
        return new_state

    def _resolve_votes(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Tallies votes and applies conviction or returns to discussion."""
        player_ids: List[str] = state["player_ids"]
        player_names: Dict[str, str] = state["player_names"]
        target_id = state.get("accused_target_id")
        target_name = player_names.get(target_id, "The suspect")
        spy_id = state["spy_player_id"]
        spy_name = player_names.get(spy_id, "The Spy")
        secret_loc = state["secret_location"]
        loc_name = secret_loc["name"]
        votes = state.get("votes", {})
        history: List[str] = state["round_history"]

        # Strict majority calculation (> 50% of eligible voters)
        guilty_votes = sum(1 for v in votes.values() if v == "guilty")
        total_voters = len(player_ids)
        strict_majority = total_voters // 2 + 1

        if guilty_votes >= strict_majority:
            # Conviction confirmed!
            tally_msg = f"VOTE PASSED ({guilty_votes}/{len(votes)} votes)! {target_name} was CONVICTED!"
            history.append(tally_msg)

            if target_id == spy_id:
                # Spy was correctly accused!
                if state.get("allow_spy_guess", True) and state.get("spy_guesses_remaining", 0) > 0:
                    # Give Spy one final location guess!
                    state["phase"] = "SPY_GUESS"
                    guess_prompt = f"{spy_name} was caught! The Spy has 1 final chance to guess the location."
                    state["last_action"] = guess_prompt
                    history.append(guess_prompt)
                else:
                    # Non-spies win immediately
                    state["phase"] = "ROUND_RESOLUTION"
                    state["round_outcome"] = "SPY_CAUGHT"
                    win_msg = f"NON-SPIES WIN! {spy_name} was caught! (Location was '{loc_name}')."
                    state["outcome_reason"] = win_msg
                    state["last_action"] = win_msg
                    history.append(win_msg)

                    round_pts = calculate_round_points(player_ids, spy_id, "SPY_CAUGHT", votes)
                    state["round_points"] = round_pts
                    cum = dict(state.get("cumulative_scores", {}))
                    for pid, p in round_pts.items():
                        cum[pid] = cum.get(pid, 0) + p
                    state["cumulative_scores"] = cum
            else:
                # An innocent explorer was convicted! Spy wins!
                state["phase"] = "ROUND_RESOLUTION"
                state["round_outcome"] = "INNOCENT_ACCUSED"
                msg = f"SPY WINS! {target_name} was innocent! The true Spy was {spy_name} (Location was '{loc_name}')."
                state["outcome_reason"] = msg
                state["last_action"] = msg
                history.append(msg)

                round_pts = calculate_round_points(
                    player_ids, spy_id, "INNOCENT_ACCUSED", votes
                )
                state["round_points"] = round_pts
                cum = dict(state.get("cumulative_scores", {}))
                for pid, p in round_pts.items():
                    cum[pid] = cum.get(pid, 0) + p
                state["cumulative_scores"] = cum
        else:
            # Accusation failed! Resume discussion if time remains
            tally_msg = f"VOTE FAILED ({guilty_votes}/{len(votes)} guilty). {target_name} was NOT convicted."
            history.append(tally_msg)

            remaining = state.get("remaining_discussion_seconds", 0)
            if remaining > 0:
                now = time.time()
                state["phase"] = "DISCUSSION"
                state["discussion_end_time"] = now + remaining
                resume_msg = f"Accusation dismissed. Discussion resumes ({remaining}s remaining)."
                state["last_action"] = resume_msg
                history.append(resume_msg)
            else:
                # Timer was already up when vote occurred -> Spy survives
                state["phase"] = "ROUND_RESOLUTION"
                state["round_outcome"] = "SPY_SURVIVED_TIME"
                msg = f"TIME EXPIRED! {spy_name} survived undetected! (Location was '{loc_name}')."
                state["outcome_reason"] = msg
                state["last_action"] = msg
                history.append(msg)

                round_pts = calculate_round_points(player_ids, spy_id, "SPY_SURVIVED_TIME", votes)
                state["round_points"] = round_pts
                cum = dict(state.get("cumulative_scores", {}))
                for pid, p in round_pts.items():
                    cum[pid] = cum.get(pid, 0) + p
                state["cumulative_scores"] = cum

        return state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        phase = state.get("phase")
        moves: List[Dict[str, Any]] = []

        if phase == "ROLE_REVEAL":
            if player_id not in state.get("acknowledged_players", []):
                moves.append({"action": "acknowledge_role"})
        elif phase == "DISCUSSION":
            for target_id in state.get("player_ids", []):
                if target_id != player_id:
                    moves.append({"action": "accuse_player", "target_player_id": target_id})
            if player_id == state.get("spy_player_id") and state.get("spy_guesses_remaining", 0) > 0:
                moves.append({"action": "spy_guess_location"})
        elif phase == "ACCUSATION_VOTING":
            if player_id not in state.get("votes", {}):
                moves.append({"action": "cast_vote", "vote": "guilty"})
                moves.append({"action": "cast_vote", "vote": "innocent"})
        elif phase == "SPY_GUESS":
            if player_id == state.get("spy_player_id"):
                moves.append({"action": "spy_guess_location"})
        elif phase == "ROUND_RESOLUTION":
            moves.append({"action": "next_round"})
        elif phase == "MATCH_RESULTS":
            moves.append({"action": "rematch"})

        return moves

    def filter_state_for_player(
        self, state: Dict[str, Any], player_id: Optional[str]
    ) -> Dict[str, Any]:
        """
        AUTHORITATIVE PRIVACY MASKING:
        - In 'ROLE_REVEAL', 'DISCUSSION', 'ACCUSATION_VOTING', and 'SPY_GUESS':
          * The Spy's identity is strictly hidden from ALL players.
          * The Secret Location is strictly hidden from the Spy.
          * Secret role assignments map is stripped entirely.
          * Only the authenticated player receives 'my_role' ('spy' or 'explorer')
            and 'my_location' (Location name for explorers, null for Spy).
          * Individual secret votes in 'ACCUSATION_VOTING' are masked; only
            'voted_player_ids' is shared so clients know who has submitted without
            leaking choices.
        - In 'ROUND_RESOLUTION' and 'MATCH_RESULTS':
          * All secrets (Spy identity, location, role assignments, vote breakdown)
            are revealed for celebration and transparency.
        """
        phase = state.get("phase")
        masked = dict(state)

        # In resolution or match results, all information is public
        if phase in ("ROUND_RESOLUTION", "MATCH_RESULTS"):
            if player_id:
                spy_id = state.get("spy_player_id")
                masked["my_role"] = "spy" if player_id == spy_id else "explorer"
                if player_id == spy_id:
                    masked["my_location"] = None
                else:
                    sec_loc = state.get("secret_location", {})
                    masked["my_location"] = sec_loc.get("name") if isinstance(sec_loc, dict) else sec_loc
            return masked

        # Otherwise, strictly sanitize and mask all secrets
        masked.pop("role_assignments", None)
        masked.pop("spy_player_id", None)
        masked.pop("secret_location", None)

        # Mask votes during voting phase (expose only list of who voted)
        if phase == "ACCUSATION_VOTING":
            votes = masked.pop("votes", {})
            masked["voted_player_ids"] = list(votes.keys())
        else:
            masked.pop("votes", None)

        # Provide individual player-specific role and location
        if player_id:
            actual_spy_id = state.get("spy_player_id")
            if player_id == actual_spy_id:
                masked["my_role"] = "spy"
                masked["my_location"] = None
                masked["my_location_category"] = None
            else:
                masked["my_role"] = "explorer"
                sec_loc = state.get("secret_location", {})
                masked["my_location"] = sec_loc.get("name") if isinstance(sec_loc, dict) else sec_loc
                masked["my_location_category"] = (
                    sec_loc.get("category") if isinstance(sec_loc, dict) else None
                )
        else:
            masked["my_role"] = None
            masked["my_location"] = None
            masked["my_location_category"] = None

        return masked
