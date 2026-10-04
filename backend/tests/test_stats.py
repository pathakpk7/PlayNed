import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from backend.app.database import Base, get_db
from backend.app.main import app
from backend.app.models_db import DBUser

# Setup in-memory SQLite database for test isolation
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

@pytest.fixture(autouse=True)
def setup_database():
    app.dependency_overrides[get_db] = override_get_db
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    # Create test user
    test_user = DBUser(
        id="test-user-123",
        email="testplayer@example.com",
        username="TestPlayer",
        hashed_password="fakehashedpassword",
    )
    db.add(test_user)
    db.commit()
    yield
    Base.metadata.drop_all(bind=engine)
    app.dependency_overrides.pop(get_db, None)

client = TestClient(app)

def test_record_cricket_super_over_stats():
    # 1. Record Super Over win with runs & wickets
    response = client.post(
        "/api/v1/stats/record",
        json={
            "user_id": "test-user-123",
            "game_id": "cricket",
            "section_id": "super_over",
            "outcome": "win",
            "score": 24,
            "opponent_name": "AI Bowler",
            "details": {"balls_faced": 6, "boundaries": 3},
            "extra_stats_update": {"runs": 24, "wickets": 2, "sixes": 2, "fours": 1}
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["game_id"] == "cricket"
    assert data["section_id"] == "super_over"
    assert data["matches_played"] == 1
    assert data["matches_won"] == 1
    assert data["high_score"] == 24
    assert data["current_streak"] == 1
    assert data["extra_data"]["runs"] == 24
    assert data["extra_data"]["wickets"] == 2

    # 2. Record second match in Super Over (accumulating stats)
    response2 = client.post(
        "/api/v1/stats/record",
        json={
            "user_id": "test-user-123",
            "game_id": "cricket",
            "section_id": "super_over",
            "outcome": "win",
            "score": 18,
            "opponent_name": "AI Bowler",
            "extra_stats_update": {"runs": 18, "wickets": 1, "sixes": 1}
        }
    )
    assert response2.status_code == 200
    data2 = response2.json()
    assert data2["matches_played"] == 2
    assert data2["matches_won"] == 2
    assert data2["current_streak"] == 2
    assert data2["high_score"] == 24 # Kept max
    assert data2["extra_data"]["runs"] == 42 # 24 + 18
    assert data2["extra_data"]["wickets"] == 3 # 2 + 1
    assert data2["extra_data"]["sixes"] == 3 # 2 + 1

def test_record_cricket_draft_and_stat_clash_sections():
    # Record Draft mode match
    res_draft = client.post(
        "/api/v1/stats/record",
        json={
            "user_id": "test-user-123",
            "game_id": "cricket",
            "section_id": "draft",
            "outcome": "win",
            "score": 88,
            "details": {"squad": ["Virat Kohli", "Jasprit Bumrah"]},
            "extra_stats_update": {"draft_wins": 1, "total_budget_spent": 96}
        }
    )
    assert res_draft.status_code == 200
    assert res_draft.json()["section_id"] == "draft"
    assert res_draft.json()["matches_won"] == 1

    # Record Stat Clash quiz
    res_clash = client.post(
        "/api/v1/stats/record",
        json={
            "user_id": "test-user-123",
            "game_id": "cricket",
            "section_id": "stat_clash",
            "outcome": "win",
            "score": 50,
            "extra_stats_update": {"questions_answered": 5, "correct_answers": 5}
        }
    )
    assert res_clash.status_code == 200

    # Retrieve all game stats
    get_res = client.get("/api/v1/stats/test-user-123")
    assert get_res.status_code == 200
    full_stats = get_res.json()
    assert full_stats["user_id"] == "test-user-123"
    cricket = full_stats["games"]["cricket"]
    assert cricket["total_played"] == 2
    assert cricket["total_won"] == 2
    assert "draft" in cricket["sections"]
    assert "stat_clash" in cricket["sections"]
    assert "super_over" in cricket["sections"]
    assert len(full_stats["recent_matches"]) == 2

def test_shut_the_box_and_other_games_stats():
    res = client.post(
        "/api/v1/stats/record",
        json={
            "user_id": "test-user-123",
            "game_id": "shut_the_box",
            "section_id": "classic",
            "outcome": "win",
            "score": 0, # Shut the box perfect score
            "extra_stats_update": {"boxes_shut_count": 1}
        }
    )
    assert res.status_code == 200
    assert res.json()["game_id"] == "shut_the_box"
    assert res.json()["matches_won"] == 1
