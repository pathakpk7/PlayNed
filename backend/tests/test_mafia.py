"""Comprehensive Unit & Integration Tests for Mafia / Werewolf Game Engine & Factions."""

import pytest
from backend.app.games.mafia.engine import MafiaEngine, MAFIA_METADATA, MafiaPhase
from backend.app.games.mafia.roles import (
    RoleType,
    Faction,
    ROLE_REGISTRY,
    get_role_distribution,
    assign_roles,
)
from backend.app.platform.registry import game_registry


def test_mafia_metadata_and_registry():
    meta = game_registry.get_game_metadata("mafia")
    engine = game_registry.get_game_engine("mafia")

    assert meta is not None
    assert meta.name == "Mafia / Werewolf"
    assert meta.min_players == 5
    assert meta.max_players == 12
    assert meta.supports_local is True
    assert meta.supports_online is True
    assert isinstance(engine, MafiaEngine)


def test_player_count_boundaries():
    engine = MafiaEngine()

    # Reject < 5
    for count in [1, 2, 3, 4]:
        pids = [f"p{i}" for i in range(1, count + 1)]
        pnames = {pid: f"Player {pid}" for pid in pids}
        with pytest.raises(ValueError, match="requires between 5 and 12 players"):
            engine.create_initial_state(pids, pnames)

    # Reject > 12
    thirteen_pids = [f"p{i}" for i in range(1, 14)]
    thirteen_names = {pid: f"Player {pid}" for pid in thirteen_pids}
    with pytest.raises(ValueError, match="requires between 5 and 12 players"):
        engine.create_initial_state(thirteen_pids, thirteen_names)


def test_role_distributions_from_5_to_12_players():
    # Expected distributions per player count
    # 5: 1 Mafia, 1 Doctor, 1 Detective, 2 Villagers
    # 6: 2 Mafia, 1 Doctor, 1 Detective, 2 Villagers
    # 7: 2 Mafia, 1 Doctor, 1 Detective, 3 Villagers
    # 8: 2 Mafia, 1 Doctor, 1 Detective, 4 Villagers
    # 9: 2 Mafia, 1 Doctor, 1 Detective, 5 Villagers
    # 10: 3 Mafia, 1 Doctor, 1 Detective, 5 Villagers
    # 11: 3 Mafia, 1 Doctor, 1 Detective, 6 Villagers
    # 12: 3 Mafia, 1 Doctor, 1 Detective, 7 Villagers
    for count in range(5, 13):
        roles = get_role_distribution(count)
        assert len(roles) == count
        mafia_count = roles.count(RoleType.MAFIA)
        doc_count = roles.count(RoleType.DOCTOR)
        det_count = roles.count(RoleType.DETECTIVE)
        vil_count = roles.count(RoleType.VILLAGER)

        assert doc_count == 1
        assert det_count == 1
        assert mafia_count >= 1
        assert vil_count >= 2

        if count == 5:
            assert mafia_count == 1
            assert vil_count == 2
        elif 6 <= count <= 9:
            assert mafia_count == 2
        elif count >= 10:
            assert mafia_count == 3


def test_fair_role_assignment():
    pids = [f"p{i}" for i in range(1, 7)]
    roles = assign_roles(pids, seed=42)
    assert len(roles) == 6
    for pid in pids:
        assert pid in roles
        assert roles[pid] in [r.value for r in RoleType]


