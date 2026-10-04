from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.config import settings
from backend.app.database import engine, Base, init_db
from backend.app.routers import auth, game, profile, codex, multiplayer, platform_games, platform_rooms, platform_ws

# Initialize Database Tables & Migrations
init_db()

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.4.3",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Legacy & Hangman-specific API routes (Preserved with 100% backward compatibility)
app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(game.router, prefix=settings.API_V1_STR)
app.include_router(profile.router, prefix=settings.API_V1_STR)
app.include_router(codex.router, prefix=settings.API_V1_STR)
app.include_router(multiplayer.router, prefix=settings.API_V1_STR)

# PlayNed Platform API routes
app.include_router(platform_games.router, prefix=settings.API_V1_STR)
app.include_router(platform_rooms.router, prefix=settings.API_V1_STR)
app.include_router(platform_ws.router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {
        "status": "online",
        "app": "PlayNed 2D Multiplayer Game Platform",
        "version": "1.4.3",
        "docs": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.app.main:app", host="0.0.0.0", port=8000, reload=True)
