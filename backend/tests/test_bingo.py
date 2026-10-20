import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.platform.registry import game_registry
from backend.app.games.bingo.engine import BingoEngine, BINGO_METADATA, COLUMN_RANGES

client = TestClient(app)

def test_bingo_metadata_registered():
    meta = game_registry.get_game_metadata("bingo")
    assert meta is not None
    assert meta.id == "bingo"
    assert meta.name == "Bingo"
    assert meta.min_players == 1
    assert meta.max_players == 2
    assert meta.supports_local is True
    assert meta.supports_online is True
    assert meta.supports_ai is True

    engine = game_registry.get_game_engine("bingo")
    assert engine is not None
    assert isinstance(engine, BingoEngine)

def test_bingo_card_generation():
    engine = BingoEngine()
    card = engine.generate_card()
    cells = card["cells"]
    marked = card["marked"]

    assert len(cells) == 25
    assert len(marked) == 25

    # Center cell is FREE (value 0) and permanently marked
    assert cells[12] == 0
    assert marked[12] is True

    # 24 actual numbers, no duplicates
    non_free = [c for i, c in enumerate(cells) if i != 12]
    assert len(non_free) == 24
    assert len(set(non_free)) == 24
    assert all(1 <= n <= 75 for n in non_free)

    # Column ranges
    for col_idx in range(5):
        low, high = COLUMN_RANGES[col_idx]
        for row_idx in range(5):
            idx = row_idx * 5 + col_idx
            if idx != 12:
                assert low <= cells[idx] <= high, f"Cell {idx} with val {cells[idx]} outside range {low}-{high}"

def test_bingo_initial_state():
    engine = BingoEngine()
    state = engine.create_initial_state(
        player_ids=["p1", "p2"],
        player_names={"p1": "Alice", "p2": "Bob"},
        options={"pattern": "CLASSIC"}
    )

    assert state["game_id"] == "bingo"
    assert state["pattern"] == "CLASSIC"
    assert state["status"] == "in_progress"
    assert len(state["cards"]) == 2
    assert len(state["draw_pool"]) == 75
    assert state["drawn_numbers"] == []
    assert state["current_number"] is None

    # Each player receives a unique card
    c1 = state["cards"]["p1"]["cells"]
    c2 = state["cards"]["p2"]["cells"]
    assert c1 != c2

def test_bingo_number_drawing_and_marking():
    engine = BingoEngine()
    state = engine.create_initial_state(
        player_ids=["p1"],
        player_names={"p1": "Alice"},
        options={"pattern": "CLASSIC"}
    )

    card = state["cards"]["p1"]
    first_pool_num = state["draw_pool"][0]

    # Draw next number
    new_state = engine.apply_move(state, "p1", {"action": "draw_number"})
    assert new_state["current_number"] == first_pool_num
    assert len(new_state["drawn_numbers"]) == 1
    assert len(new_state["draw_pool"]) == 74

    # If first_pool_num is on Alice's card, it should be marked
    for idx, num in enumerate(card["cells"]):
        if num == first_pool_num:
            assert card["marked"][idx] is True

def test_classic_win_patterns():
    engine = BingoEngine()

    # 1. Row win
    card = {"cells": list(range(25)), "marked": [False] * 25}
    # Mark row 0: 0, 1, 2, 3, 4
    for i in range(5):
        card["marked"][i] = True
    res = engine.check_winner(card, "CLASSIC")
    assert res["winner"] is True
    assert res["pattern"] == "ROW_1"
    assert res["winning_cells"] == [0, 1, 2, 3, 4]

    # 2. Column win
    card2 = {"cells": list(range(25)), "marked": [False] * 25}
    # Mark col 1 (I): 1, 6, 11, 16, 21
    for r in range(5):
        card2["marked"][r * 5 + 1] = True
    res2 = engine.check_winner(card2, "CLASSIC")
    assert res2["winner"] is True
    assert res2["pattern"] == "COLUMN_I"
    assert res2["winning_cells"] == [1, 6, 11, 16, 21]

    # 3. Main Diagonal win (includes center 12)
    card3 = {"cells": list(range(25)), "marked": [False] * 25}
    for i in [0, 6, 12, 18, 24]:
        card3["marked"][i] = True
    res3 = engine.check_winner(card3, "CLASSIC")
    assert res3["winner"] is True
    assert res3["pattern"] == "DIAGONAL_MAIN"

    # 4. Anti Diagonal win (includes center 12)
    card4 = {"cells": list(range(25)), "marked": [False] * 25}
    for i in [4, 8, 12, 16, 20]:
        card4["marked"][i] = True
    res4 = engine.check_winner(card4, "CLASSIC")
    assert res4["winner"] is True
    assert res4["pattern"] == "DIAGONAL_ANTI"

    # Incomplete line should not win
    card_inc = {"cells": list(range(25)), "marked": [False] * 25}
    card_inc["marked"][0] = True
    card_inc["marked"][1] = True
    card_inc["marked"][2] = True
    assert engine.check_winner(card_inc, "CLASSIC")["winner"] is False

