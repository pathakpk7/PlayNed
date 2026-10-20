"""Mafia / Werewolf Game Engine for PlayNed.

Authoritative server state machine supporting 5 to 12 players, role coordination,
hidden night actions, doctor protection, detective investigations, daytime trials,
and complete faction victory calculations.
"""

from enum import Enum
import random
import time
from typing import Dict, Any, List, Optional, Tuple

from backend.app.platform.game_definition import BaseGameEngine, GameMetadata
from backend.app.games.mafia.roles import (
    Faction,
    RoleType,
    ROLE_REGISTRY,
    assign_roles,
)

MAFIA_METADATA = GameMetadata(
    id="mafia",
    name="Mafia / Werewolf",
    tagline="Deceive, deduce, protect, or eliminate. Will Town or Mafia survive?",
    description=(
        "Classic social deduction game for 5–12 players. Secret roles are assigned at night: "
        "the Mafia coordinates eliminations, the Doctor protects lives, and the Detective "
        "investigates suspects. By day, surviving citizens debate and vote to exile the guilty."
    ),
    category="Social Deduction / Party Games",
    min_players=5,
    max_players=12,
    supports_local=True,
    supports_online=True,
    supports_teams=True,
    supports_ai=False,
    estimated_duration_minutes=10,
    accent_color_hex="#991B1B",
    bg_color_hex="#140D11",
    icon_name="nightlight_round",
    rules_summary=[
        "5 to 12 players receive secret roles: Town (Villagers, Doctor, Detective) vs Mafia.",
        "Night Phase: Mafia votes on an elimination target; Doctor chooses one living citizen to save; Detective investigates one suspect for Mafia affiliation.",
        "Morning Announcement: The town discovers who was eliminated or if the Doctor made a heroic save.",
        "Day Discussion: Surviving players debate suspicious behavior during a timed discussion.",
        "Day Voting: Each living player casts one secret vote. The suspect with the strict plurality of votes is exiled. Ties result in no elimination.",
        "Win Conditions: Town wins when all Mafia members are eliminated. Mafia wins when living Mafia count equals or exceeds living Town members.",
    ],
)


class MafiaPhase(str, Enum):
    ROLE_REVEAL = "ROLE_REVEAL"
    NIGHT_ACTIONS = "NIGHT_ACTIONS"
    NIGHT_RESOLUTION = "NIGHT_RESOLUTION"
    DAY_ANNOUNCEMENT = "DAY_ANNOUNCEMENT"
    DAY_DISCUSSION = "DAY_DISCUSSION"
    DAY_VOTING = "DAY_VOTING"
    VOTE_RESOLUTION = "VOTE_RESOLUTION"
    MATCH_RESULTS = "MATCH_RESULTS"


