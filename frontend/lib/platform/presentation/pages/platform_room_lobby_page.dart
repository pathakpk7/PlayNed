import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../models/game_model.dart';
import '../../registry/game_registry.dart';
import '../../services/platform_api_service.dart';
import '../widgets/platform_app_bar.dart';

class PlatformRoomLobbyPage extends ConsumerStatefulWidget {
  final String roomCode;

  const PlatformRoomLobbyPage({
    super.key,
    required this.roomCode,
  });

  @override
  ConsumerState<PlatformRoomLobbyPage> createState() => _PlatformRoomLobbyPageState();
}

class _PlatformRoomLobbyPageState extends ConsumerState<PlatformRoomLobbyPage> {
  PlatformRoom? _room;
  GameMetadata? _game;
  bool _isLoading = true;
  String? _errorMessage;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _fallbackPollTimer;

  @override
  void initState() {
    super.initState();
    _fetchRoomAndConnect();
  }

  @override
  void dispose() {
    _fallbackPollTimer?.cancel();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  Future<void> _fetchRoomAndConnect() async {
    final api = ref.read(platformApiServiceProvider);
    final auth = ref.read(authProvider);
    final playerId = auth.userId ?? 'player_guest';
    final playerName = auth.username ?? 'Player';

    try {
      // First try to join or get room
      PlatformRoom room;
      try {
        room = await api.joinRoom(
          roomCode: widget.roomCode,
          playerName: playerName,
          playerId: playerId,
        );
      } catch (_) {
        room = await api.getRoom(widget.roomCode);
      }

      final game = PlayNedGameRegistry.getGame(room.gameId);

      if (mounted) {
        setState(() {
          _room = room;
          _game = game;
          _isLoading = false;
        });
      }

      // Check if match already started
      if (room.status == 'in_progress') {
        _launchGame(room);
        return;
      }

      // Connect WebSocket
      _wsChannel = api.connectWebSocket(widget.roomCode, playerId);
      if (_wsChannel != null) {
        _wsSubscription = _wsChannel!.stream.listen(
          (message) {
            try {
              final data = jsonDecode(message as String) as Map<String, dynamic>;
              _handleWebSocketEvent(data);
            } catch (_) {}
          },
          onError: (err) {
            _startFallbackPolling();
          },
        );
      } else {
        _startFallbackPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Unable to connect to room '${widget.roomCode}'.";
          _isLoading = false;
        });
      }
    }
  }

  void _startFallbackPolling() {
    _fallbackPollTimer?.cancel();
    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final api = ref.read(platformApiServiceProvider);
        final updated = await api.getRoom(widget.roomCode);
        if (mounted) {
          setState(() => _room = updated);
          if (updated.status == 'in_progress') {
            _fallbackPollTimer?.cancel();
            _launchGame(updated);
          }
        }
      } catch (_) {}
    });
  }

  void _handleWebSocketEvent(Map<String, dynamic> data) {
    final type = data['type'];
    if (data['room'] != null) {
      final updatedRoom = PlatformRoom.fromJson(data['room'] as Map<String, dynamic>);
      if (mounted) {
        setState(() => _room = updatedRoom);
      }

      if (type == 'GAME_STARTED' || updatedRoom.status == 'in_progress') {
        _launchGame(updatedRoom);
      }
    }
  }

  void _launchGame(PlatformRoom room) {
    if (!mounted) return;
    final gameId = room.gameId;
    if (gameId == 'hangman') {
      context.go('/multiplayer/game/${room.roomCode}?pid=${_getLocalPlayerId()}&name=${Uri.encodeComponent(_getLocalPlayerName())}');
    } else if (gameId == 'dots_and_boxes') {
      context.go('/games/dots_and_boxes/play?room=${room.roomCode}&pid=${_getLocalPlayerId()}');
    } else if (gameId == 'quoridor') {
      context.go('/games/quoridor/play?room=${room.roomCode}&pid=${_getLocalPlayerId()}');
    } else if (gameId == 'pentago') {
      context.go('/games/pentago/play?room=${room.roomCode}&pid=${_getLocalPlayerId()}');
    } else if (gameId == 'shut_the_box') {
      context.go('/games/shut_the_box/play?room=${room.roomCode}&pid=${_getLocalPlayerId()}');
    } else if (gameId == 'cricket') {
      context.go('/games/cricket/play?room=${room.roomCode}&pid=${_getLocalPlayerId()}');
    }
  }

  String _getLocalPlayerId() {
    final auth = ref.read(authProvider);
    return auth.userId ?? (_room?.players.first.playerId ?? 'p1');
  }

  String _getLocalPlayerName() {
    final auth = ref.read(authProvider);
    return auth.username ?? 'Player';
  }

  void _toggleReady() async {
    if (_room == null) return;
    final pid = _getLocalPlayerId();
    final localPlayer = _room!.players.firstWhere((p) => p.playerId == pid, orElse: () => _room!.players.first);
    final targetReady = !localPlayer.isReady;

    try {
      final api = ref.read(platformApiServiceProvider);
      await api.setPlayerReady(roomCode: _room!.roomCode, playerId: pid, isReady: targetReady);
    } catch (_) {}
  }

  void _startMatch() async {
    if (_room == null) return;
    final pid = _getLocalPlayerId();
    try {
      final api = ref.read(platformApiServiceProvider);
      await api.startMatch(roomCode: _room!.roomCode, playerId: pid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot start match: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: PlatformAppBar(title: "ROOM ${widget.roomCode}"),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFD5A84B))),
      );
    }

    if (_errorMessage != null || _room == null) {
      return Scaffold(
        appBar: const PlatformAppBar(title: "ROOM ERROR"),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? "Room not found", style: const TextStyle(color: Color(0xFFE57373), fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text("RETURN HOME"),
              ),
            ],
          ),
        ),
      );
    }

    final room = _room!;
    final game = _game ?? PlayNedGameRegistry.allGames.first;
    final localPid = _getLocalPlayerId();
    final isHost = room.hostPlayerId == localPid;
    final localPlayer = room.players.firstWhere((p) => p.playerId == localPid, orElse: () => room.players.first);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0D),
      appBar: PlatformAppBar(title: "ROOM ${room.roomCode}"),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Code Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181816),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD5A84B), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "ROOM CODE",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: const Color(0xFFA9A396),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            room.roomCode,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 38,
                              letterSpacing: 6.0,
                              color: const Color(0xFFD5A84B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined, size: 20, color: Color(0xFFF1EBDD)),
                            tooltip: "Copy Room Code",
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: room.roomCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Room Code ${room.roomCode} copied!")),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Selected Game: ${game.name}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF1EBDD),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Player List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PLAYERS (${room.players.length} / ${room.maxPlayers})",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: const Color(0xFFA9A396),
                      ),
                    ),
                    if (room.players.length < game.minPlayers)
                      Text(
                        "Waiting for at least ${game.minPlayers} players...",
                        style: GoogleFonts.inter(fontSize: 10.5, fontStyle: FontStyle.italic, color: const Color(0xFFE5A93C)),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Player Cards
                ...room.players.map((p) {
                  final isMe = p.playerId == localPid;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141412),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMe ? const Color(0xFFD5A84B).withOpacity(0.5) : const Color(0xFF2A2A26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: p.isHost ? const Color(0xFFD5A84B) : const Color(0xFF2A2A26),
                              child: Text(
                                p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : 'P',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: p.isHost ? const Color(0xFF0F0F0D) : const Color(0xFFF1EBDD),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFF1EBDD),
                                      ),
                                    ),
                                    if (isMe)
                                      Text(
                                        " (YOU)",
                                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFD5A84B)),
                                      ),
                                  ],
                                ),
                                if (p.team != null)
                                  Text(
                                    p.team!,
                                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (p.isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD5A84B).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "HOST",
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFFD5A84B),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: p.isReady
                                      ? const Color(0xFF48BB78).withOpacity(0.18)
                                      : const Color(0xFF2A2A26),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.isReady ? "READY" : "WAITING",
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: p.isReady ? const Color(0xFF48BB78) : const Color(0xFFA9A396),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Actions: Host Start vs Guest Ready
                if (isHost)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5A84B),
                        foregroundColor: const Color(0xFF0F0F0D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: room.players.length >= game.minPlayers ? _startMatch : null,
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(
                        "START GAME",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: localPlayer.isReady ? const Color(0xFF2A2A26) : const Color(0xFF48BB78),
                        foregroundColor: const Color(0xFFF1EBDD),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _toggleReady,
                      icon: Icon(localPlayer.isReady ? Icons.close : Icons.check, size: 18),
                      label: Text(
                        localPlayer.isReady ? "SET NOT READY" : "I'M READY",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
