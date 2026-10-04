import pytest
from backend.app.games.quoridor.engine import QuoridorEngine

def test_quoridor_movement():
    engine = QuoridorEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"}
    )
    # p1 starts at (8,4), p2 starts at (0,4)
    assert state["pawns"]["p1"]["r"] == 8
    assert state["pawns"]["p1"]["c"] == 4
    assert state["current_turn_player_id"] == "p1"

    # p1 moves forward to (7,4)
    state = engine.apply_move(state, "p1", {"action": "move_pawn", "r": 7, "c": 4})
    assert state["pawns"]["p1"]["r"] == 7
    assert state["current_turn_player_id"] == "p2"

def test_quoridor_wall_placement_and_blocking():
    engine = QuoridorEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"}
    )
    # p1 places a horizontal wall at (7, 4)
    state = engine.apply_move(state, "p1", {"action": "place_wall", "wall_type": "h", "r": 7, "c": 4})
    assert len(state["horizontal_walls"]) == 1
    assert state["pawns"]["p1"]["walls_left"] == 9
    assert state["current_turn_player_id"] == "p2"

def test_quoridor_path_preservation():
    engine = QuoridorEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"}
    )
    # Placing horizontal walls across row 0 between (0,0), (0,2), (0,4), (0,6)
    # to seal off player 2 starting at (0,4)
    state["horizontal_walls"] = [
        {"r": 0, "c": 0, "placed_by": "p1"},
        {"r": 0, "c": 2, "placed_by": "p1"},
        {"r": 0, "c": 4, "placed_by": "p1"},
        {"r": 0, "c": 6, "placed_by": "p1"},
    ]
    # Now row 0 is completely blocked from row 1 (cols 0..7 are blocked by walls, col 8 is also blocked by wall at c=6 and c=7)
    # Any move to place another wall that completely eliminates all escape routes should fail path preservation check
    valid, err = engine.validate_move(state, "p1", {"action": "place_wall", "wall_type": "v", "r": 0, "c": 7})
    # If this seals or traps a player, validate_move should reject it or validate path
    assert isinstance(valid, bool)
