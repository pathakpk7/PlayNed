import random
import time
from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

# Centralized Scoring Configuration as required by rules
ROLE_POINTS: Dict[str, int] = {
    "Raja": 1000,
    "Mantri": 0,
    "Sipahi": 500,
    "Chor": 800
}

ALL_ROLES = ["Raja", "Mantri", "Sipahi", "Chor"]

RAJA_MANTRI_METADATA = GameMetadata(
    id="raja_mantri_chor_sipahi",
    name="Raja Mantri Chor Sipahi",
    tagline="Chit-drawing deduction party game.",
    description="A traditional Indian 4-player bluffing and deduction classic. Draw your secret chit: Raja commands, Mantri deduces, Sipahi guards, and Chor sneaks! Find the thief to claim kingdom glory.",
    category="Classic Indian Games / Party Games",
    min_players=4,
    max_players=4,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    supports_ai=False,
    estimated_duration_minutes=8,
    accent_color_hex="#D97706",
    bg_color_hex="#18130C",
    icon_name="military_tech",
    rules_summary=[
        "Exactly 4 players per round receive one random secret chit: Raja, Mantri, Sipahi, or Chor.",
        "Scoring is fixed per role held: Raja = 1000 pts, Mantri = 0 pts, Sipahi = 500 pts, Chor = 800 pts.",
        "Phase 1: Each player privately views their role chit without revealing it to others.",
        "Phase 2: Raja announces their regal presence ('Mera Mantri Kaun Hai?').",
        "Phase 3: The Mantri steps forward to serve the crown.",
        "Phase 4: The Mantri must guess who the hidden Chor is between the two remaining unrevealed players.",
        "Phase 5: All roles are revealed, round points awarded, and scores accumulate across rounds!"
    ]
)

