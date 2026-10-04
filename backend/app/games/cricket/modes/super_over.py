import random
from typing import Dict, Any, List, Optional, Tuple
from backend.app.games.cricket.data.players import get_player_by_id, CricketPlayer

class SuperOverEngine:
    """Server-authoritative Super Over Duel match engine."""

    DELIVERY_TYPES = ["GOOD_LENGTH", "YORKER", "BOUNCER", "FULL", "SLOWER"]
    SHOT_TYPES = ["DEFEND", "NORMAL", "ATTACK", "LOFT"]

    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        player_ids = player_ids[:2] if len(player_ids) >= 2 else ["p1", "p2"]
        p1, p2 = player_ids[0], player_ids[1]

        return {
            "mode_id": "super_over",
            "player_ids": [p1, p2],
            "player_names": player_names,
            "status": "selection", # selection -> innings_1 -> innings_2 -> match_finished
            "phase": "selection", # select_team, waiting_delivery, delivery_resolved
            
            # Selections: {player_id: {"batters": [id1, id2], "bowler": id3, "ready": bool}}
            "selections": {
                p1: {"batters": [], "bowler": None, "ready": False},
                p2: {"batters": [], "bowler": None, "ready": False},
            },

            # Innings Tracking
            "current_innings": 1, # 1 or 2
            "batting_player_id": p1,
            "bowling_player_id": p2,
            
            # Innings 1 details
            "innings_1": {
                "batting_player_id": p1,
                "bowling_player_id": p2,
                "total_runs": 0,
                "wickets": 0,
                "legal_balls": 0,
                "active_batter_index": 0, # 0 -> batter 1, 1 -> batter 2
                "deliveries": [], # List of ball details
            },

            # Innings 2 details
            "innings_2": {
                "batting_player_id": p2,
                "bowling_player_id": p1,
                "target": 0,
                "total_runs": 0,
                "wickets": 0,
                "legal_balls": 0,
                "active_batter_index": 0,
                "deliveries": [],
            },

            # Active Ball Inputs
            "pending_bowler_action": None, # delivery type
            "pending_batter_action": None, # shot type
            "last_delivery_result": None,
            "winner_id": None,
            "winner_name": None,
            "last_action": f"Super Over Duel started! Both players select 2 batters and 1 bowler."
        }

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        if state.get("status") == "match_finished":
            return False, "Match is already finished."

        action = move.get("action")

        if action == "select_players":
            if state.get("status") != "selection":
                return False, "Player selection phase is closed."
            
            batters = move.get("batters", [])
            bowler = move.get("bowler")

            if len(batters) != 2:
                return False, "Must select exactly 2 batters."
            if batters[0] == batters[1]:
                return False, "Cannot select the same batter twice."
            if not bowler:
                return False, "Must select 1 bowler."
            if bowler in batters:
                # Allowed in cricket (all-rounder can bowl and bat), but check existence
                pass

            for bid in batters + [bowler]:
                if not get_player_by_id(bid):
                    return False, f"Invalid cricket player id: '{bid}'."

            return True, None

        elif action == "bowl_delivery":
            if state.get("status") not in ("innings_1", "innings_2"):
                return False, "Match is not currently in a live innings."

            current_bowler = state.get("bowling_player_id")
            if player_id != current_bowler:
                return False, f"Only the bowling player ({state.get('player_names', {}).get(current_bowler)}) can bowl."

            delivery_type = move.get("delivery_type")
            if delivery_type not in self.DELIVERY_TYPES:
                return False, f"Invalid delivery type '{delivery_type}'. Must be one of {self.DELIVERY_TYPES}."

            return True, None

        elif action == "play_shot":
            if state.get("status") not in ("innings_1", "innings_2"):
                return False, "Match is not currently in a live innings."

            current_batter = state.get("batting_player_id")
            if player_id != current_batter:
                return False, f"Only the batting player ({state.get('player_names', {}).get(current_batter)}) can play a shot."

            shot_type = move.get("shot_type")
            if shot_type not in self.SHOT_TYPES:
                return False, f"Invalid shot type '{shot_type}'. Must be one of {self.SHOT_TYPES}."

            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        action = move.get("action")
        pname = new_state["player_names"].get(player_id, "Player")

        if action == "select_players":
            batters = move.get("batters", [])
            bowler = move.get("bowler")
            new_state["selections"] = dict(new_state["selections"])
            new_state["selections"][player_id] = {
                "batters": batters,
                "bowler": bowler,
                "ready": True
            }
            new_state["last_action"] = f"{pname} locked in their 2 Batters & Bowler."

            # Check if both players ready
            p1, p2 = new_state["player_ids"]
            if new_state["selections"][p1]["ready"] and new_state["selections"][p2]["ready"]:
                new_state["status"] = "innings_1"
                new_state["phase"] = "waiting_delivery"
                b1_id = new_state["selections"][p1]["batters"][0]
                bowler_id = new_state["selections"][p2]["bowler"]
                b1 = get_player_by_id(b1_id)
                bwl = get_player_by_id(bowler_id)
                new_state["last_action"] = f"Innings 1 Begins! {b1.name if b1 else 'Batter'} faces {bwl.name if bwl else 'Bowler'}."
            return new_state

        elif action == "bowl_delivery":
            new_state["pending_bowler_action"] = move.get("delivery_type")
            new_state["last_action"] = f"{pname} selected delivery: {move.get('delivery_type')}."
            
            # If both actions submitted, resolve delivery
            if new_state.get("pending_batter_action"):
                return self._resolve_delivery(new_state)
            return new_state

        elif action == "play_shot":
            new_state["pending_batter_action"] = move.get("shot_type")
            new_state["last_action"] = f"{pname} selected shot: {move.get('shot_type')}."
            
            # If both actions submitted, resolve delivery
            if new_state.get("pending_bowler_action"):
                return self._resolve_delivery(new_state)
            return new_state

        return new_state

    def _calculate_outcome(self, batter: CricketPlayer, bowler: CricketPlayer, delivery: str, shot: str) -> Tuple[str, int, str]:
        """
        Determines the realistic ball outcome (runs/wicket) using a skill + matchup probability matrix.
        Returns (result_label, runs_scored, commentary).
        """
        # Base outcome probabilities [0, 1, 2, 4, 6, WICKET]
        probs = {0: 20, 1: 30, 2: 15, 4: 15, 6: 10, "W": 10}

        # Strategic Matchup Adjustments
        # 1. Yorker vs Loft -> High risk of wicket or clean bowled
        if delivery == "YORKER" and shot == "LOFT":
            probs["W"] += 35
            probs[0] += 20
            probs[6] -= 8
            probs[4] -= 10
        # 2. Yorker vs Defend -> Safe dig-out (0 or 1 run)
        elif delivery == "YORKER" and shot == "DEFEND":
            probs[0] += 40
            probs[1] += 30
            probs["W"] -= 5
        # 3. Bouncer vs Attack/Loft -> High reward or top edge
        elif delivery == "BOUNCER" and shot in ("ATTACK", "LOFT"):
            probs[6] += 25
            probs[4] += 15
            probs["W"] += 15
            probs[0] -= 10
        # 4. Slower Ball vs Loft -> Mis-timed catch or dispatched
        elif delivery == "SLOWER" and shot == "LOFT":
            probs["W"] += 25
            probs[6] += 15
            probs[0] += 15
        # 5. Full Pitch vs Attack/Loft -> Batter's sweet spot
        elif delivery == "FULL" and shot in ("ATTACK", "LOFT"):
            probs[4] += 30
            probs[6] += 25
            probs["W"] -= 5
            probs[0] -= 15
        # 6. Good Length vs Defend -> Dot ball dominance
        elif delivery == "GOOD_LENGTH" and shot == "DEFEND":
            probs[0] += 50
            probs[1] += 20
            probs["W"] -= 5

        # Player Rating modifiers
        bat_diff = (batter.batting_rating + batter.timing + batter.power) - (bowler.bowling_rating + bowler.accuracy + bowler.variation)
        if bat_diff > 0:
            probs[4] += int(bat_diff * 0.15)
            probs[6] += int(bat_diff * 0.15)
            probs["W"] -= int(bat_diff * 0.1)
        else:
            probs["W"] += int(abs(bat_diff) * 0.2)
            probs[0] += int(abs(bat_diff) * 0.15)
            probs[6] -= int(abs(bat_diff) * 0.1)

        # Normalize probabilities
        clean_probs = {k: max(2, v) for k, v in probs.items()}
        total_p = sum(clean_probs.values())
        roll = random.uniform(0, total_p)
        
        cumulative = 0
        outcome = 0
        for out, p in clean_probs.items():
            cumulative += p
            if roll <= cumulative:
                outcome = out
                break

        # Generate contextual commentary
        if outcome == "W":
            commentaries = [
                f"OUT! {bowler.name}'s lethal {delivery.lower()} induces the false shot, and {batter.name} has to walk!",
                f"WICKET! Timber! {bowler.name} beats the bat of {batter.name} with perfection!",
                f"OUT! Top edge taken! {bowler.name} strikes with precision against {batter.name}!"
            ]
            return "WICKET", 0, random.choice(commentaries)
        elif outcome == 6:
            commentaries = [
                f"SIX! {batter.name} launches {bowler.name}'s {delivery.lower()} into the upper tier with supreme power!",
                f"MAXIMUM! That has gone all the way! Stupendous timing from {batter.name}!",
                f"SIX RUNS! Clean strike into the stands against {bowler.name}!"
            ]
            return "6", 6, random.choice(commentaries)
        elif outcome == 4:
            commentaries = [
                f"FOUR! {batter.name} pierces the gap through extra cover for a boundary!",
                f"FOUR! Bludgeoned through point! Sublime placement from {batter.name}!",
                f"BOUNDARY! {batter.name} punishes the {delivery.lower()} to the fence!"
            ]
            return "4", 4, random.choice(commentaries)
        elif outcome == 2:
            return "2", 2, f"Good running! {batter.name} nudges the {delivery.lower()} into the deep for a quick brace."
        elif outcome == 1:
            return "1", 1, f"Single taken. {batter.name} rotates the strike against {bowler.name}."
        else:
            return "0", 0, f"Dot ball! {bowler.name} beats the blade of {batter.name} with a pinpoint {delivery.lower()}."

    def _resolve_delivery(self, state: Dict[str, Any]) -> Dict[str, Any]:
        innings_key = f"innings_{state['current_innings']}"
        inn = state[innings_key]

        bat_player_id = state["batting_player_id"]
        bowl_player_id = state["bowling_player_id"]

        bat_sel = state["selections"][bat_player_id]
        bowl_sel = state["selections"][bowl_player_id]

        active_batter_id = bat_sel["batters"][inn["active_batter_index"]]
        bowler_id = bowl_sel["bowler"]

        batter = get_player_by_id(active_batter_id)
        bowler = get_player_by_id(bowler_id)

        del_type = state["pending_bowler_action"]
        shot_type = state["pending_batter_action"]

        res_label, runs, comm = self._calculate_outcome(batter, bowler, del_type, shot_type)

        is_wicket = (res_label == "WICKET")
        inn["legal_balls"] += 1
        inn["total_runs"] += runs
        if is_wicket:
            inn["wickets"] += 1
            if inn["wickets"] < 2:
                inn["active_batter_index"] = 1 # Next batter comes in

        delivery_info = {
            "ball_number": inn["legal_balls"],
            "batter_id": active_batter_id,
            "batter_name": batter.name if batter else "Batter",
            "bowler_id": bowler_id,
            "bowler_name": bowler.name if bowler else "Bowler",
            "delivery_type": del_type,
            "shot_type": shot_type,
            "result": res_label,
            "runs": runs,
            "commentary": comm,
            "total_runs_after": inn["total_runs"],
            "wickets_after": inn["wickets"]
        }
        inn["deliveries"].append(delivery_info)

        state["last_delivery_result"] = delivery_info
        state["last_action"] = comm
        state["pending_bowler_action"] = None
        state["pending_batter_action"] = None

        # Check Innings 1 Completion (6 balls or 2 wickets)
        if state["current_innings"] == 1:
            if inn["legal_balls"] >= 6 or inn["wickets"] >= 2:
                state["current_innings"] = 2
                state["batting_player_id"] = bowl_player_id
                state["bowling_player_id"] = bat_player_id
                state["innings_2"]["target"] = inn["total_runs"] + 1
                
                b2_id = state["selections"][bowl_player_id]["batters"][0]
                bwl2_id = state["selections"][bat_player_id]["bowler"]
                b2 = get_player_by_id(b2_id)
                bwl2 = get_player_by_id(bwl2_id)

                state["last_action"] = f"Innings 1 Complete! Target is {state['innings_2']['target']} runs. {b2.name if b2 else 'Batter'} faces {bwl2.name if bwl2 else 'Bowler'}."
            return state

        # Check Innings 2 Completion
        elif state["current_innings"] == 2:
            target = inn["target"]
            current_runs = inn["total_runs"]
            
            # Chase achieved
            if current_runs >= target:
                return self._finish_match(state, winner_id=bat_player_id)
            
            # Innings ended
            if inn["legal_balls"] >= 6 or inn["wickets"] >= 2:
                if current_runs >= target:
                    return self._finish_match(state, winner_id=bat_player_id)
                elif current_runs == (target - 1): # Exact Tie
                    return self._finish_match(state, winner_id=None, is_tie=True)
                else:
                    return self._finish_match(state, winner_id=bowl_player_id)

        return state

    def _finish_match(self, state: Dict[str, Any], winner_id: Optional[str], is_tie: bool = False) -> Dict[str, Any]:
        state["status"] = "match_finished"
        pnames = state["player_names"]
        
        inn1_score = f"{state['innings_1']['total_runs']}/{state['innings_1']['wickets']}"
        inn2_score = f"{state['innings_2']['total_runs']}/{state['innings_2']['wickets']}"
        p1 = state["player_ids"][0]
        p2 = state["player_ids"][1]

        if is_tie:
            state["winner_id"] = None
            state["winner_name"] = "Draw"
            state["last_action"] = f"MATCH TIED! ({inn1_score} vs {inn2_score}). A thrilling Super Over conclusion!"
        else:
            state["winner_id"] = winner_id
            state["winner_name"] = pnames.get(winner_id, "Winner")
            state["last_action"] = f"VICTORY! {state['winner_name']} wins the Super Over Duel ({pnames.get(p1)}: {inn1_score}, {pnames.get(p2)}: {inn2_score})!"

        return state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        status = state.get("status")
        if status == "selection":
            return [{"action": "select_players", "batters": ["id1", "id2"], "bowler": "id3"}]
        elif status in ("innings_1", "innings_2"):
            if player_id == state.get("bowling_player_id"):
                return [{"action": "bowl_delivery", "delivery_type": d} for d in self.DELIVERY_TYPES]
            elif player_id == state.get("batting_player_id"):
                return [{"action": "play_shot", "shot_type": s} for s in self.SHOT_TYPES]
        return []
