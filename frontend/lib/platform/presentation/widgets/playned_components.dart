import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../models/game_model.dart';
import '../../registry/game_registry.dart';
import '../../services/platform_api_service.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Tactile Button with subtle micro-interactions for PlayNed
enum PlayNedButtonVariant { primary, secondary, outlined, ghost }

class PlayNedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PlayNedButtonVariant variant;
  final Color? customAccent;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const PlayNedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = PlayNedButtonVariant.primary,
    this.customAccent,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  State<PlayNedButton> createState() => _PlayNedButtonState();
}

class _PlayNedButtonState extends State<PlayNedButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.customAccent ?? PlayNedTokens.brandGold;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    BorderSide border;

    switch (widget.variant) {
      case PlayNedButtonVariant.primary:
        bg = _isPressed
            ? accent.withOpacity(0.85)
            : (_isHovered ? PlayNedTokens.brandGoldBright : accent);
        fg = PlayNedTokens.textInverse;
        border = BorderSide.none;
        break;
      case PlayNedButtonVariant.secondary:
        bg = _isPressed
            ? PlayNedTokens.surfaceHover
            : (_isHovered ? PlayNedTokens.surfaceElevated : PlayNedTokens.surface);
        fg = _isHovered ? accent : PlayNedTokens.textPrimary;
        border = BorderSide(
          color: _isHovered ? accent.withOpacity(0.5) : PlayNedTokens.border,
          width: 1,
        );
        break;
      case PlayNedButtonVariant.outlined:
        bg = _isHovered ? accent.withOpacity(0.12) : Colors.transparent;
        fg = _isHovered ? PlayNedTokens.textPrimary : accent;
        border = BorderSide(
          color: _isHovered ? accent : accent.withOpacity(0.7),
          width: 1.2,
        );
        break;
      case PlayNedButtonVariant.ghost:
        bg = _isHovered ? PlayNedTokens.surfaceHover : Colors.transparent;
        fg = _isHovered ? PlayNedTokens.textPrimary : PlayNedTokens.textSecondary;
        border = BorderSide.none;
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (widget.icon != null) ...[
          Icon(widget.icon, size: 16, color: fg),
          const SizedBox(width: PlayNedTokens.space8),
        ],
        Text(
          widget.label,
          style: PlayNedTokens.buttonLabel.copyWith(color: fg),
        ),
      ],
    );

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => isEnabled ? setState(() => _isPressed = true) : null,
        onTapUp: (_) => isEnabled ? setState(() => _isPressed = false) : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: PlayNedTokens.animMicro,
          curve: PlayNedTokens.animCurve,
          width: widget.width,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: PlayNedTokens.space16, vertical: PlayNedTokens.space12),
          decoration: BoxDecoration(
            color: isEnabled ? bg : PlayNedTokens.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
            border: Border.fromBorderSide(border),
            boxShadow: _isHovered && widget.variant == PlayNedButtonVariant.primary
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Standardized tactile container card for platform pages
class PlayNedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const PlayNedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PlayNedTokens.space16),
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? PlayNedTokens.border,
      width: 1,
    );

    final widgetChild = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? PlayNedTokens.surface,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: border,
      ),
      child: child,
    );

    if (onTap == null) return widgetChild;

    return InkWell(
      borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
      onTap: onTap,
      child: widgetChild,
    );
  }
}

/// Category & Metadata Badges
class GameCategoryBadge extends StatelessWidget {
  final String category;
  final Color? accentColor;

  const GameCategoryBadge({super.key, required this.category, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? PlayNedTokens.brandGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PlayNedTokens.space8, vertical: PlayNedTokens.space4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusXs),
        border: Border.all(color: accent.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        category.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: accent,
        ),
      ),
    );
  }
}

class PlayerCountBadge extends StatelessWidget {
  final int minPlayers;
  final int maxPlayers;

  const PlayerCountBadge({super.key, required this.minPlayers, required this.maxPlayers});

