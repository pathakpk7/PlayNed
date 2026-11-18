import 'dart:ui';
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
  final List<Widget>? actions;

  const PlatformAppBar({
    super.key,
    this.title,
    this.showHomeButton = true,
    this.onGamesClick,
    this.onQuickPlayClick,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

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
              horizontal: PlayNedTokens.space24,
              vertical: PlayNedTokens.space24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Menu",
                      style: PlayNedTokens.sectionHeading.copyWith(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: PlayNedTokens.space16),
                _MobileMenuTile(
                  icon: Icons.grid_view,
                  title: "Explore games",
                  onTap: () {
                    Navigator.pop(ctx);
                    if (onGamesClick != null) {
                      onGamesClick!();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                _MobileMenuTile(
                  icon: Icons.bolt,
                  title: "Quick play",
                  onTap: () {
                    Navigator.pop(ctx);
                    if (onQuickPlayClick != null) {
                      onQuickPlayClick!();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                _MobileMenuTile(
                  icon: Icons.meeting_room_outlined,
                  title: "Join match",
                  onTap: () {
                    Navigator.pop(ctx);
                    _showJoinRoomDialog(context);
                  },
                ),
                const SizedBox(height: 12),
                _MobileMenuTile(
                  icon: isLoggedIn ? Icons.account_circle : Icons.login,
                  title: isLoggedIn ? (username ?? "Profile") : "Sign in",
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isLoggedIn) {
                      context.push('/profile');
                    } else {
                      context.push('/auth');
                    }
                  },
                ),
                _MobileMenuTile(
                  icon: Icons.settings_outlined,
                  title: "Settings",
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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: PlayNedTokens.background.withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(color: PlayNedTokens.borderSubtle, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 880;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Brand Logo
                      PlayNedLogo(
                        size: 28,
                        showText: true,
                        onTap: () => context.go('/'),
                      ),
                      if (title != null && constraints.maxWidth >= 600) ...[
                        const SizedBox(width: 14),
                        Container(
                          width: 1,
                          height: 16,
                          color: PlayNedTokens.borderBright,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          title!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: PlayNedTokens.textPrimary,
                          ),
                        ),
                      ],

                      if (isDesktop) ...[
                        const SizedBox(width: 32),
                        _NavTextButton(
                          label: "Games",
                          onPressed: onGamesClick ?? () => context.go('/'),
                        ),
                        const SizedBox(width: 8),
                        _NavTextButton(
                          label: "Quick play",
                          onPressed: onQuickPlayClick ?? () => context.go('/'),
                        ),
                        const SizedBox(width: 8),
                        _NavTextButton(
                          label: "Join match",
                          onPressed: () => _showJoinRoomDialog(context),
                        ),
                      ],

                      const Spacer(),

                      if (actions != null) ...[
                        ...actions!,
                        const SizedBox(width: 8),
                      ],

                      if (isDesktop) ...[
                        // Account Action
                        GestureDetector(
                          onTap: () {
                            if (authState.isLoggedIn) {
                              context.push('/profile');
                            } else {
                              context.push('/auth');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  authState.isLoggedIn ? Icons.account_circle_outlined : Icons.login_outlined,
                                  size: 17,
                                  color: authState.isLoggedIn ? PlayNedTokens.brandGold : PlayNedTokens.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  authState.isLoggedIn ? (authState.username ?? "Profile") : "Sign in",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: authState.isLoggedIn ? PlayNedTokens.brandGold : PlayNedTokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 19, color: PlayNedTokens.textSecondary),
                          tooltip: "Settings",
                          onPressed: () => context.push('/settings'),
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.meeting_room_outlined, size: 20, color: PlayNedTokens.textPrimary),
                          tooltip: "Join Match",
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
        child: AnimatedContainer(
          duration: PlayNedTokens.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? PlayNedTokens.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
              color: _isHovered ? PlayNedTokens.textPrimary : PlayNedTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MobileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(icon, color: PlayNedTokens.textPrimary, size: 20),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: PlayNedTokens.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