class MafiaEngine(BaseGameEngine):
    def create_initial_state(
        self,
        player_ids: List[str],
        player_names: Dict[str, str],
        options: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        n = len(player_ids)
        if n < 5 or n > 12:
            raise ValueError(f"Mafia requires between 5 and 12 players (got {n}).")

        opts = options or {}
        seed = opts.get("seed")
        include_jester = bool(opts.get("include_jester", False))
        include_bodyguard = bool(opts.get("include_bodyguard", False))
        discussion_duration_seconds = int(opts.get("discussion_duration_seconds", 120))
        allow_self_heal = bool(opts.get("allow_self_heal", False))
        reveal_role_on_death = bool(opts.get("reveal_role_on_death", True))

        role_assignments = assign_roles(
            player_ids=player_ids,
            seed=seed,
            include_jester=include_jester,
            include_bodyguard=include_bodyguard,
        )

        state: Dict[str, Any] = {
            "game_id": "mafia",
            "player_ids": list(player_ids),
            "player_names": dict(player_names),
            "phase": MafiaPhase.ROLE_REVEAL.value,
            "round_number": 1,
            "alive_status": {pid: True for pid in player_ids},
            "role_assignments": role_assignments,
            "acknowledged_players": [],
            # Night Phase Tracking
            "night_actions": {
                "mafia_votes": {},       # {mafia_player_id: target_player_id}
                "doctor_target": None,   # target_player_id
                "detective_target": None,# target_player_id
                "bodyguard_target": None,# target_player_id
            },
            "investigation_results": {}, # {detective_player_id: [{"target_id": ..., "target_name": ..., "is_mafia": ...}]}
            "last_night_casualty": None, # player_id or None
            "last_voted_out": None,      # player_id or None
            # Day Discussion & Voting
            "discussion_duration_seconds": discussion_duration_seconds,
            "discussion_end_time": None,
            "voting_end_time": None,
            "votes": {},                 # {voter_id: target_id}
            "voted_player_ids": [],
            # Game Rules Options
            "allow_self_heal": allow_self_heal,
            "reveal_role_on_death": reveal_role_on_death,
            "include_jester": include_jester,
            "include_bodyguard": include_bodyguard,
            # Win State
            "winning_faction": None,     # "town", "mafia", "jester"
            "winner_player_ids": [],
            "log": ["Match initialized. Secret roles assigned privately."],
            "last_action": "Match started! Inspect your secret role privately.",
            "created_at": time.time(),
            "updated_at": time.time(),
        }
        return state

    def validate_move(
        self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]
    ) -> Tuple[bool, Optional[str]]:
        if player_id not in state.get("player_ids", []):
            return False, f"Player {player_id} is not part of this match."

        action = move.get("action")
        if not action:
            return False, "Move is missing an 'action' field."

        phase = state.get("phase")
        is_alive = state.get("alive_status", {}).get(player_id, False)

        # Actions allowed when dead (only acknowledging or viewing)
        if not is_alive and action not in ("acknowledge_role", "next_round", "rematch"):
            return False, "Dead players cannot take active gameplay actions or vote."

        if action == "acknowledge_role":
            if phase != MafiaPhase.ROLE_REVEAL.value:
                return False, "Role acknowledgement is only valid during the ROLE_REVEAL phase."
            return True, None

        if action == "mafia_vote":
            if phase != MafiaPhase.NIGHT_ACTIONS.value:
                return False, "Mafia votes can only be submitted during NIGHT_ACTIONS phase."
            role = state.get("role_assignments", {}).get(player_id)
            if role != RoleType.MAFIA.value:
                return False, "Only living Mafia members can submit Mafia elimination votes."
            target = move.get("target_id") or move.get("target_player_id")
            if not target or not state.get("alive_status", {}).get(target, False):
                return False, "Mafia target must be a living player."
            return True, None

        if action == "doctor_protect":
            if phase != MafiaPhase.NIGHT_ACTIONS.value:
                return False, "Doctor protection can only be submitted during NIGHT_ACTIONS phase."
            role = state.get("role_assignments", {}).get(player_id)
            if role != RoleType.DOCTOR.value:
                return False, "Only the Doctor can perform medical protection."
            target = move.get("target_id") or move.get("target_player_id")
            if not target or not state.get("alive_status", {}).get(target, False):
                return False, "Doctor target must be a living player."
            if not state.get("allow_self_heal", False) and target == player_id:
                return False, "Doctor cannot protect themselves under current game rules."
            return True, None

        if action == "detective_investigate":
            if phase != MafiaPhase.NIGHT_ACTIONS.value:
                return False, "Detective investigation can only be submitted during NIGHT_ACTIONS phase."
            role = state.get("role_assignments", {}).get(player_id)
            if role != RoleType.DETECTIVE.value:
                return False, "Only the Detective can investigate suspects."
            target = move.get("target_id") or move.get("target_player_id")
            if not target or not state.get("alive_status", {}).get(target, False):
                return False, "Investigation target must be a living player."
            if target == player_id:
                return False, "Detective cannot investigate themselves."
            return True, None

        if action == "bodyguard_protect":
            if phase != MafiaPhase.NIGHT_ACTIONS.value:
                return False, "Bodyguard protection can only be submitted during NIGHT_ACTIONS phase."
            role = state.get("role_assignments", {}).get(player_id)
            if role != RoleType.BODYGUARD.value:
                return False, "Only the Bodyguard can guard a citizen."
            target = move.get("target_id") or move.get("target_player_id")
            if not target or not state.get("alive_status", {}).get(target, False):
                return False, "Bodyguard target must be a living player."
            return True, None

        if action == "resolve_night":
            if phase != MafiaPhase.NIGHT_ACTIONS.value:
                return False, "Can only resolve night from NIGHT_ACTIONS phase."
            return True, None

        if action == "acknowledge_announcement":
            if phase != MafiaPhase.DAY_ANNOUNCEMENT.value:
                return False, "Can only acknowledge announcement during DAY_ANNOUNCEMENT phase."
            return True, None

        if action == "start_voting":
            if phase != MafiaPhase.DAY_DISCUSSION.value:
                return False, "Can only transition to voting during DAY_DISCUSSION phase."
            return True, None

        if action in ("cast_vote", "vote"):
            if phase != MafiaPhase.DAY_VOTING.value:
                return False, "Votes can only be cast during DAY_VOTING phase."
            target = move.get("target_id") or move.get("target_player_id")
            # Allow 'abstain' / 'skip'
            if target and target not in ("abstain", "skip"):
                if not state.get("alive_status", {}).get(target, False):
                    return False, "Voted suspect must be a living player."
                if target == player_id:
                    return False, "Players cannot vote for themselves."
            return True, None

        if action == "resolve_voting":
            if phase != MafiaPhase.DAY_VOTING.value:
                return False, "Can only resolve voting from DAY_VOTING phase."
            return True, None

        if action == "next_night":
            if phase not in (MafiaPhase.VOTE_RESOLUTION.value, MafiaPhase.DAY_ANNOUNCEMENT.value):
                return False, "Can only start next night from resolution phase."
            return True, None

        if action == "rematch":
            if phase != MafiaPhase.MATCH_RESULTS.value:
                return False, "Rematch is only available when the match has concluded."
            return True, None

        return False, f"Unknown action: {action}"

    def apply_move(
        self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]
    ) -> Dict[str, Any]:
        is_valid, err = self.validate_move(state, player_id, move)
        if not is_valid:
            raise ValueError(err)

        action = move["action"]
        history = list(state.get("log", []))
        now = time.time()
        pname = state.get("player_names", {}).get(player_id, player_id)

        # 1. ROLE REVEAL ACKNOWLEDGEMENT
        if action == "acknowledge_role":
            ack = list(state.get("acknowledged_players", []))
            if player_id not in ack:
                ack.append(player_id)
            state["acknowledged_players"] = ack

            if len(ack) >= len(state["player_ids"]) or move.get("force_advance", False):
                msg = "All players acknowledged their roles. Night 1 descends upon the town."
                history.append(msg)
                state["phase"] = MafiaPhase.NIGHT_ACTIONS.value
                state["night_actions"] = {
                    "mafia_votes": {},
                    "doctor_target": None,
                    "detective_target": None,
                    "bodyguard_target": None,
                }
                state["last_action"] = msg
            else:
                state["last_action"] = f"{pname} acknowledged their role."

        # 2. NIGHT ACTIONS
        elif action == "mafia_vote":
            target = move.get("target_id") or move.get("target_player_id")
            mafia_votes = dict(state.get("night_actions", {}).get("mafia_votes", {}))
            mafia_votes[player_id] = target
            state["night_actions"]["mafia_votes"] = mafia_votes
            state["last_action"] = f"Mafia member {pname} updated their target."
            if self._all_night_actions_submitted(state) or move.get("force_resolve", False):
                return self._resolve_night_actions(state)

        elif action == "doctor_protect":
            target = move.get("target_id") or move.get("target_player_id")
            state["night_actions"]["doctor_target"] = target
            state["last_action"] = "Doctor selected a patient to protect."
            if self._all_night_actions_submitted(state) or move.get("force_resolve", False):
                return self._resolve_night_actions(state)

        elif action == "detective_investigate":
            target = move.get("target_id") or move.get("target_player_id")
            state["night_actions"]["detective_target"] = target
            state["last_action"] = "Detective began investigating a suspect."
            if self._all_night_actions_submitted(state) or move.get("force_resolve", False):
                return self._resolve_night_actions(state)

        elif action == "bodyguard_protect":
            target = move.get("target_id") or move.get("target_player_id")
            state["night_actions"]["bodyguard_target"] = target
            state["last_action"] = "Bodyguard took up guard position."
            if self._all_night_actions_submitted(state) or move.get("force_resolve", False):
                return self._resolve_night_actions(state)

        elif action == "resolve_night":
            return self._resolve_night_actions(state)

        # 3. DAY ANNOUNCEMENT ACKNOWLEDGEMENT / TRANSITION
        elif action == "acknowledge_announcement":
            msg = f"Day {state['round_number']} discussion begins ({state['discussion_duration_seconds']}s timer)."
            history.append(msg)
            state["phase"] = MafiaPhase.DAY_DISCUSSION.value
            state["discussion_end_time"] = now + state["discussion_duration_seconds"]
            state["last_action"] = msg

        # 4. START DAY VOTING
        elif action == "start_voting":
            msg = f"Day {state['round_number']} discussion concluded. Court is in session—cast your votes!"
            history.append(msg)
            state["phase"] = MafiaPhase.DAY_VOTING.value
            state["votes"] = {}
            state["voted_player_ids"] = []
            state["voting_end_time"] = now + 60.0
            state["last_action"] = msg

        # 5. CAST DAY VOTE
        elif action in ("cast_vote", "vote"):
            target = move.get("target_id") or move.get("target_player_id")
            votes = dict(state.get("votes", {}))
            votes[player_id] = target
            voted_pids = list(state.get("voted_player_ids", []))
            if player_id not in voted_pids:
                voted_pids.append(player_id)

            state["votes"] = votes
            state["voted_player_ids"] = voted_pids
            state["last_action"] = f"{pname} cast their vote."

            living_count = sum(1 for alive in state.get("alive_status", {}).values() if alive)
            if len(votes) >= living_count or move.get("force_resolve", False):
                return self._resolve_day_voting(state)

        elif action == "resolve_voting":
            return self._resolve_day_voting(state)

        # 6. ADVANCE TO NEXT NIGHT
        elif action == "next_night":
            next_round = state["round_number"] + 1
            state["round_number"] = next_round
            msg = f"Night {next_round} falls upon the town. Citizens sleep as shadows stir."
            history.append(msg)
            state["phase"] = MafiaPhase.NIGHT_ACTIONS.value
            state["night_actions"] = {
                "mafia_votes": {},
                "doctor_target": None,
                "detective_target": None,
                "bodyguard_target": None,
            }
            state["last_action"] = msg

        # 7. REMATCH
        elif action == "rematch":
            return self.create_initial_state(
                player_ids=state["player_ids"],
                player_names=state["player_names"],
                options={
                    "discussion_duration_seconds": state["discussion_duration_seconds"],
                    "allow_self_heal": state["allow_self_heal"],
                    "reveal_role_on_death": state["reveal_role_on_death"],
                    "include_jester": state["include_jester"],
                    "include_bodyguard": state["include_bodyguard"],
                },
            )

        state["log"] = history
        state["updated_at"] = now
        return state

    def _all_night_actions_submitted(self, state: Dict[str, Any]) -> bool:
        """Checks if all required living roles have submitted their night actions."""
        alive_status = state.get("alive_status", {})
        roles = state.get("role_assignments", {})
        actions = state.get("night_actions", {})

        # Living Mafia
        living_mafia = [
            pid for pid, is_alive in alive_status.items()
            if is_alive and roles.get(pid) == RoleType.MAFIA.value
        ]
        mafia_votes = actions.get("mafia_votes", {})
        if living_mafia and not all(m_id in mafia_votes for m_id in living_mafia):
            return False

        # Living Doctor
        living_doctor = [
            pid for pid, is_alive in alive_status.items()
            if is_alive and roles.get(pid) == RoleType.DOCTOR.value
        ]
        if living_doctor and actions.get("doctor_target") is None:
            return False

        # Living Detective
        living_detective = [
            pid for pid, is_alive in alive_status.items()
            if is_alive and roles.get(pid) == RoleType.DETECTIVE.value
        ]
        if living_detective and actions.get("detective_target") is None:
            return False

        return True

    def _resolve_night_actions(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Resolves attacks, protection, and investigations authoritatively."""
        history = list(state.get("log", []))
        alive_status = dict(state.get("alive_status", {}))
        roles = state.get("role_assignments", {})
        actions = state.get("night_actions", {})

        # 1. Determine Mafia Faction Target
        mafia_votes = actions.get("mafia_votes", {})
        target_counts: Dict[str, int] = {}
        for tgt in mafia_votes.values():
            if tgt and alive_status.get(tgt, False):
                target_counts[tgt] = target_counts.get(tgt, 0) + 1

        attack_target: Optional[str] = None
        if target_counts:
            # Pick target with highest votes (plurality)
            attack_target = max(target_counts, key=target_counts.get)

        # 2. Determine Protections
        doctor_target = actions.get("doctor_target")
        bodyguard_target = actions.get("bodyguard_target")
        is_saved = attack_target is not None and (
            attack_target == doctor_target or attack_target == bodyguard_target
        )

        casualty: Optional[str] = None
        if attack_target and not is_saved:
            casualty = attack_target
            alive_status[casualty] = False
            victim_name = state.get("player_names", {}).get(casualty, casualty)
            victim_role = roles.get(casualty, "Unknown")
            if state.get("reveal_role_on_death", True):
                msg = f"Night casualty: {victim_name} was found dead! They were a {victim_role.upper()}."
            else:
                msg = f"Night casualty: {victim_name} was found dead!"
            history.append(msg)
        elif is_saved:
            msg = "Morning arrives. The town awakens to find that nobody died last night!"
            history.append(msg)
        else:
            msg = "Morning arrives. The town was quiet—nobody was attacked."
            history.append(msg)

        # 3. Resolve Detective Investigation
        detective_target = actions.get("detective_target")
        if detective_target:
            living_detectives = [
                pid for pid, alive in alive_status.items()
                if alive and roles.get(pid) == RoleType.DETECTIVE.value
            ]
            target_role = roles.get(detective_target)
            target_name = state.get("player_names", {}).get(detective_target, detective_target)
            is_mafia = (target_role == RoleType.MAFIA.value)

            inv_res = dict(state.get("investigation_results", {}))
            for det_id in living_detectives:
                det_history = list(inv_res.get(det_id, []))
                det_history.append({
                    "round": state["round_number"],
                    "target_id": detective_target,
                    "target_name": target_name,
                    "is_mafia": is_mafia,
                })
                inv_res[det_id] = det_history
            state["investigation_results"] = inv_res

        state["alive_status"] = alive_status
        state["last_night_casualty"] = casualty

        # 4. Check Win Conditions After Night
        winner = self._check_win_conditions(state)
        if winner:
            return self._conclude_match(state, winner, history)

        state["phase"] = MafiaPhase.DAY_ANNOUNCEMENT.value
        state["last_action"] = msg
        state["log"] = history
        state["updated_at"] = time.time()
        return state

    def _resolve_day_voting(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Tallies votes, exiles player if strict plurality, and checks win conditions."""
        history = list(state.get("log", []))
        alive_status = dict(state.get("alive_status", {}))
        roles = state.get("role_assignments", {})
        votes = state.get("votes", {})

        # Tally valid votes for living players
        vote_counts: Dict[str, int] = {}
        for voter_id, target in votes.items():
            if target and target not in ("abstain", "skip") and alive_status.get(target, False):
                vote_counts[target] = vote_counts.get(target, 0) + 1

        exiled_id: Optional[str] = None
        if vote_counts:
            sorted_votes = sorted(vote_counts.items(), key=lambda x: x[1], reverse=True)
            top_target, top_count = sorted_votes[0]

            # Check for tie
            if len(sorted_votes) > 1 and sorted_votes[1][1] == top_count:
                # Tie! Nobody is eliminated
                tie_names = [
                    state.get("player_names", {}).get(tgt, tgt)
                    for tgt, cnt in sorted_votes if cnt == top_count
                ]
                msg = f"Voting tied ({top_count} votes each for {', '.join(tie_names)}). No citizen was exiled today!"
                history.append(msg)
            else:
                exiled_id = top_target
                alive_status[exiled_id] = False
                exiled_name = state.get("player_names", {}).get(exiled_id, exiled_id)
                exiled_role = roles.get(exiled_id, "Unknown")

                if state.get("reveal_role_on_death", True):
                    msg = f"The town voted ({top_count} votes) to exile {exiled_name}! Their true role was {exiled_role.upper()}."
                else:
                    msg = f"The town voted ({top_count} votes) to exile {exiled_name}."
                history.append(msg)

                # JESTER WIN CONDITION
                if exiled_role == RoleType.JESTER.value:
                    state["alive_status"] = alive_status
                    state["last_voted_out"] = exiled_id
                    return self._conclude_match(state, "jester", history, jester_id=exiled_id)
        else:
            msg = "The town abstained from voting. No citizen was exiled today."
            history.append(msg)

        state["alive_status"] = alive_status
        state["last_voted_out"] = exiled_id

        # Check Win Conditions After Day Voting
        winner = self._check_win_conditions(state)
        if winner:
            return self._conclude_match(state, winner, history)

        state["phase"] = MafiaPhase.VOTE_RESOLUTION.value
        state["last_action"] = msg
        state["log"] = history
        state["updated_at"] = time.time()
        return state

    def _check_win_conditions(self, state: Dict[str, Any]) -> Optional[str]:
        """
        Determines if Town or Mafia has won:
        - Town wins when ALL Mafia are dead.
        - Mafia wins when living Mafia >= living non-Mafia.
        """
        alive_status = state.get("alive_status", {})
        roles = state.get("role_assignments", {})

        living_mafia = 0
        living_non_mafia = 0

        for pid, alive in alive_status.items():
            if alive:
                if roles.get(pid) == RoleType.MAFIA.value:
                    living_mafia += 1
                else:
                    living_non_mafia += 1

        if living_mafia == 0:
            return "town"

        if living_mafia >= living_non_mafia:
            return "mafia"

        return None

    def _conclude_match(
        self, state: Dict[str, Any], winner: str, history: List[str], jester_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Sets game over status and winners."""
        roles = state.get("role_assignments", {})
        winner_pids: List[str] = []

        if winner == "town":
            winner_pids = [
                pid for pid, role in roles.items()
                if role in (RoleType.VILLAGER.value, RoleType.DOCTOR.value, RoleType.DETECTIVE.value, RoleType.BODYGUARD.value)
            ]
            win_msg = "VICTORY FOR THE TOWN! All Mafia members have been eliminated!"
        elif winner == "mafia":
            winner_pids = [
                pid for pid, role in roles.items()
                if role == RoleType.MAFIA.value
            ]
            win_msg = "VICTORY FOR THE MAFIA! The syndicate has overpowered the town!"
        elif winner == "jester" and jester_id:
            winner_pids = [jester_id]
            j_name = state.get("player_names", {}).get(jester_id, jester_id)
            win_msg = f"JESTER VICTORY! {j_name} fooled the entire town and got themselves exiled!"
        else:
            win_msg = "Match ended."

        history.append(win_msg)
        state["phase"] = MafiaPhase.MATCH_RESULTS.value
        state["winning_faction"] = winner
        state["winner_player_ids"] = winner_pids
        state["last_action"] = win_msg
        state["log"] = history
        state["updated_at"] = time.time()
        return state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        phase = state.get("phase")
        alive_status = state.get("alive_status", {})
        is_alive = alive_status.get(player_id, False)
        roles = state.get("role_assignments", {})
        my_role = roles.get(player_id)
        moves: List[Dict[str, Any]] = []

        if not is_alive and phase not in (MafiaPhase.ROLE_REVEAL.value, MafiaPhase.MATCH_RESULTS.value):
            return moves

        if phase == MafiaPhase.ROLE_REVEAL.value:
            if player_id not in state.get("acknowledged_players", []):
                moves.append({"action": "acknowledge_role"})
        elif phase == MafiaPhase.NIGHT_ACTIONS.value:
            living_targets = [pid for pid, alive in alive_status.items() if alive]
            if my_role == RoleType.MAFIA.value:
                for tgt in living_targets:
                    moves.append({"action": "mafia_vote", "target_id": tgt})
            elif my_role == RoleType.DOCTOR.value:
                allow_self = state.get("allow_self_heal", False)
                for tgt in living_targets:
                    if allow_self or tgt != player_id:
                        moves.append({"action": "doctor_protect", "target_id": tgt})
            elif my_role == RoleType.DETECTIVE.value:
                for tgt in living_targets:
                    if tgt != player_id:
                        moves.append({"action": "detective_investigate", "target_id": tgt})
            elif my_role == RoleType.BODYGUARD.value:
                for tgt in living_targets:
                    moves.append({"action": "bodyguard_protect", "target_id": tgt})
        elif phase == MafiaPhase.DAY_ANNOUNCEMENT.value:
            moves.append({"action": "acknowledge_announcement"})
        elif phase == MafiaPhase.DAY_DISCUSSION.value:
            moves.append({"action": "start_voting"})
        elif phase == MafiaPhase.DAY_VOTING.value:
            if player_id not in state.get("votes", {}):
                living_targets = [pid for pid, alive in alive_status.items() if alive and pid != player_id]
                for tgt in living_targets:
                    moves.append({"action": "cast_vote", "target_id": tgt})
                moves.append({"action": "cast_vote", "target_id": "abstain"})
        elif phase == MafiaPhase.VOTE_RESOLUTION.value:
            moves.append({"action": "next_night"})
        elif phase == MafiaPhase.MATCH_RESULTS.value:
            moves.append({"action": "rematch"})

        return moves

    def filter_state_for_player(
        self, state: Dict[str, Any], player_id: Optional[str]
    ) -> Dict[str, Any]:
        """
        AUTHORITATIVE PRIVACY MASKING:
        - When 'MATCH_RESULTS': full transparency, all roles revealed.
        - During live gameplay:
          * 'role_assignments' is strictly hidden from clients.
          * 'player_id' receives their own 'my_role' and role details.
          * If 'my_role == mafia', player receives 'mafia_teammates' (all Mafia player IDs).
            Non-mafia receive no information about Mafia members.
          * If 'my_role == detective', player receives their own 'investigations'.
            Non-detectives never receive investigation results.
          * Night action targets (mafia votes, doctor target, detective target) are
            strictly hidden from players not holding that role.
          * During DAY_VOTING: individual votes are hidden; only 'voted_player_ids' is exposed.
        """
        phase = state.get("phase")
        masked = dict(state)

        # Full reveal at match end
        if phase == MafiaPhase.MATCH_RESULTS.value:
            if player_id:
                roles = state.get("role_assignments", {})
                masked["my_role"] = roles.get(player_id)
            return masked

        # Strip authoritative global secrets
        roles = state.get("role_assignments", {})
        masked.pop("role_assignments", None)

        # Provide individual role details
        my_role = roles.get(player_id) if player_id else None
        masked["my_role"] = my_role

        # Mafia Coordination
        if my_role == RoleType.MAFIA.value:
            masked["mafia_teammates"] = [
                pid for pid, r in roles.items() if r == RoleType.MAFIA.value
            ]
        else:
            masked["mafia_teammates"] = []
            # Hide Mafia night votes from non-Mafia
            if "night_actions" in masked:
                night_copy = dict(masked["night_actions"])
                night_copy["mafia_votes"] = {}
                masked["night_actions"] = night_copy

        # Detective Private Intelligence
        if my_role == RoleType.DETECTIVE.value and player_id:
            inv_map = state.get("investigation_results", {})
            masked["my_investigations"] = inv_map.get(player_id, [])
        else:
            masked["my_investigations"] = []
        masked.pop("investigation_results", None)

        # Doctor / Bodyguard target privacy
        if "night_actions" in masked:
            night_copy = dict(masked["night_actions"])
            if my_role != RoleType.DOCTOR.value:
                night_copy["doctor_target"] = None
            if my_role != RoleType.BODYGUARD.value:
                night_copy["bodyguard_target"] = None
            masked["night_actions"] = night_copy

        # Mask day votes until resolution
        if phase == MafiaPhase.DAY_VOTING.value:
            votes = masked.pop("votes", {})
            masked["voted_player_ids"] = list(votes.keys())

        return masked
