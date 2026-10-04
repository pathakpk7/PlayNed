import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/cricket_models.dart';

class ChitBowlDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<CricketPlayer> eligiblePlayers;
  final Function(CricketPlayer) onPlayerSelected;
  final bool allowRedraw;
  final int maxRedraws;

  const ChitBowlDialog({
    super.key,
    required this.title,
    this.subtitle = "Tap into the bowl of folded chits to reveal a random cricket legend!",
    required this.eligiblePlayers,
    required this.onPlayerSelected,
    this.allowRedraw = true,
    this.maxRedraws = 2,
  });

  static Future<CricketPlayer?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<CricketPlayer> eligiblePlayers,
    bool allowRedraw = true,
    int maxRedraws = 2,
  }) {
    return showDialog<CricketPlayer>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChitBowlDialog(
        title: title,
        subtitle: subtitle ?? "Tap into the bowl of folded chits to reveal a random cricket legend!",
        eligiblePlayers: eligiblePlayers,
        allowRedraw: allowRedraw,
        maxRedraws: maxRedraws,
        onPlayerSelected: (p) => Navigator.of(ctx).pop(p),
      ),
    );
  }

  @override
  State<ChitBowlDialog> createState() => _ChitBowlDialogState();
}

class _ChitBowlDialogState extends State<ChitBowlDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _unfurlAnimation;
  late Animation<double> _scaleAnimation;

  CricketPlayer? _revealedPlayer;
  bool _isUnfurling = false;
  int _remainingRedraws = 2;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _remainingRedraws = widget.maxRedraws;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _unfurlAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _pickChit() {
    if (widget.eligiblePlayers.isEmpty || _isUnfurling) return;

    final picked = widget.eligiblePlayers[_random.nextInt(widget.eligiblePlayers.length)];
    setState(() {
      _isUnfurling = true;
      _revealedPlayer = picked;
    });

    _animController.forward(from: 0.0);
  }

  void _redrawChit() {
    if (_remainingRedraws <= 0) return;
    setState(() {
      _remainingRedraws -= 1;
      _isUnfurling = false;
      _revealedPlayer = null;
    });
    _animController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1710), Color(0xFF0F0C08)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD5A84B), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFD5A84B).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.casino_outlined, color: Color(0xFFE5A93C), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "BOWL OF CHITS",
                      style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD), letterSpacing: 1.0),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFA9A396), size: 20),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
            ),
            const SizedBox(height: 18),

            // Main Interactive Stage (Bowl vs Unfurled Chit)
            if (_revealedPlayer == null) ...[
              _buildChitBowlContainer(),
            ] else ...[
              _buildUnfurledChitCard(_revealedPlayer!),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            if (_revealedPlayer == null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.eligiblePlayers.isNotEmpty ? _pickChit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: const Color(0xFF0F0C08),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.touch_app, size: 20),
                  label: Text(
                    "DRAW A CHIT FROM BOWL (${widget.eligiblePlayers.length} CHITS)",
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  if (widget.allowRedraw && _remainingRedraws > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: _redrawChit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF1EBDD),
                          side: const BorderSide(color: Color(0xFFD5A84B), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.refresh, size: 16, color: Color(0xFFE5A93C)),
                        label: Text(
                          "REDRAW ($_remainingRedraws LEFT)",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onPlayerSelected(_revealedPlayer!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48BB78),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        "ACCEPT ${_revealedPlayer!.name.toUpperCase()}",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChitBowlContainer() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF16110A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF382A1C)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wooden Bowl Graphic
          Positioned(
            bottom: 20,
            child: Container(
              width: 240,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D4026), Color(0xFF2C1B0E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(120),
                  bottomRight: Radius.circular(120),
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border.all(color: const Color(0xFFD5A84B), width: 3.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.7),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "CRICKET AUCTION BOWL",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: const Color(0xFFE5A93C).withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),

          // Folded Chits Floating in the Bowl
          ...List.generate(min(12, max(6, widget.eligiblePlayers.length)), (idx) {
            final double angle = (idx * 0.45) - 1.2;
            final double xOffset = (sin(idx * 1.3) * 65.0);
            final double yOffset = (cos(idx * 1.1) * 25.0) - 10;

            return Transform.translate(
              offset: Offset(xOffset, yOffset),
              child: Transform.rotate(
                angle: angle,
                child: InkWell(
                  onTap: _pickChit,
                  child: _buildFoldedChitMini(idx),
                ),
              ),
            );
          }),

          // Hint overlay
          Positioned(
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0C08).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD5A84B).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, size: 14, color: Color(0xFFE5A93C)),
                  const SizedBox(width: 6),
                  Text(
                    "Click on any chit to draw!",
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldedChitMini(int index) {
    return Container(
      width: 52,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EBD4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF8C7352), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Crease line
          Center(
            child: Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFF8C7352).withOpacity(0.4),
            ),
          ),
          Center(
            child: Text(
              "? ?",
              style: GoogleFonts.caveat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A3B2C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnfurledChitCard(CricketPlayer player) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(
        turns: Tween<double>(begin: -0.05, end: 0.0).animate(_unfurlAnimation),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF9E845B), width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Parchment Watermark & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9E845B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF9E845B)),
                    ),
                    child: Text(
                      "OFFICIAL LOTTERY CHIT",
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: const Color(0xFF5A4425)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC53030),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${player.draftCost} CREDITS",
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Handwritten player name style
              CircleAvatar(
                radius: 26,
                backgroundColor: player.avatarColor,
                child: Text(
                  player.name[0],
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                player.name,
                style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF2C1E11)),
                textAlign: TextAlign.center,
              ),
              Text(
                "${player.country} • ${player.role} (${player.careerSpan})",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7A654C)),
              ),
              const SizedBox(height: 12),

              // Quick Key Attributes on Parchment
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E7D3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD3C2A9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildParchmentStat("Bat Rating", "${player.battingRating}"),
                    _buildParchmentStat("Bowl Rating", "${player.bowlingRating}"),
                    _buildParchmentStat("Int'l Runs", "${player.internationalRuns}"),
                    _buildParchmentStat("Int'l Wkts", "${player.internationalWickets}"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParchmentStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF7A654C))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2C1E11))),
      ],
    );
  }
}
