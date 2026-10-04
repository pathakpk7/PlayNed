from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field

class GameMetadata(BaseModel):
    id: str
    name: str
    tagline: str
    description: str
    category: str  # Strategy, Word/Puzzle, Board, Casual
    min_players: int
    max_players: int
    supports_local: bool = True
    supports_online: bool = True
    supports_teams: bool = False
    supports_ai: bool = False
    estimated_duration_minutes: int = 5
    accent_color_hex: str = "#D5A84B"
    bg_color_hex: str = "#181816"
    icon_name: str = "gamepad"
    rules_summary: List[str] = Field(default_factory=list)

class BaseGameEngine(ABC):
    @abstractmethod
    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Creates the starting match state for this game."""
        pass

    @abstractmethod
    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> tuple[bool, Optional[str]]:
        """Checks if a move is legal. Returns (is_valid, error_message)."""
        pass

    @abstractmethod
    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        """Applies a legal move and returns the updated state."""
        pass

    @abstractmethod
    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        """Returns valid moves for player_id or a summary of available actions."""
        pass
