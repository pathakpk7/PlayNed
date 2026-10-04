import pytest
from backend.app.platform.registry import game_registry

def test_registry_games_exist():
    games = game_registry.list_games()
    game_ids = [g.id for g in games]
    assert "hangman" in game_ids
    assert "dots_and_boxes" in game_ids
    assert "quoridor" in game_ids
    assert "pentago" in game_ids

def test_game_metadata():
    meta = game_registry.get_game_metadata("quoridor")
    assert meta is not None
    assert meta.name == "Quoridor"
    assert meta.min_players == 2
    assert meta.max_players == 4

    meta_dab = game_registry.get_game_metadata("dots_and_boxes")
    assert meta_dab is not None
    assert meta_dab.name == "Dots & Boxes"
