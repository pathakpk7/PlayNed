import pytest
from backend.app.games.cricket.modes.auction import CricketAuctionBackendEngine
from backend.app.games.cricket.engine import CricketHubEngine

def test_auction_backend_initial_state():
    engine = CricketAuctionBackendEngine()
    state = engine.create_initial_state(
        player_ids=["user1", "user2"],
        player_names={"user1": "Alice", "user2": "Bob"}
    )
    
    assert state["mode_id"] == "auction"
    assert state["phase"] == "marquee_draft"
    assert len(state["franchises"]) == 10
    
    for f in state["franchises"].values():
        assert f["purse_remaining"] == 120.0
        assert f["overseas_count"] == 0
        assert len(f["squad"]) == 0

def test_auction_marquee_selection_deducts_18_cr():
    engine = CricketAuctionBackendEngine()
    state = engine.create_initial_state(
        player_ids=["user1"],
        player_names={"user1": "Alice"}
    )
    
    move = {
        "action": "select_marquee",
        "team_id": "mumbai_mariners",
        "player_id": "virat_kohli"
    }
    
    valid, err = engine.validate_move(state, "user1", move)
    assert valid is True
    assert err is None
    
    new_state = engine.apply_move(state, "user1", move)
    mm = new_state["franchises"]["mumbai_mariners"]
    assert mm["purse_remaining"] == 102.0
    assert len(mm["squad"]) == 1
    assert mm["squad"][0]["id"] == "virat_kohli"

def test_cricket_hub_dispatch_to_auction():
    hub_engine = CricketHubEngine()
    state = hub_engine.create_initial_state(
        player_ids=["user1"],
        player_names={"user1": "Alice"},
        options={"cricket_mode": "auction"}
    )
    assert state["game_id"] == "cricket"
    assert state["active_cricket_mode"] == "auction"
    assert state["phase"] == "marquee_draft"
    assert len(state["franchises"]) == 10
