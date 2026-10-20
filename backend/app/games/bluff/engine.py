import random
import time
from typing import Dict, Any, List, Optional, Tuple
from backend.app.platform.game_definition import BaseGameEngine, GameMetadata

RANKS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
SUITS = ["S", "H", "D", "C"]  # Spades, Hearts, Diamonds, Clubs

RANK_VALUES = {r: i for i, r in enumerate(RANKS)}

BLUFF_METADATA = GameMetadata(
    id="bluff",
    name="Bluff / Cheat",
    tagline="Play cards face-down, declare ranks, and call bluffs!",
    description=(
        "Classic 3–6 player deception card game. Discard cards face-down and claim "
        "they match the required sequential rank. Tell the truth or bluff your way to an empty "
        "hand—just don't get caught!"
    ),
    category="Classic Card Games / Party Games",
    min_players=3,
    max_players=6,
    supports_local=True,
    supports_online=True,
    supports_teams=False,
    supports_ai=False,
    estimated_duration_minutes=8,
    accent_color_hex="#8B5CF6",
    bg_color_hex="#151022",
    icon_name="style",
    rules_summary=[
        "Standard 52-card deck dealt fairly among 3 to 6 players.",
        "Starting rank is Ace (A). Ranks advance sequentially: A -> 2 -> 3 -> ... -> K -> A.",
        "On your turn, play 1 or more cards face-down in the central pile and declare the required rank.",
        "You may play truthful cards or bluff with any other cards in your hand.",
        "Any opponent can call 'Bluff!' before the next turn begins.",
        "If caught bluffing, the bluffer takes the entire central pile. If truthful, the challenger takes the pile.",
        "Win by emptying your hand and surviving any challenge to your final play!",
    ],
)


def create_standard_deck() -> List[str]:
    return [f"{r}_{s}" for r in RANKS for s in SUITS]


def sort_cards(cards: List[str]) -> List[str]:
    def sort_key(card: str) -> Tuple[int, str]:
        parts = card.split("_")
        rank = parts[0]
        suit = parts[1] if len(parts) > 1 else ""
        return (RANK_VALUES.get(rank, 0), suit)

    return sorted(cards, key=sort_key)


def get_next_rank(current_rank: str) -> str:
    if current_rank not in RANK_VALUES:
        return "A"
    idx = RANK_VALUES[current_rank]
    return RANKS[(idx + 1) % len(RANKS)]


