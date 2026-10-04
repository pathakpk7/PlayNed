import random
from typing import Dict, Any, List, Optional, Tuple
from backend.app.games.cricket.data.players import (
    CRICKET_PLAYERS_DATA,
    get_player_by_id,
    CricketPlayer
)

class CricketDraftEngine:
    """
    Cricket Draft Mode Engine:
    - 100 Budget squad drafting
    - Squad requirements: 2 Batters, 1 All-Rounder, 1 Bowler, 1 Wicket-Keeper (5 total)
    - Post-draft tactical squad scoring or 5-over simulated cricket clash
    """

    ROLE_REQUIREMENTS = {
        "Batter": 2,
        "All-Rounder": 1,
        "Bowler": 1,
        "Wicket-Keeper": 1
    }

    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        p1 = player_ids[0] if len(player_ids) > 0 else "p1"
        p2 = player_ids[1] if len(player_ids) > 1 else "p2"

        # Snake Draft Order: 10 picks total (5 per player)
        draft_order = [p1, p2, p2, p1, p1, p2, p2, p1, p1, p2]

        return {
            "mode_id": "draft",
            "status": "drafting", # drafting, draft_complete, match_simulated
            "budget_limit": 100,
            "player_ids": [p1, p2],
            "player_names": player_names,
            "draft_order": draft_order,
            "current_pick_index": 0,
            "current_turn_player_id": draft_order[0],
            
            # Drafted Players: {p1: [player_id, ...], p2: [player_id, ...]}
            "drafted_players": {
                p1: [],
                p2: []
            },
            "squad_slots": {
                p1: {"opening_batter": None, "finisher": None, "all_rounder": None, "wicket_keeper": None, "bowler": None},
                p2: {"opening_batter": None, "finisher": None, "all_rounder": None, "wicket_keeper": None, "bowler": None}
            },
            "remaining_budget": {
                p1: 100,
                p2: 100
            },
            "squad_roles_count": {
                p1: {"Batter": 0, "All-Rounder": 0, "Bowler": 0, "Wicket-Keeper": 0},
                p2: {"Batter": 0, "All-Rounder": 0, "Bowler": 0, "Wicket-Keeper": 0}
            },
            
            # Post Draft Analysis & Match Simulation
            "squad_ratings": {},
            "simulated_match": None,
            "winner_id": None,
            "winner_name": None,
            "last_action": f"{player_names.get(draft_order[0], 'Player 1')} is on the clock to draft their 1st player (Budget: 100)!"
        }

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        if state.get("status") == "match_simulated":
            return False, "Draft match is already completed."

        action = move.get("action")

        if action == "draft_player":
            if state.get("status") != "drafting":
                return False, "Draft is not currently active."

            current_turn = state.get("current_turn_player_id")
            if player_id != current_turn:
                return False, f"It is {state['player_names'].get(current_turn)}'s turn to draft."

            target_player_id = move.get("player_id")
            if not target_player_id:
                return False, "Must specify a player_id to draft."

            player = get_player_by_id(target_player_id)
            if not player:
                return False, f"Invalid cricket player id '{target_player_id}'."

            p1, p2 = state["player_ids"]
            already_drafted = state["drafted_players"][p1] + state["drafted_players"][p2]
            if target_player_id in already_drafted:
                return False, f"{player.name} has already been drafted."

            # Budget Check
            current_budget = state["remaining_budget"][player_id]
            if player.draft_cost > current_budget:
                return False, f"Insufficient budget! {player.name} costs {player.draft_cost} (Remaining: {current_budget})."

            if len(state["drafted_players"][player_id]) >= 5:
                return False, "Squad is already full (5 players)."

            return True, None

        elif action == "simulate_match":
            if state.get("status") != "draft_complete":
                return False, "Both squads must be fully drafted before simulating a clash."
            return True, None

        elif action == "calculate_ratings":
            if state.get("status") not in ("draft_complete", "match_simulated"):
                return False, "Draft must be complete to view ratings."
            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        action = move.get("action")
        pnames = new_state["player_names"]

        if action == "draft_player":
            pid = move.get("player_id")
            slot = move.get("slot")
            player = get_player_by_id(pid)
            role = player.role
            cost = player.draft_cost

            new_state["drafted_players"] = dict(new_state["drafted_players"])
            new_state["drafted_players"][player_id] = list(new_state["drafted_players"][player_id]) + [pid]

            if "squad_slots" in new_state:
                new_state["squad_slots"] = dict(new_state["squad_slots"])
                new_state["squad_slots"][player_id] = dict(new_state["squad_slots"][player_id])
                if slot and slot in new_state["squad_slots"][player_id]:
                    new_state["squad_slots"][player_id][slot] = pid
                else:
                    for s_k, s_v in new_state["squad_slots"][player_id].items():
                        if s_v is None:
                            new_state["squad_slots"][player_id][s_k] = pid
                            break

            new_state["remaining_budget"] = dict(new_state["remaining_budget"])
            new_state["remaining_budget"][player_id] -= cost

            new_state["squad_roles_count"] = dict(new_state["squad_roles_count"])
            new_state["squad_roles_count"][player_id] = dict(new_state["squad_roles_count"][player_id])
            new_state["squad_roles_count"][player_id][role] = new_state["squad_roles_count"][player_id].get(role, 0) + 1

            new_state["current_pick_index"] += 1

            if new_state["current_pick_index"] >= len(new_state["draft_order"]):
                # Draft Complete!
                new_state["status"] = "draft_complete"
                new_state["current_turn_player_id"] = None
                new_state["squad_ratings"] = self._compute_squad_ratings(new_state)
                new_state["last_action"] = f"Draft Completed! Both squads fully assembled within 100 budget. Ready for Tactical Match Simulation!"
            else:
                next_turn_pid = new_state["draft_order"][new_state["current_pick_index"]]
                new_state["current_turn_player_id"] = next_turn_pid
                new_state["last_action"] = f"{pnames.get(player_id)} drafted {player.name} ({cost} pts). {pnames.get(next_turn_pid)} is now on the clock!"

            return new_state

        elif action == "simulate_match":
            new_state["simulated_match"] = self._simulate_5over_clash(new_state)
            new_state["status"] = "match_simulated"
            match = new_state["simulated_match"]
            new_state["winner_id"] = match["winner_id"]
            new_state["winner_name"] = match["winner_name"]
            new_state["last_action"] = match["summary"]
            return new_state

        elif action == "calculate_ratings":
            new_state["squad_ratings"] = self._compute_squad_ratings(new_state)
            return new_state

        return new_state

    def _compute_squad_ratings(self, state: Dict[str, Any]) -> Dict[str, Any]:
        ratings = {}
        for pid in state["player_ids"]:
            player_ids = state["drafted_players"][pid]
            players = [get_player_by_id(i) for i in player_ids if get_player_by_id(i)]

            if not players:
                continue

            batting_power = sum(p.power for p in players) // len(players)
            batting_timing = sum(p.timing for p in players) // len(players)
            batting_overall = sum(p.batting_rating for p in players) // len(players)
            
            bowling_pace = sum(p.pace for p in players) // len(players)
            bowling_accuracy = sum(p.accuracy for p in players) // len(players)
            bowling_overall = sum(p.bowling_rating for p in players) // len(players)

            total_runs = sum(p.international_runs for p in players)
            total_wickets = sum(p.international_wickets for p in players)
            total_cost_used = 100 - state["remaining_budget"][pid]

            overall_team_rating = (batting_overall * 0.5 + bowling_overall * 0.5)

            ratings[pid] = {
                "overall_rating": round(overall_team_rating, 1),
                "batting_rating": batting_overall,
                "bowling_rating": bowling_overall,
                "batting_power": batting_power,
                "batting_timing": batting_timing,
                "bowling_pace": bowling_pace,
                "bowling_accuracy": bowling_accuracy,
                "total_international_runs": total_runs,
                "total_international_wickets": total_wickets,
                "budget_used": total_cost_used
            }
        return ratings

    def _simulate_5over_clash(self, state: Dict[str, Any]) -> Dict[str, Any]:
        p1, p2 = state["player_ids"]
        pnames = state["player_names"]

        p1_players = [get_player_by_id(i) for i in state["drafted_players"][p1]]
        p2_players = [get_player_by_id(i) for i in state["drafted_players"][p2]]

        # Innings 1: P1 Bats vs P2 Bowls (30 balls / 5 overs)
        in1_score, in1_wickets, in1_balls, in1_comm = self._simulate_innings(p1_players, p2_players, target=None)

        # Innings 2: P2 Chases vs P1 Bowls
        target = in1_score + 1
        in2_score, in2_wickets, in2_balls, in2_comm = self._simulate_innings(p2_players, p1_players, target=target)

        winner_id = None
        winner_name = "Draw"
        if in2_score >= target:
            winner_id = p2
            winner_name = pnames.get(p2, "Player 2")
            summary = f"{winner_name} won by {5 - in2_wickets} wickets! (Chased down {target} in {in2_balls} balls)."
        elif in2_score < in1_score:
            winner_id = p1
            winner_name = pnames.get(p1, "Player 1")
            summary = f"{winner_name} won by {in1_score - in2_score} runs! (Defended {in1_score})."
        else:
            summary = f"Match TIED! Both teams scored {in1_score} runs in the 5-over draft clash!"

        return {
            "innings_1": {
                "batting_player_id": p1,
                "runs": in1_score,
                "wickets": in1_wickets,
                "balls": in1_balls,
                "overs": f"{in1_balls // 6}.{in1_balls % 6}",
                "highlights": in1_comm
            },
            "innings_2": {
                "batting_player_id": p2,
                "target": target,
                "runs": in2_score,
                "wickets": in2_wickets,
                "balls": in2_balls,
                "overs": f"{in2_balls // 6}.{in2_balls % 6}",
                "highlights": in2_comm
            },
            "winner_id": winner_id,
            "winner_name": winner_name,
            "summary": summary
        }

    def _simulate_innings(self, batting_team: List[CricketPlayer], bowling_team: List[CricketPlayer], target: Optional[int]) -> Tuple[int, int, int, List[str]]:
        runs = 0
        wickets = 0
        balls = 0
        highlights = []

        batters = [p for p in batting_team if p.role in ("Batter", "Wicket-Keeper", "All-Rounder")]
        bowlers = [p for p in bowling_team if p.role in ("Bowler", "All-Rounder")]

        if not bowlers:
            bowlers = bowling_team

        current_batter_idx = 0

        for ball in range(1, 31): # 5 overs (30 balls)
            balls += 1
            batter = batters[current_batter_idx % len(batters)]
            bowler = bowlers[(ball // 6) % len(bowlers)]

            # Simulation resolution
            bat_power = batter.batting_rating
            bowl_power = bowler.bowling_rating

            chance = random.randint(1, 100) + (bat_power - bowl_power) // 3

            if chance < 12:
                wickets += 1
                highlights.append(f"Over {ball // 6}.{ball % 6}: WICKET! {bowler.name} dismisses {batter.name}!")
                current_batter_idx += 1
                if wickets >= 5:
                    break
            elif chance > 88:
                runs += 6
                highlights.append(f"Over {ball // 6}.{ball % 6}: SIX! {batter.name} launches {bowler.name} over long-on for maximum!")
            elif chance > 70:
                runs += 4
                highlights.append(f"Over {ball // 6}.{ball % 6}: FOUR! {batter.name} crunches a boundary off {bowler.name}.")
            elif chance > 40:
                runs += random.choice([1, 2])
            else:
                runs += 0 # Dot ball

            if target and runs >= target:
                break

        return runs, wickets, balls, highlights

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        status = state.get("status")
        if status == "drafting" and state.get("current_turn_player_id") == player_id:
            return [{"action": "draft_player", "player_id": "id"}]
        elif status == "draft_complete":
            return [{"action": "simulate_match"}, {"action": "calculate_ratings"}]
        return []
