import random
from typing import Dict, Any, List, Optional, Tuple
from backend.app.games.cricket.data.players import get_player_by_id, CricketPlayer

STAT_CHALLENGE_PRESETS = [
    {
        "stat_key": "odi_runs",
        "title": "ODI Runs Milestone",
        "stat_label": "ODI Runs",
        "target": 12000,
        "required_player_count": 5,
        "description": "Select 5 players whose combined ODI Runs are closest to 12,000 without exceeding it."
    },
    {
        "stat_key": "odi_wickets",
        "title": "ODI Wicket Hunters",
        "stat_label": "ODI Wickets",
        "target": 600,
        "required_player_count": 5,
        "description": "Select 5 players whose combined ODI Wickets are closest to 600 without exceeding it."
    },
    {
        "stat_key": "odi_centuries",
        "title": "Century Vault",
        "stat_label": "ODI Centuries",
        "target": 60,
        "required_player_count": 5,
        "description": "Select 5 players whose combined ODI Centuries are closest to 60 without exceeding it."
    },
    {
        "stat_key": "international_sixes",
        "title": "Maximum Sixes",
        "stat_label": "International Sixes",
        "target": 750,
        "required_player_count": 5,
        "description": "Select 5 players whose combined International Sixes are closest to 750 without exceeding it."
    },
    {
        "stat_key": "international_catches",
        "title": "Safe Hands",
        "stat_label": "International Catches",
        "target": 600,
        "required_player_count": 5,
        "description": "Select 5 players whose combined International Catches are closest to 600 without exceeding it."
    },
    {
        "stat_key": "test_runs",
        "title": "Test Cricket Run Mountain",
        "stat_label": "Test Runs",
        "target": 18000,
        "required_player_count": 5,
        "description": "Select 5 players whose combined Test Runs are closest to 18,000 without exceeding it."
    }
]

