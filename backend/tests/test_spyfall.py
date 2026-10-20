import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.games.spyfall.engine import SpyfallEngine, SPYFALL_METADATA
from backend.app.games.spyfall.locations import (
    get_all_locations,
    get_categories,
    get_locations_by_category,
    match_location_guess,
    normalize_location_name,
)
from backend.app.games.spyfall.scoring import calculate_round_points
from backend.app.platform.registry import game_registry

client = TestClient(app)


def test_spyfall_metadata_and_registry():
    assert SPYFALL_METADATA.id == "spyfall"
    assert SPYFALL_METADATA.min_players == 3
    assert SPYFALL_METADATA.max_players == 8
    assert SPYFALL_METADATA.supports_local is True
    assert SPYFALL_METADATA.supports_online is True

    reg_meta = game_registry.get_game_metadata("spyfall")
    assert reg_meta is not None
    assert reg_meta.name == "Spyfall"

    engine = game_registry.get_game_engine("spyfall")
    assert isinstance(engine, SpyfallEngine)


def test_locations_dataset_completeness_and_matching():
    all_locs = get_all_locations()
    assert len(all_locs) >= 60  # At least 60 locations
    unique_names = {l["name"] for l in all_locs}
    assert len(unique_names) == len(all_locs)  # No duplicate names

    categories = get_categories()
    assert len(categories) == 5

    for cat in categories:
        cat_locs = get_locations_by_category(cat)
        assert len(cat_locs) >= 10  # Plentiful locations per category

    # Matching logic tests
    assert match_location_guess("airport", "Airport") is True
    assert match_location_guess("   AIRPORT!  ", "Airport") is True
    assert match_location_guess("Space Station", "Space Station") is True
    assert match_location_guess("space station", "Space Station") is True
    assert match_location_guess("wrong location", "Airport") is False
    assert match_location_guess("", "Airport") is False


def test_role_and_location_assignment_fairness():
    engine = SpyfallEngine()
    players = [f"p{i}" for i in range(1, 6)]
    names = {p: f"Player {p}" for p in players}

    state = engine.create_initial_state(players, names)
    assert state["phase"] == "ROLE_REVEAL"
    assert state["current_round"] == 1
    assert state["total_rounds"] == 3

    roles = state["role_assignments"]
    spy_id = state["spy_player_id"]
    assert spy_id in players
    assert roles[spy_id] == "spy"

    # Exactly 1 spy, rest explorers
    assert list(roles.values()).count("spy") == 1
    assert list(roles.values()).count("explorer") == len(players) - 1

    # Valid secret location assigned
    loc = state["secret_location"]
    assert "name" in loc
    assert "category" in loc

    # Invalid player counts rejected
    with pytest.raises(ValueError):
        engine.create_initial_state(["p1", "p2"], {"p1": "A", "p2": "B"})

    with pytest.raises(ValueError):
        engine.create_initial_state(
            [f"p{i}" for i in range(1, 10)], {f"p{i}": f"P{i}" for i in range(1, 10)}
        )


