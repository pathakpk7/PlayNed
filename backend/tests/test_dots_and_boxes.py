import pytest
from backend.app.games.dots_and_boxes.engine import DotsAndBoxesEngine

def test_dots_and_boxes_flow():
    engine = DotsAndBoxesEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"},
        options={"grid_rows": 4, "grid_cols": 4} # 4x4 dots = 3x3 boxes = 9 boxes
    )

    assert state["grid_rows"] == 4
    assert state["grid_cols"] == 4
    assert state["box_rows"] == 3
    assert state["box_cols"] == 3
    assert state["total_boxes"] == 9
    assert state["current_turn_player_id"] == "p1"

    # p1 draws top line of box (0,0): h:0,0
    state = engine.apply_move(state, "p1", {"type": "h", "r": 0, "c": 0})
    assert state["current_turn_player_id"] == "p2"

    # p2 draws bottom line of box (0,0): h:1,0
    state = engine.apply_move(state, "p2", {"type": "h", "r": 1, "c": 0})
    assert state["current_turn_player_id"] == "p1"

    # p1 draws left line of box (0,0): v:0,0
    state = engine.apply_move(state, "p1", {"type": "v", "r": 0, "c": 0})
    assert state["current_turn_player_id"] == "p2"

    # p2 draws right line of box (0,0): v:0,1 -> Completes box (0,0)!
    state = engine.apply_move(state, "p2", {"type": "v", "r": 0, "c": 1})
    assert state["scores"]["p2"] == 1
    assert "0,0" in state["boxes"]
    assert state["boxes"]["0,0"] == "p2"
    # p2 gets a BONUS turn!
    assert state["current_turn_player_id"] == "p2"
    assert state["bonus_turn"] is True

def test_dots_and_boxes_9x9_board():
    engine = DotsAndBoxesEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"},
        options={"grid_rows": 9, "grid_cols": 9} # 9x9 dots = 8x8 boxes = 64 boxes
    )
    assert state["grid_rows"] == 9
    assert state["grid_cols"] == 9
    assert state["box_rows"] == 8
    assert state["box_cols"] == 8
    assert state["total_boxes"] == 64

def test_dots_and_boxes_illegal_move():
    engine = DotsAndBoxesEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"}
    )
    # Wrong player turn
    valid, err = engine.validate_move(state, "p2", {"type": "h", "r": 0, "c": 0})
    assert not valid
    assert "not your turn" in err.lower()

    # Out of bounds
    valid, err = engine.validate_move(state, "p1", {"type": "h", "r": 99, "c": 0})
    assert not valid
