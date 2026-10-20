import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Classified Dossier Card displaying the player's secret role and location.
class SpyfallRoleCardWidget extends StatefulWidget {
  final bool isSpy;
  final String? locationName;
  final String? category;
  final String? description;
  final List<String> themes;
  final bool initiallyConcealed;
  final VoidCallback? onToggleConceal;
  final VoidCallback? onBrowseLocations;

  const SpyfallRoleCardWidget({
    super.key,
    required this.isSpy,
    this.locationName,
    this.category,
    this.description,
    this.themes = const [],
    this.initiallyConcealed = false,
    this.onToggleConceal,
    this.onBrowseLocations,
  });

  @override
  State<SpyfallRoleCardWidget> createState() => _SpyfallRoleCardWidgetState();
}

class _SpyfallRoleCardWidgetState extends State<SpyfallRoleCardWidget> {
  late bool _concealed;

  @override
  void initState() {
    super.initState();
    _concealed = widget.initiallyConcealed;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isSpy ? PlayNedTokens.accentSpyfall : PlayNedTokens.brandGold;

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: PlayNedTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        border: Border.all(
          color: accent.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(PlayNedTokens.radiusMd - 1)),
              border: Border(bottom: BorderSide(color: accent.withOpacity(0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isSpy ? Icons.fingerprint : Icons.security,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TOP SECRET // CLASSIFIED',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    setState(() => _concealed = !_concealed);
                    widget.onToggleConceal?.call();
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          _concealed ? Icons.visibility : Icons.visibility_off,
                          size: 14,
                          color: PlayNedTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _concealed ? 'REVEAL' : 'HIDE',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PlayNedTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Dossier Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: _concealed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 36, color: PlayNedTokens.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            'DOSSIER CONCEALED',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PlayNedTokens.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "REVEAL" above to inspect your identity',
                            style: PlayNedTokens.metadata.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                : widget.isSpy
                    ? _buildSpyContent(accent)
                    : _buildExplorerContent(accent),
          ),
        ],
      ),
    );
  }

  Widget _buildSpyContent(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: accent),
              ),
              child: Icon(Icons.fingerprint, size: 28, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ACTIVE AGENT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'YOU ARE THE SPY',
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PlayNedTokens.background,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
            border: Border.all(color: PlayNedTokens.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR MISSION:',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: PlayNedTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• You do NOT know the secret location.\n'
                '• Listen attentively to other players\' questions and answers.\n'
                '• Give ambiguous, confident answers when asked.\n'
                '• Guess the secret location or survive without getting convicted!',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  height: 1.5,
                  color: PlayNedTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (widget.onBrowseLocations != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PlayNedButton(
              label: 'BROWSE ALL LOCATIONS',
              icon: Icons.map,
              variant: PlayNedButtonVariant.secondary,
              onPressed: widget.onBrowseLocations,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExplorerContent(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: accent),
              ),
              child: Icon(Icons.location_on, size: 28, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.category != null && widget.category!.isNotEmpty)
                    Text(
                      widget.category!.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  Text(
                    widget.locationName ?? 'CLASSIFIED LOCATION',
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: PlayNedTokens.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.description != null && widget.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.description!,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: PlayNedTokens.textMuted,
            ),
          ),
        ],
        if (widget.themes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.themes.map((theme) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PlayNedTokens.background,
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  border: Border.all(color: PlayNedTokens.borderSubtle),
                ),
                child: Text(
                  '#$theme',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    color: PlayNedTokens.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PlayNedTokens.background,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
            border: Border.all(color: PlayNedTokens.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR MISSION:',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: PlayNedTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• Ask questions that subtly prove you know the location.\n'
                '• Be careful not to be too specific or the Spy will figure it out!\n'
                '• Identify the Spy and call an accusation before time runs out.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  height: 1.5,
                  color: PlayNedTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