class BluffEngine(BaseGameEngine):
    @staticmethod
    def deal_deck(player_ids: List[str], seed: Optional[int] = None) -> Dict[str, List[str]]:
        """Shuffles 52 cards fairly and distributes them as evenly as possible."""
        deck = create_standard_deck()
        rng = random.Random(seed)
        rng.shuffle(deck)

        hands: Dict[str, List[str]] = {pid: [] for pid in player_ids}
        for i, card in enumerate(deck):
            pid = player_ids[i % len(player_ids)]
            hands[pid].append(card)

        for pid in player_ids:
            hands[pid] = sort_cards(hands[pid])

        return hands

    def create_initial_state(
        self,
        player_ids: List[str],
        player_names: Dict[str, str],
        options: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        n = len(player_ids)
        if n < 3 or n > 6:
            raise ValueError(f"Bluff requires between 3 and 6 players (got {n}).")

        hands = self.deal_deck(player_ids)
        card_counts = {pid: len(hands[pid]) for pid in player_ids}

        start_rank = "A"
        current_pid = player_ids[0]
        starter_name = player_names.get(current_pid, "Player 1")

        state: Dict[str, Any] = {
            "game_id": "bluff",
            "player_ids": list(player_ids),
            "player_names": dict(player_names),
            "hands": hands,  # Server-private full hands
            "card_counts": card_counts,
            "pile": [],  # Server-private central pile
            "pile_count": 0,
            "current_player_index": 0,
            "current_player_id": current_pid,
            "required_rank": start_rank,
            "phase": "PLAY",  # PLAY, CHALLENGE, CHALLENGE_REVEAL, GAME_OVER
            "last_play": None,
            "passes": [],
            "challenge_result": None,
            "last_challenge_result": None,
            "winner_id": None,
            "winner_name": None,
            "round_history": [f"Game started! {starter_name} must play {start_rank}s."],
            "last_action": f"Match began! {starter_name}'s turn to play {start_rank}s.",
            "created_at": time.time(),
            "updated_at": time.time(),
        }
        return state

    def validate_move(
        self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]
    ) -> Tuple[bool, Optional[str]]:
        action = move.get("action")
        phase = state.get("phase")
        player_ids = state.get("player_ids", [])

        if player_id not in player_ids:
            return False, "Player is not in this match."

        if action == "play_cards":
            if phase != "PLAY":
                return False, f"Cannot play cards in phase '{phase}'."
            if player_id != state.get("current_player_id"):
                return False, "It is not your turn to play."
            cards = move.get("cards", [])
            if not isinstance(cards, list) or len(cards) == 0:
                return False, "Must select at least 1 card to play."
            player_hand = state.get("hands", {}).get(player_id, [])
            hand_copy = list(player_hand)
            for card in cards:
                if card not in hand_copy:
                    return False, f"Card '{card}' is not in player's hand."
                hand_copy.remove(card)
            return True, None

        elif action == "challenge":
            if phase != "CHALLENGE":
                return False, f"Cannot challenge in phase '{phase}'."
            last_play = state.get("last_play")
            if not last_play:
                return False, "No active play to challenge."
            if player_id == last_play.get("player_id"):
                return False, "You cannot challenge your own play."
            return True, None

        elif action == "pass":
            if phase != "CHALLENGE":
                return False, f"Cannot pass in phase '{phase}'."
            last_play = state.get("last_play")
            if not last_play:
                return False, "No active play to pass."
            if player_id == last_play.get("player_id"):
                return False, "You cannot pass on your own play."
            return True, None

        elif action == "continue_after_challenge":
            if phase != "CHALLENGE_REVEAL":
                return False, f"Cannot continue in phase '{phase}'."
            return True, None

        elif action == "rematch":
            if phase != "GAME_OVER":
                return False, "Cannot rematch until the game is over."
            return True, None

        return False, f"Unknown action '{action}'."

    def apply_move(
        self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]
    ) -> Dict[str, Any]:
        is_valid, err = self.validate_move(state, player_id, move)
        if not is_valid:
            raise ValueError(err)

        new_state = {
            k: [dict(item) if isinstance(item, dict) else item for item in v]
            if isinstance(v, list)
            else (dict(v) if isinstance(v, dict) else v)
            for k, v in state.items()
        }

        action = move["action"]
        player_ids: List[str] = new_state["player_ids"]
        player_names: Dict[str, str] = new_state["player_names"]
        hands: Dict[str, List[str]] = new_state["hands"]
        pile: List[str] = new_state["pile"]
        required_rank: str = new_state["required_rank"]

        if action == "play_cards":
            played_cards: List[str] = move["cards"]
            current_hand = list(hands[player_id])
            for card in played_cards:
                current_hand.remove(card)
            hands[player_id] = sort_cards(current_hand)

            pile.extend(played_cards)
            new_state["pile"] = pile
            new_state["pile_count"] = len(pile)

            card_counts = dict(new_state["card_counts"])
            card_counts[player_id] = len(current_hand)
            new_state["card_counts"] = card_counts

            p_name = player_names.get(player_id, "Player")
            count = len(played_cards)
            s_suffix = "s" if count > 1 else ""

            new_state["last_play"] = {
                "player_id": player_id,
                "player_name": p_name,
                "declared_rank": required_rank,
                "card_count": count,
                "actual_cards": list(played_cards),
            }
            new_state["passes"] = []
            new_state["phase"] = "CHALLENGE"

            if len(current_hand) == 0:
                action_text = f"{p_name} played {count} card{s_suffix} claiming {required_rank}{s_suffix} (HAND EMPTY! Awaiting challenge)."
            else:
                action_text = f"{p_name} played {count} card{s_suffix} claiming {required_rank}{s_suffix}."

            new_state["last_action"] = action_text
            new_state["round_history"].append(action_text)

        elif action == "challenge":
            last_play = new_state["last_play"]
            bluffer_id = last_play["player_id"]
            bluffer_name = player_names.get(bluffer_id, "Player")
            challenger_id = player_id
            challenger_name = player_names.get(challenger_id, "Challenger")
            declared_rank = last_play["declared_rank"]
            actual_cards: List[str] = list(last_play["actual_cards"])

            # Check if any card rank differs from declared rank
            was_bluff = any(c.split("_")[0] != declared_rank for c in actual_cards)
            pile_cards_count = len(pile)

            if was_bluff:
                # Bluff caught! Bluffer takes entire pile
                pile_collector_id = bluffer_id
                pile_collector_name = bluffer_name
                # Challenger wins the challenge and takes next lead
                next_leader_id = challenger_id
                msg = (
                    f"BLUFF CAUGHT! {challenger_name} challenged {bluffer_name}. "
                    f"Cards were {', '.join(actual_cards)}. "
                    f"{bluffer_name} picks up all {pile_cards_count} cards!"
                )
            else:
                # Truthful! Challenger was mistaken and takes entire pile
                pile_collector_id = challenger_id
                pile_collector_name = challenger_name
                # Bluffer was truthful, wins challenge and leads next
                next_leader_id = bluffer_id
                msg = (
                    f"TRUTHFUL! {challenger_name} challenged {bluffer_name}, but cards were {', '.join(actual_cards)}. "
                    f"{challenger_name} picks up all {pile_cards_count} cards!"
                )

            # Assign pile to collector
            hands[pile_collector_id].extend(pile)
            hands[pile_collector_id] = sort_cards(hands[pile_collector_id])
            pile = []
            new_state["pile"] = pile
            new_state["pile_count"] = 0

            # Update card counts
            card_counts = dict(new_state["card_counts"])
            for pid in player_ids:
                card_counts[pid] = len(hands[pid])
            new_state["card_counts"] = card_counts

            res = {
                "challenger_id": challenger_id,
                "challenger_name": challenger_name,
                "bluffer_id": bluffer_id,
                "bluffer_name": bluffer_name,
                "declared_rank": declared_rank,
                "revealed_cards": actual_cards,
                "was_bluff": was_bluff,
                "pile_collector_id": pile_collector_id,
                "pile_collector_name": pile_collector_name,
                "cards_collected_count": pile_cards_count,
                "next_leader_id": next_leader_id,
                "outcome_msg": msg,
            }
            new_state["challenge_result"] = res
            new_state["last_challenge_result"] = res
            new_state["phase"] = "CHALLENGE_REVEAL"
            new_state["last_action"] = msg
            new_state["round_history"].append(msg)

        elif action == "pass":
            passes = list(new_state.get("passes", []))
            if player_id not in passes:
                passes.append(player_id)
            new_state["passes"] = passes

            last_play = new_state["last_play"]
            last_player_id = last_play["player_id"]
            other_players = [pid for pid in player_ids if pid != last_player_id]

            # In local pass-and-play or online, advance if all opponents have passed or force_advance is set
            should_advance = move.get("force_advance", False) or (len(passes) >= len(other_players))

            if should_advance:
                # Check if the player who played has 0 cards left
                if len(hands[last_player_id]) == 0:
                    # Player discarded all cards and survived without challenge!
                    w_name = player_names.get(last_player_id, "Player")
                    new_state["phase"] = "GAME_OVER"
                    new_state["winner_id"] = last_player_id
                    new_state["winner_name"] = w_name
                    win_msg = f"{w_name} successfully emptied their hand unchallenged and WINS THE MATCH!"
                    new_state["last_action"] = win_msg
                    new_state["round_history"].append(win_msg)
                else:
                    # Advance to next player clockwise
                    last_idx = player_ids.index(last_player_id)
                    next_idx = (last_idx + 1) % len(player_ids)
                    next_pid = player_ids[next_idx]
                    next_name = player_names.get(next_pid, "Player")

                    next_rank = get_next_rank(last_play["declared_rank"])
                    new_state["current_player_index"] = next_idx
                    new_state["current_player_id"] = next_pid
                    new_state["required_rank"] = next_rank
                    new_state["phase"] = "PLAY"
                    new_state["passes"] = []

                    turn_msg = f"No challenge. {next_name}'s turn to play {next_rank}s."
                    new_state["last_action"] = turn_msg
                    new_state["round_history"].append(turn_msg)

        elif action == "continue_after_challenge":
            res = new_state.get("challenge_result")
            last_play = new_state.get("last_play")
            bluffer_id = last_play["player_id"] if last_play else None

            # Check if the player who played cards had 0 cards AND was not the pile collector (survived challenge)
            if bluffer_id and len(hands[bluffer_id]) == 0:
                w_name = player_names.get(bluffer_id, "Player")
                new_state["phase"] = "GAME_OVER"
                new_state["winner_id"] = bluffer_id
                new_state["winner_name"] = w_name
                win_msg = f"{w_name} survived the challenge with 0 cards and WINS THE MATCH!"
                new_state["last_action"] = win_msg
                new_state["round_history"].append(win_msg)
            else:
                next_leader_id = res["next_leader_id"] if res else player_ids[0]
                next_idx = player_ids.index(next_leader_id)
                next_name = player_names.get(next_leader_id, "Player")
                next_rank = get_next_rank(last_play["declared_rank"]) if last_play else "A"

                new_state["current_player_index"] = next_idx
                new_state["current_player_id"] = next_leader_id
                new_state["required_rank"] = next_rank
                new_state["phase"] = "PLAY"
                new_state["passes"] = []
                new_state["challenge_result"] = None

                lead_msg = f"{next_name} takes the lead to play {next_rank}s."
                new_state["last_action"] = lead_msg
                new_state["round_history"].append(lead_msg)

        elif action == "rematch":
            new_state = self.create_initial_state(player_ids, player_names)
            new_state["last_action"] = "Rematch initiated! New round begins."

        new_state["updated_at"] = time.time()
        return new_state

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        phase = state.get("phase")
        moves: List[Dict[str, Any]] = []

        if phase == "PLAY":
            if player_id == state.get("current_player_id"):
                hand = state.get("hands", {}).get(player_id, [])
                moves.append({
                    "action": "play_cards",
                    "required_rank": state.get("required_rank"),
                    "hand_size": len(hand),
                })
        elif phase == "CHALLENGE":
            last_play = state.get("last_play")
            if last_play and player_id != last_play.get("player_id"):
                moves.append({"action": "challenge"})
                if player_id not in state.get("passes", []):
                    moves.append({"action": "pass"})
        elif phase == "CHALLENGE_REVEAL":
            moves.append({"action": "continue_after_challenge"})
        elif phase == "GAME_OVER":
            moves.append({"action": "rematch"})

        return moves

    def filter_state_for_player(
        self, state: Dict[str, Any], player_id: Optional[str]
    ) -> Dict[str, Any]:
        """
        Authoritative Privacy Masking:
        - Masks all opponents' cards. Only the requested player sees their own cards in 'my_hand'.
        - Central pile cards are concealed (only pile_count is exposed).
        - 'last_play' actual_cards remain hidden during CHALLENGE phase, and are ONLY revealed
          in CHALLENGE_REVEAL.
        """
        masked = dict(state)

        # Remove full hands mapping
        hands = masked.pop("hands", {})
        if player_id and player_id in hands:
            masked["my_hand"] = list(hands[player_id])
        else:
            masked["my_hand"] = []

        # Central pile cards are private; provide count
        pile = masked.pop("pile", [])
        masked["pile_count"] = len(pile)

        # Hide actual_cards from last_play unless in CHALLENGE_REVEAL
        phase = masked.get("phase")
        if masked.get("last_play") and phase != "CHALLENGE_REVEAL":
            lp = dict(masked["last_play"])
            lp.pop("actual_cards", None)
            masked["last_play"] = lp

        return masked