  @override
  Widget build(BuildContext context) {
    final label = minPlayers == maxPlayers
        ? (minPlayers == 1 ? "1 PLAYER" : "$minPlayers PLAYERS")
        : "$minPlayers–$maxPlayers PLAYERS";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          minPlayers == 1 ? Icons.person_outline : Icons.group_outlined,
          size: 13,
          color: PlayNedTokens.textSecondary,
        ),
        const SizedBox(width: PlayNedTokens.space4),
        Text(
          label,
          style: PlayNedTokens.metadata.copyWith(fontSize: 10, color: PlayNedTokens.textSecondary),
        ),
      ],
    );
  }
}

class DurationBadge extends StatelessWidget {
  final int minutes;

  const DurationBadge({super.key, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 13, color: PlayNedTokens.textSecondary),
        const SizedBox(width: PlayNedTokens.space4),
        Text(
          "~$minutes MIN",
          style: PlayNedTokens.metadata.copyWith(fontSize: 10, color: PlayNedTokens.textSecondary),
        ),
      ],
    );
  }
}

/// Section Header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? tag;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.tag,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tag != null) ...[
          Text(tag!.toUpperCase(), style: PlayNedTokens.metadata.copyWith(color: PlayNedTokens.brandGold)),
          const SizedBox(height: PlayNedTokens.space4),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(title, style: PlayNedTokens.sectionHeading),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: PlayNedTokens.space4),
          Text(subtitle!, style: PlayNedTokens.bodyMuted),
        ],
      ],
    );
  }
}

