import pytest
from backend.app.games.ultimate_tic_tac_toe.engine import UltimateTicTacToeEngine, ULTIMATE_TIC_TAC_TOE_METADATA
from backend.app.platform.registry import game_registry

def test_ultimate_tic_tac_toe_registered():
    meta = game_registry.get_game_metadata("ultimate_tic_tac_toe")
    engine = game_registry.get_game_engine("ultimate_tic_tac_toe")
    assert meta is not None
    assert meta.id == "ultimate_tic_tac_toe"
    assert meta.name == "Ultimate Tic-Tac-Toe"
    assert isinstance(engine, UltimateTicTacToeEngine)

def test_initial_state():
    engine = UltimateTicTacToeEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    
    assert state["status"] == "in_progress"
    assert len(state["boards"]) == 9
    for b in state["boards"]:
        assert b["cells"] == [None] * 9
        assert b["winner"] is None
        assert b["status"] == "active"
    assert state["macro_board"] == [None] * 9
    assert state["current_turn_player_id"] == "p1"
    assert state["current_symbol"] == "X"
    assert state["next_board"] is None  # Initial Free Move
    assert engine.get_valid_boards(state) == list(range(9))

def test_valid_move_and_target_routing():
    engine = UltimateTicTacToeEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    
    # Player 1 (X) plays Board 0, Cell 4 (center cell of top-left board)
    state = engine.apply_move(state, "p1", {"board": 0, "cell": 4})
    
    assert state["boards"][0]["cells"][4] == "X"
    assert state["current_symbol"] == "O"
    assert state["current_turn_player_id"] == "p2"
    # Destination board should be Board 4
    assert state["next_board"] == 4
    assert engine.get_valid_boards(state) == [4]
    assert state["turn_number"] == 1

def test_invalid_moves():
    engine = UltimateTicTacToeEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    
    # 1. Wrong player
    with pytest.raises(ValueError, match="Not your turn"):
        engine.apply_move(state, "p2", {"board": 0, "cell": 0})
        
    # P1 plays (0, 4) -> sends P2 to Board 4
    state = engine.apply_move(state, "p1", {"board": 0, "cell": 4})
    
    # 2. P2 tries to play in wrong board (e.g. Board 1 instead of Board 4)
    with pytest.raises(ValueError, match="Illegal move: You must play in Board 4"):
        engine.apply_move(state, "p2", {"board": 1, "cell": 0})
        
    # P2 plays valid move in Board 4, cell 0 -> sends P1 to Board 0
    state = engine.apply_move(state, "p2", {"board": 4, "cell": 0})
    
    # 3. P1 tries to play already occupied cell (0, 4)
    with pytest.raises(ValueError, match="already occupied"):
        engine.apply_move(state, "p1", {"board": 0, "cell": 4})

def test_micro_board_win():
    engine = UltimateTicTacToeEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    
    # Pre-populate Board 0 with X on 0 and 1
    state["boards"][0]["cells"][0] = "X"
    state["boards"][0]["cells"][1] = "X"
    state["next_board"] = 0
    
    # P1 plays (0, 2) -> completes top row (0, 1, 2) in Board 0!
    state = engine.apply_move(state, "p1", {"board": 0, "cell": 2})
    
    assert state["boards"][0]["winner"] == "X"
    assert state["boards"][0]["status"] == "won"
    assert state["boards"][0]["winning_line"] == [0, 1, 2]
    assert state["macro_board"][0] == "X"
    assert state["x_boards_won"] == 1
    
    # P1 played cell 2 -> opponent is sent to Board 2
    assert state["next_board"] == 2

def test_free_move_when_target_board_is_won():
    engine = UltimateTicTacToeEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    
    # Manually populate Board 0 as won by X
    state["boards"][0]["cells"] = ["X", "X", "X", None, None, None, None, None, None]
    state["boards"][0]["winner"] = "X"
    state["boards"][0]["status"] = "won"
    state["macro_board"][0] = "X"
    state["x_boards_won"] = 1
    
    # P1 (X) plays in Board 1, cell 0 -> normally sends P2 to Board 0
    # But Board 0 is already WON -> P2 must receive FREE MOVE (next_board is None)
    state = engine.apply_move(state, "p1", {"board": 1, "cell": 0})
    
    assert state["next_board"] is None
    # Valid boards should be all boards except Board 0
    valid_boards = engine.get_valid_boards(state)
    assert 0 not in valid_boards
    assert len(valid_boards) == 8

def test_macro_board_win():
    engine = UltimateTicTacToeEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    
    # Boards 0 and 1 are already won by X
    state["boards"][0]["winner"] = "X"
    state["macro_board"][0] = "X"
    state["boards"][1]["winner"] = "X"
    state["macro_board"][1] = "X"
    
    # Board 2 has X on cells 0 and 1
    state["boards"][2]["cells"][0] = "X"
    state["boards"][2]["cells"][1] = "X"
    state["next_board"] = 2
    
    # P1 plays Board 2, cell 2 -> wins Board 2 and achieves 3-in-a-row (0, 1, 2) on macro board!
    state = engine.apply_move(state, "p1", {"board": 2, "cell": 2})
    
    assert state["status"] == "won"
    assert state["macro_winner"] == "X"
    assert state["winner_symbol"] == "X"
    assert state["winner_id"] == "p1"
    assert state["macro_winning_line"] == [0, 1, 2]
    
    # Moves rejected after game end
    with pytest.raises(ValueError, match="already finished"):
        engine.apply_move(state, "p2", {"board": 3, "cell": 0})

def test_full_draw_condition():
    engine = UltimateTicTacToeEngine()
    state = engine.create_initial_state(["p1", "p2"], {"p1": "Alice", "p2": "Bob"})
    
    # Simulate drawn macro board: alternating X and O without 3 in a row
    # X O X
    # X O X
    # O X O
    pattern = ["X", "O", "X", "X", "O", "X", "O", "X", None]
    for i in range(8):
        state["boards"][i]["winner"] = pattern[i]
        state["macro_board"][i] = pattern[i]
        
    # Board 8 is almost full with draw
    state["boards"][8]["cells"] = ["X", "O", "X", "X", "O", "O", "O", "X", None]
    state["next_board"] = 8
    
    # P1 (X) plays the final cell 8 in Board 8 -> Board 8 draws -> Macro board has no 3-in-a-row -> Match DRAW
    state = engine.apply_move(state, "p1", {"board": 8, "cell": 8})
    
    assert state["boards"][8]["winner"] == "draw"
    assert state["status"] == "draw"
    assert state["macro_winner"] == "draw"
