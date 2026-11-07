import pytest
from backend.app.games.higher_or_lower.engine import (
    HigherOrLowerEngine,
    HIGHER_OR_LOWER_METADATA,
    MIN_NUMBER,
    MAX_NUMBER,
)
from backend.app.platform.registry import game_registry

class MockRNG:
    def __init__(self, sequence):
        self.sequence = list(sequence)
        self.index = 0

    def randint(self, a, b):
        if self.index < len(self.sequence):
            val = self.sequence[self.index]
            self.index += 1
            return val
        return a

def test_higher_or_lower_metadata_and_registry():
    assert HIGHER_OR_LOWER_METADATA.id == "higher_or_lower"
    assert HIGHER_OR_LOWER_METADATA.min_players == 2
    assert HIGHER_OR_LOWER_METADATA.max_players == 4
    assert HIGHER_OR_LOWER_METADATA.supports_local is True
    assert HIGHER_OR_LOWER_METADATA.supports_online is True

    reg_meta = game_registry.get_game_metadata("higher_or_lower")
    reg_engine = game_registry.get_game_engine("higher_or_lower")
    assert reg_meta is not None
    assert reg_meta.name == "Higher or Lower: Numbers"
    assert reg_engine is not None

def test_player_count_boundaries():
    engine = HigherOrLowerEngine()
    
    # < 2 players rejected
    with pytest.raises(ValueError, match="requires 2 to 4 players"):
        engine.create_initial_state(["p1"], {"p1": "Alice"})

    # > 4 players rejected
    with pytest.raises(ValueError, match="requires 2 to 4 players"):
        engine.create_initial_state(
            ["p1", "p2", "p3", "p4", "p5"],
            {"p1": "A", "p2": "B", "p3": "C", "p4": "D", "p5": "E"}
        )

    # 2 to 4 valid
    s2 = engine.create_initial_state(["p1", "p2"], {"p1": "A", "p2": "B"})
    assert len(s2["player_ids"]) == 2
    assert s2["min_number"] == 1
    assert s2["max_number"] == 100
    assert 1 <= s2["current_number"] <= 100

def test_number_boundaries_min_and_max():
    # Test boundary sequence: 1 and 100
    mock_rng = MockRNG([1, 100, 1])
    engine = HigherOrLowerEngine(rng=mock_rng)

    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    assert state["current_number"] == 1

    # p1 predicts HIGHER when next is 100 -> Correct
    state = engine.apply_move(state, "p1", {"action": "predict", "direction": "HIGHER"})
    assert state["scores"]["p1"] == 1
    assert state["current_number"] == 100
    assert state["last_prediction"]["outcome"] == "CORRECT"

    # p2 predicts LOWER when next is 1 -> Correct
    state = engine.apply_move(state, "p2", {"action": "predict", "direction": "LOWER"})
    assert state["scores"]["p2"] == 1
    assert state["current_number"] == 1
    assert state["last_prediction"]["outcome"] == "CORRECT"

def test_equal_number_handling():
    # When next number equals current number, award 0 points, treat as tie
    mock_rng = MockRNG([50, 50])
    engine = HigherOrLowerEngine(rng=mock_rng)

    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    assert state["current_number"] == 50

    state = engine.apply_move(state, "p1", {"action": "predict", "direction": "HIGHER"})
    assert state["scores"]["p1"] == 0
    assert state["tie_counts"]["p1"] == 1
    assert state["correct_counts"]["p1"] == 0
    assert state["last_prediction"]["outcome"] == "EQUAL"
    assert "identical" in state["last_prediction"]["explanation"]

def test_incorrect_predictions_and_streaks():
    mock_rng = MockRNG([50, 30, 20, 80])
    engine = HigherOrLowerEngine(rng=mock_rng)

    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    # current=50, next=30. p1 predicts HIGHER -> Incorrect
    state = engine.apply_move(state, "p1", {"action": "predict", "direction": "HIGHER"})
    assert state["scores"]["p1"] == 0
    assert state["streaks"]["p1"] == 0
    assert state["last_prediction"]["outcome"] == "INCORRECT"

    # current=30, next=20. p2 predicts LOWER -> Correct (streak=1)
    state = engine.apply_move(state, "p2", {"action": "predict", "direction": "LOWER"})
    assert state["scores"]["p2"] == 1
    assert state["streaks"]["p2"] == 1

    # current=20, next=80. p1 predicts HIGHER -> Correct (streak=1)
    state = engine.apply_move(state, "p1", {"action": "predict", "direction": "HIGHER"})
    assert state["scores"]["p1"] == 1
    assert state["streaks"]["p1"] == 1