/// Join Room Modal Dialog with enhanced UX & loading/error handling
class JoinRoomDialog extends ConsumerStatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  ConsumerState<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<JoinRoomDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitJoin() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _errorMessage = "Please enter a valid 6-character room code.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(platformApiServiceProvider);
      final room = await api.getRoom(code);
      if (mounted) {
        Navigator.of(context).pop();
        context.push('/room/${room.roomCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Room '$code' not found or may have expired. Please verify and retry.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PlayNedTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        side: const BorderSide(color: PlayNedTokens.border, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(PlayNedTokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(PlayNedTokens.space8),
                    decoration: BoxDecoration(
                      color: PlayNedTokens.brandGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    ),
                    child: const Icon(Icons.meeting_room_outlined, color: PlayNedTokens.brandGold, size: 20),
                  ),
                  const SizedBox(width: PlayNedTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("JOIN A ROOM", style: PlayNedTokens.gameTitle),
                        Text("Enter the 6-character multiplayer code", style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: PlayNedTokens.space20),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.0,
                  color: PlayNedTokens.brandGold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "CODE",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 20,
                    letterSpacing: 4.0,
                    color: PlayNedTokens.textMuted,
                  ),
                  counterText: "",
                  filled: true,
                  fillColor: PlayNedTokens.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: PlayNedTokens.space16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                    borderSide: const BorderSide(color: PlayNedTokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                    borderSide: const BorderSide(color: PlayNedTokens.brandGold, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _submitJoin(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: PlayNedTokens.space10),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(fontSize: 11.5, color: PlayNedTokens.terracotta),
                ),
              ],
              const SizedBox(height: PlayNedTokens.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlayNedButton(
                    label: "CANCEL",
                    variant: PlayNedButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: PlayNedTokens.space10),
                  PlayNedButton(
                    label: "JOIN ROOM",
                    variant: PlayNedButtonVariant.primary,
                    isLoading: _isLoading,
                    onPressed: _submitJoin,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Create Room Modal Dialog with customizable options
class CreateRoomDialog extends ConsumerStatefulWidget {
  final String? preselectedGameId;

  const CreateRoomDialog({super.key, this.preselectedGameId});

  @override
  ConsumerState<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<CreateRoomDialog> {
  late String _selectedGameId;
  String _selectedMode = 'online';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedGameId = widget.preselectedGameId ?? PlayNedGameRegistry.allGames.first.id;
  }

  Future<void> _handleCreate() async {
    setState(() => _isLoading = true);
    final game = PlayNedGameRegistry.getGame(_selectedGameId);
    if (game == null) return;

    try {
      final auth = ref.read(authProvider);
      final api = ref.read(platformApiServiceProvider);
      final hostName = auth.username ?? "Host Player";

      final room = await api.createRoom(
        gameId: game.id,
        playerName: hostName,
        playerId: auth.userId,
        roomType: _selectedMode,
        maxPlayers: game.maxPlayers,
      );

      if (mounted) {
        Navigator.of(context).pop();
        context.push('/room/${room.roomCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create room: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = PlayNedGameRegistry.getGame(_selectedGameId) ?? PlayNedGameRegistry.allGames.first;

    return Dialog(
      backgroundColor: PlayNedTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusLg),
        side: const BorderSide(color: PlayNedTokens.border, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(PlayNedTokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(PlayNedTokens.space8),
                    decoration: BoxDecoration(
                      color: PlayNedTokens.brandGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    ),
                    child: const Icon(Icons.add_box_outlined, color: PlayNedTokens.brandGold, size: 20),
                  ),
                  const SizedBox(width: PlayNedTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CREATE MULTIPLAYER ROOM", style: PlayNedTokens.gameTitle),
                        Text("Set up a new match and invite players", style: PlayNedTokens.bodyMuted.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: PlayNedTokens.space20),
              Text("SELECT GAME", style: PlayNedTokens.metadata),
              const SizedBox(height: PlayNedTokens.space8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: PlayNedTokens.space12),
                decoration: BoxDecoration(
                  color: PlayNedTokens.background,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
                  border: Border.all(color: PlayNedTokens.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGameId,
                    isExpanded: true,
                    dropdownColor: PlayNedTokens.surfaceElevated,
                    items: PlayNedGameRegistry.allGames.map((g) {
                      return DropdownMenuItem<String>(
                        value: g.id,
                        child: Row(
                          children: [
                            Icon(g.icon, size: 16, color: g.accentColor),
                            const SizedBox(width: PlayNedTokens.space10),
                            Text(g.name, style: PlayNedTokens.body.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGameId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: PlayNedTokens.space16),
              Text("ROOM TYPE", style: PlayNedTokens.metadata),
              const SizedBox(height: PlayNedTokens.space8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: _selectedMode == 'online',
                      showCheckmark: false,
                      avatar: Icon(Icons.wifi, size: 14, color: _selectedMode == 'online' ? PlayNedTokens.textInverse : PlayNedTokens.textSecondary),
                      label: const Text("ONLINE MULTIPLAYER"),
                      labelStyle: PlayNedTokens.buttonLabel.copyWith(
                        fontSize: 11,
                        color: _selectedMode == 'online' ? PlayNedTokens.textInverse : PlayNedTokens.textPrimary,
                      ),
                      selectedColor: PlayNedTokens.brandGold,
                      backgroundColor: PlayNedTokens.background,
                      onSelected: (_) => setState(() => _selectedMode = 'online'),
                    ),
                  ),
                  const SizedBox(width: PlayNedTokens.space10),
                  Expanded(
                    child: ChoiceChip(
                      selected: _selectedMode == 'local',
                      showCheckmark: false,
                      avatar: Icon(Icons.screen_rotation_alt, size: 14, color: _selectedMode == 'local' ? PlayNedTokens.textInverse : PlayNedTokens.textSecondary),
                      label: const Text("PASS & PLAY (LOCAL)"),
                      labelStyle: PlayNedTokens.buttonLabel.copyWith(
                        fontSize: 11,
                        color: _selectedMode == 'local' ? PlayNedTokens.textInverse : PlayNedTokens.textPrimary,
                      ),
                      selectedColor: PlayNedTokens.brandGold,
                      backgroundColor: PlayNedTokens.background,
                      onSelected: (_) => setState(() => _selectedMode = 'local'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PlayNedTokens.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlayNedButton(
                    label: "CANCEL",
                    variant: PlayNedButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: PlayNedTokens.space10),
                  PlayNedButton(
                    label: "CREATE ROOM",
                    variant: PlayNedButtonVariant.primary,
                    isLoading: _isLoading,
                    onPressed: _handleCreate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle geometric 2D grid background pattern
class PlayNedBackgroundPattern extends StatelessWidget {
  final Widget child;

  const PlayNedBackgroundPattern({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPatternPainter(),
      child: child,
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFFF1EBDD).withOpacity(0.022)
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