def test_four_corners_pattern():
    engine = BingoEngine()
    card = {"cells": list(range(25)), "marked": [False] * 25}
    for c in [0, 4, 20, 24]:
        card["marked"][c] = True

    res = engine.check_winner(card, "FOUR_CORNERS")
    assert res["winner"] is True
    assert res["pattern"] == "FOUR_CORNERS"
    assert res["winning_cells"] == [0, 4, 20, 24]

    # Missing one corner
    card["marked"][24] = False
    assert engine.check_winner(card, "FOUR_CORNERS")["winner"] is False

def test_x_pattern():
    engine = BingoEngine()
    card = {"cells": list(range(25)), "marked": [False] * 25}
    x_cells = [0, 6, 12, 18, 24, 4, 8, 16, 20]
    for c in x_cells:
        card["marked"][c] = True

    res = engine.check_winner(card, "X")
    assert res["winner"] is True
    assert res["pattern"] == "X"
    assert len(res["winning_cells"]) == 9

def test_blackout_pattern():
    engine = BingoEngine()
    card = {"cells": list(range(25)), "marked": [True] * 25}
    res = engine.check_winner(card, "BLACKOUT")
    assert res["winner"] is True
    assert res["pattern"] == "BLACKOUT"
    assert len(res["winning_cells"]) == 25

    # 1 cell missing
    card["marked"][10] = False
    assert engine.check_winner(card, "BLACKOUT")["winner"] is False

def test_bingo_room_api_lifecycle():
    # 1. Create a room for Bingo
    res = client.post("/api/v1/rooms", json={
        "game_id": "bingo",
        "player_name": "HostPlayer",
        "player_id": "host_bingo",
        "max_players": 2,
        "settings": {"pattern": "CLASSIC"}
    })
    assert res.status_code == 200
    room = res.json()
    code = room["room_code"]
    assert room["status"] == "waiting"

    # 2. Guest joins
    res = client.post(f"/api/v1/rooms/{code}/join", json={
        "player_name": "GuestPlayer",
        "player_id": "guest_bingo"
    })
    assert res.status_code == 200

    # 3. Guest ready
    res = client.post(f"/api/v1/rooms/{code}/ready", json={
        "player_id": "guest_bingo",
        "is_ready": True
    })
    assert res.status_code == 200

    # 4. Host starts match
    res = client.post(f"/api/v1/rooms/{code}/start", json={
        "player_id": "host_bingo"
    })
    assert res.status_code == 200
    room = res.json()
    assert room["status"] == "in_progress"
    assert room["match_state"]["game_id"] == "bingo"
    assert "host_bingo" in room["match_state"]["cards"]
    assert "guest_bingo" in room["match_state"]["cards"]

    # 5. Move: Draw number
    res = client.post(f"/api/v1/rooms/{code}/move", json={
        "player_id": "host_bingo",
        "move": {"action": "draw_number"}
    })
    assert res.status_code == 200
    state = res.json()["match_state"]
    assert len(state["drawn_numbers"]) == 1
    assert state["current_number"] is not None
    assert state["current_letter"] in ["B", "I", "N", "G", "O"]
