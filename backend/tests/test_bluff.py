import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.games.bluff.engine import (
    BluffEngine,
    BLUFF_METADATA,
    RANKS,
    SUITS,
    create_standard_deck,
    get_next_rank,
)
from backend.app.platform.registry import game_registry

client = TestClient(app)


def test_bluff_metadata_and_registry():
    assert BLUFF_METADATA.id == "bluff"
    assert BLUFF_METADATA.min_players == 3
    assert BLUFF_METADATA.max_players == 6
    assert BLUFF_METADATA.supports_local is True
    assert BLUFF_METADATA.supports_online is True

    reg_meta = game_registry.get_game_metadata("bluff")
    assert reg_meta is not None
    assert reg_meta.name == "Bluff / Cheat"

    engine = game_registry.get_game_engine("bluff")
    assert isinstance(engine, BluffEngine)


def test_standard_deck_and_rank_cycle():
    deck = create_standard_deck()
    assert len(deck) == 52
    assert len(set(deck)) == 52

    # Verify sequential rank progression
    assert get_next_rank("A") == "2"
    assert get_next_rank("2") == "3"
    assert get_next_rank("10") == "J"
    assert get_next_rank("J") == "Q"
    assert get_next_rank("Q") == "K"
    assert get_next_rank("K") == "A"  # Wraps back to Ace


def test_fair_distribution_and_player_limits():
    engine = BluffEngine()

    # 3 players: 52 // 3 = 17 remainder 1 (two get 17, one gets 18)
    hands3 = engine.deal_deck(["p1", "p2", "p3"])
    assert sum(len(h) for h in hands3.values()) == 52
    assert sorted([len(h) for h in hands3.values()]) == [17, 17, 18]

    # 4 players: exactly 13 each
    hands4 = engine.deal_deck(["p1", "p2", "p3", "p4"])
    assert all(len(h) == 13 for h in hands4.values())

    # 6 players: 52 // 6 = 8 remainder 4 (two get 8, four get 9)
    hands6 = engine.deal_deck(["p1", "p2", "p3", "p4", "p5", "p6"])
    assert sum(len(h) for h in hands6.values()) == 52
    assert sorted([len(h) for h in hands6.values()]) == [8, 8, 9, 9, 9, 9]

    # Player count limits
    with pytest.raises(ValueError):
        engine.create_initial_state(["p1", "p2"], {"p1": "A", "p2": "B"})

    with pytest.raises(ValueError):
        engine.create_initial_state(
            ["p1", "p2", "p3", "p4", "p5", "p6", "p7"],
            {f"p{i}": f"Player {i}" for i in range(1, 8)},
        )


def test_truthful_play_and_failed_challenge():
    engine = BluffEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    assert state["phase"] == "PLAY"
    assert state["current_player_id"] == "p1"
    assert state["required_rank"] == "A"

    # Give p1 an Ace to play truthfully
    state["hands"]["p1"] = ["A_S", "5_D", "9_C"]
    state["card_counts"]["p1"] = 3

    # Alice plays 1 Ace
    move_play = {"action": "play_cards", "cards": ["A_S"]}
    state = engine.apply_move(state, "p1", move_play)

    assert state["phase"] == "CHALLENGE"
    assert state["pile_count"] == 1
    assert state["card_counts"]["p1"] == 2
    assert state["last_play"]["declared_rank"] == "A"

    # Bob challenges Alice
    move_chal = {"action": "challenge"}
    state = engine.apply_move(state, "p2", move_chal)

    assert state["phase"] == "CHALLENGE_REVEAL"
    assert state["challenge_result"]["was_bluff"] is False
    assert state["challenge_result"]["pile_collector_id"] == "p2"  # Bob takes pile
    assert "A_S" in state["hands"]["p2"]
    assert state["pile_count"] == 0

    # Advance after challenge
    state = engine.apply_move(state, "p1", {"action": "continue_after_challenge"})
    assert state["phase"] == "PLAY"
    assert state["required_rank"] == "2"  # Advances to next rank