def test_strict_authoritative_privacy_masking():
    engine = SpyfallEngine()
    players = ["p1", "p2", "p3", "p4"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie", "p4": "Dave"}

    state = engine.create_initial_state(players, names)
    spy_id = state["spy_player_id"]
    non_spy_id = [p for p in players if p != spy_id][0]
    loc_name = state["secret_location"]["name"]

    # 1. Mask for the Spy
    spy_masked = engine.filter_state_for_player(state, spy_id)
    assert "role_assignments" not in spy_masked
    assert "spy_player_id" not in spy_masked
    assert "secret_location" not in spy_masked
    assert spy_masked["my_role"] == "spy"
    assert spy_masked["my_location"] is None  # Spy must NEVER see secret location!

    # 2. Mask for Non-Spy Explorer
    explorer_masked = engine.filter_state_for_player(state, non_spy_id)
    assert "role_assignments" not in explorer_masked
    assert "spy_player_id" not in explorer_masked  # Explorer must NEVER see Spy identity!
    assert "secret_location" not in explorer_masked
    assert explorer_masked["my_role"] == "explorer"
    assert explorer_masked["my_location"] == loc_name


def test_discussion_flow_and_accusation_conviction():
    engine = SpyfallEngine()
    players = ["p1", "p2", "p3", "p4"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie", "p4": "Dave"}

    state = engine.create_initial_state(players, names)
    spy_id = "p1"
    state["spy_player_id"] = spy_id
    state["role_assignments"] = {p: ("spy" if p == spy_id else "explorer") for p in players}

    # All acknowledge roles
    for p in players:
        state = engine.apply_move(state, p, {"action": "acknowledge_role"})
    assert state["phase"] == "DISCUSSION"

    # Bob accuses Alice (the Spy)
    state = engine.apply_move(state, "p2", {"action": "accuse_player", "target_player_id": "p1"})
    assert state["phase"] == "ACCUSATION_VOTING"
    assert state["accused_target_id"] == "p1"

    # In voting phase, votes map is masked publicly
    masked_vote = engine.filter_state_for_player(state, "p3")
    assert "votes" not in masked_vote
    assert "voted_player_ids" in masked_vote

    # Charlie and Dave vote guilty (3 out of 4 players = strict majority)
    state = engine.apply_move(state, "p3", {"action": "cast_vote", "vote": "guilty"})
    state = engine.apply_move(state, "p4", {"action": "cast_vote", "vote": "guilty"})
    state = engine.apply_move(state, "p1", {"action": "cast_vote", "vote": "innocent"})

    # Spy was caught! Since allow_spy_guess is True, transitions to SPY_GUESS
    assert state["phase"] == "SPY_GUESS"

    # Non-spy cannot guess
    with pytest.raises(ValueError):
        engine.apply_move(state, "p2", {"action": "spy_guess_location", "guessed_location": "Airport"})

    # Spy makes wrong final guess
    state = engine.apply_move(state, "p1", {"action": "spy_guess_location", "guessed_location": "Completely Wrong"})
    assert state["phase"] == "ROUND_RESOLUTION"
    assert state["round_outcome"] == "SPY_CAUGHT"
    assert state["round_points"]["p1"] == 0
    assert state["round_points"]["p2"] == 2  # Accused/voted guilty
    assert state["round_points"]["p3"] == 2  # Voted guilty
    assert state["round_points"]["p4"] == 2  # Voted guilty


def test_spy_guesses_location_and_steals_win():
    engine = SpyfallEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    spy_id = "p1"
    state["spy_player_id"] = spy_id
    state["role_assignments"] = {"p1": "spy", "p2": "explorer", "p3": "explorer"}
    state["secret_location"] = {"id": "casino", "name": "Casino", "category": "Leisure & Entertainment"}

    # Start discussion
    for p in players:
        state = engine.apply_move(state, p, {"action": "acknowledge_role"})
    assert state["phase"] == "DISCUSSION"

    # Alice (Spy) guesses correctly during discussion
    state = engine.apply_move(state, "p1", {"action": "spy_guess_location", "guessed_location": "casino"})
    assert state["phase"] == "ROUND_RESOLUTION"
    assert state["round_outcome"] == "SPY_GUESSED_LOCATION"
    assert state["round_points"]["p1"] == 3
    assert state["cumulative_scores"]["p1"] == 3
    assert state["round_points"]["p2"] == 0
    assert state["round_points"]["p3"] == 0


def test_innocent_player_conviction():
    engine = SpyfallEngine()
    players = ["p1", "p2", "p3", "p4"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie", "p4": "Dave"}

    state = engine.create_initial_state(players, names)
    state["spy_player_id"] = "p1"  # Alice is Spy
    state["role_assignments"] = {"p1": "spy", "p2": "explorer", "p3": "explorer", "p4": "explorer"}

    for p in players:
        state = engine.apply_move(state, p, {"action": "acknowledge_role"})

    # Alice (Spy) cunningly accuses innocent Bob
    state = engine.apply_move(state, "p1", {"action": "accuse_player", "target_player_id": "p2"})
    assert state["phase"] == "ACCUSATION_VOTING"

    # Charlie and Dave are fooled and vote guilty
    state = engine.apply_move(state, "p3", {"action": "cast_vote", "vote": "guilty"})
    state = engine.apply_move(state, "p4", {"action": "cast_vote", "vote": "guilty"})
    state = engine.apply_move(state, "p2", {"action": "cast_vote", "vote": "innocent"})

    # Innocent player convicted -> Spy wins!
    assert state["phase"] == "ROUND_RESOLUTION"
    assert state["round_outcome"] == "INNOCENT_ACCUSED"
    assert state["round_points"]["p1"] == 2  # Spy survives
    assert state["round_points"]["p2"] == 0
    assert state["round_points"]["p3"] == 0


def test_timer_expired_spy_survives():
    engine = SpyfallEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    state["spy_player_id"] = "p1"
    for p in players:
        state = engine.apply_move(state, p, {"action": "acknowledge_role"})
    assert state["phase"] == "DISCUSSION"

    # Discussion timer expires without successful accusation
    state = engine.apply_move(state, "p1", {"action": "timer_expired"})
    assert state["phase"] == "ROUND_RESOLUTION"
    assert state["round_outcome"] == "SPY_SURVIVED_TIME"
    assert state["round_points"]["p1"] == 2  # Spy survives: +2
    assert state["round_points"]["p2"] == 1  # Non-spies get +1
    assert state["round_points"]["p3"] == 1


def test_multi_round_progression_and_match_end():
    engine = SpyfallEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names, {"total_rounds": 2})
    state["cumulative_scores"] = {"p1": 3, "p2": 0, "p3": 0}
    state["current_round"] = 1
    state["phase"] = "ROUND_RESOLUTION"

    # Advance to round 2
    state = engine.apply_move(state, "p1", {"action": "next_round"})
    assert state["current_round"] == 2
    assert state["phase"] == "ROLE_REVEAL"
    assert state["cumulative_scores"]["p1"] == 3  # Scores preserved!

    # Complete round 2
    state["phase"] = "ROUND_RESOLUTION"
    state = engine.apply_move(state, "p1", {"action": "next_round"})
    assert state["phase"] == "MATCH_RESULTS"
    assert "winner_player_ids" in state
    assert state["winner_player_ids"] == ["p1"]


def test_online_platform_room_lifecycle():
    # 1. Create a Spyfall room (max_players 8)
    create_res = client.post(
        "/api/v1/rooms",
        json={"game_id": "spyfall", "player_name": "Host Alice", "player_id": "h_alice", "max_players": 8},
    )
    assert create_res.status_code == 200
    room_data = create_res.json()
    code = room_data["room_code"]
    assert room_data["game_id"] == "spyfall"
    assert room_data["max_players"] == 8

    # 2. Join 2 more players (Bob, Charlie)
    j_res1 = client.post(f"/api/v1/rooms/{code}/join", json={"player_name": "Bob", "player_id": "p_bob"})
    assert j_res1.status_code == 200
    j_res2 = client.post(f"/api/v1/rooms/{code}/join", json={"player_name": "Charlie", "player_id": "p_charlie"})
    assert j_res2.status_code == 200

    # 3. Ready up
    client.post(f"/api/v1/rooms/{code}/ready", json={"player_id": "p_bob", "is_ready": True})
    client.post(f"/api/v1/rooms/{code}/ready", json={"player_id": "p_charlie", "is_ready": True})

    # 4. Start match
    start_res = client.post(f"/api/v1/rooms/{code}/start", json={"player_id": "h_alice"})
    assert start_res.status_code == 200
    started_room = start_res.json()
    assert started_room["status"] == "in_progress"

    # 5. Fetch room with player_id to verify privacy masking over REST
    get_res = client.get(f"/api/v1/rooms/{code}?player_id=h_alice")
    assert get_res.status_code == 200
    host_view = get_res.json()
    match_st = host_view["match_state"]
    assert "role_assignments" not in match_st
    assert "spy_player_id" not in match_st
    assert "secret_location" not in match_st
    assert "my_role" in match_st
    assert match_st["my_role"] in ("spy", "explorer")
