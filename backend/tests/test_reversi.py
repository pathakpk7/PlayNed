import pytest
from backend.app.games.reversi.engine import ReversiEngine, REVERSI_METADATA
from backend.app.platform.registry import game_registry

def test_reversi_registration():
    meta = game_registry.get_game_metadata("reversi")
    assert meta is not None
    assert meta.name == "Reversi & Othello"
    assert meta.min_players == 2
    assert meta.max_players == 2
    engine = game_registry.get_game_engine("reversi")
    assert isinstance(engine, ReversiEngine)

def test_othello_initial_state():
    engine = ReversiEngine()
    state = engine.create_initial_state(["alice", "bob"], {"alice": "Alice", "bob": "Bob"}, {"variant": "othello"})
    assert state["status"] == "in_progress"
    assert state["black_count"] == 2
    assert state["white_count"] == 2
    assert state["current_turn_player_id"] == "alice"
    # Verify center 4 discs
    board = state["board"]
    assert board[3][3] == 2  # White
    assert board[3][4] == 1  # Black
    assert board[4][3] == 1  # Black
    assert board[4][4] == 2  # White

def test_othello_legal_moves_opening():
    engine = ReversiEngine()
    state = engine.create_initial_state(["alice", "bob"], {"alice": "Alice", "bob": "Bob"})
    # For Black on move 1, standard legal moves are (2,3), (3,2), (4,5), (5,4)
    legal_moves = engine.get_available_moves(state, "alice")
    coords = {(m["r"], m["c"]) for m in legal_moves}
    assert (2, 3) in coords
    assert (3, 2) in coords
    assert (4, 5) in coords
    assert (5, 4) in coords
    assert len(coords) == 4

def test_apply_move_and_flip():
    engine = ReversiEngine()
    state = engine.create_initial_state(["alice", "bob"], {"alice": "Alice", "bob": "Bob"})
    # Alice (Black) plays (2, 3)
    new_state = engine.apply_move(state, "alice", {"action": "place_disc", "r": 2, "c": 3})
    board = new_state["board"]
    assert board[2][3] == 1  # Black placed
    assert board[3][3] == 1  # White flipped to Black
    assert new_state["black_count"] == 4
    assert new_state["white_count"] == 1
    assert new_state["current_turn_player_id"] == "bob"

def test_illegal_non_capturing_move():
    engine = ReversiEngine()
    state = engine.create_initial_state(["alice", "bob"], {"alice": "Alice", "bob": "Bob"})
    valid, err = engine.validate_move(state, "alice", {"action": "place_disc", "r": 0, "c": 0})
    assert valid is False
    assert "does not sandwich" in err