def test_caught_bluff_and_pile_pickup():
    engine = BluffEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    state["hands"]["p1"] = ["K_H", "K_S", "7_C"]
    state["card_counts"]["p1"] = 3
    state["pile"] = ["2_C", "3_D"]  # Some existing pile cards
    state["pile_count"] = 2

    # Required rank is A, but Alice plays Kings (BLUFF)
    move_play = {"action": "play_cards", "cards": ["K_H", "K_S"]}
    state = engine.apply_move(state, "p1", move_play)

    assert state["phase"] == "CHALLENGE"
    assert state["pile_count"] == 4

    # Charlie calls bluff
    state = engine.apply_move(state, "p3", {"action": "challenge"})

    assert state["phase"] == "CHALLENGE_REVEAL"
    assert state["challenge_result"]["was_bluff"] is True
    assert state["challenge_result"]["pile_collector_id"] == "p1"  # Alice caught, picks up pile
    assert len(state["hands"]["p1"]) == 1 + 4  # 1 remaining + 4 from pile = 5
    assert state["pile_count"] == 0

    # Advance after challenge: Charlie caught the bluff, so Charlie leads next
    state = engine.apply_move(state, "p3", {"action": "continue_after_challenge"})
    assert state["phase"] == "PLAY"
    assert state["current_player_id"] == "p3"
    assert state["required_rank"] == "2"


def test_unchallenged_play_turn_advancement():
    engine = BluffEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    card = state["hands"]["p1"][0]
    state = engine.apply_move(state, "p1", {"action": "play_cards", "cards": [card]})
    assert state["phase"] == "CHALLENGE"

    # Both opponents pass
    state = engine.apply_move(state, "p2", {"action": "pass"})
    assert state["phase"] == "CHALLENGE"
    state = engine.apply_move(state, "p3", {"action": "pass"})

    # Now all opponents passed -> Turn moves to p2, rank advances to 2
    assert state["phase"] == "PLAY"
    assert state["current_player_id"] == "p2"
    assert state["required_rank"] == "2"


def test_winning_condition_surviving_challenge():
    engine = BluffEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    state["hands"]["p1"] = ["A_C"]
    state["card_counts"]["p1"] = 1

    # Alice plays her last card truthfully
    state = engine.apply_move(state, "p1", {"action": "play_cards", "cards": ["A_C"]})
    assert state["phase"] == "CHALLENGE"
    assert state["card_counts"]["p1"] == 0
    assert state["winner_id"] is None  # Cannot win yet while challenge is pending!

    # Bob challenges Alice
    state = engine.apply_move(state, "p2", {"action": "challenge"})
    assert state["phase"] == "CHALLENGE_REVEAL"
    assert state["challenge_result"]["was_bluff"] is False
    assert state["challenge_result"]["pile_collector_id"] == "p2"

    # Alice survived! Continue triggers game over with Alice as winner
    state = engine.apply_move(state, "p1", {"action": "continue_after_challenge"})
    assert state["phase"] == "GAME_OVER"
    assert state["winner_id"] == "p1"
    assert state["winner_name"] == "Alice"


def test_winning_condition_unchallenged():
    engine = BluffEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    state["hands"]["p1"] = ["A_D"]
    state["card_counts"]["p1"] = 1

    # Alice plays her last card
    state = engine.apply_move(state, "p1", {"action": "play_cards", "cards": ["A_D"]})
    assert state["phase"] == "CHALLENGE"

    # Opponents pass
    state = engine.apply_move(state, "p2", {"action": "pass"})
    state = engine.apply_move(state, "p3", {"action": "pass"})

    # Alice wins unchallenged!
    assert state["phase"] == "GAME_OVER"
    assert state["winner_id"] == "p1"
    assert state["winner_name"] == "Alice"


