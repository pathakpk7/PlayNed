import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../game/presentation/providers/game_provider.dart';
import '../../../../platform/presentation/widgets/playned_logo.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _showTimerSelectionDialog(BuildContext context, WidgetRef ref, String? userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181816),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFD5A84B), width: 1.5),
        ),
        title: Text(
          "SELECT TIMED DURATION",
          style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select countdown duration for this game:",
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
            ),
            const SizedBox(height: 16),
            _TimerOptionTile(
              label: "30 SECONDS — BLITZ",
              icon: Icons.bolt,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(gameProvider.notifier).startNewGame(mode: 'timed', userId: userId);
                context.push('/game/timed?duration=30');
              },
            ),
            const SizedBox(height: 8),
            _TimerOptionTile(
              label: "60 SECONDS — STANDARD",
              icon: Icons.timer,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(gameProvider.notifier).startNewGame(mode: 'timed', userId: userId);
                context.push('/game/timed?duration=60');
              },
            ),
            const SizedBox(height: 8),
            _TimerOptionTile(
              label: "90 SECONDS — EXTENDED",
              icon: Icons.hourglass_top,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(gameProvider.notifier).startNewGame(mode: 'timed', userId: userId);
                context.push('/game/timed?duration=90');
              },
            ),
            const SizedBox(height: 8),
            _TimerOptionTile(
              label: "120 SECONDS — RELAXED",
              icon: Icons.hourglass_bottom,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(gameProvider.notifier).startNewGame(mode: 'timed', userId: userId);
                context.push('/game/timed?duration=120');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          tooltip: "Return to PlayNed",
          onPressed: () => context.go('/'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlayNedLogo(size: 24, showText: false),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "HANGMAN REIMAGINED",
                  style: GoogleFonts.dmSerifDisplay(
                    letterSpacing: 1.5,
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  "BY PLAYNED",
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFFD5A84B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined, size: 20),
            tooltip: "Vocabulary Vault (Codex)",
            onPressed: () => context.push('/codex'),
          ),
          IconButton(
            icon: Icon(authState.isLoggedIn ? Icons.account_circle_outlined : Icons.login_outlined, size: 20),
            tooltip: authState.isLoggedIn ? authState.username : "Login / Sign Up",
            onPressed: () {
              if (authState.isLoggedIn) {
                context.push('/profile');
              } else {
                context.push('/auth');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 20),
            tooltip: "Profile",
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: "Settings",
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181816),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A26)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "HANGMAN REIMAGINED",
                            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "/'haŋmən/",
                            style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFFD5A84B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "— by PlayNed",
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "A game of deduction in which each incorrect guess brings the player closer to defeat.",
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396), height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Hero Mode 1: Classic Mode (100 Levels)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    final targetLvl = gameState.level > 0 ? gameState.level : 1;
                    ref.read(gameProvider.notifier).startNewGame(mode: 'classic', level: targetLvl, userId: authState.userId);
                    context.push('/game/classic?level=$targetLvl');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181816),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD5A84B), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "01 — CLASSIC MODE",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: const Color(0xFFD5A84B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD5A84B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "LEVEL ${gameState.level} / 100",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD5A84B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Climb 100 levels from familiar words to brutal vocabulary.",
                          style: GoogleFonts.dmSerifDisplay(fontSize: 17, color: const Color(0xFFF1EBDD)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                              onPressed: () => context.push('/levels'),
                              icon: const Icon(Icons.map_outlined, size: 14, color: Color(0xFFA9A396)),
                              label: Text("Level Map", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                            ),
                            Row(
                              children: [
                                Text(
                                  "PLAY NOW",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: const Color(0xFFD5A84B),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, size: 14, color: Color(0xFFD5A84B)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Section Header
                Text(
                  "CHOOSE YOUR CHALLENGE",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFFA9A396),
                  ),
                ),
                const SizedBox(height: 8),

                // Ultra-Compact 2 Row x 2 Column Grid of Themed Cards
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Mode 02: Timed Mode
                    _EditorialModeCard(
                      number: "02",
                      title: "Timed Mode",
                      description: "Choose 30s-120s timer.",
                      badgeText: "30s-120s",
                      icon: Icons.timer_outlined,
                      accentColor: const Color(0xFFD5A84B),
                      backgroundColor: const Color(0xFF221A0F),
                      onTap: () {
                        _showTimerSelectionDialog(context, ref, authState.userId);
                      },
                    ),

                    // Mode 03: Daily Challenge
                    _EditorialModeCard(
                      number: "03",
                      title: "Daily Challenge",
                      description: "Global word updated daily.",
                      badgeText: "GLOBAL WORD",
                      icon: Icons.calendar_today_outlined,
                      accentColor: const Color(0xFFC47B5A),
                      backgroundColor: const Color(0xFF221814),
                      onTap: () {
                        ref.read(gameProvider.notifier).startNewGame(mode: 'daily', userId: authState.userId);
                        context.push('/game/daily');
                      },
                    ),

                    // Mode 04: Category Mode
                    _EditorialModeCard(
                      number: "04",
                      title: "Category Mode",
                      description: "12 specialized preset domains.",
                      badgeText: "12 DOMAINS",
                      icon: Icons.category_outlined,
                      accentColor: const Color(0xFF5A8BC4),
                      backgroundColor: const Color(0xFF141A24),
                      onTap: () {
                        context.push('/categories');
                      },
                    ),

                    // Mode 05: 1v1 Room Duel
                    _EditorialModeCard(
                      number: "05",
                      title: "1v1 Room Duel",
                      description: "Turn-based 2-player duels.",
                      badgeText: "VERSUS ROOM",
                      icon: Icons.groups_outlined,
                      accentColor: const Color(0xFF67A87A),
                      backgroundColor: const Color(0xFF142218),
                      onTap: () {
                        context.push('/multiplayer');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TimerOptionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11110F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A2A26)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFD5A84B)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFA9A396)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialModeCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final String badgeText;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _EditorialModeCard({
    required this.number,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Faded Watermark Graphic in Bottom Right
            Positioned(
              right: -8,
              bottom: -8,
              child: Icon(
                icon,
                size: 54,
                color: accentColor.withOpacity(0.08),
              ),
            ),
            // Card Contents
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              number,
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                badgeText.toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: accentColor),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(icon, size: 12, color: accentColor),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSerifDisplay(fontSize: 14, color: const Color(0xFFF1EBDD)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFFA9A396)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
