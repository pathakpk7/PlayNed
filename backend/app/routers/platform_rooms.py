from typing import Dict, Any, Optional
from pydantic import BaseModel, Field
from fastapi import APIRouter, HTTPException, status
from backend.app.platform.room_manager import room_manager, RoomData
from backend.app.platform.websocket_manager import ws_manager

router = APIRouter(prefix="/rooms", tags=["Platform Rooms"])

class CreatePlatformRoomRequest(BaseModel):
    game_id: str
    player_name: str
    player_id: Optional[str] = None
    room_type: Optional[str] = "online"
    max_players: Optional[int] = None
    settings: Optional[Dict[str, Any]] = None

class JoinPlatformRoomRequest(BaseModel):
    player_name: str
    player_id: Optional[str] = None
    team: Optional[str] = None

class PlayerReadyRequest(BaseModel):
    player_id: str
    is_ready: bool = True

class StartMatchRequest(BaseModel):
    player_id: str

class SubmitMoveRequest(BaseModel):
    player_id: str
    move: Dict[str, Any]

@router.post("", response_model=RoomData)
def create_room(req: CreatePlatformRoomRequest):
    try:
        room = room_manager.create_room(
            game_id=req.game_id,
            host_name=req.player_name,
            host_id=req.player_id,
            room_type=req.room_type or "online",
            max_players=req.max_players,
            settings=req.settings
        )
        return room
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get("/{room_code}", response_model=RoomData)
def get_room(room_code: str):
    room = room_manager.get_room(room_code)
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found.")
    return room

@router.post("/{room_code}/join", response_model=RoomData)
async def join_room(room_code: str, req: JoinPlatformRoomRequest):
    try:
        room = room_manager.join_room(
            room_code=room_code,
            player_name=req.player_name,
            player_id=req.player_id,
            team=req.team
        )
        await ws_manager.broadcast(room_code, {
            "type": "PLAYER_JOINED",
            "room": room.model_dump()
        })
        return room
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/{room_code}/leave")
async def leave_room(room_code: str, player_id: str):
    room = room_manager.leave_room(room_code, player_id)
    if room:
        await ws_manager.broadcast(room_code, {
            "type": "PLAYER_LEFT",
            "player_id": player_id,
            "room": room.model_dump()
        })
        return room
    return {"message": "Left room"}

@router.post("/{room_code}/ready", response_model=RoomData)
async def set_ready(room_code: str, req: PlayerReadyRequest):
    try:
        room = room_manager.set_player_ready(room_code, req.player_id, req.is_ready)
        await ws_manager.broadcast(room_code, {
            "type": "PLAYER_READY",
            "player_id": req.player_id,
            "is_ready": req.is_ready,
            "room": room.model_dump()
        })
        return room
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/{room_code}/start", response_model=RoomData)
async def start_match(room_code: str, req: StartMatchRequest):
    try:
        room = room_manager.start_match(room_code, req.player_id)
        await ws_manager.broadcast(room_code, {
            "type": "GAME_STARTED",
            "room": room.model_dump()
        })
        return room
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/{room_code}/move", response_model=RoomData)
async def submit_move(room_code: str, req: SubmitMoveRequest):
    try:
        room = room_manager.submit_move(room_code, req.player_id, req.move)
        await ws_manager.broadcast(room_code, {
            "type": "STATE_UPDATED",
            "player_id": req.player_id,
            "move": req.move,
            "room": room.model_dump()
        })
        return room
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
