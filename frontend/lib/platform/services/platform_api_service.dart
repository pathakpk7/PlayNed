import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hangman_reimagined/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/game_model.dart';
import '../registry/game_registry.dart';

final platformApiServiceProvider = Provider<PlatformApiService>((ref) {
  return PlatformApiService();
});

class PlatformApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get wsBaseUrl => AppConfig.wsBaseUrl;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // Game Catalog
  Future<List<GameMetadata>> fetchGames() async {
    try {
      final res = await _dio.get('/games');
      final list = res.data as List<dynamic>;
      return list.map((g) => GameMetadata.fromJson(g as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback to static registry if offline or backend launching
      return PlayNedGameRegistry.allGames;
    }
  }

  Future<GameMetadata?> fetchGameDetails(String gameId) async {
    try {
      final res = await _dio.get('/games/$gameId');
      return GameMetadata.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      return PlayNedGameRegistry.getGame(gameId);
    }
  }

  // Room Management
  Future<PlatformRoom> createRoom({
    required String gameId,
    required String playerName,
    String? playerId,
    String roomType = 'online',
    int? maxPlayers,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final res = await _dio.post('/rooms', data: {
        'game_id': gameId,
        'player_name': playerName,
        'player_id': playerId,
        'room_type': roomType,
        'max_players': maxPlayers,
        'settings': settings ?? {},
      });
      return PlatformRoom.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      // Create local standalone room fallback if network unavailable
      return PlatformRoom(
        id: 'local_room',
        roomCode: 'LOCAL1',
        gameId: gameId,
        hostPlayerId: playerId ?? 'p1',
        status: 'waiting',
        roomType: roomType,
        maxPlayers: maxPlayers ?? 2,
        settings: settings ?? {},
        players: [
          RoomPlayer(
            playerId: playerId ?? 'p1',
            displayName: playerName,
            isHost: true,
            isReady: true,
          ),
        ],
      );
    }
  }

  Future<PlatformRoom> getRoom(String roomCode) async {
    final res = await _dio.get('/rooms/${roomCode.toUpperCase()}');
    return PlatformRoom.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PlatformRoom> joinRoom({
    required String roomCode,
    required String playerName,
    String? playerId,
    String? team,
  }) async {
    final res = await _dio.post('/rooms/${roomCode.toUpperCase()}/join', data: {
      'player_name': playerName,
      'player_id': playerId,
      'team': team,
    });
    return PlatformRoom.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PlatformRoom> setPlayerReady({
    required String roomCode,
    required String playerId,
    required bool isReady,
  }) async {
    final res = await _dio.post('/rooms/${roomCode.toUpperCase()}/ready', data: {
      'player_id': playerId,
      'is_ready': isReady,
    });
    return PlatformRoom.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PlatformRoom> startMatch({
    required String roomCode,
    required String playerId,
  }) async {
    final res = await _dio.post('/rooms/${roomCode.toUpperCase()}/start', data: {
      'player_id': playerId,
    });
    return PlatformRoom.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PlatformRoom> submitMove({
    required String roomCode,
    required String playerId,
    required Map<String, dynamic> move,
  }) async {
    final res = await _dio.post('/rooms/${roomCode.toUpperCase()}/move', data: {
      'player_id': playerId,
      'move': move,
    });
    return PlatformRoom.fromJson(res.data as Map<String, dynamic>);
  }

  // WebSocket Channel Creator
  WebSocketChannel? connectWebSocket(String roomCode, String playerId) {
    try {
      final uri = Uri.parse('$wsBaseUrl/ws/${roomCode.toUpperCase()}/$playerId');
      return WebSocketChannel.connect(uri);
    } catch (e) {
      return null;
    }
  }

  // Cross-Game & Section-Specific Persistent Stats
  Future<Map<String, dynamic>?> recordGameResult({
    required String userId,
    required String gameId,
    String sectionId = 'classic',
    String outcome = 'win',
    int score = 0,
    String? opponentName,
    Map<String, dynamic>? details,
    Map<String, dynamic>? extraStatsUpdate,
  }) async {
    try {
      final res = await _dio.post('/stats/record', data: {
        'user_id': userId,
        'game_id': gameId,
        'section_id': sectionId,
        'outcome': outcome,
        'score': score,
        'opponent_name': opponentName,
        'details': details ?? {},
        'extra_stats_update': extraStatsUpdate ?? {},
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print("Error saving game stats to backend: $e");
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserAllGameStats(String userId, {String? gameId}) async {
    try {
      final res = await _dio.get('/stats/$userId', queryParameters: {
        if (gameId != null && gameId.isNotEmpty) 'game_id': gameId,
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching all game stats: $e");
      }
      return null;
    }
  }
}
