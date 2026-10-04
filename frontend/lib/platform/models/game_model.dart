import 'package:flutter/material.dart';

class GameMetadata {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String category;
  final int minPlayers;
  final int maxPlayers;
  final bool supportsLocal;
  final bool supportsOnline;
  final bool supportsTeams;
  final int estimatedDurationMinutes;
  final Color accentColor;
  final Color backgroundColor;
  final IconData icon;
  final List<String> rulesSummary;

  const GameMetadata({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.minPlayers,
    required this.maxPlayers,
    this.supportsLocal = true,
    this.supportsOnline = true,
    this.supportsTeams = false,
    this.estimatedDurationMinutes = 5,
    required this.accentColor,
    required this.backgroundColor,
    required this.icon,
    required this.rulesSummary,
  });

  factory GameMetadata.fromJson(Map<String, dynamic> json) {
    return GameMetadata(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      tagline: json['tagline'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Casual',
      minPlayers: json['min_players'] ?? 1,
      maxPlayers: json['max_players'] ?? 4,
      supportsLocal: json['supports_local'] ?? true,
      supportsOnline: json['supports_online'] ?? true,
      supportsTeams: json['supports_teams'] ?? false,
      estimatedDurationMinutes: json['estimated_duration_minutes'] ?? 5,
      accentColor: _parseHexColor(json['accent_color_hex']) ?? const Color(0xFFD5A84B),
      backgroundColor: _parseHexColor(json['bg_color_hex']) ?? const Color(0xFF181816),
      icon: _parseIcon(json['icon_name']),
      rulesSummary: List<String>.from(json['rules_summary'] ?? []),
    );
  }

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return null;
  }

  static IconData _parseIcon(String? iconName) {
    switch (iconName) {
      case 'font_download':
      case 'spellcheck':
        return Icons.spellcheck;
      case 'grid_on':
        return Icons.grid_on;
      case 'straighten':
      case 'view_quilt':
        return Icons.view_quilt;
      case 'rotate_right':
      case 'cached':
        return Icons.rotate_right;
      default:
        return Icons.sports_esports;
    }
  }
}

class RoomPlayer {
  final String playerId;
  final String displayName;
  final bool isHost;
  final bool isReady;
  final bool isConnected;
  final String? team;

  const RoomPlayer({
    required this.playerId,
    required this.displayName,
    this.isHost = false,
    this.isReady = false,
    this.isConnected = true,
    this.team,
  });

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    return RoomPlayer(
      playerId: json['player_id'] ?? '',
      displayName: json['display_name'] ?? 'Player',
      isHost: json['is_host'] ?? false,
      isReady: json['is_ready'] ?? false,
      isConnected: json['is_connected'] ?? true,
      team: json['team'],
    );
  }
}

class PlatformRoom {
  final String id;
  final String roomCode;
  final String gameId;
  final String hostPlayerId;
  final String status; // waiting, in_progress, finished, cancelled
  final String roomType; // online, local, team
  final int maxPlayers;
  final Map<String, dynamic> settings;
  final List<RoomPlayer> players;
  final Map<String, dynamic>? matchState;

  const PlatformRoom({
    required this.id,
    required this.roomCode,
    required this.gameId,
    required this.hostPlayerId,
    required this.status,
    required this.roomType,
    required this.maxPlayers,
    required this.settings,
    required this.players,
    this.matchState,
  });

  factory PlatformRoom.fromJson(Map<String, dynamic> json) {
    final rawPlayers = (json['players'] as List<dynamic>?) ?? [];
    return PlatformRoom(
      id: json['id'] ?? '',
      roomCode: json['room_code'] ?? '',
      gameId: json['game_id'] ?? '',
      hostPlayerId: json['host_player_id'] ?? '',
      status: json['status'] ?? 'waiting',
      roomType: json['room_type'] ?? 'online',
      maxPlayers: json['max_players'] ?? 2,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      players: rawPlayers.map((p) => RoomPlayer.fromJson(p as Map<String, dynamic>)).toList(),
      matchState: json['match_state'] != null ? Map<String, dynamic>.from(json['match_state']) : null,
    );
  }
}
