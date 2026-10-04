from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

# Authentication Request/Response Models
class SignUpRequest(BaseModel):
    email: str
    username: str
    password: str

class LoginRequest(BaseModel):
    email_or_username: str
    password: str

class AuthResponse(BaseModel):
    token: str
    user_id: str
    username: str
    email: str

# Word & Game Models
class WordDna(BaseModel):
    length: int
    vowels: int
    consonants: int
    has_repeated_letters: bool
    category: str
    part_of_speech: str

class StartGameRequest(BaseModel):
    mode: str = Field(default="classic", description="classic, daily, category, timed")
    level: Optional[int] = Field(default=1, ge=1, le=100)
    category: Optional[str] = Field(default="General")
    user_id: Optional[str] = None

class GuessRequest(BaseModel):
    game_id: str
    letter: str = Field(..., min_length=1, max_length=1)

class HintRequest(BaseModel):
    game_id: str
    hint_step: Optional[int] = Field(default=1, ge=1, le=3)

class LifelineRequest(BaseModel):
    game_id: str
    option: str = Field(..., description="reveal_letter or striking_clue")
    user_id: Optional[str] = None

class KnowledgeCard(BaseModel):
    word: str
    definition: str
    part_of_speech: str
    synonyms: List[str]
    category: str

class WittyLossPopupPayload(BaseModel):
    title: str
    message: str
    consecutive_losses: int
    vocabulary_suggestion: str

class GameStateResponse(BaseModel):
    game_id: str
    mode: str
    level: int
    tier_label: str
    masked_word: List[str]
    revealed_indices: List[int]
    lives_remaining: int  # 5 hearts max for Classic
    score: int
    combo: int
    mistakes: int
    status: str  # in_progress, won, lost
    word_dna: WordDna
    guessed_letters: List[str]
    clue1_definition: Optional[str] = None  # Meaning / Definition
    clue2_sentence: Optional[str] = None    # Context sentence (masked)
    clue3_context: Optional[str] = None     # Category / POS / Structure context
    striking_clue: Optional[str] = None     # Option B Lifeline Striking Clue
    lifeline_unlocked: bool = False         # True if level >= 5
    word_lifelines: int = 2                 # Inventory count
    lifeline_used: bool = False             # Whether lifeline was activated in current round
    lifeline_unlocked_moment: bool = False  # Triggers unlock popup on level 5
    knowledge_card: Optional[KnowledgeCard] = None
    witty_loss_popup: Optional[WittyLossPopupPayload] = None
    heart_regen_seconds_left: int = 0

class HintResponse(BaseModel):
    game_id: str
    hint_step: int
    clue_text: str
    game_state: GameStateResponse

class LifelineResponse(BaseModel):
    game_id: str
    option: str
    revealed_letter: Optional[str] = None
    revealed_position: Optional[int] = None
    striking_clue: Optional[str] = None
    word_lifelines_remaining: int
    game_state: GameStateResponse

class DailyChallengeResponse(BaseModel):
    date: str
    word_dna: WordDna
    game_id: str

class ModeStatItem(BaseModel):
    games_played: int = 0
    games_won: int = 0
    games_lost: int = 0
    xp_earned: int = 0
    best_score: int = 0
    best_time_seconds: int = 0
    total_words: int = 0
    current_streak: int = 0

class RealUserProfile(BaseModel):
    user_id: str
    username: str
    email: str
    hearts_remaining: int
    heart_regen_seconds_left: int
    classic_level: int
    highest_classic_level: int
    total_xp: int
    consecutive_losses: int
    word_lifelines: int = 2
    lifeline_unlocked: bool = False
    mode_stats: Dict[str, ModeStatItem]
    category_stats: Dict[str, ModeStatItem]

# Codex Models
class CodexItemResponse(BaseModel):
    id: str
    word: str
    category: str
    definition: str
    part_of_speech: str
    example_sentence: str
    synonyms: List[str]
    times_encountered: int
    times_won: int
    mastery_status: str

class CodexListResponse(BaseModel):
    total_unlocked: int
    total_mastered: int
    items: List[CodexItemResponse]

# Multiplayer 1v1 Models
class CreateRoomRequest(BaseModel):
    player_name: str
    user_id: Optional[str] = None
    category: Optional[str] = "General"

class JoinRoomRequest(BaseModel):
    room_code: str
    player_name: str
    user_id: Optional[str] = None

class RoomGuessRequest(BaseModel):
    room_code: str
    player_id: str
    letter: str = Field(..., min_length=1, max_length=1)

class RoomStateResponse(BaseModel):
    room_code: str
    player1_id: str
    player1_name: str
    player1_score: int
    player2_id: Optional[str] = None
    player2_name: Optional[str] = None
    player2_score: int
    current_turn_player_id: str
    current_turn_player_name: str
    masked_word: List[str]
    guessed_letters: List[str]
    lives_remaining: int
    status: str  # waiting_for_player2, in_progress, won, lost
    word_dna: WordDna
    winner_id: Optional[str] = None
    winner_name: Optional[str] = None

# Platform Game & Multi-Game Stats Models
class RecordGameSessionRequest(BaseModel):
    user_id: str
    game_id: str
    section_id: str = "classic"
    outcome: str = "win" # win, loss, tie, completed
    score: int = 0
    opponent_name: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    extra_stats_update: Optional[Dict[str, Any]] = None

class GameSectionStatItem(BaseModel):
    game_id: str
    section_id: str
    matches_played: int = 0
    matches_won: int = 0
    matches_lost: int = 0
    matches_tied: int = 0
    high_score: int = 0
    total_score: int = 0
    current_streak: int = 0
    best_streak: int = 0
    extra_data: Dict[str, Any] = {}
    last_played_at: Optional[str] = None

class GameStatsGroup(BaseModel):
    game_id: str
    total_played: int = 0
    total_won: int = 0
    total_lost: int = 0
    total_tied: int = 0
    high_score: int = 0
    sections: Dict[str, GameSectionStatItem] = {}

class GameMatchLogItem(BaseModel):
    id: str
    game_id: str
    section_id: str
    outcome: str
    score: int = 0
    opponent_name: Optional[str] = None
    details: Dict[str, Any] = {}
    played_at: str

class UserAllGameStatsResponse(BaseModel):
    user_id: str
    username: str
    total_games_played: int = 0
    total_games_won: int = 0
    games: Dict[str, GameStatsGroup] = {}
    recent_matches: List[GameMatchLogItem] = []

