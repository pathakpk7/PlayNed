import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/session/client_session.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../models/game_model.dart';
import '../../registry/game_registry.dart';
import '../../services/platform_api_service.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

enum PlayNedButtonVariant { primary, secondary, outlined, ghost }

/// High-precision interactive button with fluid micro-physics
class PlayNedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PlayNedButtonVariant variant;
  final Color? customAccent;
  final Color? accentColor;
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
    this.accentColor,
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
    final accent = widget.accentColor ?? widget.customAccent ?? PlayNedTokens.brandGold;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    BorderSide border;

    switch (widget.variant) {
      case PlayNedButtonVariant.primary:
        bg = _isPressed
            ? accent.withOpacity(0.88)
            : (_isHovered ? PlayNedTokens.brandGoldBright : accent);
        fg = PlayNedTokens.textInverse;
        border = BorderSide.none;
        break;
      case PlayNedButtonVariant.secondary:
        bg = _isPressed
            ? PlayNedTokens.surfaceHover
            : (_isHovered ? PlayNedTokens.surfaceElevated : PlayNedTokens.surface);
        fg = _isHovered ? PlayNedTokens.textPrimary : PlayNedTokens.textSecondary;
        border = BorderSide(
          color: _isHovered ? PlayNedTokens.borderBright : PlayNedTokens.border,
          width: 1,
        );
        break;
      case PlayNedButtonVariant.outlined:
        bg = _isHovered ? accent.withOpacity(0.08) : Colors.transparent;
        fg = _isHovered ? PlayNedTokens.textPrimary : accent;
        border = BorderSide(
          color: _isHovered ? accent : accent.withOpacity(0.5),
          width: 1.2,
        );
        break;
      case PlayNedButtonVariant.ghost:
        bg = _isHovered ? PlayNedTokens.surfaceHover : Colors.transparent;
        fg = _isHovered ? PlayNedTokens.textPrimary : PlayNedTokens.textSecondary;
        border = BorderSide.none;
        break;
    }

    final scale = _isPressed ? 0.98 : (_isHovered ? 1.015 : 1.0);

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => isEnabled ? setState(() => _isPressed = true) : null,
        onTapUp: (_) => isEnabled ? setState(() => _isPressed = false) : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: PlayNedTokens.animMicro,
          curve: PlayNedTokens.animCurve,
          child: AnimatedContainer(
            duration: PlayNedTokens.animFast,
            curve: PlayNedTokens.animCurve,
            width: widget.width,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isEnabled ? bg : PlayNedTokens.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
              border: Border.fromBorderSide(border),
            ),
            child: Row(
              mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: PlayNedTokens.buttonLabel.copyWith(
                    color: fg,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized tactile container card for platform pages
class PlayNedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const PlayNedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PlayNedTokens.space20),
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  State<PlayNedCard> createState() => _PlayNedCardState();
}

class _PlayNedCardState extends State<PlayNedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: widget.borderColor ?? (_isHovered ? PlayNedTokens.borderBright : PlayNedTokens.borderSubtle),
      width: 1,
    );

    final cardContent = AnimatedContainer(
      duration: PlayNedTokens.animFast,
      curve: PlayNedTokens.animCurve,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? (_isHovered ? PlayNedTokens.surfaceElevated : PlayNedTokens.surface),
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: border,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return cardContent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: cardContent,
      ),
    );
  }
}

/// Typographic category tag without rounded pill clichés
class GameCategoryBadge extends StatelessWidget {
  final String category;
  final Color? accentColor;

  const GameCategoryBadge({super.key, required this.category, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? PlayNedTokens.brandGold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: PlayNedTokens.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
      ],
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
        ? (minPlayers == 1 ? "1 player" : "$minPlayers players")
        : "$minPlayers–$maxPlayers players";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          minPlayers == 1 ? Icons.person_outline : Icons.group_outlined,
          size: 14,
          color: PlayNedTokens.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: PlayNedTokens.textMuted,
          ),
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
        const Icon(Icons.schedule, size: 13, color: PlayNedTokens.textMuted),
        const SizedBox(width: 4),
        Text(
          "~$minutes min",
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: PlayNedTokens.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Editorial Section Header without generic uppercase eyebrows or full stops
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? tag; // kept for compatibility, rendered subtly
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PlayNedTokens.sectionHeading,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: PlayNedTokens.bodyMuted,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ],
    );
  }
}