def test_accuracy_calculation():
    # 5 attempts: 3 correct, 1 incorrect, 1 tie
    # Valid non-tied = 4. Accuracy = 3 / 4 = 75.0%
    acc = HigherOrLowerEngine.calculate_accuracy(correct=3, attempts=5, ties=1)
    assert acc == 75.0

    # 0 attempts
    assert HigherOrLowerEngine.calculate_accuracy(correct=0, attempts=0, ties=0) == 0.0

    # Only ties
    assert HigherOrLowerEngine.calculate_accuracy(correct=0, attempts=2, ties=2) == 0.0

def test_fixed_rounds_match_completion():
    mock_rng = MockRNG([50, 75, 25, 80, 10])
    engine = HigherOrLowerEngine(rng=mock_rng)

    # 2 rounds fixed, 2 players (4 total turns)
    state = engine.create_initial_state(
        ["p1", "p2"],
        {"p1": "Alice", "p2": "Bob"},
        {"match_mode": "custom", "custom_type": "fixed_rounds", "total_rounds": 2}
    )

    # Round 1:
    # p1: current 50, next 75, predicts HIGHER -> correct
    state = engine.apply_move(state, "p1", {"action": "predict", "direction": "HIGHER"})
    assert state["round_number"] == 1
    # p2: current 75, next 25, predicts HIGHER -> incorrect
    state = engine.apply_move(state, "p2", {"action": "predict", "direction": "HIGHER"})
    assert state["round_number"] == 2  # round advanced

    # Round 2:
    # p1: current 25, next 80, predicts HIGHER -> correct
    state = engine.apply_move(state, "p1", {"action": "predict", "direction": "HIGHER"})
    # p2: current 80, next 10, predicts LOWER -> correct
    state = engine.apply_move(state, "p2", {"action": "predict", "direction": "LOWER"})

    # Finished!
    assert state["status"] == "finished"
    assert state["winner_id"] == "p1"  # p1 scored 2, p2 scored 1
    assert state["scores"]["p1"] == 2
    assert state["scores"]["p2"] == 1

def test_sudden_death_tiebreaker():
    # Initial: 50.
    # Round 1: p1 predicts HIGHER -> next 70 (correct). p2 predicts HIGHER -> next 90 (correct).
    # Scores: p1: 1, p2: 1. End of 1-round match -> Tied!
    # Sudden Death R1:
    # p1 predicts HIGHER -> next 95 (correct).
    # p2 predicts HIGHER -> next 40 (incorrect).
    # p1 wins sudden death!
    mock_rng = MockRNG([50, 70, 90, 95, 40])
    engine = HigherOrLowerEngine(rng=mock_rng)

    state = engine.create_initial_state(
        ["p1", "p2"],
        {"p1": "Alice", "p2": "Bob"},
        {"match_mode": "custom", "custom_type": "fixed_rounds", "total_rounds": 1}
    )

    state = engine.apply_move(state, "p1", {"action": "predict", "direction": "HIGHER"})
    state = engine.apply_move(state, "p2", {"action": "predict", "direction": "HIGHER"})

    assert state["status"] == "sudden_death"
    assert state["sudden_death_round"] == 1
    assert set(state["sudden_death_candidates"]) == {"p1", "p2"}

    # Sudden Death turn 1: p1
    state = engine.apply_move(state, "p1", {"action": "predict", "direction": "HIGHER"})
    assert state["status"] == "sudden_death"
    assert state["current_turn_player_id"] == "p2"

    # Sudden Death turn 2: p2
    state = engine.apply_move(state, "p2", {"action": "predict", "direction": "HIGHER"})
    assert state["status"] == "finished"
    assert state["winner_id"] == "p1"
    assert state["winner_name"] == "Alice"

def test_move_validation_and_security():
    engine = HigherOrLowerEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})

    # Out of turn
    valid, err = engine.validate_move(state, "p2", {"action": "predict", "direction": "HIGHER"})
    assert not valid
    assert "not player p2's turn" in err

    # Invalid direction
    valid, err = engine.validate_move(state, "p1", {"action": "predict", "direction": "SIDEWAYS"})
    assert not valid
    assert "Invalid prediction direction" in err

    # Unknown action
    valid, err = engine.validate_move(state, "p1", {"action": "hack", "direction": "HIGHER"})
    assert not valid

    # State filtering hides unrevealed next numbers
    filtered = engine.filter_state_for_player(state, "p1")
    assert filtered["is_my_turn"] is True
    assert "next_number" not in filtered
