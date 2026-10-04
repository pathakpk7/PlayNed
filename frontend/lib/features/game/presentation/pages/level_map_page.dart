import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/game_provider.dart';

class LevelMapPage extends ConsumerWidget {
  const LevelMapPage({super.key});

  String _getTierLabel(int level) {
    if (level <= 15) return "01 — FAMILIAR";
    if (level <= 30) return "16 — EASY";
    if (level <= 50) return "31 — MODERATE";
    if (level <= 70) return "51 — CHALLENGING";
    if (level <= 85) return "71 — HARD";
    if (level <= 95) return "86 — EXPERT";
    return "96 — HARDCORE EXPERT";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final currentUnlockedLevel = gameState.level;

    return Scaffold(
      appBar: AppBar(
        title: Text("CLASSIC 100 LEVELS", style: GoogleFonts.dmSerifDisplay()),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181816),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD5A84B), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_outline, color: Color(0xFFD5A84B), size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CURRENT PROGRESSION",
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFFD5A84B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "LEVEL $currentUnlockedLevel / 100",
                            style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFFF1EBDD)),
                          ),
                          Text(
                            _getTierLabel(currentUnlockedLevel),
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "LEVEL PROGRESSION LIST",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFFA9A396)),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 90,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      final levelNum = index + 1;
                      final isUnlocked = levelNum <= currentUnlockedLevel;
                      final isCurrent = levelNum == currentUnlockedLevel;

                      return Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFD5A84B).withOpacity(0.2)
                              : (isUnlocked ? const Color(0xFF181816) : const Color(0xFF11110F)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFFD5A84B)
                                : (isUnlocked ? const Color(0xFF2A2A26) : Colors.transparent),
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: isUnlocked
                              ? () {
                                  ref.read(gameProvider.notifier).startNewGame(
                                        mode: 'classic',
                                        level: levelNum,
                                        userId: ref.read(authProvider).userId,
                                      );
                                  context.push('/game/classic?level=$levelNum');
                                }
                              : null,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  levelNum < 10 ? "0$levelNum" : "$levelNum",
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 16,
                                    color: isCurrent
                                        ? const Color(0xFFD5A84B)
                                        : (isUnlocked ? const Color(0xFFF1EBDD) : const Color(0xFFA9A396).withOpacity(0.3)),
                                  ),
                                ),
                                if (isCurrent)
                                  Text(
                                    "PLAY",
                                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFFD5A84B)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
