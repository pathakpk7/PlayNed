import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.games.raja_mantri_chor_sipahi.engine import (
    RajaMantriEngine,
    RAJA_MANTRI_METADATA,
    ROLE_POINTS,
    ALL_ROLES
)
from backend.app.platform.registry import game_registry

client = TestClient(app)

def test_raja_mantri_metadata_and_registry():
    assert RAJA_MANTRI_METADATA.id == "raja_mantri_chor_sipahi"
    assert RAJA_MANTRI_METADATA.min_players == 4
    assert RAJA_MANTRI_METADATA.max_players == 4
    assert RAJA_MANTRI_METADATA.supports_local is True
    assert RAJA_MANTRI_METADATA.supports_online is True

    reg_meta = game_registry.get_game_metadata("raja_mantri_chor_sipahi")
    assert reg_meta is not None
    assert reg_meta.name == "Raja Mantri Chor Sipahi"

    engine = game_registry.get_game_engine("raja_mantri_chor_sipahi")
    assert isinstance(engine, RajaMantriEngine)

def test_exact_scoring_rules_constants():
    # Exactly as required: Raja=1000, Mantri=0, Sipahi=500, Chor=800
    assert ROLE_POINTS["Raja"] == 1000
    assert ROLE_POINTS["Mantri"] == 0
    assert ROLE_POINTS["Sipahi"] == 500
    assert ROLE_POINTS["Chor"] == 800
    # Must not be conventional 800 for Mantri or 0 for Chor
    assert ROLE_POINTS["Mantri"] != 800
    assert ROLE_POINTS["Chor"] != 0

def test_fair_role_assignment():
    engine = RajaMantriEngine()
    players = ["p1", "p2", "p3", "p4"]

    assignments = engine.shuffle_chits(players)
    assert len(assignments) == 4
    assigned_roles = set(assignments.values())
    assert assigned_roles == set(ALL_ROLES)
    assert len(assigned_roles) == 4

    # Requires exactly 4 players
    with pytest.raises(ValueError):
        engine.shuffle_chits(["p1", "p2", "p3"])

    with pytest.raises(ValueError):
        engine.shuffle_chits(["p1", "p2", "p3", "p4", "p5"])

