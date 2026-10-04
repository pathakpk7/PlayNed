import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/game_provider.dart';

class CategoryItem {
  final String name;
  final String description;
  final IconData icon;

  const CategoryItem({
    required this.name,
    required this.description,
    required this.icon,
  });
}

const List<CategoryItem> presetCategories = [
  CategoryItem(name: "Technology", description: "Software, hardware, internet, computing, AI", icon: Icons.memory),
  CategoryItem(name: "Science", description: "Physics, chemistry, biology, scientific terms", icon: Icons.science),
  CategoryItem(name: "Nature", description: "Plants, landscapes, natural phenomena", icon: Icons.eco),
  CategoryItem(name: "Animals", description: "Mammals, birds, insects, marine life", icon: Icons.pets),
  CategoryItem(name: "Space", description: "Astronomy, planets, galaxies, space exploration", icon: Icons.public),
  CategoryItem(name: "Geography", description: "Places, landforms, geographical terms", icon: Icons.explore),
  CategoryItem(name: "Food & Cooking", description: "Ingredients, dishes, cooking terminology", icon: Icons.restaurant),
  CategoryItem(name: "Sports", description: "Sports, equipment, techniques, terminology", icon: Icons.sports_soccer),
  CategoryItem(name: "History", description: "Historical terms, civilizations, events", icon: Icons.history_edu),
  CategoryItem(name: "Medicine", description: "Anatomy, diseases, medical terminology", icon: Icons.local_hospital),
  CategoryItem(name: "Arts & Culture", description: "Art, literature, music, theatre", icon: Icons.palette),
  CategoryItem(name: "Business", description: "Finance, economics, commerce, management", icon: Icons.business_center),
];

class CategorySelectionPage extends ConsumerWidget {
  const CategorySelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("SELECT CATEGORY", style: GoogleFonts.dmSerifDisplay()),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181816),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD5A84B), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CATEGORICAL DEDUCTION",
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFFD5A84B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Choose a Vocabulary Domain",
                        style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFFF1EBDD)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Test your specialized terminology across 12 curated knowledge domains.",
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "AVAILABLE DOMAINS",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFFA9A396)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisExtent: 110,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: presetCategories.length,
                    itemBuilder: (context, index) {
                      final cat = presetCategories[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF181816),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2A2A26)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            ref.read(gameProvider.notifier).startNewGame(
                                  mode: 'category',
                                  category: cat.name,
                                  userId: authState.userId,
                                );
                            context.push('/game/category?cat=${Uri.encodeComponent(cat.name)}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD5A84B).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(cat.icon, color: const Color(0xFFD5A84B), size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD)),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        cat.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396), height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFA9A396)),
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
