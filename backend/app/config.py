import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "PlayNed - 2D Multiplayer Game Platform"
    API_V1_STR: str = "/api/v1"
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://xyzcompany.supabase.co")
    SUPABASE_ANON_KEY: str = os.getenv("SUPABASE_ANON_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    DATABASE_PATH: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data", "words.db"))
    
    class Config:
        case_sensitive = True

settings = Settings()
