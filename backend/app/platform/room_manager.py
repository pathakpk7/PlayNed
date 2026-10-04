import uuid
import random
import string
import time
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field
from backend.app.platform.registry import game_registry

class PlayerInfo(BaseModel):
    player_id: str
    display_name: str
    is_host: bool = False
    is_ready: bool = False
    is_connected: bool = True
    team: Optional[str] = None
    joined_at: float = Field(default_factory=time.time)

class RoomData(BaseModel):
    id: str
    room_code: str
    game_id: str
    host_player_id: str
    status: str = "waiting" # waiting, in_progress, finished, cancelled
    room_type: str = "online" # online, local, team
    max_players: int = 2
    settings: Dict[str, Any] = Field(default_factory=dict)
    players: List[PlayerInfo] = Field(default_factory=list)
    match_state: Optional[Dict[str, Any]] = None
    created_at: float = Field(default_factory=time.time)
    updated_at: float = Field(default_factory=time.time)

class RoomManager:
    def __init__(self):
        self._rooms: Dict[str, RoomData] = {}

    def _generate_code(self) -> str:
        chars = string.ascii_uppercase + string.digits
        # Avoid visually confusing characters 0, O, 1, I
        chars = "".join([c for c in chars if c not in ("0", "O", "1", "I")])
        while True:
            code = "".join(random.choices(chars, k=6))
            if code not in self._rooms:
                return code

    def create_room(
        self,
        game_id: str,
        host_name: str,
        host_id: Optional[str] = None,
        room_type: str = "online",
        max_players: Optional[int] = None,
        settings: Optional[Dict[str, Any]] = None
    ) -> RoomData:
        meta = game_registry.get_game_metadata(game_id)
        if not meta:
            raise ValueError(f"Game '{game_id}' not recognized on PlayNed.")

        room_code = self._generate_code()
        actual_host_id = host_id or f"p_{uuid.uuid4().hex[:8]}"
        actual_host_name = host_name.strip() or "Host"
        limit_players = max_players if max_players is not None else meta.max_players

        host_player = PlayerInfo(
            player_id=actual_host_id,
            display_name=actual_host_name,
            is_host=True,
            is_ready=True,
            is_connected=True,
            team="Team A" if meta.supports_teams else None
        )

        room = RoomData(
            id=str(uuid.uuid4()),
            room_code=room_code,
            game_id=game_id,
            host_player_id=actual_host_id,
            status="waiting",
            room_type=room_type,
            max_players=limit_players,
            settings=settings or {},
            players=[host_player],
            match_state=None
        )

        self._rooms[room_code] = room
        return room

    def get_room(self, room_code: str) -> Optional[RoomData]:
        return self._rooms.get(room_code.upper().strip())

    def join_room(
        self,
        room_code: str,
        player_name: str,
        player_id: Optional[str] = None,
        team: Optional[str] = None
    ) -> RoomData:
        code = room_code.upper().strip()
        room = self._rooms.get(code)
        if not room:
            raise ValueError("Room not found.")

        actual_pid = player_id or f"p_{uuid.uuid4().hex[:8]}"
        actual_name = player_name.strip() or f"Player {len(room.players) + 1}"

        # Check if reconnecting existing player
        for p in room.players:
            if p.player_id == actual_pid or (player_id and p.player_id == player_id):
                p.is_connected = True
                p.display_name = actual_name
                room.updated_at = time.time()
                return room

        if room.status != "waiting":
            raise ValueError("Game in this room has already started or finished.")

        if len(room.players) >= room.max_players:
            raise ValueError(f"Room is already full (max {room.max_players} players).")

        new_player = PlayerInfo(
            player_id=actual_pid,
            display_name=actual_name,
            is_host=False,
            is_ready=False,
            is_connected=True,
            team=team or (f"Team {chr(65 + len(room.players))}" if room.settings.get("teams") else None)
        )

        room.players.append(new_player)
        room.updated_at = time.time()
        return room

    def leave_room(self, room_code: str, player_id: str) -> Optional[RoomData]:
        code = room_code.upper().strip()
        room = self._rooms.get(code)
        if not room:
            return None

        room.players = [p for p in room.players if p.player_id != player_id]

        if not room.players:
            # Delete empty room
            del self._rooms[code]
            return None

        # Reassign host if host left
        if room.host_player_id == player_id:
            room.players[0].is_host = True
            room.players[0].is_ready = True
            room.host_player_id = room.players[0].player_id

        room.updated_at = time.time()
        return room

    def set_player_ready(self, room_code: str, player_id: str, is_ready: bool) -> RoomData:
        code = room_code.upper().strip()
        room = self._rooms.get(code)
        if not room:
            raise ValueError("Room not found.")

        for p in room.players:
            if p.player_id == player_id:
                p.is_ready = is_ready
                room.updated_at = time.time()
                return room

        raise ValueError("Player not found in room.")

    def start_match(self, room_code: str, requester_player_id: str) -> RoomData:
        code = room_code.upper().strip()
        room = self._rooms.get(code)
        if not room:
            raise ValueError("Room not found.")

        if room.host_player_id != requester_player_id:
            raise ValueError("Only the room host can start the game.")

        meta = game_registry.get_game_metadata(room.game_id)
        engine = game_registry.get_game_engine(room.game_id)
        if not meta or not engine:
            raise ValueError(f"Game engine for '{room.game_id}' is unavailable.")

        if len(room.players) < meta.min_players:
            raise ValueError(f"Need at least {meta.min_players} players to start (currently {len(room.players)}).")

        player_ids = [p.player_id for p in room.players]
        player_names = {p.player_id: p.display_name for p in room.players}

        initial_state = engine.create_initial_state(
            player_ids=player_ids,
            player_names=player_names,
            options=room.settings
        )

        room.match_state = initial_state
        room.status = "in_progress"
        room.updated_at = time.time()
        return room

    def submit_move(self, room_code: str, player_id: str, move: Dict[str, Any]) -> RoomData:
        code = room_code.upper().strip()
        room = self._rooms.get(code)
        if not room:
            raise ValueError("Room not found.")

        if room.status != "in_progress" or not room.match_state:
            raise ValueError("No active match in progress.")

        engine = game_registry.get_game_engine(room.game_id)
        if not engine:
            raise ValueError(f"Game engine for '{room.game_id}' is unavailable.")

        updated_state = engine.apply_move(room.match_state, player_id, move)
        room.match_state = updated_state
        
        if updated_state.get("status") in ("won", "lost", "draw", "finished"):
            room.status = "finished"

        room.updated_at = time.time()
        return room

room_manager = RoomManager()
