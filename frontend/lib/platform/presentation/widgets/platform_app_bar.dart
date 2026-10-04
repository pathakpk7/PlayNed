import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class PlatformAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showHomeButton;

  const PlatformAppBar({
    super.key,
    this.title,
    this.showHomeButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  void _showJoinRoomDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181816),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFD5A84B), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.meeting_room_outlined, color: Color(0xFFD5A84B), size: 20),
            const SizedBox(width: 8),
            Text(
              "JOIN MULTIPLAYER ROOM",
              style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter the 6-character room code provided by your host:",
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: const Color(0xFFD5A84B),
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "CODE",
                counterText: "",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.inter(color: const Color(0xFFA9A396))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD5A84B),
              foregroundColor: const Color(0xFF0F0F0D),
            ),
            onPressed: () {
              final code = textController.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                context.push('/room/$code');
              }
            },
            child: Text("JOIN ROOM", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF0F0F0D),
      titleSpacing: 16,
      title: InkWell(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD5A84B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "PLAYNED",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: const Color(0xFF0F0F0D),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(width: 10),
              Text(
                "· $title",
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 16,
                  color: const Color(0xFFF1EBDD),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Join Room Quick Action
        TextButton.icon(
          onPressed: () => _showJoinRoomDialog(context, ref),
          icon: const Icon(Icons.vpn_key_outlined, size: 16, color: Color(0xFFD5A84B)),
          label: Text(
            "JOIN ROOM",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: const Color(0xFFD5A84B),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // User Auth / Profile
        IconButton(
          icon: Icon(
            authState.isLoggedIn ? Icons.account_circle_outlined : Icons.login_outlined,
            size: 20,
            color: const Color(0xFFF1EBDD),
          ),
          tooltip: authState.isLoggedIn ? (authState.username ?? "Profile") : "Login / Sign Up",
          onPressed: () {
            if (authState.isLoggedIn) {
              context.push('/profile');
            } else {
              context.push('/auth');
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFFA9A396)),
          tooltip: "Settings",
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
