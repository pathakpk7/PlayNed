import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../../features/game/data/local_word_bank.dart';

class ApiClient {
  static String get baseUrl => AppConfig.apiBaseUrl;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Options _getOptions() {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return Options(headers: {'Authorization': 'Bearer $_authToken'});
    }
    return Options();
  }

  // Auth Endpoints
  Future<Map<String, dynamic>> signup(String email, String username, String password) async {
    final response = await _dio.post('/auth/signup', data: {
      'email': email,
      'username': username,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email_or_username': emailOrUsername,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await _dio.get('/profile/$userId', options: _getOptions());
      return response.data;
    } catch (e) {
      return {
        'user_id': userId,
        'username': 'PlayerOne',
        'email': 'player@example.com',
        'hearts_remaining': 5,
        'heart_regen_seconds_left': 0,
        'classic_level': 1,
        'highest_classic_level': 1,
        'total_xp': 0,
        'consecutive_losses': 0,
        'mode_stats': {},
        'category_stats': {},
      };
    }
  }

  // Game Endpoints
  Future<Map<String, dynamic>> startGame({
    String mode = 'classic',
    int level = 1,
    String category = 'General',
    String? userId,
  }) async {
    try {
      final response = await _dio.post('/game/start', data: {
        'mode': mode,
        'level': level,
        'category': category,
        'user_id': userId,
      }, options: _getOptions());
      return response.data;
    } catch (e) {
      return _generateLocalFallbackGame(mode, level, category);
    }
  }

  Future<Map<String, dynamic>> makeGuess(String gameId, String letter) async {
    try {
      final response = await _dio.post('/game/guess', data: {
        'game_id': gameId,
        'letter': letter,
      }, options: _getOptions());
      return response.data;
    } catch (e) {
      throw Exception("Failed to send guess to server: $e");
    }
  }

  Future<Map<String, dynamic>> requestHint(String gameId, {int hintStep = 1}) async {
    try {
      final response = await _dio.post('/game/hint', data: {
        'game_id': gameId,
        'hint_step': hintStep,
      }, options: _getOptions());
      return response.data;
    } catch (e) {
      throw Exception("Failed to fetch hint: $e");
    }
  }

  Future<Map<String, dynamic>> useLifeline({required String gameId, required String option, String? userId}) async {
    try {
      final response = await _dio.post('/game/lifeline', data: {
        'game_id': gameId,
        'option': option,
        'user_id': userId,
      }, options: _getOptions());
      return response.data;
    } catch (e) {
      throw Exception("Failed to activate Word Lifeline: $e");
    }
  }

  Future<Map<String, dynamic>> getDailyChallenge({String? userId}) async {
    try {
      final response = await _dio.get('/game/daily', queryParameters: {'user_id': userId ?? 'anon'});
      return response.data;
    } catch (e) {
      return {
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'word_dna': {
          'length': 8,
          'vowels': 3,
          'consonants': 5,
          'has_repeated_letters': true,
          'category': 'Science',
          'part_of_speech': 'adjective'
        },
        'game_id': 'local_daily'
      };
    }
  }

  Map<String, dynamic> _generateLocalFallbackGame(String mode, int level, String category) {
    final localWord = LocalWordBank.selectWord(mode: mode, level: level, category: category);
    final masked = List.generate(localWord.length, (_) => '_');

    return {
      'game_id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'secret_word': localWord.word.toUpperCase(),
      'mode': mode,
      'level': level,
      'tier_label': LocalWordBank.getTierLabel(level),
      'masked_word': masked,
      'revealed_indices': [],
      'lives_remaining': 5,
      'score': 0,
      'combo': 0,
      'mistakes': 0,
      'status': 'in_progress',
      'word_dna': localWord.toWordDna(),
      'guessed_letters': <String>[],
      'hint_clue': null,
      'clue1_definition': null,
      'clue2_sentence': null,
      'clue3_context': null,
      'striking_clue': null,
      'word_lifelines': 2,
      'lifeline_unlocked': level >= 5,
      'lifeline_used': false,
      'heart_regen_seconds_left': 0,
    };
  }

  // Codex Endpoints
  Future<Map<String, dynamic>> getUserCodex(String userId, {String? query, String? category}) async {
    try {
      final response = await _dio.get('/codex/$userId', queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category.isNotEmpty) 'category': category,
      }, options: _getOptions());
      return response.data;
    } catch (e) {
      return {'total_unlocked': 0, 'total_mastered': 0, 'items': []};
    }
  }

  // Multiplayer Endpoints
  Future<Map<String, dynamic>> createRoom({required String playerName, String? userId, String category = 'General'}) async {
    final response = await _dio.post('/multiplayer/create', data: {
      'player_name': playerName,
      'user_id': userId,
      'category': category,
    }, options: _getOptions());
    return response.data;
  }

  Future<Map<String, dynamic>> joinRoom({required String roomCode, required String playerName, String? userId}) async {
    final response = await _dio.post('/multiplayer/join', data: {
      'room_code': roomCode,
      'player_name': playerName,
      'user_id': userId,
    }, options: _getOptions());
    return response.data;
  }

  Future<Map<String, dynamic>> getRoomState(String roomCode) async {
    final response = await _dio.get('/multiplayer/room/$roomCode', options: _getOptions());
    return response.data;
  }

  Future<Map<String, dynamic>> makeRoomGuess({required String roomCode, required String playerId, required String letter}) async {
    final response = await _dio.post('/multiplayer/guess', data: {
      'room_code': roomCode,
      'player_id': playerId,
      'letter': letter,
    }, options: _getOptions());
    return response.data;
  }
}