def test_round_state_flow_and_guessing():
    engine = RajaMantriEngine()
    players = ["p1", "p2", "p3", "p4"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie", "p4": "Dave"}

    state = engine.create_initial_state(players, names, {"total_rounds": 3})
    assert state["phase"] == "CHIT_REVEAL"
    assert state["current_round"] == 1
    assert state["total_rounds"] == 3

    raja_pid = state["raja_player_id"]
    mantri_pid = state["mantri_player_id"]
    sipahi_pid = state["sipahi_player_id"]
    chor_pid = state["chor_player_id"]

    assert len({raja_pid, mantri_pid, sipahi_pid, chor_pid}) == 4

    # 1. Privacy Masking during CHIT_REVEAL
    masked_for_p1 = engine.filter_state_for_player(state, "p1")
    assert "role_assignments" not in masked_for_p1
    assert masked_for_p1["my_role"] == state["role_assignments"]["p1"]
    assert masked_for_p1["raja_player_id"] is None
    assert masked_for_p1["mantri_player_id"] is None
    assert masked_for_p1["chor_player_id"] is None
    assert masked_for_p1["sipahi_player_id"] is None

    # 2. Advance through acknowledgements
    for p in ["p1", "p2", "p3", "p4"]:
        state = engine.apply_move(state, p, {"action": "acknowledge_chit"})

    assert state["phase"] == "RAJA_REVEAL"
    assert raja_pid in state["revealed_roles"]
    assert state["revealed_roles"][raja_pid] == "Raja"

    # In RAJA_REVEAL, Raja is public, but Mantri, Sipahi, Chor remain hidden
    masked_raja = engine.filter_state_for_player(state, "p2")
    assert masked_raja["raja_player_id"] == raja_pid
    assert masked_raja["mantri_player_id"] is None
    assert masked_raja["chor_player_id"] is None

    # 3. Raja summons Mantri
    # Unauthorized player cannot summon
    invalid_pid = next(p for p in players if p != raja_pid and p != players[0])
    valid, err = engine.validate_move(state, invalid_pid, {"action": "call_mantri"})
    assert not valid

    state = engine.apply_move(state, raja_pid, {"action": "call_mantri"})
    assert state["phase"] == "MANTRI_REVEAL"
    assert mantri_pid in state["revealed_roles"]

    # 4. Mantri steps forward to guess
    state = engine.apply_move(state, mantri_pid, {"action": "step_forward"})
    assert state["phase"] == "CHOR_GUESS"
    eligible = state["eligible_suspect_ids"]
    assert set(eligible) == {sipahi_pid, chor_pid}
    assert raja_pid not in eligible
    assert mantri_pid not in eligible

    # 5. Invalid guess validations:
    # Non-mantri cannot guess
    valid, err = engine.validate_move(state, raja_pid, {"action": "guess_chor", "target_player_id": chor_pid})
    assert not valid
    assert "Only the Mantri" in err

    # Mantri cannot guess themselves
    valid, err = engine.validate_move(state, mantri_pid, {"action": "guess_chor", "target_player_id": mantri_pid})
    assert not valid

    # Mantri cannot guess Raja
    valid, err = engine.validate_move(state, mantri_pid, {"action": "guess_chor", "target_player_id": raja_pid})
    assert not valid

    # 6. Valid guess (Mantri correctly guesses Chor)
    state = engine.apply_move(state, mantri_pid, {"action": "guess_chor", "target_player_id": chor_pid})
    assert state["phase"] == "FULL_REVEAL"
    assert state["guess_correct"] is True
    assert state["guessed_chor_player_id"] == chor_pid

    # Check exact points awarded:
    # Raja=1000, Mantri=0, Sipahi=500, Chor=800
    pts = state["round_points"]
    assert pts[raja_pid] == 1000
    assert pts[mantri_pid] == 0
    assert pts[sipahi_pid] == 500
    assert pts[chor_pid] == 800

    assert state["cumulative_scores"][raja_pid] == 1000
    assert state["cumulative_scores"][mantri_pid] == 0
    assert state["cumulative_scores"][sipahi_pid] == 500
    assert state["cumulative_scores"][chor_pid] == 800

    # In FULL_REVEAL, all roles are public in filter_state_for_player
    masked_full = engine.filter_state_for_player(state, "p1")
    assert masked_full["revealed_roles"] == state["role_assignments"]

    # Cannot submit another guess in same round
    valid, err = engine.validate_move(state, mantri_pid, {"action": "guess_chor", "target_player_id": chor_pid})
    assert not valid

def test_fixed_scoring_independent_of_guess_outcome():
    """Verify that Mantri and Chor receive fixed role points even when guess is wrong."""
    engine = RajaMantriEngine()
    players = ["p1", "p2", "p3", "p4"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie", "p4": "Dave"}

    state = engine.create_initial_state(players, names, {"total_rounds": 1})
    state["phase"] = "CHOR_GUESS"

    raja_pid = state["raja_player_id"]
    mantri_pid = state["mantri_player_id"]
    sipahi_pid = state["sipahi_player_id"]
    chor_pid = state["chor_player_id"]

    # Mantri incorrectly guesses Sipahi instead of Chor
    state = engine.apply_move(state, mantri_pid, {"action": "guess_chor", "target_player_id": sipahi_pid})
    assert state["guess_correct"] is False
    assert state["guessed_chor_player_id"] == sipahi_pid

    # Fixed role points MUST be awarded as specified:
    pts = state["round_points"]
    assert pts[raja_pid] == 1000
    assert pts[mantri_pid] == 0
    assert pts[sipahi_pid] == 500
    assert pts[chor_pid] == 800

def test_match_completion_and_tie_handling():
    engine = RajaMantriEngine()
    players = ["p1", "p2", "p3", "p4"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie", "p4": "Dave"}

    state = engine.create_initial_state(players, names, {"total_rounds": 1})
    state["phase"] = "FULL_REVEAL"

    # End match
    state = engine.apply_move(state, "p1", {"action": "next_round"})
    assert state["phase"] == "MATCH_RESULTS"
    assert state["status"] == "finished"
    assert "winner_player_ids" in state
    assert len(state["winner_player_ids"]) >= 1

    # Test explicit tie scenario
    tie_state = dict(state)
    tie_state["cumulative_scores"] = {"p1": 1500, "p2": 1500, "p3": 500, "p4": 800}
    tie_state["current_round"] = 2
    tie_state["total_rounds"] = 2
    tie_state["phase"] = "FULL_REVEAL"

    end_tie_state = engine.apply_move(tie_state, "p1", {"action": "next_round"})
    assert end_tie_state["is_tie"] is True
    assert set(end_tie_state["winner_player_ids"]) == {"p1", "p2"}
    assert "tie" in end_tie_state["last_action"].lower()

def test_raja_mantri_room_api_lifecycle():
    # 1. Create Room (max_players 4)
    res = client.post("/api/v1/rooms", json={
        "game_id": "raja_mantri_chor_sipahi",
        "player_name": "Host Alice",
        "player_id": "p_host",
        "max_players": 4,
        "settings": {"total_rounds": 3}
    })
    assert res.status_code == 200
    room = res.json()
    code = room["room_code"]
    assert room["max_players"] == 4
    assert len(room["players"]) == 1

    # 2. Join 3 more players
    for idx, (p_id, p_name) in enumerate([("p_2", "Bob"), ("p_3", "Charlie"), ("p_4", "Dave")]):
        j_res = client.post(f"/api/v1/rooms/{code}/join", json={"player_name": p_name, "player_id": p_id})
        assert j_res.status_code == 200

    # 3. Cannot join 5th player
    full_res = client.post(f"/api/v1/rooms/{code}/join", json={"player_name": "Eve", "player_id": "p_5"})
    assert full_res.status_code == 400

    # 4. Start Match
    start_res = client.post(f"/api/v1/rooms/{code}/start", json={"player_id": "p_host"})
    assert start_res.status_code == 200
    started_room = start_res.json()
    assert started_room["status"] == "in_progress"

    # 5. Fetch room with player_id to verify privacy masking over REST
    get_res = client.get(f"/api/v1/rooms/{code}?player_id=p_host")
    assert get_res.status_code == 200
    host_view = get_res.json()
    m_state = host_view["match_state"]
    assert "role_assignments" not in m_state
    assert "my_role" in m_state
    assert m_state["my_role"] in ALL_ROLES
    assert m_state["raja_player_id"] is None
