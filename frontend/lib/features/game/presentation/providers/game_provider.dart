import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/local_word_bank.dart';

final apiClientProvider = Provider((ref) => ApiClient());

class GameState {
  final String gameId;
  final String mode;
  final int level;
  final String tierLabel;
  final List<String> maskedWord;
  final int livesRemaining; // 5 hearts max
  final int score;
  final int combo;
  final int mistakes;
  final String status; // in_progress, won, lost
  final Map<String, dynamic> wordDna;
  final List<String> guessedLetters;
  final String? hintClue;
  final String? clue1Definition;
  final String? clue2Sentence;
  final String? clue3Context;
  final String? strikingClue;
  final bool lifelineUnlocked;
  final int wordLifelines;
  final bool lifelineUsed;
  final bool lifelineUnlockedMoment;
  final int hintStep;
  final Map<String, dynamic>? knowledgeCard;
  final Map<String, dynamic>? wittyLossPopup;
  final bool isLoading;
  final String? errorMessage;
  final int heartRegenSecondsLeft;

  GameState({
    required this.gameId,
    required this.mode,
    required this.level,
    required this.tierLabel,
    required this.maskedWord,
    required this.livesRemaining,
    required this.score,
    required this.combo,
    required this.mistakes,
    required this.status,
    required this.wordDna,
    required this.guessedLetters,
    this.hintClue,
    this.clue1Definition,
    this.clue2Sentence,
    this.clue3Context,
    this.strikingClue,
    this.lifelineUnlocked = false,
    this.wordLifelines = 2,
    this.lifelineUsed = false,
    this.lifelineUnlockedMoment = false,
    this.hintStep = 0,
    this.knowledgeCard,
    this.wittyLossPopup,
    this.isLoading = false,
    this.errorMessage,
    this.heartRegenSecondsLeft = 0,
  });

