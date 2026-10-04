import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../game/presentation/providers/game_provider.dart';

final codexFutureProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  final userId = params['userId'] ?? '';
  final query = params['query'];
  final category = params['category'];
  return api.getUserCodex(userId, query: query, category: category);
});

class CodexPage extends ConsumerStatefulWidget {
  const CodexPage({super.key});

  @override
  ConsumerState<CodexPage> createState() => _CodexPageState();
}

class _CodexPageState extends ConsumerState<CodexPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Technology',
    'Science',
    'Nature',
    'Animals',
    'Space',
    'Geography',
    'Food & Cooking',
    'Sports',
    'History',
    'Medicine',
    'Arts & Culture',
    'Business',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isLoggedIn || authState.userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("VOCABULARY VAULT", style: GoogleFonts.dmSerifDisplay())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book_outlined, size: 56, color: Color(0xFFA9A396)),
                const SizedBox(height: 16),
                Text(
                  "Log in to unlock and browse your personal Vocabulary Vault.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF1EBDD)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final queryParams = {
      'userId': authState.userId!,
      'query': _searchController.text,
      'category': _selectedCategory,
    };

    final codexAsync = ref.watch(codexFutureProvider(queryParams));

    return Scaffold(
      appBar: AppBar(
        title: Text("VOCABULARY VAULT", style: GoogleFonts.dmSerifDisplay()),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Stat Container
                codexAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181816),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD5A84B), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_added_outlined, color: Color(0xFFD5A84B), size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PERSONAL LEXICON RECORD",
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFFD5A84B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${data['total_unlocked'] ?? 0} WORDS ENCOUNTERED  ·  ${data['total_mastered'] ?? 0} MASTERED",
                              style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFFF1EBDD)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search unlocked vocabulary...",
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFA9A396)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFA9A396)),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Filter Pills
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(
                          cat.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF11110F) : const Color(0xFFF1EBDD),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFD5A84B),
                        backgroundColor: const Color(0xFF181816),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Word List View
                Expanded(
                  child: codexAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD5A84B))),
                    error: (err, _) => Center(child: Text("Error loading codex: $err", style: const TextStyle(color: Color(0xFFB95745)))),
                    data: (data) {
                      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            "No words found in your codex yet. Play Classic, Timed, or Category mode to unlock vocabulary!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFA9A396)),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final word = item['word'] ?? '';
                          final cat = item['category'] ?? 'General';
                          final pos = item['part_of_speech'] ?? 'noun';
                          final def = item['definition'] ?? '';
                          final sentence = item['example_sentence'] ?? '';
                          final status = item['mastery_status'] ?? 'learning';
                          final isMastered = status == 'mastered';
                          final timesEncountered = item['times_encountered'] ?? 1;
                          final timesWon = item['times_won'] ?? 0;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181816),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isMastered ? const Color(0xFFD5A84B).withOpacity(0.4) : const Color(0xFF2A2A26)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          word.toUpperCase(),
                                          style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "[$pos]",
                                          style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFFD5A84B)),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isMastered ? const Color(0xFFD5A84B).withOpacity(0.15) : const Color(0xFF2A2A26),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: isMastered ? const Color(0xFFD5A84B) : const Color(0xFF4A4A44)),
                                      ),
                                      child: Text(
                                        isMastered ? "MASTERED" : "LEARNING",
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isMastered ? const Color(0xFFD5A84B) : const Color(0xFFA9A396),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  def,
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1EBDD), height: 1.3),
                                ),
                                if (sentence.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "\"$sentence\"",
                                    style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFFA9A396)),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A26),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        cat.toUpperCase(),
                                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFA9A396)),
                                      ),
                                    ),
                                    Text(
                                      "Encountered $timesEncountered times  ·  $timesWon wins",
                                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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
