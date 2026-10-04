import 'package:go_router/go_router.dart';
import '../../platform/presentation/pages/platform_home_page.dart';
import '../../platform/presentation/pages/game_detail_page.dart';
import '../../platform/presentation/pages/platform_room_lobby_page.dart';
import '../../games/dots_and_boxes/presentation/pages/dots_and_boxes_game_page.dart';
import '../../games/quoridor/presentation/pages/quoridor_game_page.dart';
import '../../games/pentago/presentation/pages/pentago_game_page.dart';
import '../../games/shut_the_box/presentation/pages/shut_the_box_game_page.dart';
import '../../games/ultimate_tic_tac_toe/presentation/pages/ultimate_tic_tac_toe_game_page.dart';
import '../../games/cricket/presentation/pages/cricket_hub_page.dart';
import '../../games/cricket/presentation/pages/super_over_game_page.dart';
import '../../games/cricket/presentation/pages/stat_clash_game_page.dart';
import '../../games/cricket/presentation/pages/challenge_hub_page.dart';
import '../../games/cricket/presentation/pages/cricket_draft_game_page.dart';
import '../../games/reversi/presentation/pages/reversi_hub_page.dart';
import '../../games/reversi/presentation/pages/reversi_game_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/game/presentation/pages/level_map_page.dart';
import '../../features/game/presentation/pages/category_selection_page.dart';
import '../../features/codex/presentation/pages/codex_page.dart';
import '../../features/multiplayer/presentation/pages/multiplayer_lobby_page.dart';
import '../../features/multiplayer/presentation/pages/multiplayer_game_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // PlayNed Platform Hub
    GoRoute(
      path: '/',
      builder: (context, state) => const PlatformHomePage(),
    ),
    GoRoute(
      path: '/games/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId'] ?? 'hangman';
        return GameDetailPage(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/room/:code',
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return PlatformRoomLobbyPage(roomCode: code);
      },
    ),

    // New 2D Games
    GoRoute(
      path: '/games/dots_and_boxes/play',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'online';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return DotsAndBoxesGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),
    GoRoute(
      path: '/games/quoridor/play',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'online';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return QuoridorGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),
    GoRoute(
      path: '/games/pentago/play',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'online';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return PentagoGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),
    GoRoute(
      path: '/games/shut_the_box/play',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'online';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return ShutTheBoxGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),
    GoRoute(
      path: '/games/ultimate_tic_tac_toe/play',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'online';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return UltimateTicTacToeGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),
    GoRoute(
      path: '/games/ultimate-tic-tac-toe/play',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'online';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return UltimateTicTacToeGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),

    // Reversi & Othello
    GoRoute(
      path: '/games/reversi',
      builder: (context, state) => const ReversiHubPage(),
    ),
    GoRoute(
      path: '/games/reversi/hub',
      builder: (context, state) => const ReversiHubPage(),
    ),
    GoRoute(
      path: '/games/reversi/play',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'ai';
        final variant = state.uri.queryParameters['variant'] ?? 'othello';
        final diff = state.uri.queryParameters['difficulty'] ?? 'grandmaster';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return ReversiGamePage(
          mode: mode,
          variant: variant,
          difficulty: diff,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),

    // Cricket Game Hub & Modes
    GoRoute(
      path: '/games/cricket/hub',
      builder: (context, state) => const CricketHubPage(),
    ),
    GoRoute(
      path: '/games/cricket/super-over',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'local';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return SuperOverGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),
    GoRoute(
      path: '/games/cricket/stat-clash',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'local';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return StatClashGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),
    GoRoute(
      path: '/games/cricket/challenges',
      builder: (context, state) => const ChallengeHubPage(),
    ),
    GoRoute(
      path: '/games/cricket/draft',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'local';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return CricketDraftGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),
    GoRoute(
      path: '/games/cricket/play',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'online';
        final room = state.uri.queryParameters['room'];
        final pid = state.uri.queryParameters['pid'];
        return SuperOverGamePage(
          mode: mode,
          roomCode: room,
          localPlayerId: pid,
        );
      },
    ),

    // Hangman Reimagined Dedicated Views (Preserved 100%)
    GoRoute(
      path: '/games/hangman/hub',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/games/hangman/play',
      builder: (context, state) {
        final lvl = int.tryParse(state.uri.queryParameters['level'] ?? '') ?? 1;
        return GamePage(mode: 'classic', level: lvl);
      },
    ),
    GoRoute(
      path: '/game/:mode',
      builder: (context, state) {
        final mode = state.pathParameters['mode'] ?? 'classic';
        final cat = state.uri.queryParameters['cat'] ?? 'Technology';
        final duration = int.tryParse(state.uri.queryParameters['duration'] ?? '') ?? 60;
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '');
        return GamePage(mode: mode, category: cat, timerDuration: duration, level: level);
      },
    ),
    GoRoute(
      path: '/levels',
      builder: (context, state) => const LevelMapPage(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategorySelectionPage(),
    ),
    GoRoute(
      path: '/codex',
      builder: (context, state) => const CodexPage(),
    ),
    GoRoute(
      path: '/multiplayer',
      builder: (context, state) => const MultiplayerLobbyPage(),
    ),
    GoRoute(
      path: '/multiplayer/game/:code',
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        final pid = state.uri.queryParameters['pid'] ?? '';
        final name = state.uri.queryParameters['name'] ?? 'Player';
        return MultiplayerGamePage(
          roomCode: code,
          localPlayerId: pid,
          localPlayerName: name,
        );
      },
    ),

    // Account & Platform
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
