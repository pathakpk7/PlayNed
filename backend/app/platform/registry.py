from typing import Dict, List, Optional
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata
from backend.app.games.hangman.engine import HangmanGameEngine, HANGMAN_METADATA
from backend.app.games.dots_and_boxes.engine import DotsAndBoxesEngine, DOTS_AND_BOXES_METADATA
from backend.app.games.quoridor.engine import QuoridorEngine, QUORIDOR_METADATA
from backend.app.games.pentago.engine import PentagoEngine, PENTAGO_METADATA
from backend.app.games.shut_the_box.engine import ShutTheBoxEngine, SHUT_THE_BOX_METADATA
from backend.app.games.cricket.engine import CricketHubEngine, CRICKET_METADATA
from backend.app.games.reversi.engine import ReversiEngine, REVERSI_METADATA

class GameRegistry:
    def __init__(self):
        self._games: Dict[str, tuple[GameMetadata, BaseGameEngine]] = {}
        self._register_default_games()

    def _register_default_games(self):
        self.register_game(HANGMAN_METADATA, HangmanGameEngine())
        self.register_game(DOTS_AND_BOXES_METADATA, DotsAndBoxesEngine())
        self.register_game(QUORIDOR_METADATA, QuoridorEngine())
        self.register_game(PENTAGO_METADATA, PentagoEngine())
        self.register_game(SHUT_THE_BOX_METADATA, ShutTheBoxEngine())
        self.register_game(CRICKET_METADATA, CricketHubEngine())
        self.register_game(REVERSI_METADATA, ReversiEngine())

    def register_game(self, metadata: GameMetadata, engine: BaseGameEngine):
        self._games[metadata.id] = (metadata, engine)

    def list_games(self) -> List[GameMetadata]:
        return [meta for meta, _ in self._games.values()]

    def get_game_metadata(self, game_id: str) -> Optional[GameMetadata]:
        entry = self._games.get(game_id)
        return entry[0] if entry else None

    def get_game_engine(self, game_id: str) -> Optional[BaseGameEngine]:
        entry = self._games.get(game_id)
        return entry[1] if entry else None

game_registry = GameRegistry()
