import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Load environment variables from .env if present
load_dotenv()

# Portable PostgreSQL / SQLite database connection (Neon DB / Supabase / Local SQLite)
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./hangman_game.db")

# Normalize dialect prefix for Neon / PostgreSQL URLs (SQLAlchemy requires postgresql://)
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# SQLite vs Cloud PostgreSQL connection settings
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

# Engine configuration with pre-ping to handle serverless pool timeouts (e.g. Neon)
engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    Base.metadata.create_all(bind=engine)
    if DATABASE_URL.startswith("sqlite"):
        with engine.connect() as conn:
            from sqlalchemy import text
            users_cols = [row[1] for row in conn.execute(text("PRAGMA table_info(users)")).fetchall()]
            if users_cols and "word_lifelines" not in users_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN word_lifelines INTEGER DEFAULT 2"))
                conn.commit()

            gh_cols = [row[1] for row in conn.execute(text("PRAGMA table_info(game_history)")).fetchall()]
            if gh_cols:
                if "word_lifelines_used" not in gh_cols:
                    conn.execute(text("ALTER TABLE game_history ADD COLUMN word_lifelines_used INTEGER DEFAULT 0"))
                    conn.commit()
                if "lifeline_option_used" not in gh_cols:
                    conn.execute(text("ALTER TABLE game_history ADD COLUMN lifeline_option_used VARCHAR(50)"))
                    conn.commit()
