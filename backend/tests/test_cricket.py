import pytest
from backend.app.games.cricket.data.players import (
    CRICKET_PLAYERS_DATA,
    get_all_cricket_players,
    get_cricket_player_by_id,
    get_player_by_id
)
from backend.app.games.cricket.modes.super_over import SuperOverEngine
from backend.app.games.cricket.modes.stat_clash import StatClashEngine
from backend.app.games.cricket.modes.challenges import CricketChallengeEngine
from backend.app.games.cricket.engine import CricketHubEngine, CRICKET_METADATA
from backend.app.platform.registry import game_registry

def test_cricket_dataset():
    players = get_all_cricket_players()
    assert len(players) >= 20
    virat = get_cricket_player_by_id("virat_kohli")
    assert virat is not None
    assert virat["name"] == "Virat Kohli"
    assert virat["odi_runs"] > 10000
    assert virat["batting_rating"] >= 90

    bumrah = get_player_by_id("jasprit_bumrah")
    assert bumrah is not None
    assert bumrah.role == "Bowler"
    assert bumrah.bowling_rating >= 90

def test_super_over_engine():
    engine = SuperOverEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    assert state["status"] == "selection"
    assert state["current_innings"] == 1

    # Team selection
    move_p1 = {
        "action": "select_players",
        "batters": ["virat_kohli", "rohit_sharma"],
        "bowler": "jasprit_bumrah"
    }
    valid, err = engine.validate_move(state, "p1", move_p1)
    assert valid, err
    state = engine.apply_move(state, "p1", move_p1)

    move_p2 = {
        "action": "select_players",
        "batters": ["ab_de_villiers", "ms_dhoni"],
        "bowler": "wasim_akram"
    }
    valid, err = engine.validate_move(state, "p2", move_p2)
    assert valid, err
    state = engine.apply_move(state, "p2", move_p2)

    assert state["status"] == "innings_1"

    # Play ball 1 (Innings 1: P2 bowls to P1)
    move_bowl = {"action": "bowl_delivery", "delivery_type": "YORKER"}
    valid, err = engine.validate_move(state, "p2", move_bowl)
    assert valid, err
    state = engine.apply_move(state, "p2", move_bowl)
    assert state["pending_bowler_action"] == "YORKER"

    move_bat = {"action": "play_shot", "shot_type": "DEFEND"}
    valid, err = engine.validate_move(state, "p1", move_bat)
    assert valid, err
    state = engine.apply_move(state, "p1", move_bat)
    
    assert state["innings_1"]["legal_balls"] == 1
    assert len(state["innings_1"]["deliveries"]) == 1

def test_stat_clash_engine():
    engine = StatClashEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"}, {"series_mode": "single"})
    assert state["status"] == "in_progress"
    assert state["active_challenge"] is not None

    # Draft a squad of 5 players for p1
    move_pick_p1 = {
        "action": "submit_squad",
        "player_ids": ["virat_kohli", "rohit_sharma", "sachin_tendulkar", "brian_lara", "ms_dhoni"]
    }
    valid, err = engine.validate_move(state, "p1", move_pick_p1)
    assert valid, err
    state = engine.apply_move(state, "p1", move_pick_p1)
    assert state["round_submissions"]["p1"]["submitted"] is True

    # Draft a squad of 5 players for p2
    move_pick_p2 = {
        "action": "submit_squad",
        "player_ids": ["ricky_ponting", "jacques_kallis", "ab_de_villiers", "chris_gayle", "glenn_mcgrath"]
    }
    valid, err = engine.validate_move(state, "p2", move_pick_p2)
    assert valid, err
    state = engine.apply_move(state, "p2", move_pick_p2)
    assert state["round_submissions"]["p2"]["submitted"] is True
    # Single mode should finish after 1 round resolved
    assert state["status"] == "finished"
    assert (state["winner_id"] is not None) or (state.get("is_tie") is True)

def test_challenge_engine():
    engine = CricketChallengeEngine()
    wai = engine.generate_who_am_i()
    assert len(wai["clues"]) > 0
    assert len(wai["options"]) == 4

    hl = engine.generate_higher_lower()
    assert "player_a" in hl
    assert "player_b" in hl

    sof = engine.generate_stat_or_fiction()
    assert "statement" in sof
    assert isinstance(sof["is_true"], bool)

def test_registry_integration():
    meta = game_registry.get_game_metadata("cricket")
    assert meta is not None
    assert meta.id == "cricket"
    assert meta.name == "Cricket Hub"

    engine = game_registry.get_game_engine("cricket")
    assert engine is not None
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    assert state["game_id"] == "cricket"

def test_cricket_draft_engine():
    from backend.app.games.cricket.modes.draft import CricketDraftEngine
    engine = CricketDraftEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    assert state["status"] == "drafting"
    assert state["remaining_budget"]["p1"] == 100
    assert state["remaining_budget"]["p2"] == 100

    # P1 picks Virat Kohli
    vk = get_cricket_player_by_id("virat_kohli")
    cost_vk = vk["draft_cost"] if vk else 25
    move1 = {"action": "draft_player", "player_id": "virat_kohli"}
    valid, err = engine.validate_move(state, "p1", move1)
    assert valid, err
    state = engine.apply_move(state, "p1", move1)
    assert state["remaining_budget"]["p1"] == 100 - cost_vk
    assert state["squad_roles_count"]["p1"]["Batter"] == 1

    # P2 picks AB de Villiers
    ab = get_cricket_player_by_id("ab_de_villiers")
    cost_ab = ab["draft_cost"] if ab else 25
    move2 = {"action": "draft_player", "player_id": "ab_de_villiers"}
    valid, err = engine.validate_move(state, "p2", move2)
    assert valid, err
    state = engine.apply_move(state, "p2", move2)
    assert state["remaining_budget"]["p2"] == 100 - cost_ab

    # Check budget enforcement
    state["remaining_budget"]["p1"] = 10
    move_expensive = {"action": "draft_player", "player_id": "sachin_tendulkar"}
    state["current_turn_player_id"] = "p1"
    valid, err = engine.validate_move(state, "p1", move_expensive)
    assert not valid
    assert "budget" in err.lower()