def test_caught_bluff_on_last_card_prevents_win():
    engine = BluffEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    state["hands"]["p1"] = ["K_C"]  # Alice has a King, but rank required is A
    state["card_counts"]["p1"] = 1
    state["pile"] = ["3_H", "4_H"]
    state["pile_count"] = 2

    # Alice bluffs with her last card
    state = engine.apply_move(state, "p1", {"action": "play_cards", "cards": ["K_C"]})
    assert state["phase"] == "CHALLENGE"

    # Charlie challenges and catches Alice!
    state = engine.apply_move(state, "p3", {"action": "challenge"})
    assert state["phase"] == "CHALLENGE_REVEAL"
    assert state["challenge_result"]["was_bluff"] is True
    assert state["challenge_result"]["pile_collector_id"] == "p1"

    # Alice had to take the pile! Her hand is not empty!
    assert len(state["hands"]["p1"]) == 3
    state = engine.apply_move(state, "p3", {"action": "continue_after_challenge"})
    assert state["phase"] == "PLAY"
    assert state["winner_id"] is None  # Did not win!


def test_authoritative_privacy_masking():
    engine = BluffEngine()
    players = ["p1", "p2", "p3"]
    names = {"p1": "Alice", "p2": "Bob", "p3": "Charlie"}

    state = engine.create_initial_state(players, names)
    p1_first_card = state["hands"]["p1"][0]

    # Mask for player p2
    masked = engine.filter_state_for_player(state, "p2")
    assert "hands" not in masked
    assert "pile" not in masked
    assert "my_hand" in masked
    assert masked["my_hand"] == state["hands"]["p2"]
    assert p1_first_card not in masked["my_hand"]
    assert masked["card_counts"]["p1"] == len(state["hands"]["p1"])

    # Test play masking
    state = engine.apply_move(state, "p1", {"action": "play_cards", "cards": [p1_first_card]})
    assert state["phase"] == "CHALLENGE"

    # In challenge phase, actual_cards must be stripped from public view
    masked_chal = engine.filter_state_for_player(state, "p2")
    assert "actual_cards" not in masked_chal["last_play"]
    assert masked_chal["last_play"]["card_count"] == 1
    assert masked_chal["last_play"]["declared_rank"] == "A"


def test_online_platform_room_lifecycle():
    # 1. Create a Bluff room
    create_res = client.post(
        "/api/v1/rooms",
        json={"game_id": "bluff", "player_name": "Alice", "player_id": "h_alice", "max_players": 6},
    )
    assert create_res.status_code == 200
    room_data = create_res.json()
    code = room_data["room_code"]
    assert room_data["game_id"] == "bluff"
    assert room_data["max_players"] == 6

    # 2. Join players Bob and Charlie
    j_res1 = client.post(
        f"/api/v1/rooms/{code}/join", json={"player_name": "Bob", "player_id": "p_bob"}
    )
    assert j_res1.status_code == 200
    j_res2 = client.post(
        f"/api/v1/rooms/{code}/join", json={"player_name": "Charlie", "player_id": "p_charlie"}
    )
    assert j_res2.status_code == 200

    # 3. Ready up
    client.post(f"/api/v1/rooms/{code}/ready", json={"player_id": "p_bob", "is_ready": True})
    client.post(f"/api/v1/rooms/{code}/ready", json={"player_id": "p_charlie", "is_ready": True})

    # 4. Start match
    start_res = client.post(f"/api/v1/rooms/{code}/start", json={"player_id": "h_alice"})
    assert start_res.status_code == 200
    started_room = start_res.json()
    assert started_room["status"] == "in_progress"
    match_state = started_room["match_state"]
    assert match_state["game_id"] == "bluff"
    assert match_state["phase"] == "PLAY"

    # 5. Fetch room with player_id to verify privacy masking over REST
    get_res = client.get(f"/api/v1/rooms/{code}?player_id=h_alice")
    assert get_res.status_code == 200
    host_view = get_res.json()
    assert "hands" not in host_view["match_state"]
    assert "my_hand" in host_view["match_state"]
    assert host_view["match_state"]["my_hand"] is not None