  GameState copyWith({
    String? gameId,
    String? mode,
    int? level,
    String? tierLabel,
    List<String>? maskedWord,
    int? livesRemaining,
    int? score,
    int? combo,
    int? mistakes,
    String? status,
    Map<String, dynamic>? wordDna,
    List<String>? guessedLetters,
    String? hintClue,
    String? clue1Definition,
    String? clue2Sentence,
    String? clue3Context,
    String? strikingClue,
    bool? lifelineUnlocked,
    int? wordLifelines,
    bool? lifelineUsed,
    bool? lifelineUnlockedMoment,
    int? hintStep,
    Map<String, dynamic>? knowledgeCard,
    Map<String, dynamic>? wittyLossPopup,
    bool? isLoading,
    String? errorMessage,
    int? heartRegenSecondsLeft,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      tierLabel: tierLabel ?? this.tierLabel,
      maskedWord: maskedWord ?? this.maskedWord,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      mistakes: mistakes ?? this.mistakes,
      status: status ?? this.status,
      wordDna: wordDna ?? this.wordDna,
      guessedLetters: guessedLetters ?? this.guessedLetters,
      hintClue: hintClue ?? this.hintClue,
      clue1Definition: clue1Definition ?? this.clue1Definition,
      clue2Sentence: clue2Sentence ?? this.clue2Sentence,
      clue3Context: clue3Context ?? this.clue3Context,
      strikingClue: strikingClue ?? this.strikingClue,
      lifelineUnlocked: lifelineUnlocked ?? this.lifelineUnlocked,
      wordLifelines: wordLifelines ?? this.wordLifelines,
      lifelineUsed: lifelineUsed ?? this.lifelineUsed,
      lifelineUnlockedMoment: lifelineUnlockedMoment ?? this.lifelineUnlockedMoment,
      hintStep: hintStep ?? this.hintStep,
      knowledgeCard: knowledgeCard ?? this.knowledgeCard,
      wittyLossPopup: wittyLossPopup ?? this.wittyLossPopup,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      heartRegenSecondsLeft: heartRegenSecondsLeft ?? this.heartRegenSecondsLeft,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final ApiClient _apiClient;
  LocalWord? _currentLocalWord;

  GameNotifier(this._apiClient)
      : super(GameState(
          gameId: '',
          mode: 'classic',
          level: 1,
          tierLabel: 'Very Easy',
          maskedWord: [],
          livesRemaining: 5,
          score: 0,
          combo: 0,
          mistakes: 0,
          status: 'in_progress',
          wordDna: {},
          guessedLetters: [],
        ));

  Future<void> startNewGame({
    String mode = 'classic',
    int level = 1,
    String category = 'General',
    String? userId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    _currentLocalWord = LocalWordBank.selectWord(mode: mode, level: level, category: category);

    try {
      final res = await _apiClient.startGame(mode: mode, level: level, category: category, userId: userId);
      final isLocal = (res['game_id'] as String? ?? '').startsWith('local_');

      state = GameState(
        gameId: res['game_id'] ?? 'g_1',
        mode: res['mode'] ?? mode,
        level: res['level'] ?? level,
        tierLabel: res['tier_label'] ?? LocalWordBank.getTierLabel(level),
        maskedWord: List<String>.from(res['masked_word'] ?? List.generate(_currentLocalWord!.length, (_) => '_')),
        livesRemaining: res['lives_remaining'] ?? 5,
        score: isLocal ? state.score : (res['score'] ?? 0),
        combo: 0,
        mistakes: 0,
        status: res['status'] ?? 'in_progress',
        wordDna: res['word_dna'] ?? _currentLocalWord!.toWordDna(),
        guessedLetters: List<String>.from(res['guessed_letters'] ?? []),
        hintClue: res['hint_clue'],
        clue1Definition: res['clue1_definition'],
        clue2Sentence: res['clue2_sentence'],
        clue3Context: res['clue3_context'],
        strikingClue: res['striking_clue'],
        lifelineUnlocked: res['lifeline_unlocked'] ?? (level >= 5),
        wordLifelines: res['word_lifelines'] ?? 2,
        lifelineUsed: res['lifeline_used'] ?? false,
        lifelineUnlockedMoment: res['lifeline_unlocked_moment'] ?? false,
        hintStep: 0,
        knowledgeCard: res['knowledge_card'],
        wittyLossPopup: res['witty_loss_popup'],
        heartRegenSecondsLeft: res['heart_regen_seconds_left'] ?? 0,
        isLoading: false,
      );
    } catch (e) {
      final masked = List.generate(_currentLocalWord!.length, (_) => '_');
      state = GameState(
        gameId: 'local_${DateTime.now().millisecondsSinceEpoch}',
        mode: mode,
        level: level,
        tierLabel: LocalWordBank.getTierLabel(level),
        maskedWord: masked,
        livesRemaining: 5,
        score: state.score,
        combo: 0,
        mistakes: 0,
        status: 'in_progress',
        wordDna: _currentLocalWord!.toWordDna(),
        guessedLetters: [],
        lifelineUnlocked: level >= 5,
        wordLifelines: 2,
        lifelineUsed: false,
        isLoading: false,
      );
    }
  }

  Future<void> useLifeline(String option, {String? userId}) async {
    if (state.lifelineUsed || state.status != 'in_progress' || state.wordLifelines <= 0) return;

    if (!state.gameId.startsWith('local_')) {
      try {
        final res = await _apiClient.useLifeline(gameId: state.gameId, option: option, userId: userId);
        final gState = res['game_state'] ?? {};
        state = state.copyWith(
          maskedWord: List<String>.from(gState['masked_word'] ?? state.maskedWord),
          strikingClue: res['striking_clue'] ?? gState['striking_clue'] ?? state.strikingClue,
          wordLifelines: res['word_lifelines_remaining'] ?? gState['word_lifelines'] ?? state.wordLifelines,
          lifelineUsed: true,
          status: gState['status'] ?? state.status,
        );
        return;
      } catch (_) {
        // Fall back to local execution
      }
    }

    _handleLocalLifeline(option);
  }

  void _handleLocalLifeline(String option) {
    if (_currentLocalWord == null) return;
    final word = _currentLocalWord!.word.toUpperCase();
    final updatedMasked = List<String>.from(state.maskedWord);
    String? strikingClue = state.strikingClue;

    if (option == 'option_a' || option == 'reveal_letter') {
      final unrevealedIndices = <int>[];
      for (int i = 0; i < updatedMasked.length; i++) {
        if (updatedMasked[i] == '_') unrevealedIndices.add(i);
      }
      if (unrevealedIndices.isNotEmpty) {
        final chosenIdx = unrevealedIndices[Random().nextInt(unrevealedIndices.length)];
        final charToReveal = word[chosenIdx];
        for (int i = 0; i < word.length; i++) {
          if (word[i] == charToReveal) updatedMasked[i] = charToReveal;
        }
      }
    } else if (option == 'option_b' || option == 'striking_clue') {
      strikingClue = _currentLocalWord!.strikingClue;
    } else if (option == 'option_c' || option == 'vowel_scan') {
      const vowels = ['A', 'E', 'I', 'O', 'U'];
      for (int i = 0; i < word.length; i++) {
        if (vowels.contains(word[i])) updatedMasked[i] = word[i];
      }
    }

    final isWon = !updatedMasked.contains('_');
    final newStatus = isWon ? 'won' : state.status;
    final knowledgeCard = isWon ? _currentLocalWord!.toKnowledgeCard('won', state.mistakes, state.combo) : state.knowledgeCard;

    state = state.copyWith(
      maskedWord: updatedMasked,
      strikingClue: strikingClue,
      wordLifelines: max(0, state.wordLifelines - 1),
      lifelineUsed: true,
      status: newStatus,
      knowledgeCard: knowledgeCard,
    );
  }

  Future<void> makeGuess(String letter) async {
    final upperLetter = letter.toUpperCase();
    if (state.status != 'in_progress' || state.guessedLetters.contains(upperLetter)) return;

    final updatedGuessed = [...state.guessedLetters, upperLetter];
    state = state.copyWith(guessedLetters: updatedGuessed);

    if (!state.gameId.startsWith('local_')) {
      try {
        final res = await _apiClient.makeGuess(state.gameId, upperLetter);
        state = state.copyWith(
          maskedWord: List<String>.from(res['masked_word'] ?? state.maskedWord),
          livesRemaining: res['lives_remaining'] ?? state.livesRemaining,
          score: res['score'] ?? state.score,
          combo: res['combo'] ?? state.combo,
          mistakes: res['mistakes'] ?? state.mistakes,
          status: res['status'] ?? state.status,
          knowledgeCard: res['knowledge_card'],
          wittyLossPopup: res['witty_loss_popup'],
        );
        return;
      } catch (_) {
        // Fall back to local evaluation
      }
    }

    _handleLocalGuess(upperLetter);
  }

  void _handleLocalGuess(String letter) {
    if (_currentLocalWord == null) {
      _currentLocalWord = LocalWordBank.selectWord(mode: state.mode, level: state.level);
    }

    final secretWord = _currentLocalWord!.word.toUpperCase();
    final updatedMasked = List<String>.from(state.maskedWord);

    bool isMatch = false;
    for (int i = 0; i < secretWord.length; i++) {
      if (i < updatedMasked.length && secretWord[i] == letter) {
        updatedMasked[i] = letter;
        isMatch = true;
      }
    }

    int updatedLives = state.livesRemaining;
    int updatedScore = state.score;
    int updatedCombo = state.combo;
    int updatedMistakes = state.mistakes;
    String updatedStatus = state.status;
    Map<String, dynamic>? knowledgeCard = state.knowledgeCard;
    Map<String, dynamic>? wittyLossPopup = state.wittyLossPopup;

    if (isMatch) {
      updatedCombo += 1;
      updatedScore += 100 * updatedCombo;
      if (!updatedMasked.contains('_')) {
        updatedStatus = 'won';
        updatedScore += 500; // completion bonus
        knowledgeCard = _currentLocalWord!.toKnowledgeCard('won', updatedMistakes, updatedCombo);
      }
    } else {
      updatedLives -= 1;
      updatedCombo = 0;
      updatedMistakes += 1;

      if (updatedLives <= 0) {
        updatedStatus = 'lost';
        // Reveal all characters in masked word upon defeat
        for (int i = 0; i < secretWord.length; i++) {
          if (i < updatedMasked.length) updatedMasked[i] = secretWord[i];
        }
        knowledgeCard = _currentLocalWord!.toKnowledgeCard('lost', updatedMistakes, updatedCombo);
        wittyLossPopup = {
          'title': 'The Gallows Await',
          'message': 'The secret word was "$secretWord". Add it to your Codex vault to master its roots.',
          'consecutive_losses': 1,
          'vocabulary_suggestion': secretWord,
        };
      }
    }

    state = state.copyWith(
      maskedWord: updatedMasked,
      livesRemaining: updatedLives,
      score: updatedScore,
      combo: updatedCombo,
      mistakes: updatedMistakes,
      status: updatedStatus,
      knowledgeCard: knowledgeCard,
      wittyLossPopup: wittyLossPopup,
    );
  }

  Future<void> requestHint([int? step]) async {
    final targetStep = step ?? ((state.hintStep < 3) ? state.hintStep + 1 : 3);

    if (!state.gameId.startsWith('local_')) {
      try {
        final res = await _apiClient.requestHint(state.gameId, hintStep: targetStep);
        final clue = res['clue_text'] ?? "Clue revealed.";
        final gState = res['game_state'] ?? {};

        state = state.copyWith(
          hintClue: clue,
          clue1Definition: gState['clue1_definition'] ?? res['clue1_definition'] ?? state.clue1Definition,
          clue2Sentence: gState['clue2_sentence'] ?? res['clue2_sentence'] ?? state.clue2Sentence,
          clue3Context: gState['clue3_context'] ?? res['clue3_context'] ?? state.clue3Context,
          hintStep: targetStep,
          maskedWord: List<String>.from(gState['masked_word'] ?? state.maskedWord),
          status: gState['status'] ?? state.status,
        );
        return;
      } catch (_) {
        // Fall back to local hint
      }
    }

    if (_currentLocalWord == null) {
      _currentLocalWord = LocalWordBank.selectWord(mode: state.mode, level: state.level);
    }

    final clue1 = "${_currentLocalWord!.definition} (${_currentLocalWord!.origin})";
    final clue2 = _currentLocalWord!.usageContext;
    final clue3 = _currentLocalWord!.exampleSentence;

    state = state.copyWith(
      hintStep: targetStep,
      clue1Definition: targetStep >= 1 ? clue1 : state.clue1Definition,
      clue2Sentence: targetStep >= 2 ? clue2 : state.clue2Sentence,
      clue3Context: targetStep >= 3 ? clue3 : state.clue3Context,
      hintClue: targetStep == 1 ? clue1 : (targetStep == 2 ? clue2 : clue3),
    );
  }

  void markTimedOut() {
    if (_currentLocalWord != null) {
      final secretWord = _currentLocalWord!.word.toUpperCase();
      final revealedMasked = secretWord.split('');
      state = state.copyWith(
        status: 'lost',
        livesRemaining: 0,
        maskedWord: revealedMasked,
        knowledgeCard: _currentLocalWord!.toKnowledgeCard('lost', state.mistakes, 0),
        wittyLossPopup: {
          'title': 'Time Expired',
          'message': 'The clock ran out on "$secretWord". Master this term in your Codex.',
          'consecutive_losses': 1,
          'vocabulary_suggestion': secretWord,
        },
      );
    } else {
      state = state.copyWith(status: 'lost', livesRemaining: 0);
    }
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final api = ref.watch(apiClientProvider);
  return GameNotifier(api);
});
