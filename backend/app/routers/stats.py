import json
import uuid
from datetime import datetime, timezone
from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models_db import DBUser, DBGameStats, DBGameMatchLog
from backend.app.models.game import (
    RecordGameSessionRequest,
    GameSectionStatItem,
    GameStatsGroup,
    GameMatchLogItem,
    UserAllGameStatsResponse,
)

router = APIRouter(prefix="/stats", tags=["Platform & Game Stats"])

KNOWN_SECTIONS = {
    "cricket": ["super_over", "draft", "stat_clash", "challenges"],
    "hangman": ["classic", "timed", "daily", "category", "infinite"],
    "shut_the_box": ["classic", "solo", "multiplayer"],
    "dots_and_boxes": ["grid_3x3", "grid_4x4", "grid_5x5", "multiplayer"],
    "quoridor": ["classic", "multiplayer"],
    "pentago": ["classic", "multiplayer"],
    "reversi": ["othello", "reversi_classic", "solo_ai", "multiplayer"],
}

@router.post("/record", response_model=GameSectionStatItem)
def record_game_session(payload: RecordGameSessionRequest, db: Session = Depends(get_db)):
    """Records a completed game match/session for a player, updating both aggregated section stats and match logs."""
    user = db.query(DBUser).filter(DBUser.id == payload.user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    game_id = payload.game_id.lower().strip()
    section_id = payload.section_id.lower().strip()

    # Find existing section stat or create new
    stat = db.query(DBGameStats).filter(
        DBGameStats.user_id == payload.user_id,
        DBGameStats.game_id == game_id,
        DBGameStats.section_id == section_id
    ).first()

    if not stat:
        stat = DBGameStats(
            user_id=payload.user_id,
            game_id=game_id,
            section_id=section_id,
            matches_played=0,
            matches_won=0,
            matches_lost=0,
            matches_tied=0,
            high_score=0,
            total_score=0,
            current_streak=0,
            best_streak=0,
            extra_data="{}"
        )
        db.add(stat)

    stat.matches_played += 1
    outcome_clean = payload.outcome.lower().strip()

    if outcome_clean == "win":
        stat.matches_won += 1
        stat.current_streak += 1
        if stat.current_streak > stat.best_streak:
            stat.best_streak = stat.current_streak
    elif outcome_clean == "loss":
        stat.matches_lost += 1
        stat.current_streak = 0
    elif outcome_clean == "tie" or outcome_clean == "draw":
        stat.matches_tied += 1
    else: # "completed"
        stat.matches_won += 1

    if payload.score > stat.high_score:
        stat.high_score = payload.score
    stat.total_score += payload.score

    # Parse and update extra domain stats JSON
    try:
        current_extra: Dict[str, Any] = json.loads(stat.extra_data) if stat.extra_data else {}
    except Exception:
        current_extra = {}

    if payload.extra_stats_update:
        for k, v in payload.extra_stats_update.items():
            if isinstance(v, (int, float)) and isinstance(current_extra.get(k), (int, float)):
                current_extra[k] = current_extra[k] + v
            else:
                current_extra[k] = v

    stat.extra_data = json.dumps(current_extra)
    stat.last_played_at = datetime.now(timezone.utc)

    # Add match log
    match_log = DBGameMatchLog(
        id=str(uuid.uuid4()),
        user_id=payload.user_id,
        game_id=game_id,
        section_id=section_id,
        outcome=payload.outcome,
        score=payload.score,
        opponent_name=payload.opponent_name,
        details=json.dumps(payload.details or {}),
        played_at=datetime.now(timezone.utc)
    )
    db.add(match_log)

    db.commit()
    db.refresh(stat)

    return GameSectionStatItem(
        game_id=stat.game_id,
        section_id=stat.section_id,
        matches_played=stat.matches_played,
        matches_won=stat.matches_won,
        matches_lost=stat.matches_lost,
        matches_tied=stat.matches_tied,
        high_score=stat.high_score,
        total_score=stat.total_score,
        current_streak=stat.current_streak,
        best_streak=stat.best_streak,
        extra_data=current_extra,
        last_played_at=stat.last_played_at.isoformat() if stat.last_played_at else None
    )

@router.get("/{user_id}", response_model=UserAllGameStatsResponse)
def get_user_all_game_stats(
    user_id: str,
    game_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Retrieves full per-game and per-section statistics and recent match logs for a user."""
    user = db.query(DBUser).filter(DBUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    stats_query = db.query(DBGameStats).filter(DBGameStats.user_id == user_id)
    if game_id:
        stats_query = stats_query.filter(DBGameStats.game_id == game_id.lower().strip())
    all_stats = stats_query.all()

    logs_query = db.query(DBGameMatchLog).filter(DBGameMatchLog.user_id == user_id)
    if game_id:
        logs_query = logs_query.filter(DBGameMatchLog.game_id == game_id.lower().strip())
    all_logs = logs_query.order_by(DBGameMatchLog.played_at.desc()).limit(30).all()

    # Grouping
    games_map: Dict[str, GameStatsGroup] = {}
    total_played = 0
    total_won = 0

    # Ensure known games exist
    games_to_init = [game_id.lower().strip()] if game_id else list(KNOWN_SECTIONS.keys())
    for gid in games_to_init:
        sections_dict = {}
        for sec in KNOWN_SECTIONS.get(gid, ["classic"]):
            sections_dict[sec] = GameSectionStatItem(game_id=gid, section_id=sec)
        games_map[gid] = GameStatsGroup(
            game_id=gid,
            total_played=0,
            total_won=0,
            total_lost=0,
            total_tied=0,
            high_score=0,
            sections=sections_dict
        )

    for st in all_stats:
        gid = st.game_id
        sec = st.section_id
        if gid not in games_map:
            games_map[gid] = GameStatsGroup(game_id=gid, sections={})

        try:
            extra_parsed = json.loads(st.extra_data) if st.extra_data else {}
        except Exception:
            extra_parsed = {}

        sec_item = GameSectionStatItem(
            game_id=gid,
            section_id=sec,
            matches_played=st.matches_played,
            matches_won=st.matches_won,
            matches_lost=st.matches_lost,
            matches_tied=st.matches_tied,
            high_score=st.high_score,
            total_score=st.total_score,
            current_streak=st.current_streak,
            best_streak=st.best_streak,
            extra_data=extra_parsed,
            last_played_at=st.last_played_at.isoformat() if st.last_played_at else None
        )
        games_map[gid].sections[sec] = sec_item
        games_map[gid].total_played += st.matches_played
        games_map[gid].total_won += st.matches_won
        games_map[gid].total_lost += st.matches_lost
        games_map[gid].total_tied += st.matches_tied
        games_map[gid].high_score = max(games_map[gid].high_score, st.high_score)

        total_played += st.matches_played
        total_won += st.matches_won

    match_log_items = []
    for l in all_logs:
        try:
            d_parsed = json.loads(l.details) if l.details else {}
        except Exception:
            d_parsed = {}
        match_log_items.append(
            GameMatchLogItem(
                id=l.id,
                game_id=l.game_id,
                section_id=l.section_id,
                outcome=l.outcome,
                score=l.score,
                opponent_name=l.opponent_name,
                details=d_parsed,
                played_at=l.played_at.isoformat() if l.played_at else ""
            )
        )

    return UserAllGameStatsResponse(
        user_id=user.id,
        username=user.username,
        total_games_played=total_played,
        total_games_won=total_won,
        games=games_map,
        recent_matches=match_log_items
    )