class StatClashEngine:
    """Server-authoritative Stat Clash game engine."""

    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        options = options or {}
        series_mode = options.get("series_mode", "best_of_3") # single, best_of_3, best_of_5
        
        rounds_to_win = 1 if series_mode == "single" else (2 if series_mode == "best_of_3" else 3)
        max_rounds = 1 if series_mode == "single" else (3 if series_mode == "best_of_3" else 5)

        p1 = player_ids[0] if len(player_ids) > 0 else "p1"
        p2 = player_ids[1] if len(player_ids) > 1 else "p2"

        # Shuffle challenge queue
        challenges = list(STAT_CHALLENGE_PRESETS)
        random.shuffle(challenges)
        active_challenge = challenges[0]

        return {
            "mode_id": "stat_clash",
            "series_mode": series_mode,
            "max_rounds": max_rounds,
            "rounds_to_win": rounds_to_win,
            "current_round": 1,
            "player_ids": [p1, p2],
            "player_names": player_names,
            "series_score": {p1: 0, p2: 0},
            "status": "in_progress", # in_progress, round_resolved, finished
            
            # Active Round Challenge Details
            "challenge_queue": [c["stat_key"] for c in challenges],
            "active_challenge": active_challenge,
            
            # Round Submissions: {p1: {"player_ids": [...], "total": 0, "diff": 0, "busted": False, "submitted": False}}
            "round_submissions": {
                p1: {"player_ids": [], "total": 0, "diff": None, "busted": False, "submitted": False},
                p2: {"player_ids": [], "total": 0, "diff": None, "busted": False, "submitted": False},
            },

            "round_history": [],
            "winner_id": None,
            "winner_name": None,
            "last_action": f"Round 1: {active_challenge['title']}! Build your 5-player squad closest to {active_challenge['target']} {active_challenge['stat_label']}."
        }

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        if state.get("status") == "finished":
            return False, "Match is already finished."

        action = move.get("action")

        if action == "submit_squad":
            if state.get("status") == "round_resolved":
                return False, "Current round is already resolved. Please proceed to the next round."

            players = move.get("player_ids", [])
            req_count = state["active_challenge"]["required_player_count"]

            if len(players) != req_count:
                return False, f"Must select exactly {req_count} players."

            if len(set(players)) != req_count:
                return False, "Duplicate players are not allowed in the squad."

            for pid in players:
                if not get_player_by_id(pid):
                    return False, f"Invalid cricket player id: '{pid}'."

            return True, None

        elif action == "next_round":
            if state.get("status") != "round_resolved":
                return False, "Cannot advance to next round until current round is resolved."
            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        action = move.get("action")
        pname = new_state["player_names"].get(player_id, "Player")

        if action == "submit_squad":
            selected_ids = move.get("player_ids", [])
            stat_key = new_state["active_challenge"]["stat_key"]
            target = new_state["active_challenge"]["target"]

            total_stat = 0
            for pid in selected_ids:
                p = get_player_by_id(pid)
                if p:
                    total_stat += getattr(p, stat_key, 0)

            is_busted = (total_stat > target)
            diff = (target - total_stat) if not is_busted else 999999

            new_state["round_submissions"] = dict(new_state["round_submissions"])
            new_state["round_submissions"][player_id] = {
                "player_ids": selected_ids,
                "total": total_stat,
                "diff": diff,
                "busted": is_busted,
                "submitted": True
            }

            p1, p2 = new_state["player_ids"]
            s1 = new_state["round_submissions"][p1]
            s2 = new_state["round_submissions"][p2]

            if s1["submitted"] and s2["submitted"]:
                return self._resolve_round(new_state)
            else:
                new_state["last_action"] = f"{pname} submitted their 5-player squad! Waiting for opponent."
                return new_state

        elif action == "next_round":
            return self._advance_to_next_round(new_state)

        return new_state

    def _resolve_round(self, state: Dict[str, Any]) -> Dict[str, Any]:
        p1, p2 = state["player_ids"]
        pnames = state["player_names"]
        s1 = state["round_submissions"][p1]
        s2 = state["round_submissions"][p2]
        target = state["active_challenge"]["target"]
        stat_lbl = state["active_challenge"]["stat_label"]

        p1_diff = s1["diff"]
        p2_diff = s2["diff"]

        round_winner = None
        if s1["busted"] and s2["busted"]:
            round_msg = f"Both players busted by exceeding {target} {stat_lbl}! Round is a Tie."
        elif s1["busted"]:
            round_winner = p2
            round_msg = f"{pnames[p2]} wins Round {state['current_round']}! ({s2['total']} vs {pnames[p1]}'s bust of {s1['total']})."
        elif s2["busted"]:
            round_winner = p1
            round_msg = f"{pnames[p1]} wins Round {state['current_round']}! ({s1['total']} vs {pnames[p2]}'s bust of {s2['total']})."
        elif p1_diff < p2_diff:
            round_winner = p1
            round_msg = f"{pnames[p1]} wins Round {state['current_round']}! ({s1['total']} vs {s2['total']}, closer by {p2_diff - p1_diff} {stat_lbl})."
        elif p2_diff < p1_diff:
            round_winner = p2
            round_msg = f"{pnames[p2]} wins Round {state['current_round']}! ({s2['total']} vs {s1['total']}, closer by {p1_diff - p2_diff} {stat_lbl})."
        else:
            round_msg = f"Dead Heat! Both players scored exactly {s1['total']} {stat_lbl}! Round is a Tie."

        if round_winner:
            state["series_score"][round_winner] += 1

        state["status"] = "round_resolved"
        state["last_action"] = round_msg

        state["round_history"].append({
            "round_number": state["current_round"],
            "challenge": state["active_challenge"]["title"],
            "stat_label": stat_lbl,
            "target": target,
            "p1_total": s1["total"],
            "p2_total": s2["total"],
            "p1_busted": s1["busted"],
            "p2_busted": s2["busted"],
            "winner_id": round_winner,
            "winner_name": pnames.get(round_winner, "Tie")
        })

        # Check if series is won
        req_wins = state["rounds_to_win"]
        if state["series_score"][p1] >= req_wins:
            return self._finish_series(state, winner_id=p1)
        elif state["series_score"][p2] >= req_wins:
            return self._finish_series(state, winner_id=p2)
        elif state["current_round"] >= state["max_rounds"]:
            if state["series_score"][p1] > state["series_score"][p2]:
                return self._finish_series(state, winner_id=p1)
            elif state["series_score"][p2] > state["series_score"][p1]:
                return self._finish_series(state, winner_id=p2)
            else:
                return self._finish_series(state, winner_id=None, is_tie=True)

        return state

    def _advance_to_next_round(self, state: Dict[str, Any]) -> Dict[str, Any]:
        state["current_round"] += 1
        p1, p2 = state["player_ids"]

        # Select next challenge from queue or random
        next_idx = (state["current_round"] - 1) % len(STAT_CHALLENGE_PRESETS)
        state["active_challenge"] = STAT_CHALLENGE_PRESETS[next_idx]
        
        state["round_submissions"] = {
            p1: {"player_ids": [], "total": 0, "diff": None, "busted": False, "submitted": False},
            p2: {"player_ids": [], "total": 0, "diff": None, "busted": False, "submitted": False},
        }
        state["status"] = "in_progress"
        c = state["active_challenge"]
        state["last_action"] = f"Round {state['current_round']}: {c['title']}! Target: {c['target']} {c['stat_label']}."
        return state

    def _finish_series(self, state: Dict[str, Any], winner_id: Optional[str], is_tie: bool = False) -> Dict[str, Any]:
        state["status"] = "finished"
        state["is_tie"] = is_tie
        pnames = state["player_names"]
        p1, p2 = state["player_ids"]
        score_str = f"{pnames[p1]} {state['series_score'][p1]} – {state['series_score'][p2]} {pnames[p2]}"

        if is_tie:
            state["winner_id"] = None
            state["winner_name"] = "Draw"
            state["last_action"] = f"SERIES TIED! ({score_str}). An evenly matched statistical contest!"
        else:
            state["winner_id"] = winner_id
            state["winner_name"] = pnames.get(winner_id, "Winner")
            state["last_action"] = f"SERIES VICTORY! {state['winner_name']} wins the Stat Clash ({score_str})!"

        return state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        status = state.get("status")
        if status == "in_progress":
            return [{"action": "submit_squad", "player_ids": ["id1", "id2", "id3", "id4", "id5"]}]
        elif status == "round_resolved":
            return [{"action": "next_round"}]
        return []