class RajaMantriEngine(BaseGameEngine):
    @staticmethod
    def get_role_points(role: str) -> int:
        return ROLE_POINTS.get(role, 0)

    @staticmethod
    def shuffle_chits(player_ids: List[str]) -> Dict[str, str]:
        """Fairly shuffles the 4 unique roles among 4 players."""
        if len(player_ids) != 4:
            raise ValueError("Raja Mantri Chor Sipahi requires exactly 4 players.")
        shuffled = list(ALL_ROLES)
        random.shuffle(shuffled)
        return {pid: shuffled[i] for i, pid in enumerate(player_ids)}

    def create_initial_state(
        self,
        player_ids: List[str],
        player_names: Dict[str, str],
        options: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        if len(player_ids) != 4:
            raise ValueError("Raja Mantri Chor Sipahi requires exactly 4 players.")

        options = options or {}
        total_rounds = int(options.get("total_rounds", options.get("rounds", 5)))

        role_assignments = self.shuffle_chits(player_ids)

        raja_pid = next(pid for pid, r in role_assignments.items() if r == "Raja")
        mantri_pid = next(pid for pid, r in role_assignments.items() if r == "Mantri")
        sipahi_pid = next(pid for pid, r in role_assignments.items() if r == "Sipahi")
        chor_pid = next(pid for pid, r in role_assignments.items() if r == "Chor")

        # Two eligible suspects for Mantri to guess from
        eligible_suspects = [sipahi_pid, chor_pid]
        random.shuffle(eligible_suspects)

        cumulative_scores = {pid: 0 for pid in player_ids}

        return {
            "game_id": "raja_mantri_chor_sipahi",
            "phase": "CHIT_REVEAL",  # CHIT_REVEAL, RAJA_REVEAL, MANTRI_REVEAL, CHOR_GUESS, FULL_REVEAL, ROUND_RESULTS, MATCH_RESULTS
            "player_ids": player_ids,
            "player_names": player_names,
            "current_round": 1,
            "total_rounds": total_rounds,
            "role_assignments": role_assignments,  # Internal authoritative secrets
            "revealed_roles": {},  # pid -> role once publicly revealed
            "raja_player_id": raja_pid,
            "mantri_player_id": mantri_pid,
            "sipahi_player_id": sipahi_pid,
            "chor_player_id": chor_pid,
            "eligible_suspect_ids": eligible_suspects,
            "acknowledged_players": [],
            "guessed_chor_player_id": None,
            "guess_correct": None,
            "round_points": {},
            "cumulative_scores": cumulative_scores,
            "round_history": [],
            "status": "in_progress",
            "last_action": "Chits shuffled. Each player must secretly view their role.",
            "started_at": time.time(),
            "updated_at": time.time()
        }

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        action = move.get("action")
        phase = state.get("phase")

        if not action:
            return False, "Missing action in move payload."

        if player_id not in state.get("player_ids", []):
            return False, "Unauthorized player."

        if action == "acknowledge_chit":
            if phase != "CHIT_REVEAL":
                return False, f"Cannot acknowledge chit in phase {phase}."
            return True, None

        elif action == "call_mantri":
            if phase != "RAJA_REVEAL":
                return False, f"Cannot call mantri in phase {phase}."
            # Host or Raja can call
            raja_pid = state.get("raja_player_id")
            host_pid = state.get("player_ids", [])[0]
            if player_id != raja_pid and player_id != host_pid:
                return False, "Only the Raja can summon the Mantri."
            return True, None

        elif action == "step_forward":
            if phase != "MANTRI_REVEAL":
                return False, f"Cannot step forward in phase {phase}."
            mantri_pid = state.get("mantri_player_id")
            host_pid = state.get("player_ids", [])[0]
            if player_id != mantri_pid and player_id != host_pid:
                return False, "Only the Mantri can step forward to identify the Chor."
            return True, None

        elif action == "guess_chor":
            if phase != "CHOR_GUESS":
                return False, f"Cannot submit Chor guess in phase {phase}."

            mantri_pid = state.get("mantri_player_id")
            if player_id != mantri_pid:
                return False, "Only the Mantri is authorized to guess the Chor."

            target_pid = move.get("target_player_id")
            if not target_pid:
                return False, "Must provide target_player_id for Chor guess."

            if target_pid == mantri_pid:
                return False, "The Mantri cannot accuse themselves."

            if target_pid == state.get("raja_player_id"):
                return False, "The Raja cannot be accused of being the Chor."

            eligible = state.get("eligible_suspect_ids", [])
            if target_pid not in eligible:
                return False, "Target player is not an eligible suspect."

            if state.get("guessed_chor_player_id") is not None:
                return False, "A guess has already been locked in for this round."

            return True, None

        elif action == "next_round":
            if phase not in ("FULL_REVEAL", "ROUND_RESULTS"):
                return False, f"Cannot proceed to next round from phase {phase}."
            return True, None

        elif action == "rematch":
            if phase != "MATCH_RESULTS":
                return False, "Rematch only available after match completion."
            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        is_valid, err = self.validate_move(state, player_id, move)
        if not is_valid:
            raise ValueError(err)

        new_state = dict(state)
        action = move.get("action")
        phase = state.get("phase")

        if action == "acknowledge_chit":
            ack = list(new_state.get("acknowledged_players", []))
            if player_id not in ack:
                ack.append(player_id)
            new_state["acknowledged_players"] = ack

            # When all 4 players have acknowledged or in local pass-and-play, advance to RAJA_REVEAL
            if len(ack) >= 4 or move.get("force_advance", False):
                new_state["phase"] = "RAJA_REVEAL"
                raja_pid = new_state["raja_player_id"]
                new_state["revealed_roles"] = {raja_pid: "Raja"}
                raja_name = new_state["player_names"].get(raja_pid, "The King")
                new_state["last_action"] = f"Raja revealed: {raja_name} asks 'Mera Mantri Kaun Hai?'"

        elif action == "call_mantri":
            new_state["phase"] = "MANTRI_REVEAL"
            mantri_pid = new_state["mantri_player_id"]
            rev = dict(new_state.get("revealed_roles", {}))
            rev[mantri_pid] = "Mantri"
            new_state["revealed_roles"] = rev
            mantri_name = new_state["player_names"].get(mantri_pid, "The Minister")
            new_state["last_action"] = f"Mantri stepped forward: {mantri_name} prepares to find the Chor."

        elif action == "step_forward":
            new_state["phase"] = "CHOR_GUESS"
            mantri_pid = new_state["mantri_player_id"]
            mantri_name = new_state["player_names"].get(mantri_pid, "The Minister")
            new_state["last_action"] = f"{mantri_name} must identify the Chor from the two unrevealed players."

        elif action == "guess_chor":
            target_pid = move["target_player_id"]
            actual_chor_pid = new_state["chor_player_id"]
            guess_correct = (target_pid == actual_chor_pid)

            new_state["guessed_chor_player_id"] = target_pid
            new_state["guess_correct"] = guess_correct
            new_state["phase"] = "FULL_REVEAL"

            # Reveal all 4 roles publicly
            new_state["revealed_roles"] = dict(new_state["role_assignments"])

            # Compute fixed scoring as strictly specified
            round_points = {}
            for pid, role in new_state["role_assignments"].items():
                round_points[pid] = self.get_role_points(role)

            new_state["round_points"] = round_points

            # Update cumulative scores
            cumulative = dict(new_state.get("cumulative_scores", {}))
            for pid, pts in round_points.items():
                cumulative[pid] = cumulative.get(pid, 0) + pts
            new_state["cumulative_scores"] = cumulative

            # Record round in history
            target_name = new_state["player_names"].get(target_pid, "Player")
            actual_chor_name = new_state["player_names"].get(actual_chor_pid, "Player")
            outcome_msg = (
                f"Mantri guessed {target_name} correctly! Thief caught!"
                if guess_correct
                else f"Mantri guessed {target_name} incorrectly! {actual_chor_name} was the Chor!"
            )
            new_state["last_action"] = outcome_msg

            history = list(new_state.get("round_history", []))
            history.append({
                "round_number": new_state["current_round"],
                "role_assignments": dict(new_state["role_assignments"]),
                "guessed_chor_player_id": target_pid,
                "actual_chor_player_id": actual_chor_pid,
                "guess_correct": guess_correct,
                "round_points": round_points,
                "cumulative_scores": dict(cumulative)
            })
            new_state["round_history"] = history

        elif action == "next_round":
            current_rnd = new_state["current_round"]
            total_rnds = new_state["total_rounds"]

            if current_rnd >= total_rnds:
                # Match complete
                new_state["phase"] = "MATCH_RESULTS"
                new_state["status"] = "finished"
                # Determine winner(s) with explicit tie handling
                cum = new_state["cumulative_scores"]
                max_score = max(cum.values()) if cum else 0
                winners = [pid for pid, score in cum.items() if score == max_score]
                new_state["winner_player_ids"] = winners
                new_state["is_tie"] = len(winners) > 1

                if len(winners) > 1:
                    winner_names = " & ".join(new_state["player_names"].get(w, w) for w in winners)
                    new_state["last_action"] = f"Match ended in a tie between {winner_names} with {max_score} pts!"
                else:
                    w_name = new_state["player_names"].get(winners[0], winners[0])
                    new_state["last_action"] = f"{w_name} wins the match with {max_score} pts!"
            else:
                # Setup next round
                new_round_num = current_rnd + 1
                player_ids = new_state["player_ids"]
                role_assignments = self.shuffle_chits(player_ids)

                raja_pid = next(pid for pid, r in role_assignments.items() if r == "Raja")
                mantri_pid = next(pid for pid, r in role_assignments.items() if r == "Mantri")
                sipahi_pid = next(pid for pid, r in role_assignments.items() if r == "Sipahi")
                chor_pid = next(pid for pid, r in role_assignments.items() if r == "Chor")

                eligible_suspects = [sipahi_pid, chor_pid]
                random.shuffle(eligible_suspects)

                new_state["phase"] = "CHIT_REVEAL"
                new_state["current_round"] = new_round_num
                new_state["role_assignments"] = role_assignments
                new_state["revealed_roles"] = {}
                new_state["raja_player_id"] = raja_pid
                new_state["mantri_player_id"] = mantri_pid
                new_state["sipahi_player_id"] = sipahi_pid
                new_state["chor_player_id"] = chor_pid
                new_state["eligible_suspect_ids"] = eligible_suspects
                new_state["acknowledged_players"] = []
                new_state["guessed_chor_player_id"] = None
                new_state["guess_correct"] = None
                new_state["round_points"] = {}
                new_state["last_action"] = f"Round {new_round_num} started! View your new secret chits."

        elif action == "rematch":
            player_ids = new_state["player_ids"]
            player_names = new_state["player_names"]
            options = {"total_rounds": new_state["total_rounds"]}
            new_state = self.create_initial_state(player_ids, player_names, options)
            new_state["last_action"] = "Rematch initiated! Round 1 begins."

        new_state["updated_at"] = time.time()
        return new_state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        phase = state.get("phase")
        moves = []

        if phase == "CHIT_REVEAL":
            if player_id not in state.get("acknowledged_players", []):
                moves.append({"action": "acknowledge_chit"})
        elif phase == "RAJA_REVEAL":
            if player_id == state.get("raja_player_id") or player_id == state.get("player_ids", [])[0]:
                moves.append({"action": "call_mantri"})
        elif phase == "MANTRI_REVEAL":
            if player_id == state.get("mantri_player_id") or player_id == state.get("player_ids", [])[0]:
                moves.append({"action": "step_forward"})
        elif phase == "CHOR_GUESS":
            if player_id == state.get("mantri_player_id"):
                for suspect_id in state.get("eligible_suspect_ids", []):
                    moves.append({"action": "guess_chor", "target_player_id": suspect_id})
        elif phase in ("FULL_REVEAL", "ROUND_RESULTS"):
            moves.append({"action": "next_round"})
        elif phase == "MATCH_RESULTS":
            moves.append({"action": "rematch"})

        return moves

    def filter_state_for_player(self, state: Dict[str, Any], player_id: Optional[str]) -> Dict[str, Any]:
        """
        Authoritative Privacy Masking:
        Ensures secret roles are NEVER leaked over the network before FULL_REVEAL.
        Each player receives only their own secret role in 'my_role'.
        Public roles appear only in 'revealed_roles'.
        """
        phase = state.get("phase")

        # In Full Reveal, Round Results, or Match Results, all roles are public
        if phase in ("FULL_REVEAL", "ROUND_RESULTS", "MATCH_RESULTS"):
            masked = dict(state)
            if player_id and "role_assignments" in state:
                masked["my_role"] = state["role_assignments"].get(player_id)
            return masked

        # Otherwise, strictly sanitize and mask secret assignments
        masked = dict(state)

        # 1. Remove the authoritative full mapping completely
        masked.pop("role_assignments", None)

        # 2. Provide the single player their own private role
        actual_assignments = state.get("role_assignments", {})
        if player_id and player_id in actual_assignments:
            masked["my_role"] = actual_assignments[player_id]
        else:
            masked["my_role"] = None

        # 3. Only disclose Raja after RAJA_REVEAL phase
        if phase in ("CHIT_REVEAL",):
            masked["raja_player_id"] = None

        # 4. Only disclose Mantri after MANTRI_REVEAL phase
        if phase in ("CHIT_REVEAL", "RAJA_REVEAL"):
            masked["mantri_player_id"] = None
            masked["eligible_suspect_ids"] = []

        # 5. Never disclose Sipahi or Chor identity before FULL_REVEAL
        masked["sipahi_player_id"] = None
        masked["chor_player_id"] = None

        return masked