def test_authoritative_privacy_masking():
    engine = MafiaEngine()
    pids = [f"p{i}" for i in range(1, 7)]
    pnames = {pid: f"Agent {pid}" for pid in pids}
    state = engine.create_initial_state(pids, pnames, options={"seed": 100})

    mafia_pids = [pid for pid, r in state["role_assignments"].items() if r == RoleType.MAFIA.value]
    doctor_pids = [pid for pid, r in state["role_assignments"].items() if r == RoleType.DOCTOR.value]
    detective_pids = [pid for pid, r in state["role_assignments"].items() if r == RoleType.DETECTIVE.value]
    villager_pids = [pid for pid, r in state["role_assignments"].items() if r == RoleType.VILLAGER.value]

    mafia_player = mafia_pids[0]
    doctor_player = doctor_pids[0]
    detective_player = detective_pids[0]
    villager_player = villager_pids[0]

    # 1. Filtered for Villager
    v_masked = engine.filter_state_for_player(state, villager_player)
    assert "role_assignments" not in v_masked
    assert v_masked["my_role"] == RoleType.VILLAGER.value
    assert v_masked["mafia_teammates"] == []
    assert v_masked["my_investigations"] == []

    # 2. Filtered for Mafia
    m_masked = engine.filter_state_for_player(state, mafia_player)
    assert "role_assignments" not in m_masked
    assert m_masked["my_role"] == RoleType.MAFIA.value
    assert set(m_masked["mafia_teammates"]) == set(mafia_pids)

    # 3. Filtered for Detective
    d_masked = engine.filter_state_for_player(state, detective_player)
    assert "role_assignments" not in d_masked
    assert d_masked["my_role"] == RoleType.DETECTIVE.value
    assert d_masked["mafia_teammates"] == []


def test_night_phase_unprotected_kill_and_investigation():
    engine = MafiaEngine()
    pids = [f"p{i}" for i in range(1, 7)]
    pnames = {pid: f"P_{pid}" for pid in pids}
    state = engine.create_initial_state(pids, pnames, options={"seed": 123})

    # Acknowledge roles to advance to Night 1
    for pid in pids:
        state = engine.apply_move(state, pid, {"action": "acknowledge_role"})

    assert state["phase"] == MafiaPhase.NIGHT_ACTIONS.value

    mafia_pids = [pid for pid, r in state["role_assignments"].items() if r == RoleType.MAFIA.value]
    doc_id = [pid for pid, r in state["role_assignments"].items() if r == RoleType.DOCTOR.value][0]
    det_id = [pid for pid, r in state["role_assignments"].items() if r == RoleType.DETECTIVE.value][0]
    vil_pids = [pid for pid, r in state["role_assignments"].items() if r == RoleType.VILLAGER.value]

    victim = vil_pids[0]
    other_saved = vil_pids[1]

    # Mafia votes victim
    for m_id in mafia_pids:
        state = engine.apply_move(state, m_id, {"action": "mafia_vote", "target_id": victim})

    # Doctor protects someone else
    state = engine.apply_move(state, doc_id, {"action": "doctor_protect", "target_id": other_saved})

    # Detective investigates a Mafia member
    state = engine.apply_move(state, det_id, {"action": "detective_investigate", "target_id": mafia_pids[0]})

    # Night resolves automatically when all required roles submit actions
    assert state["phase"] == MafiaPhase.DAY_ANNOUNCEMENT.value
    assert state["alive_status"][victim] is False
    assert state["last_night_casualty"] == victim

    # Verify Detective's private results
    det_results = state["investigation_results"][det_id]
    assert len(det_results) == 1
    assert det_results[0]["target_id"] == mafia_pids[0]
    assert det_results[0]["is_mafia"] is True


def test_night_phase_doctor_heroic_save():
    engine = MafiaEngine()
    pids = [f"p{i}" for i in range(1, 6)]
    pnames = {pid: f"P_{pid}" for pid in pids}
    state = engine.create_initial_state(pids, pnames, options={"seed": 777})

    for pid in pids:
        state = engine.apply_move(state, pid, {"action": "acknowledge_role"})

    mafia_id = [pid for pid, r in state["role_assignments"].items() if r == RoleType.MAFIA.value][0]
    doc_id = [pid for pid, r in state["role_assignments"].items() if r == RoleType.DOCTOR.value][0]
    det_id = [pid for pid, r in state["role_assignments"].items() if r == RoleType.DETECTIVE.value][0]
    vil_id = [pid for pid, r in state["role_assignments"].items() if r == RoleType.VILLAGER.value][0]

    # Mafia attacks vil_id, but Doctor protects vil_id!
    state = engine.apply_move(state, mafia_id, {"action": "mafia_vote", "target_id": vil_id})
    state = engine.apply_move(state, doc_id, {"action": "doctor_protect", "target_id": vil_id})
    state = engine.apply_move(state, det_id, {"action": "detective_investigate", "target_id": vil_id})

    assert state["phase"] == MafiaPhase.DAY_ANNOUNCEMENT.value
    assert state["last_night_casualty"] is None
    assert state["alive_status"][vil_id] is True  # Survived!


