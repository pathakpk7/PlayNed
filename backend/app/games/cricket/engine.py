from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata
from backend.app.games.cricket.modes.super_over import SuperOverEngine
from backend.app.games.cricket.modes.stat_clash import StatClashEngine
from backend.app.games.cricket.modes.challenges import CricketChallengeEngine
from backend.app.games.cricket.modes.draft import CricketDraftEngine

CRICKET_METADATA = GameMetadata(
    id="cricket",
    name="Cricket Hub",
    tagline="Experience high-stakes Super Over duels, tactical Cricket Drafts, Stat Clashes, and trivia challenges.",
    description="The ultimate PlayNed cricket arena. Build dream squads in 100-budget Cricket Drafts with simulated 5-over clashes, play fast-paced 6-ball Super Over duels with authentic batsman-bowler tactical matchups, test your cricketing intellect in Stat Clash squad drafting, and conquer the Cricket Challenge Hub with trivia, timelines, and higher/lower battles.",
    category="Sports / Strategy",
    min_players=1,
    max_players=2,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    supports_ai=True,
    estimated_duration_minutes=5,
    accent_color_hex="#E5A93C",
    bg_color_hex="#0B1A14",
    icon_name="sports_cricket",
    rules_summary=[
        "Cricket Draft: Build a 5-player dream squad (2 Batters, 1 All-Rounder, 1 Bowler, 1 Wicket-Keeper) under a strict 100 Credit budget. Test tactical ratings or simulate a high-fidelity 5-over clash!",
        "Super Over Duel: Pick 2 batters and 1 bowler. Battle in a 6-ball innings. Batters choose shots (Defend, Normal, Attack, Loft) while bowlers pick deliveries (Yorker, Bouncer, Good Length, Full, Slower). Highest score wins.",
        "Stat Clash: Draft a squad of 5 real cricket legends to get closest to the target statistic without busting!",
        "Cricket Challenge Hub: Test your knowledge in Who Am I?, Higher/Lower, Stat or Fiction, Career Timelines, and Guess The Player mini-games."
    ]
)

class CricketHubEngine(BaseGameEngine):
    """
    Master PlayNed Cricket Hub Engine dispatching to sub-game modes:
    - 'draft'
    - 'super_over'
    - 'stat_clash'
    - 'challenges' / 'challenge_hub'
    """

    def __init__(self):
        self.draft_engine = CricketDraftEngine()
        self.super_over_engine = SuperOverEngine()
        self.stat_clash_engine = StatClashEngine()
        self.challenge_engine = CricketChallengeEngine()

    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        options = options or {}
        mode = options.get("cricket_mode", options.get("mode", "super_over"))
        
        if mode == "draft":
            state = self.draft_engine.create_initial_state(player_ids, player_names, options)
        elif mode == "stat_clash":
            state = self.stat_clash_engine.create_initial_state(player_ids, player_names, options)
        elif mode in ("challenge_hub", "challenges"):
            sub_type = options.get("sub_type", "who_am_i")
            state = {
                "game_id": "cricket",
                "mode_id": "challenges",
                "sub_type": sub_type,
                "player_ids": player_ids,
                "player_names": player_names,
                "score": 0,
                "streak": 0,
                "round_data": self._generate_challenge_data(sub_type)
            }
        else: # default super_over
            state = self.super_over_engine.create_initial_state(player_ids, player_names, options)
            
        state["game_id"] = "cricket"
        state["active_cricket_mode"] = mode
        return state

    def _generate_challenge_data(self, sub_type: str) -> Dict[str, Any]:
        if sub_type == "higher_lower":
            return self.challenge_engine.generate_higher_lower()
        elif sub_type == "stat_or_fiction":
            return self.challenge_engine.generate_stat_or_fiction()
        elif sub_type == "career_timeline":
            return self.challenge_engine.generate_career_timeline()
        elif sub_type == "guess_player":
            return self.challenge_engine.generate_guess_player()
        else:
            return self.challenge_engine.generate_who_am_i()

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        mode = state.get("active_cricket_mode", state.get("mode_id", "super_over"))
        if mode == "draft":
            return self.draft_engine.validate_move(state, player_id, move)
        elif mode == "stat_clash":
            return self.stat_clash_engine.validate_move(state, player_id, move)
        elif mode in ("challenges", "challenge_hub"):
            return True, None
        else:
            return self.super_over_engine.validate_move(state, player_id, move)

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        mode = state.get("active_cricket_mode", state.get("mode_id", "super_over"))
        if mode == "draft":
            return self.draft_engine.apply_move(state, player_id, move)
        elif mode == "stat_clash":
            return self.stat_clash_engine.apply_move(state, player_id, move)
        elif mode in ("challenges", "challenge_hub"):
            action = move.get("action")
            if action == "answer":
                is_correct = move.get("is_correct", False)
                if is_correct:
                    state["score"] = state.get("score", 0) + 100 + state.get("streak", 0) * 20
                    state["streak"] = state.get("streak", 0) + 1
                else:
                    state["streak"] = 0
                state["last_answer_correct"] = is_correct
            elif action == "next_question":
                sub_type = move.get("sub_type", state.get("sub_type", "who_am_i"))
                state["sub_type"] = sub_type
                state["round_data"] = self._generate_challenge_data(sub_type)
                state["last_answer_correct"] = None
            return state
        else:
            return self.super_over_engine.apply_move(state, player_id, move)

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        mode = state.get("active_cricket_mode", state.get("mode_id", "super_over"))
        if mode == "draft":
            return self.draft_engine.get_available_moves(state, player_id)
        elif mode == "stat_clash":
            return self.stat_clash_engine.get_available_moves(state, player_id)
        elif mode in ("challenges", "challenge_hub"):
            return [{"action": "answer"}, {"action": "next_question"}]
        else:
            return self.super_over_engine.get_available_moves(state, player_id)
