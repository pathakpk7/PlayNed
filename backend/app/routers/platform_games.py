from typing import List
from fastapi import APIRouter, HTTPException, status
from backend.app.platform.game_definition import GameMetadata
from backend.app.platform.registry import game_registry

router = APIRouter(prefix="/games", tags=["Platform Games"])

@router.get("", response_model=List[GameMetadata])
def get_all_games():
    """Returns catalog of all games available on the PlayNed platform."""
    return game_registry.list_games()

@router.get("/{game_id}", response_model=GameMetadata)
def get_game_details(game_id: str):
    """Returns details and metadata for a specific game."""
    meta = game_registry.get_game_metadata(game_id)
    if not meta:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Game '{game_id}' not found.")
    return meta
