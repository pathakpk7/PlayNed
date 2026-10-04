import pytest
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)

def test_get_games_catalog():
    response = client.get("/api/v1/games")
    assert response.status_code == 200
    games = response.json()
    assert len(games) >= 4
    game_ids = [g["id"] for g in games]
    assert "hangman" in game_ids
    assert "dots_and_boxes" in game_ids
    assert "quoridor" in game_ids
    assert "pentago" in game_ids

def test_room_lifecycle():
    # 1. Create a room for Dots & Boxes
    res = client.post("/api/v1/rooms", json={
        "game_id": "dots_and_boxes",
        "player_name": "HostPlayer",
        "player_id": "host_123",
        "max_players": 2
    })
    assert res.status_code == 200
    room = res.json()
    room_code = room["room_code"]
    assert room["status"] == "waiting"
    assert len(room["players"]) == 1
    assert room["players"][0]["is_host"] is True

    # 2. Player 2 joins
    res = client.post(f"/api/v1/rooms/{room_code}/join", json={
        "player_name": "GuestPlayer",
        "player_id": "guest_456"
    })
    assert res.status_code == 200
    room = res.json()
    assert len(room["players"]) == 2

    # 3. Player 2 sets ready
    res = client.post(f"/api/v1/rooms/{room_code}/ready", json={
        "player_id": "guest_456",
        "is_ready": True
    })
    assert res.status_code == 200
    assert res.json()["players"][1]["is_ready"] is True

    # 4. Host starts match
    res = client.post(f"/api/v1/rooms/{room_code}/start", json={
        "player_id": "host_123"
    })
    assert res.status_code == 200
    room = res.json()
    assert room["status"] == "in_progress"
    assert room["match_state"] is not None
    assert room["match_state"]["current_turn_player_id"] == "host_123"

    # 5. Host makes move
    res = client.post(f"/api/v1/rooms/{room_code}/move", json={
        "player_id": "host_123",
        "move": {"type": "h", "r": 0, "c": 0}
    })
    assert res.status_code == 200
    room = res.json()
    assert "0,0" in room["match_state"]["horizontal_lines"]
