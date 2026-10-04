from typing import Dict, Any, List, Optional
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata
from backend.app.services.word_service import word_service

HANGMAN_METADATA = GameMetadata(
    id="hangman",
    name="Hangman Reimagined",
    tagline="A modern, strategic word discovery deduction game.",
    description="Decipher hidden vocabulary words letter-by-letter with word DNA analytics, progressive hints, dynamic combos, and multiple game modes.",
    category="Word / Puzzle",
    min_players=1,
    max_players=4,
    supports_local=True,
    supports_online=True,
    supports_teams=True,
    estimated_duration_minutes=3,
    accent_color_hex="#D5A84B",
    bg_color_hex="#1E1912",
    icon_name="font_download",
    rules_summary=[
        "Guess secret letters one-by-one to reveal the hidden word.",
        "Incorrect letter guesses cost one life/heart out of 5 total.",
        "Gain bonus points and multiplier bonuses for consecutive correct letter guesses.",
        "Unlock and inspect Word DNA metrics (length, vowel/consonant count, repeated letters).",
        "Progress through 100 escalating difficulty tiers or battle head-to-head in turn-based duels."
    ]
)

class HangmanGameEngine(BaseGameEngine):
    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        options = options or {}
        category = options.get("category", "General")
        difficulty = options.get("difficulty", 2)
        word_data = word_service.select_word(difficulty=difficulty, category=category)
        
        secret_word = word_data["word"].lower()
        
        return {
            "game_id": "hangman",
            "secret_word": secret_word,
            "category": word_data.get("category", category),
            "part_of_speech": word_data.get("part_of_speech", "noun"),
            "definition": word_data.get("definition", ""),
            "synonyms": word_data.get("synonyms", []),
            "word_dna": {
                "length": word_data.get("length", len(secret_word)),
                "vowels": word_data.get("vowel_count", 0),
                "consonants": word_data.get("consonant_count", 0),
                "has_repeated_letters": word_data.get("has_repeated_letters", False),
                "category": word_data.get("category", category),
                "part_of_speech": word_data.get("part_of_speech", "noun"),
            },
            "masked_word": ["_" for _ in secret_word],
            "guessed_letters": [],
            "lives_remaining": 5,
            "max_lives": 5,
            "scores": {pid: 0 for pid in player_ids},
            "player_ids": player_ids,
            "player_names": player_names,
            "current_turn_index": 0,
            "current_turn_player_id": player_ids[0] if player_ids else "",
            "status": "in_progress",  # in_progress, won, lost, draw
            "winner_id": None,
            "winner_name": None,
            "last_action": None,
            "mistakes": 0,
            "combo": 0
        }

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> tuple[bool, Optional[str]]:
        if state.get("status") != "in_progress":
            return False, "Game is already finished."
        
        if len(state.get("player_ids", [])) > 1:
            if state.get("current_turn_player_id") != player_id:
                return False, "It is not your turn."

        letter = move.get("letter", "").lower().strip()
        if not letter or len(letter) != 1 or not letter.isalpha():
            return False, "Please guess a single valid alphabetical letter."

        if letter in state.get("guessed_letters", []):
            return False, f"Letter '{letter.upper()}' has already been guessed."

        return True, None

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        valid, err = self.validate_move(state, player_id, move)
        if not valid:
            raise ValueError(err)

        new_state = dict(state)
        new_state["guessed_letters"] = list(state.get("guessed_letters", []))
        new_state["scores"] = dict(state.get("scores", {}))
        
        letter = move["letter"].lower()
        new_state["guessed_letters"].append(letter)
        
        secret = new_state["secret_word"]
        masked = list(new_state["masked_word"])
        
        if letter in secret:
            occurrences = 0
            for i, c in enumerate(secret):
                if c == letter:
                    masked[i] = c
                    occurrences += 1
            new_state["masked_word"] = masked
            new_state["combo"] = new_state.get("combo", 0) + 1
            pts = 20 * occurrences * (1 + (new_state["combo"] * 0.2))
            new_state["scores"][player_id] = new_state["scores"].get(player_id, 0) + int(pts)
            new_state["last_action"] = f"{new_state['player_names'].get(player_id, 'Player')} guessed '{letter.upper()}' (+{int(pts)} pts)"
            
            # Check win condition
            if "_" not in masked:
                new_state["status"] = "won"
                # Determine highest score
                best_pid = max(new_state["scores"], key=new_state["scores"].get)
                new_state["winner_id"] = best_pid
                new_state["winner_name"] = new_state["player_names"].get(best_pid, "Winner")
        else:
            new_state["combo"] = 0
            new_state["mistakes"] = new_state.get("mistakes", 0) + 1
            new_state["lives_remaining"] = new_state.get("lives_remaining", 5) - 1
            new_state["last_action"] = f"{new_state['player_names'].get(player_id, 'Player')} guessed incorrect letter '{letter.upper()}'"
            
            # Switch turn in multiplayer
            player_ids = new_state.get("player_ids", [])
            if len(player_ids) > 1:
                cur_idx = new_state.get("current_turn_index", 0)
                next_idx = (cur_idx + 1) % len(player_ids)
                new_state["current_turn_index"] = next_idx
                new_state["current_turn_player_id"] = player_ids[next_idx]

            if new_state["lives_remaining"] <= 0:
                new_state["status"] = "lost"
                # Reveal entire word
                new_state["masked_word"] = list(secret)

        return new_state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        guessed = set(state.get("guessed_letters", []))
        import string
        return [{"letter": c} for c in string.ascii_lowercase if c not in guessed]