/// Join Room Modal Dialog
class JoinRoomDialog extends ConsumerStatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  ConsumerState<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<JoinRoomDialog> {
  final _controller = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final session = ref.read(clientSessionProvider);
    _nameController.text = session.playerName;
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitJoin() async {
    final code = _controller.text.trim().toUpperCase().replaceAll(' ', '');
    if (code.length < 4) {
      setState(() => _errorMessage = "Please enter a valid room code (e.g. AB12CD)");
      return;
    }

    final customName = _nameController.text.trim();
    if (customName.isNotEmpty) {
      await ref.read(clientSessionProvider).setGuestName(customName);
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = ref.read(clientSessionProvider);
      final api = ref.read(platformApiServiceProvider);
      
      PlatformRoom room;
      try {
        room = await api.joinRoom(
          roomCode: code,
          playerName: session.playerName,
          playerId: session.playerId,
        );
      } catch (_) {
        room = await api.getRoom(code);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        context.push('/room/${room.roomCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Room '$code' not found or expired. Check the code and try again";
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
        side: const BorderSide(color: PlayNedTokens.border, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(PlayNedTokens.space28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Join a match",
                    style: PlayNedTokens.sectionHeading.copyWith(fontSize: 22),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Enter the 6-character code shared by your host",
                style: PlayNedTokens.bodyMuted,
              ),
              const SizedBox(height: PlayNedTokens.space16),
              Text(
                "YOUR PLAYER NAME",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: PlayNedTokens.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: GoogleFonts.inter(color: PlayNedTokens.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Enter your display name",
                  hintStyle: GoogleFonts.inter(color: PlayNedTokens.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: PlayNedTokens.background,
                  prefixIcon: const Icon(Icons.person_outline, color: PlayNedTokens.brandGold, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    borderSide: const BorderSide(color: PlayNedTokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    borderSide: const BorderSide(color: PlayNedTokens.brandGold, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: PlayNedTokens.space16),
              Text(
                "ROOM CODE",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: PlayNedTokens.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8.0,
                  color: PlayNedTokens.brandGold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "CODE",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    letterSpacing: 6.0,
                    color: PlayNedTokens.textMuted,
                  ),
                  counterText: "",
                  filled: true,
                  fillColor: PlayNedTokens.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    borderSide: const BorderSide(color: PlayNedTokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                    borderSide: const BorderSide(color: PlayNedTokens.brandGold, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _submitJoin(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(fontSize: 12, color: PlayNedTokens.terracotta),
                ),
              ],
              const SizedBox(height: PlayNedTokens.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlayNedButton(
                    label: "Cancel",
                    variant: PlayNedButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  PlayNedButton(
                    label: "Join match",
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
      final session = ref.read(clientSessionProvider);
      final api = ref.read(platformApiServiceProvider);
      final hostName = session.playerName;
      final hostId = session.playerId;

      final room = await api.createRoom(
        gameId: game.id,
        playerName: hostName,
        playerId: hostId,
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
        side: const BorderSide(color: PlayNedTokens.border, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(PlayNedTokens.space28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Create a table",
                    style: PlayNedTokens.sectionHeading.copyWith(fontSize: 22),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: PlayNedTokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Select a title and launch your match room",
                style: PlayNedTokens.bodyMuted,
              ),
              const SizedBox(height: PlayNedTokens.space24),
              Text(
                "Choose game",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PlayNedTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: PlayNedTokens.background,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
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
                            const SizedBox(width: 10),
                            Text(
                              g.name,
                              style: PlayNedTokens.body.copyWith(fontWeight: FontWeight.w500),
                            ),
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
              const SizedBox(height: PlayNedTokens.space20),
              Text(
                "Mode",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PlayNedTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ModeSelectButton(
                      label: "Online multiplayer",
                      icon: Icons.wifi,
                      isSelected: _selectedMode == 'online',
                      onTap: () => setState(() => _selectedMode = 'online'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeSelectButton(
                      label: "Pass & play",
                      icon: Icons.screen_rotation_alt,
                      isSelected: _selectedMode == 'local',
                      onTap: () => setState(() => _selectedMode = 'local'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PlayNedTokens.space28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlayNedButton(
                    label: "Cancel",
                    variant: PlayNedButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  PlayNedButton(
                    label: "Launch room",
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

class _ModeSelectButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSelectButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PlayNedTokens.animFast,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? PlayNedTokens.brandGold.withOpacity(0.12) : PlayNedTokens.background,
          borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
          border: Border.all(
            color: isSelected ? PlayNedTokens.brandGold : PlayNedTokens.border,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? PlayNedTokens.brandGold : PlayNedTokens.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? PlayNedTokens.brandGold : PlayNedTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle ambient canvas illumination without artificial noise or grain
class PlayNedBackgroundPattern extends StatelessWidget {
  final Widget child;

  const PlayNedBackgroundPattern({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: PlayNedTokens.background,
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  PlayNedTokens.brandGold.withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  PlayNedTokens.brandElectric.withOpacity(0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