def test_day_voting_tie_and_elimination():
    engine = MafiaEngine()
    pids = [f"p{i}" for i in range(1, 6)]
    pnames = {pid: f"P_{pid}" for pid in pids}
    state = engine.create_initial_state(pids, pnames, options={"seed": 888})

    # Skip to Day Voting
    state["phase"] = MafiaPhase.DAY_VOTING.value
    living = [pid for pid, alive in state["alive_status"].items() if alive]

    # Test Tie Case: p1 votes p2, p2 votes p1, p3 votes p2, p4 votes p1, p5 abstains
    state = engine.apply_move(state, living[0], {"action": "cast_vote", "target_id": living[1]})
    state = engine.apply_move(state, living[1], {"action": "cast_vote", "target_id": living[0]})
    state = engine.apply_move(state, living[2], {"action": "cast_vote", "target_id": living[1]})
    state = engine.apply_move(state, living[3], {"action": "cast_vote", "target_id": living[0]})
    state = engine.apply_move(state, living[4], {"action": "cast_vote", "target_id": "abstain"})

    # Voting resolves: 2 votes for living[0], 2 votes for living[1] -> Tie! Nobody exiled
    assert state["phase"] == MafiaPhase.VOTE_RESOLUTION.value
    assert state["last_voted_out"] is None


def test_town_win_condition():
    engine = MafiaEngine()
    pids = [f"p{i}" for i in range(1, 6)]
    pnames = {pid: f"P_{pid}" for pid in pids}
    state = engine.create_initial_state(pids, pnames, options={"seed": 999})

    mafia_id = [pid for pid, r in state["role_assignments"].items() if r == RoleType.MAFIA.value][0]
    town_voters = [pid for pid in pids if pid != mafia_id]

    state["phase"] = MafiaPhase.DAY_VOTING.value

    # All living town voters vote out the only Mafia member
    for v in town_voters:
        state = engine.apply_move(state, v, {"action": "cast_vote", "target_id": mafia_id})
    state = engine.apply_move(state, mafia_id, {"action": "cast_vote", "target_id": town_voters[0]})

    assert state["phase"] == MafiaPhase.MATCH_RESULTS.value
    assert state["winning_faction"] == "town"
    assert set(state["winner_player_ids"]) == set(town_voters)


def test_mafia_win_condition():
    engine = MafiaEngine()
    pids = [f"p{i}" for i in range(1, 6)]
    pnames = {pid: f"P_{pid}" for pid in pids}
    state = engine.create_initial_state(pids, pnames, options={"seed": 999})

    mafia_id = [pid for pid, r in state["role_assignments"].items() if r == RoleType.MAFIA.value][0]
    non_mafia = [pid for pid in pids if pid != mafia_id]

    # Kill off non-mafia until living mafia == living non-mafia
    state["alive_status"][non_mafia[0]] = False
    state["alive_status"][non_mafia[1]] = False
    state["alive_status"][non_mafia[2]] = False  # Now 1 living Mafia vs 1 living Town

    state["phase"] = MafiaPhase.DAY_VOTING.value
    winner = engine._check_win_conditions(state)
    assert winner == "mafia"


def test_optional_jester_win_condition():
    engine = MafiaEngine()
    pids = [f"p{i}" for i in range(1, 7)]
    pnames = {pid: f"P_{pid}" for pid in pids}
    state = engine.create_initial_state(pids, pnames, options={"include_jester": True, "seed": 42})

    jester_ids = [pid for pid, r in state["role_assignments"].items() if r == RoleType.JESTER.value]
    assert len(jester_ids) == 1
    j_id = jester_ids[0]

    state["phase"] = MafiaPhase.DAY_VOTING.value
    voters = [pid for pid in pids if pid != j_id]

    # Town votes out the Jester!
    for v in voters:
        state = engine.apply_move(state, v, {"action": "cast_vote", "target_id": j_id})
    state = engine.apply_move(state, j_id, {"action": "cast_vote", "target_id": "abstain"})

    assert state["phase"] == MafiaPhase.MATCH_RESULTS.value
    assert state["winning_faction"] == "jester"
    assert state["winner_player_ids"] == [j_id]
