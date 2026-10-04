import pytest
from backend.app.games.shut_the_box.engine import ShutTheBoxEngine

def test_shut_the_box_initial_state():
    engine = ShutTheBoxEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"}, {"max_tile": 9})
    assert state["game_id"] == "shut_the_box"
    assert len(state["open_tiles"]) == 9
    assert state["shut_tiles"] == []
    assert state["status"] == "in_progress"
    assert state["current_turn_player_id"] == "p1"
    assert state["dice_rolled"] is False

def test_shut_the_box_roll_and_shut():
    engine = ShutTheBoxEngine()
    state = engine.create_initial_state(["p1"], {"p1": "Alice"})
    
    # Roll dice
    move_roll = {"action": "roll_dice"}
    valid, err = engine.validate_move(state, "p1", move_roll)
    assert valid is True
    
    state = engine.apply_move(state, "p1", move_roll)
    assert state["dice_rolled"] is True
    assert 2 <= state["dice_sum"] <= 12

    # Find valid combinations
    combos = engine.find_valid_combinations(state["open_tiles"], state["dice_sum"])
    if combos:
        chosen_combo = combos[0]
        move_shut = {"action": "shut_tiles", "tiles": chosen_combo}
        valid, err = engine.validate_move(state, "p1", move_shut)
        assert valid is True

        state = engine.apply_move(state, "p1", move_shut)
        for t in chosen_combo:
            assert t in state["shut_tiles"]
            assert t not in state["open_tiles"]
        assert state["dice_rolled"] is False

def test_shut_the_box_multiplayer_advance():
    engine = ShutTheBoxEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    
    # End p1's round
    state["open_tiles"] = [1, 2] # remaining 3 points
    state["dice_rolled"] = True
    state["dice_sum"] = 12 # impossible sum for [1, 2]
    
    move_end = {"action": "end_turn"}
    valid, err = engine.validate_move(state, "p1", move_end)
    assert valid is True

    state = engine.apply_move(state, "p1", move_end)
    assert state["player_scores"]["p1"] == 3
    assert state["player_rounds_completed"]["p1"] is True
    assert state["current_turn_player_id"] == "p2"
    assert len(state["open_tiles"]) == 9 # fresh box for p2
    assert state["status"] == "in_progress"
