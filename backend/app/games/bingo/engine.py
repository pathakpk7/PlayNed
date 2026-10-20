import random
import time
from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

BINGO_METADATA = GameMetadata(
    id="bingo",
    name="Bingo",
    tagline="Mark your numbers. Complete the pattern. Call Bingo.",
    description="Classic 5x5 Bingo with real-time number calling, customizable patterns, pass-and-play, solo AI, and online multiplayer duels.",
    category="Casual / Luck / Puzzle",
    min_players=1,
    max_players=2,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    supports_ai=True,
    estimated_duration_minutes=5,
    accent_color_hex="#F59E0B",
    bg_color_hex="#16140E",
    icon_name="grid_on",
    rules_summary=[
        "Standard 5x5 Bingo card with columns B (1-15), I (16-30), N (31-45), G (46-60), O (61-75).",
        "Center square is FREE and starts permanently marked.",
        "Numbers 1-75 are drawn randomly one at a time without replacement.",
        "Cards are automatically marked as called numbers match.",
        "Complete the active pattern (Classic row/column/diagonal, Four Corners, X, or Blackout) to win!"
    ]
)

COLUMN_RANGES = {
    0: (1, 15),   # B
    1: (16, 30),  # I
    2: (31, 45),  # N
    3: (46, 60),  # G
    4: (61, 75),  # O
}

COLUMN_LETTERS = ["B", "I", "N", "G", "O"]

