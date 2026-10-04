import json
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from backend.app.platform.websocket_manager import ws_manager
from backend.app.platform.room_manager import room_manager

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Platform Real-Time WebSocket"])

@router.websocket("/ws/{room_code}/{player_id}")
async def websocket_room_endpoint(websocket: WebSocket, room_code: str, player_id: str):
    code = room_code.upper().strip()
    await ws_manager.connect(websocket, code, player_id)

    # Broadcast reconnection / active presence
    room = room_manager.get_room(code)
    if room:
        # Mark player as connected
        for p in room.players:
            if p.player_id == player_id:
                p.is_connected = True
        await ws_manager.broadcast(code, {
            "type": "PLAYER_CONNECTED",
            "player_id": player_id,
            "room": room.model_dump()
        })

    try:
        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
                msg_type = msg.get("type")

                if msg_type == "MOVE":
                    move_payload = msg.get("move", {})
                    updated_room = room_manager.submit_move(code, player_id, move_payload)
                    await ws_manager.broadcast(code, {
                        "type": "STATE_UPDATED",
                        "player_id": player_id,
                        "move": move_payload,
                        "room": updated_room.model_dump()
                    })

                elif msg_type == "READY":
                    is_ready = bool(msg.get("is_ready", True))
                    updated_room = room_manager.set_player_ready(code, player_id, is_ready)
                    await ws_manager.broadcast(code, {
                        "type": "PLAYER_READY",
                        "player_id": player_id,
                        "is_ready": is_ready,
                        "room": updated_room.model_dump()
                    })

                elif msg_type == "START":
                    updated_room = room_manager.start_match(code, player_id)
                    await ws_manager.broadcast(code, {
                        "type": "GAME_STARTED",
                        "room": updated_room.model_dump()
                    })

                elif msg_type == "PING":
                    await websocket.send_json({"type": "PONG"})

            except ValueError as e:
                await websocket.send_json({
                    "type": "ERROR",
                    "message": str(e)
                })
            except Exception as e:
                logger.error(f"Error handling WS message: {e}")
                await websocket.send_json({
                    "type": "ERROR",
                    "message": "Internal server error processing action."
                })

    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, code)
        room = room_manager.get_room(code)
        if room:
            for p in room.players:
                if p.player_id == player_id:
                    p.is_connected = False
            await ws_manager.broadcast(code, {
                "type": "PLAYER_DISCONNECTED",
                "player_id": player_id,
                "room": room.model_dump()
            })
