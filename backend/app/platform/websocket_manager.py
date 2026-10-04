import json
import logging
from typing import Dict, List, Any
from fastapi import WebSocket

logger = logging.getLogger(__name__)

class WebSocketManager:
    def __init__(self):
        # room_code -> list of (WebSocket, player_id)
        self._active_connections: Dict[str, List[tuple[WebSocket, str]]] = {}

    async def connect(self, websocket: WebSocket, room_code: str, player_id: str):
        await websocket.accept()
        code = room_code.upper().strip()
        if code not in self._active_connections:
            self._active_connections[code] = []
        self._active_connections[code].append((websocket, player_id))
        logger.info(f"WebSocket connected: player {player_id} in room {code}")

    def disconnect(self, websocket: WebSocket, room_code: str):
        code = room_code.upper().strip()
        if code in self._active_connections:
            self._active_connections[code] = [
                (ws, pid) for ws, pid in self._active_connections[code] if ws != websocket
            ]
            if not self._active_connections[code]:
                del self._active_connections[code]
        logger.info(f"WebSocket disconnected from room {code}")

    async def broadcast(self, room_code: str, message: Dict[str, Any]):
        code = room_code.upper().strip()
        if code not in self._active_connections:
            return

        dead_connections = []
        for ws, pid in self._active_connections[code]:
            try:
                await ws.send_json(message)
            except Exception as e:
                logger.warning(f"Error broadcasting to player {pid} in room {code}: {e}")
                dead_connections.append((ws, pid))

        for dead in dead_connections:
            if code in self._active_connections and dead in self._active_connections[code]:
                self._active_connections[code].remove(dead)

ws_manager = WebSocketManager()
