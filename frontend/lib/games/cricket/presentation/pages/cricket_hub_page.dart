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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1560),
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

                const SizedBox(height: 24),

                // 🔥 FEATURED HERO CARD: IPL MINI AUCTION
                _buildFeaturedAuctionHero(context),

                const SizedBox(height: 32),

                Text(
                  "ALL CRICKET MODES",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: const Color(0xFFE5A93C),
                  ),
                ),
                const SizedBox(height: 16),

                // Responsive 2-Column Grid on Desktop
                LayoutBuilder(
                  builder: (context, constraints) {
                    final modeCards = [
                      _buildModeCard(
                        context,
                        title: "IPL MINI AUCTION",
                        tagline: "10-Franchise War Room, ₹120 Cr Purse & Live Bidding Wars.",
                        description:
                            "Lead your franchise in an authentic IPL-style auction. Draft marquee icons, execute strategic retention salary slabs, battle intelligent AI franchises for 160+ active cricket stars, and assemble a title-winning 18–25 player squad with Playing XI & Impact Player optimization.",
                        icon: Icons.gavel,
                        accentColor: const Color(0xFFE5A93C),
                        chips: ["10 Franchises", "₹120 Cr Purse", "Marquee Icons", "Bidding Wars", "Impact Player"],
                        onPlayLocal: () => context.push('/games/cricket/auction'),
                        onPlayOnline: () => context.push('/games/cricket'),
                      ),
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
                        onPlayOnline: null,
                      ),
                    ];

                    if (constraints.maxWidth >= 860) {
                      return Column(
                        children: [
                          // Featured IPL Mini Auction Card
                          modeCards[0],
                          const SizedBox(height: 16),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: modeCards[1]),
                                const SizedBox(width: 16),
                                Expanded(child: modeCards[2]),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: modeCards[3]),
                                const SizedBox(width: 16),
                                Expanded(child: modeCards[4]),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: modeCards
                          .map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedAuctionHero(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 28 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF261904), Color(0xFF191305), Color(0xFF0F1E16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5A93C), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A93C).withOpacity(0.18),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, size: 14, color: Color(0xFF0F1E16)),
                    const SizedBox(width: 4),
                    Text(
                      "MAJOR NEW FEATURE",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: const Color(0xFF0F1E16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "FRANCHISE MANAGEMENT SIMULATOR",
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFFC3BCAC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
                ),
                child: const Icon(Icons.gavel, color: Color(0xFFE5A93C), size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "IPL MINI AUCTION WAR ROOM",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: isDesktop ? 26 : 22,
                        color: const Color(0xFFF1EBDD),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹120 Cr Purse • 10 Franchises • 165+ Active Players • Marquee Draft • Live AI Bidding",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFE5A93C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Draft your franchise squad for the 2025–2027 season! Retain legends or pick from the elite Marquee pool featuring MS Dhoni, Shreyas Iyer, Ishan Kishan, Virat Kohli, and Jasprit Bumrah. Battle 9 distinct AI personalities in gavel-by-gavel bidding wars, manage capped/overseas limits, and build your ultimate Playing XI & Impact Player.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFFA9A396),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureBadge("10 Fictional Franchises", Icons.shield_outlined),
              _buildFeatureBadge("₹120.0 Cr Base Purse", Icons.account_balance_wallet_outlined),
              _buildFeatureBadge("MS Dhoni & Marquee Icons", Icons.workspace_premium_outlined),
              _buildFeatureBadge("165+ Active Stars", Icons.group_outlined),
              _buildFeatureBadge("Smart AI War Room", Icons.psychology_outlined),
              _buildFeatureBadge("Playing XI & Awards", Icons.emoji_events_outlined),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/games/cricket/auction'),
            icon: const Icon(Icons.gavel, size: 18),
            label: Text(
              "ENTER AUCTION WAR ROOM (START DRAFT)",
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A93C),
              foregroundColor: const Color(0xFF0F1E16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2C22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF284835)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFE5A93C)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFFC3BCAC),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    final isAuction = title == "IPL MINI AUCTION";
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121F18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAuction ? const Color(0xFFE5A93C).withOpacity(0.7) : const Color(0xFF233B2E),
          width: isAuction ? 1.6 : 1.2,
        ),
        boxShadow: isAuction
            ? [
                BoxShadow(
                  color: const Color(0xFFE5A93C).withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                        Row(
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 18,
                                color: const Color(0xFFF1EBDD),
                              ),
                            ),
                            if (isAuction) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A93C),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "NEW",
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F1E16),
                                  ),
                                ),
                              ),
                            ],
                          ],
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
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPlayLocal,
                  icon: Icon(isAuction ? Icons.gavel : Icons.sports_esports_outlined, size: 16),
                  label: Text(
                    onPlayOnline == null
                        ? "START CHALLENGES"
                        : (isAuction ? "ENTER AUCTION WAR ROOM" : "LOCAL DUEL"),
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
