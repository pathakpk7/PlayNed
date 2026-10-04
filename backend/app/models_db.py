import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from backend.app.database import Base

class DBUser(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    word_lifelines = Column(Integer, default=2)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    heart_state = relationship("DBUserHeartState", back_populates="user", uselist=False, cascade="all, delete-orphan")
    classic_progress = relationship("DBClassicProgress", back_populates="user", uselist=False, cascade="all, delete-orphan")
    mode_stats = relationship("DBModeStats", back_populates="user", cascade="all, delete-orphan")
    codex_entries = relationship("DBUserCodex", back_populates="user", cascade="all, delete-orphan")
    game_stats = relationship("DBGameStats", back_populates="user", cascade="all, delete-orphan")
    game_match_logs = relationship("DBGameMatchLog", back_populates="user", cascade="all, delete-orphan")

class DBUserHeartState(Base):
    __tablename__ = "user_heart_states"

    user_id = Column(String, ForeignKey("users.id"), primary_key=True)
    hearts_remaining = Column(Integer, default=5)
    last_regen_timestamp = Column(Float, default=lambda: datetime.now(timezone.utc).timestamp())

    user = relationship("DBUser", back_populates="heart_state")

class DBClassicProgress(Base):
    __tablename__ = "classic_progress"

    user_id = Column(String, ForeignKey("users.id"), primary_key=True)
    current_level = Column(Integer, default=1)
    highest_level = Column(Integer, default=1)
    xp = Column(Integer, default=0)
    consecutive_losses = Column(Integer, default=0)

    user = relationship("DBUser", back_populates="classic_progress")

class DBModeStats(Base):
    __tablename__ = "mode_stats"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    mode = Column(String, nullable=False) # classic, timed, practice, daily, infinite, category
    category_name = Column(String, nullable=True) # populated if mode == 'category'
    games_played = Column(Integer, default=0)
    games_won = Column(Integer, default=0)
    games_lost = Column(Integer, default=0)
    xp_earned = Column(Integer, default=0)
    best_score = Column(Integer, default=0)
    best_time_seconds = Column(Integer, default=0)
    total_words_played = Column(Integer, default=0)
    current_streak = Column(Integer, default=0)

    user = relationship("DBUser", back_populates="mode_stats")

class DBGameHistory(Base):
    __tablename__ = "game_history"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    mode = Column(String, nullable=False)
    level = Column(Integer, default=1)
    category = Column(String, default="General")
    word = Column(String, nullable=False)
    won = Column(Boolean, nullable=False)
    score = Column(Integer, default=0)
    mistakes = Column(Integer, default=0)
    hearts_remaining = Column(Integer, default=5)
    hints_used = Column(Integer, default=0)
    word_lifelines_used = Column(Integer, default=0)
    lifeline_option_used = Column(String, nullable=True)
    duration_seconds = Column(Integer, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class DBUserCodex(Base):
    __tablename__ = "user_codex"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    word = Column(String, nullable=False, index=True)
    category = Column(String, default="General")
    definition = Column(String, default="")
    part_of_speech = Column(String, default="noun")
    example_sentence = Column(String, default="")
    synonyms = Column(String, default="")
    times_encountered = Column(Integer, default=1)
    times_won = Column(Integer, default=0)
    mastery_status = Column(String, default="learning") # learning, mastered
    last_encountered_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("DBUser", back_populates="codex_entries")

class DBGameStats(Base):
    __tablename__ = "user_game_stats"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    game_id = Column(String, nullable=False, index=True)      # e.g., 'cricket', 'shut_the_box', 'dots_and_boxes', etc.
    section_id = Column(String, nullable=False, index=True)   # e.g., 'super_over', 'draft', 'stat_clash', 'challenges', 'classic'
    matches_played = Column(Integer, default=0)
    matches_won = Column(Integer, default=0)
    matches_lost = Column(Integer, default=0)
    matches_tied = Column(Integer, default=0)
    high_score = Column(Integer, default=0)
    total_score = Column(Integer, default=0)
    current_streak = Column(Integer, default=0)
    best_streak = Column(Integer, default=0)
    extra_data = Column(String, default="{}")                # JSON string for game/section specific custom counters
    last_played_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("DBUser", back_populates="game_stats")

class DBGameMatchLog(Base):
    __tablename__ = "user_game_match_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    game_id = Column(String, nullable=False, index=True)
    section_id = Column(String, nullable=False, index=True)
    outcome = Column(String, nullable=False)                 # 'win', 'loss', 'tie', 'completed'
    score = Column(Integer, default=0)
    opponent_name = Column(String, nullable=True)
    details = Column(String, default="{}")                   # JSON string for round specifics
    played_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("DBUser", back_populates="game_match_logs")
