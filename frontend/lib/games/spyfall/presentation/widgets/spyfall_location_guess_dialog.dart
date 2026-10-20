import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hangman_reimagined/games/spyfall/services/spyfall_engine.dart';
import 'package:hangman_reimagined/platform/presentation/widgets/playned_components.dart';
import 'package:hangman_reimagined/platform/theme/playned_design_tokens.dart';

/// Modal dialog for browsing locations or guessing the location as the Spy.
class SpyfallLocationGuessDialog extends StatefulWidget {
  final bool isGuessMode; // true = Spy submitting guess; false = reference lookup
  final ValueChanged<String>? onGuessSubmitted;

  const SpyfallLocationGuessDialog({
    super.key,
    this.isGuessMode = false,
    this.onGuessSubmitted,
  });

  @override
  State<SpyfallLocationGuessDialog> createState() => _SpyfallLocationGuessDialogState();
}

class _SpyfallLocationGuessDialogState extends State<SpyfallLocationGuessDialog> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _selectedLocationName;

  static const List<String> _categories = [
    'All',
    'Public Places',
    'Transport & Travel',
    'Professional Environments',
    'Leisure & Entertainment',
    'Everyday & Unusual',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredLocations = kSpyfallDefaultLocations.where((loc) {
      final matchesCategory = _selectedCategory == 'All' || loc.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          loc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loc.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final accent = widget.isGuessMode ? PlayNedTokens.accentSpyfall : PlayNedTokens.brandGold;

    return Dialog(
      backgroundColor: PlayNedTokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayNedTokens.radiusMd),
        side: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              children: [
                Icon(
                  widget.isGuessMode ? Icons.my_location : Icons.map_outlined,
                  color: accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.isGuessMode ? 'GUESS SECRET LOCATION' : 'LOCATIONS REFERENCE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: PlayNedTokens.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (widget.isGuessMode) ...[
              const SizedBox(height: 4),
              Text(
                'Choose the location you believe is the secret location. A correct guess wins the round (+3 pts)!',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  color: PlayNedTokens.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.spaceGrotesk(fontSize: 13, color: PlayNedTokens.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: GoogleFonts.spaceGrotesk(fontSize: 13, color: PlayNedTokens.textMuted),
                prefixIcon: const Icon(Icons.search, size: 18, color: PlayNedTokens.textMuted),
                isDense: true,
                filled: true,
                fillColor: PlayNedTokens.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  borderSide: const BorderSide(color: PlayNedTokens.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  borderSide: const BorderSide(color: PlayNedTokens.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                  borderSide: BorderSide(color: accent),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        cat,
                        style: GoogleFonts.spaceMono(
                          fontSize: 9.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : PlayNedTokens.textSecondary,
                        ),
                      ),
                      selectedColor: accent,
                      backgroundColor: PlayNedTokens.background,
                      side: BorderSide(
                        color: isSelected ? accent : PlayNedTokens.borderSubtle,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Location Items Grid
            Expanded(
              child: filteredLocations.isEmpty
                  ? Center(
                      child: Text(
                        'No matching locations found',
                        style: GoogleFonts.spaceGrotesk(color: PlayNedTokens.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLocations.length,
                      itemBuilder: (context, index) {
                        final loc = filteredLocations[index];
                        final isSelected = _selectedLocationName == loc.name;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? accent.withOpacity(0.15) : PlayNedTokens.background,
                            borderRadius: BorderRadius.circular(PlayNedTokens.radiusSm),
                            border: Border.all(
                              color: isSelected ? accent : PlayNedTokens.borderSubtle,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            onTap: widget.isGuessMode
                                ? () => setState(() => _selectedLocationName = loc.name)
                                : null,
                            leading: Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: isSelected ? accent : PlayNedTokens.textSecondary,
                            ),
                            title: Text(
                              loc.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? accent : PlayNedTokens.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${loc.category} • ${loc.description}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PlayNedTokens.metadata.copyWith(fontSize: 10.5),
                            ),
                            trailing: widget.isGuessMode
                                ? Radio<String>(
                                    value: loc.name,
                                    groupValue: _selectedLocationName,
                                    activeColor: accent,
                                    onChanged: (val) => setState(() => _selectedLocationName = val),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),

            if (widget.isGuessMode) ...[
              const SizedBox(height: 12),
              PlayNedButton(
                label: _selectedLocationName != null
                    ? 'CONFIRM GUESS: $_selectedLocationName'
                    : 'SELECT A LOCATION TO GUESS',
                icon: Icons.check_circle_outline,
                variant: PlayNedButtonVariant.primary,
                accentColor: PlayNedTokens.accentSpyfall,
                onPressed: _selectedLocationName != null
                    ? () {
                        Navigator.of(context).pop();
                        widget.onGuessSubmitted?.call(_selectedLocationName!);
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
