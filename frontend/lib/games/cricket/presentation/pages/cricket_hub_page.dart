import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../platform/presentation/widgets/platform_app_bar.dart';

class CricketHubPage extends ConsumerStatefulWidget {
  const CricketHubPage({super.key});

  @override
  ConsumerState<CricketHubPage> createState() => _CricketHubPageState();
}

class _CricketHubPageState extends ConsumerState<CricketHubPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1410),
      appBar: const PlatformAppBar(title: "CRICKET HUB"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner / Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF142E20), Color(0xFF0F1E16)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF28543A), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5A93C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.sports_cricket,
                          color: Color(0xFFE5A93C),
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PLAYNED CRICKET ARENA",
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 24,
                                color: const Color(0xFFF1EBDD),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Experience high-intensity 6-ball Super Over duels, tactical Stat Clash squad drafting, and expansive trivia challenges.",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFA9A396),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  "SELECT CRICKET MODE",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: const Color(0xFFE5A93C),
                  ),
                ),
                const SizedBox(height: 16),

                // MODE 1: Super Over Duel
                _buildModeCard(
                  context,
                  title: "SUPER OVER DUEL",
                  tagline: "6 Balls. 2 Batters. 1 Bowler. Pure Tactical Cricket.",
                  description:
                      "Pick 2 batsmen and 1 bowler from our authentic cricket legend database. Bowl tactical deliveries (Yorker, Bouncer, Good Length, Slower) and counter with strategic shots (Defend, Normal, Attack, Loft) in a head-to-head 6-ball innings.",
                  icon: Icons.sports_cricket,
                  accentColor: const Color(0xFFE5A93C),
                  chips: ["Tactical 1v1", "6 Legal Balls", "Local & Online"],
                  onPlayLocal: () => context.push('/games/cricket/super-over?mode=local'),
                  onPlayOnline: () => context.push('/games/cricket'),
                ),

                const SizedBox(height: 16),

                // MODE 2: Stat Clash
                _buildModeCard(
                  context,
                  title: "STAT CLASH",
                  tagline: "Draft the ultimate 5-player squad without crossing the target.",
                  description:
                      "Test your cricket statistical knowledge! Target milestones like 12,000 ODI runs, 600 wickets, or 750 international sixes. Draft a 5-legend squad closest to the mark. Exceeding the target causes a Bust!",
                  icon: Icons.analytics_outlined,
                  accentColor: const Color(0xFF4E89FF),
                  chips: ["Squad Drafting", "Real Stats", "Best of 3 / 5"],
                  onPlayLocal: () => context.push('/games/cricket/stat-clash?mode=local'),
                  onPlayOnline: () => context.push('/games/cricket'),
                ),

                const SizedBox(height: 16),

                // MODE 3: Cricket Draft
                _buildModeCard(
                  context,
                  title: "CRICKET DRAFT",
                  tagline: "100-Credit Budget Draft & 5-Over Simulated Clash.",
                  description:
                      "Build your dream squad within a strict 100-credit budget cap. Draft 2 Batters, 1 All-Rounder, 1 Bowler, and 1 Wicket-Keeper in a strategic turn-based snake draft. Inspect detailed multi-format career stats (Test, ODI, T20I), review tactical ratings, and simulate a 5-over clash!",
                  icon: Icons.groups_2_outlined,
                  accentColor: const Color(0xFFE056FD),
                  chips: ["100 Credit Cap", "Role Constraints", "5-Over Match Sim", "Multi-Format Stats"],
                  onPlayLocal: () => context.push('/games/cricket/draft?mode=local'),
                  onPlayOnline: () => context.push('/games/cricket'),
                ),

                const SizedBox(height: 16),

                // MODE 4: Cricket Challenge Hub
                _buildModeCard(
                  context,
                  title: "CRICKET CHALLENGE HUB",
                  tagline: "5 Interactive Mini-Games & Trivia Quizzes.",
                  description:
                      "Put your cricketing acumen to the test across 5 exciting game formats: Who Am I?, Higher or Lower, Stat or Fiction, Career Timelines, and Guess the Player.",
                  icon: Icons.extension_outlined,
                  accentColor: const Color(0xFF48BB78),
                  chips: ["5 Mini-Games", "Trivia & Records", "Streak Master"],
                  onPlayLocal: () => context.push('/games/cricket/challenges'),
                  onPlayOnline: null, // Solo challenge hub
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String tagline,
    required String description,
    required IconData icon,
    required Color accentColor,
    required List<String> chips,
    required VoidCallback onPlayLocal,
    VoidCallback? onPlayOnline,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF233B2E), width: 1.2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withOpacity(0.4)),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 18,
                        color: const Color(0xFFF1EBDD),
                      ),
                    ),
                    Text(
                      tagline,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFA9A396),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: chips.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2C22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF284835)),
                ),
                child: Text(
                  c,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFC3BCAC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPlayLocal,
                  icon: const Icon(Icons.sports_esports_outlined, size: 16),
                  label: Text(
                    onPlayOnline == null ? "START CHALLENGES" : "LOCAL DUEL",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: const Color(0xFF0F1E16),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (onPlayOnline != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPlayOnline,
                    icon: const Icon(Icons.wifi, size: 16),
                    label: Text(
                      "ONLINE LOBBY",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF1EBDD),
                      side: const BorderSide(color: Color(0xFF3B614B)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
