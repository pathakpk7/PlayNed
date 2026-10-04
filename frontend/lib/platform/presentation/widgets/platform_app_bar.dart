import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/features/auth/presentation/providers/auth_provider.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import 'playned_components.dart';
import 'playned_logo.dart';

class PlatformAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showHomeButton;
  final VoidCallback? onGamesClick;
  final VoidCallback? onQuickPlayClick;

  const PlatformAppBar({
    super.key,
    this.title,
    this.showHomeButton = true,
    this.onGamesClick,
    this.onQuickPlayClick,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  void _showJoinRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const JoinRoomDialog(),
    );
  }

  void _showMobileMenu(BuildContext context, WidgetRef ref, bool isLoggedIn, String? username) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PlayNedTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PlayNedTokens.radiusLg)),
        side: BorderSide(color: PlayNedTokens.border, width: 1),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PlayNedTokens.space20,
              vertical: PlayNedTokens.space24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("PLAYNED NAVIGATION", style: PlayNedTokens.metadata),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: PlayNedTokens.space12),
                ListTile(
                  leading: const Icon(Icons.sports_esports, color: PlayNedTokens.brandGold),
                  title: Text("GAMES CATALOG", style: PlayNedTokens.buttonLabel),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (onGamesClick != null) {
                      onGamesClick!();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bolt, color: PlayNedTokens.brandGold),
                  title: Text("QUICK PLAY", style: PlayNedTokens.buttonLabel),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (onQuickPlayClick != null) {
                      onQuickPlayClick!();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.meeting_room_outlined, color: PlayNedTokens.brandGold),
                  title: Text("JOIN ROOM", style: PlayNedTokens.buttonLabel),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showJoinRoomDialog(context);
                  },
                ),
                const Divider(color: PlayNedTokens.border),
                ListTile(
                  leading: Icon(
                    isLoggedIn ? Icons.account_circle : Icons.login,
                    color: PlayNedTokens.textPrimary,
                  ),
                  title: Text(
                    isLoggedIn ? (username ?? "PROFILE") : "SIGN IN / SIGN UP",
                    style: PlayNedTokens.buttonLabel,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isLoggedIn) {
                      context.push('/profile');
                    } else {
                      context.push('/auth');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: PlayNedTokens.textSecondary),
                  title: Text("SETTINGS", style: PlayNedTokens.buttonLabel),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/settings');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Container(
      decoration: const BoxDecoration(
        color: PlayNedTokens.background,
        border: Border(
          bottom: BorderSide(color: PlayNedTokens.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 880;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Logo
                  PlayNedLogo(
                    size: 28,
                    showText: true,
                    onTap: () => context.go('/'),
                  ),
                  if (title != null && constraints.maxWidth >= 600) ...[
                    const SizedBox(width: 8),
                    Text(
                      "· $title",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 17,
                        color: PlayNedTokens.textPrimary,
                      ),
                    ),
                  ],

                  if (isDesktop) ...[
                    const SizedBox(width: 20),
                    _NavTextButton(
                      label: "GAMES",
                      onPressed: onGamesClick ?? () => context.go('/'),
                    ),
                    const SizedBox(width: 6),
                    _NavTextButton(
                      label: "QUICK PLAY",
                      onPressed: onQuickPlayClick ?? () => context.go('/'),
                    ),
                    const SizedBox(width: 6),
                    PlayNedButton(
                      label: "JOIN ROOM",
                      icon: Icons.meeting_room_outlined,
                      variant: PlayNedButtonVariant.outlined,
                      customAccent: PlayNedTokens.brandGold,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      onPressed: () => _showJoinRoomDialog(context),
                    ),
                  ],

                  const Spacer(),

                  if (isDesktop) ...[
                    // Profile
                    TextButton.icon(
                      onPressed: () {
                        if (authState.isLoggedIn) {
                          context.push('/profile');
                        } else {
                          context.push('/auth');
                        }
                      },
                      icon: Icon(
                        authState.isLoggedIn ? Icons.account_circle_outlined : Icons.login_outlined,
                        size: 18,
                        color: authState.isLoggedIn ? PlayNedTokens.brandGold : PlayNedTokens.textPrimary,
                      ),
                      label: Text(
                        authState.isLoggedIn ? (authState.username ?? "PROFILE") : "SIGN IN",
                        style: PlayNedTokens.buttonLabel.copyWith(
                          fontSize: 11.5,
                          color: authState.isLoggedIn ? PlayNedTokens.brandGold : PlayNedTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20, color: PlayNedTokens.textSecondary),
                      tooltip: "Settings",
                      onPressed: () => context.push('/settings'),
                    ),
                  ] else ...[
                    // Mobile & Tablet actions
                    IconButton(
                      icon: const Icon(Icons.meeting_room_outlined, size: 20, color: PlayNedTokens.brandGold),
                      tooltip: "Join Room",
                      onPressed: () => _showJoinRoomDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu, size: 22, color: PlayNedTokens.textPrimary),
                      tooltip: "Menu",
                      onPressed: () => _showMobileMenu(
                        context,
                        ref,
                        authState.isLoggedIn,
                        authState.username,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _NavTextButton({required this.label, required this.onPressed});

  @override
  State<_NavTextButton> createState() => _NavTextButtonState();
}

class _NavTextButtonState extends State<_NavTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            widget.label,
            style: PlayNedTokens.buttonLabel.copyWith(
              color: _isHovered ? PlayNedTokens.brandGold : PlayNedTokens.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
