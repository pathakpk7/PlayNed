import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hangman_reimagined/features/auth/presentation/providers/auth_provider.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/platform_app_bar.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool soundFx = true;
  bool music = true;
  bool haptics = true;
  bool reducedMotion = false;
  bool highContrast = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: PlayNedTokens.background,
      appBar: const PlatformAppBar(title: "SETTINGS"),
      body: PlayNedBackgroundPattern(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              children: [
                // Header
                Text(
                  "SETTINGS & PREFERENCES",
                  style: PlayNedTokens.metadata.copyWith(color: PlayNedTokens.brandGold),
                ),
                const SizedBox(height: 4),
                Text("Customize your experience", style: PlayNedTokens.heroDisplay.copyWith(fontSize: 26)),
                const SizedBox(height: 24),

                // 1. Audio & Haptics Group
                _buildSettingsSection(
                  title: "AUDIO & SENSORY",
                  icon: Icons.volume_up_outlined,
                  children: [
                    _buildSwitchTile(
                      title: "Sound Effects",
                      subtitle: "Audio cues for piece moves, clicks, buzzer & dice rolls",
                      value: soundFx,
                      onChanged: (v) => setState(() => soundFx = v),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      title: "Background Ambience",
                      subtitle: "Subtle thematic background soundtrack in games",
                      value: music,
                      onChanged: (v) => setState(() => music = v),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      title: "Haptic Feedback",
                      subtitle: "Vibrate mobile device on turns, captures & wrong guesses",
                      value: haptics,
                      onChanged: (v) => setState(() => haptics = v),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Accessibility & Motion Group
                _buildSettingsSection(
                  title: "ACCESSIBILITY & DISPLAY",
                  icon: Icons.accessibility_new_outlined,
                  children: [
                    _buildSwitchTile(
                      title: "Reduced Motion",
                      subtitle: "Minimize animations, transitions and floating visual elements",
                      value: reducedMotion,
                      onChanged: (v) => setState(() => reducedMotion = v),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      title: "High Contrast Mode",
                      subtitle: "Increase borders and text contrast for board visibility",
                      value: highContrast,
                      onChanged: (v) => setState(() => highContrast = v),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Account & Sync Group
                _buildSettingsSection(
                  title: "ACCOUNT & SYNC",
                  icon: Icons.person_outline,
                  children: [
                    ListTile(
                      title: Text(
                        auth.isLoggedIn ? (auth.username ?? "Player") : "Guest Mode",
                        style: PlayNedTokens.buttonLabel.copyWith(color: PlayNedTokens.textPrimary),
                      ),
                      subtitle: Text(
                        auth.isLoggedIn ? "Authenticated with Neon Database" : "Scores and game statistics are saved locally on this device",
                        style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11.5),
                      ),
                      trailing: PlayNedButton(
                        label: auth.isLoggedIn ? "VIEW PROFILE" : "SIGN IN",
                        variant: PlayNedButtonVariant.outlined,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        onPressed: () {
                          if (auth.isLoggedIn) {
                            context.push('/profile');
                          } else {
                            context.push('/auth');
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. About & Platform Group
                _buildSettingsSection(
                  title: "ABOUT PLAYNED",
                  icon: Icons.info_outline,
                  children: [
                    ListTile(
                      title: Text("App Version", style: PlayNedTokens.body.copyWith(fontWeight: FontWeight.w600)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: PlayNedTokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(PlayNedTokens.radiusXs),
                          border: Border.all(color: PlayNedTokens.border),
                        ),
                        child: Text("v1.4.3", style: PlayNedTokens.metadata.copyWith(color: PlayNedTokens.brandGold)),
                      ),
                    ),
                    _buildDivider(),
                    ListTile(
                      title: Text("Linguistic Data & Lexicon", style: PlayNedTokens.body.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text("dwyl/english-words, wordfreq & NLTK WordNet curated dictionary", style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11.5)),
                    ),
                    _buildDivider(),
                    ListTile(
                      title: Text("Multiplayer Engine", style: PlayNedTokens.body.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text("Python FastAPI, WebSocket Rooms, Neon PostgreSQL", style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11.5)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: PlayNedTokens.brandGold),
            const SizedBox(width: 8),
            Text(
              title,
              style: PlayNedTokens.metadata.copyWith(
                fontSize: 11,
                color: PlayNedTokens.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: PlayNedTokens.surface,
            borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
            border: Border.all(color: PlayNedTokens.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: PlayNedTokens.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: PlayNedTokens.bodyMuted.copyWith(fontSize: 11.5)),
      value: value,
      activeColor: PlayNedTokens.brandGold,
      activeTrackColor: PlayNedTokens.brandGold.withOpacity(0.35),
      inactiveThumbColor: PlayNedTokens.textSecondary,
      inactiveTrackColor: PlayNedTokens.surfaceElevated,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: PlayNedTokens.borderSubtle,
    );
  }
}