class BingoEngine(BaseGameEngine):
    @staticmethod
    def get_column_letter(number: int) -> str:
        if 1 <= number <= 15:
            return "B"
        elif 16 <= number <= 30:
            return "I"
        elif 31 <= number <= 45:
            return "N"
        elif 46 <= number <= 60:
            return "G"
        elif 61 <= number <= 75:
            return "O"
        return ""

    @staticmethod
    def generate_card() -> Dict[str, Any]:
        """
        Generates a 5x5 Bingo card with 24 numbers and center FREE space (value 0).
        Returns a dict with 'cells' (25 ints) and 'marked' (25 bools, center True).
        """
        cells = [0] * 25
        marked = [False] * 25

        # Populate column by column
        for col_idx in range(5):
            low, high = COLUMN_RANGES[col_idx]
            col_nums = random.sample(range(low, high + 1), 5)
            for row_idx in range(5):
                cell_idx = row_idx * 5 + col_idx
                if cell_idx == 12:  # Center is FREE
                    cells[cell_idx] = 0
                    marked[cell_idx] = True
                else:
                    cells[cell_idx] = col_nums[row_idx]

        return {
            "cells": cells,
            "marked": marked,
        }

    @staticmethod
    def check_winner(card: Dict[str, Any], pattern: str = "CLASSIC") -> Dict[str, Any]:
        """
        Validates whether the card satisfies the specified pattern.
        Returns:
            {
                "winner": bool,
                "pattern": str,
                "winning_cells": List[int]
            }
        """
        marked = card.get("marked", [False] * 25)
        pattern_upper = (pattern or "CLASSIC").upper()

        if pattern_upper == "FOUR_CORNERS":
            corners = [0, 4, 20, 24]
            if all(marked[c] for c in corners):
                return {
                    "winner": True,
                    "pattern": "FOUR_CORNERS",
                    "winning_cells": sorted(corners)
                }

        elif pattern_upper == "X":
            x_cells = [0, 6, 12, 18, 24, 4, 8, 16, 20]
            if all(marked[c] for c in x_cells):
                return {
                    "winner": True,
                    "pattern": "X",
                    "winning_cells": sorted(list(set(x_cells)))
                }

        elif pattern_upper == "BLACKOUT":
            if all(marked):
                return {
                    "winner": True,
                    "pattern": "BLACKOUT",
                    "winning_cells": list(range(25))
                }

        else:
            # CLASSIC: Any row, any column, or any diagonal
            # 1. Rows
            for r in range(5):
                row_cells = [r * 5 + c for c in range(5)]
                if all(marked[c] for c in row_cells):
                    return {
                        "winner": True,
                        "pattern": f"ROW_{r + 1}",
                        "winning_cells": row_cells
                    }

            # 2. Columns
            for c in range(5):
                col_cells = [r * 5 + c for r in range(5)]
                if all(marked[c] for c in col_cells):
                    return {
                        "winner": True,
                        "pattern": f"COLUMN_{COLUMN_LETTERS[c]}",
                        "winning_cells": col_cells
                    }

            # 3. Main Diagonal (top-left to bottom-right)
            main_diag = [0, 6, 12, 18, 24]
            if all(marked[c] for c in main_diag):
                return {
                    "winner": True,
                    "pattern": "DIAGONAL_MAIN",
                    "winning_cells": main_diag
                }

            # 4. Anti-Diagonal (top-right to bottom-left)
            anti_diag = [4, 8, 12, 16, 20]
            if all(marked[c] for c in anti_diag):
                return {
                    "winner": True,
                    "pattern": "DIAGONAL_ANTI",
                    "winning_cells": anti_diag
                }

        return {
            "winner": False,
            "pattern": None,
            "winning_cells": []
        }

    def create_initial_state(
        self,
        player_ids: List[str],
        player_names: Dict[str, str],
        options: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        options = options or {}
        pattern = options.get("pattern", "CLASSIC").upper()
        if pattern not in ("CLASSIC", "FOUR_CORNERS", "X", "BLACKOUT"):
            pattern = "CLASSIC"

        player_ids = player_ids if player_ids else ["p1"]
        cards = {pid: self.generate_card() for pid in player_ids}

        draw_pool = list(range(1, 76))
        random.shuffle(draw_pool)

        return {
            "game_id": "bingo",
            "pattern": pattern,
            "player_ids": player_ids,
            "player_names": player_names,
            "cards": cards,
            "draw_pool": draw_pool,
            "drawn_numbers": [],
            "current_number": None,
            "current_letter": None,
            "draw_index": 0,
            "total_numbers_to_draw": 75,
            "status": "in_progress",  # in_progress, finished, draw
            "winner_id": None,
            "winner_name": None,
            "winning_pattern": None,
            "winning_cells": [],
            "last_action": f"Bingo match started ({pattern} pattern). Ready for the first draw.",
            "started_at": time.time(),
            "ended_at": None
        }

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        if state.get("status") != "in_progress":
            return False, "Match is already concluded."

        if player_id not in state.get("player_ids", []):
            return False, "You are not a player in this match."

        action = move.get("action")
        if action == "draw_number":
            draw_pool = state.get("draw_pool", [])
            if not draw_pool:
                return False, "All 75 numbers have already been drawn."
            return True, None

        elif action == "call_bingo":
            cards = state.get("cards", {})
            user_card = cards.get(player_id)
            if not user_card:
                return False, "Player card not found."
            pattern = state.get("pattern", "CLASSIC")
            win_check = self.check_winner(user_card, pattern)
            if not win_check.get("winner"):
                return False, "Invalid Bingo claim. Active pattern is not completed on your card."
            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        action = move.get("action")
        pattern = state.get("pattern", "CLASSIC")
        cards = state.get("cards", {})

        if action == "draw_number":
            draw_pool = state.get("draw_pool", [])
            drawn_numbers = state.get("drawn_numbers", [])
            if not draw_pool:
                # No more numbers, match ends in draw if no winner
                state["status"] = "finished"
                state["ended_at"] = time.time()
                state["last_action"] = "All 75 numbers drawn with no winner."
                return state

            # Draw next number authoritatively
            next_num = draw_pool.pop(0)
            drawn_numbers.append(next_num)
            next_letter = self.get_column_letter(next_num)

            state["current_number"] = next_num
            state["current_letter"] = next_letter
            state["draw_index"] = len(drawn_numbers)

            # Auto-mark number across all players' cards
            for pid, card in cards.items():
                cells = card.get("cells", [])
                marked = card.get("marked", [])
                for idx, cell_num in enumerate(cells):
                    if cell_num == next_num:
                        marked[idx] = True

            state["last_action"] = f"Drawn: {next_letter}-{next_num} (#{len(drawn_numbers)})"

            # Check for winners automatically
            winners = []
            for pid, card in cards.items():
                win_res = self.check_winner(card, pattern)
                if win_res.get("winner"):
                    winners.append((pid, win_res))

            if winners:
                state["status"] = "finished"
                state["ended_at"] = time.time()
                # If both win simultaneously in the same draw:
                if len(winners) > 1:
                    pnames = [state.get("player_names", {}).get(w[0], w[0]) for w in winners]
                    state["winner_id"] = "tie"
                    state["winner_name"] = " & ".join(pnames)
                    state["winning_pattern"] = winners[0][1].get("pattern")
                    state["winning_cells"] = winners[0][1].get("winning_cells")
                    state["last_action"] = f"Simultaneous BINGO! {state['winner_name']} win on {next_letter}-{next_num}!"
                else:
                    winner_pid, win_data = winners[0]
                    wname = state.get("player_names", {}).get(winner_pid, winner_pid)
                    state["winner_id"] = winner_pid
                    state["winner_name"] = wname
                    state["winning_pattern"] = win_data.get("pattern")
                    state["winning_cells"] = win_data.get("winning_cells")
                    state["last_action"] = f"BINGO! {wname} completed {win_data.get('pattern')} on {next_letter}-{next_num}!"

        elif action == "call_bingo":
            user_card = cards.get(player_id)
            win_check = self.check_winner(user_card, pattern)
            if win_check.get("winner"):
                state["status"] = "finished"
                state["ended_at"] = time.time()
                wname = state.get("player_names", {}).get(player_id, player_id)
                state["winner_id"] = player_id
                state["winner_name"] = wname
                state["winning_pattern"] = win_check.get("pattern")
                state["winning_cells"] = win_check.get("winning_cells")
                state["last_action"] = f"BINGO called by {wname}! Winning pattern: {win_check.get('pattern')}."

        return state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        if state.get("status") != "in_progress":
            return []
        moves = []
        if state.get("draw_pool"):
            moves.append({"action": "draw_number"})
        return moves
