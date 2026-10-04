import pytest
from backend.app.games.pentago.engine import PentagoEngine

def test_pentago_placement_and_rotation():
    engine = PentagoEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"}
    )
    assert state["phase"] == "place_marble"
    assert state["current_turn_player_id"] == "p1"

    # Step 1: Place marble at (0, 0)
    state = engine.apply_move(state, "p1", {"action": "place_marble", "r": 0, "c": 0})
    assert state["phase"] == "rotate_quadrant"
    assert state["board"][0][0] == "p1"
    # Turn has not switched yet because rotation is required
    assert state["current_turn_player_id"] == "p1"

    # Step 2: Rotate Top-Left quadrant (0) Clockwise (cw)
    # (0, 0) should rotate to (0, 2) in quadrant 0
    state = engine.apply_move(state, "p1", {"action": "rotate_quadrant", "quadrant": 0, "direction": "cw"})
    assert state["board"][0][2] == "p1"
    assert state["board"][0][0] is None
    assert state["phase"] == "place_marble"
    # Now turn advances to p2
    assert state["current_turn_player_id"] == "p2"

def test_pentago_win_detection():
    engine = PentagoEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"}
    )
    # Set up 4 in a row for p1 along row 0: cols 0, 1, 2, 3
    state["board"][0][0] = "p1"
    state["board"][0][1] = "p1"
    state["board"][0][2] = "p1"
    state["board"][0][3] = "p1"

    # p1 places 5th marble at (0, 4) using place_and_rotate
    # rotating bottom-right quadrant (3) cw so it doesn't disturb row 0
    state = engine.apply_move(state, "p1", {
        "action": "place_and_rotate",
        "r": 0,
        "c": 4,
        "quadrant": 3,
        "direction": "cw"
    })
    assert state["status"] == "won"
    assert state["winner_id"] == "p1"
