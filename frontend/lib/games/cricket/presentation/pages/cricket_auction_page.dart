import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/auction_dataset.dart';
import '../../domain/models/auction_models.dart';
import '../../domain/services/auction_engine.dart';

class CricketAuctionPage extends StatefulWidget {
  const CricketAuctionPage({super.key});

  @override
  State<CricketAuctionPage> createState() => _CricketAuctionPageState();
}

class _CricketAuctionPageState extends State<CricketAuctionPage> {
  late AuctionEngine _engine;
  Timer? _auctionTimer;
  bool _autoRun = true;
  int _timerSpeedMs = 2000; // 2 seconds per tick

  @override
  void initState() {
    super.initState();
    _engine = AuctionEngine();
  }

  @override
  void dispose() {
    _auctionTimer?.cancel();
    super.dispose();
  }

  void _startAuctionTimer() {
    _auctionTimer?.cancel();
    if (!_autoRun) return;

    _auctionTimer = Timer.periodic(Duration(milliseconds: _timerSpeedMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_engine.phase == AuctionPhase.liveAuction ||
          _engine.phase == AuctionPhase.accelerated) {
        final ongoing = _engine.tickAuctionTimer();
        setState(() {});

        if (!ongoing) {
          // Lot concluded; pause briefly then load next player
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (mounted) {
              final hasNext = _engine.nextPlayerInAuction();
              setState(() {});
              if (hasNext && _autoRun) {
                _startAuctionTimer();
              }
            }
          });
        }
      }
    });
  }

  void _toggleAutoRun() {
    setState(() {
      _autoRun = !_autoRun;
      if (_autoRun) {
        _startAuctionTimer();
      } else {
        _auctionTimer?.cancel();
      }
    });
  }

  void _manualStep() {
    _auctionTimer?.cancel();
    _autoRun = false;
    final ongoing = _engine.tickAuctionTimer();
    setState(() {});
    if (!ongoing) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _engine.nextPlayerInAuction();
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131F18),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A93C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.gavel, color: Color(0xFFE5A93C), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'IPL MINI AUCTION',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: const Color(0xFFF1EBDD),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFA9A396)),
            tooltip: 'Restart Auction',
            onPressed: () {
              setState(() {
                _auctionTimer?.cancel();
                _engine = AuctionEngine();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFFA9A396)),
            tooltip: 'Auction Rules',
            onPressed: _showRulesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFA9A396)),
            tooltip: 'Exit to Cricket Hub',
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: _buildCurrentPhaseView(),
    );
  }

  Widget _buildCurrentPhaseView() {
    switch (_engine.phase) {
      case AuctionPhase.setup:
        return _buildSetupView();
      case AuctionPhase.marqueeDraft:
        return _buildMarqueeDraftView();
      case AuctionPhase.retention:
        return _buildRetentionView();
      case AuctionPhase.liveAuction:
      case AuctionPhase.accelerated:
        return _buildLiveAuctionView();
      case AuctionPhase.squadReview:
      case AuctionPhase.completed:
        return _buildSquadSummaryView();
    }
  }

  // ==========================================
  // VIEW 1: SETUP & FRANCHISE SELECTION
  // ==========================================
  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FRANCHISE AUCTION WAR ROOM',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 28,
                  color: const Color(0xFFF1EBDD),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select your franchise to manage in the 10-team IPL Mini Auction. Take command of the ₹120 Crore purse.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFA9A396),
                ),
              ),
              const SizedBox(height: 24),

              // AI Difficulty Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131F18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF233B2E)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_outlined, color: Color(0xFFE5A93C), size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'AI Bidding Intelligence:',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF1EBDD),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    ...['Easy', 'Normal', 'Hard'].map((diff) {
                      final isSelected = _engine.aiDifficulty == diff;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(diff),
                          selected: isSelected,
                          selectedColor: const Color(0xFFE5A93C),
                          backgroundColor: const Color(0xFF1B2C22),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF0F1E16) : const Color(0xFFC3BCAC),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() => _engine.aiDifficulty = diff);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'CHOOSE YOUR FRANCHISE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFFE5A93C),
                ),
              ),
              const SizedBox(height: 16),

              // Grid of 10 Franchises
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 460,
                  mainAxisExtent: 140,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _engine.franchises.length,
                itemBuilder: (context, index) {
                  final team = _engine.franchises[index];
                  final isSelected = team.id == _engine.humanTeamId;

                  return InkWell(
                    onTap: () {
                      setState(() => _engine.setHumanTeam(team.id));
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? team.primaryColor.withOpacity(0.2) : const Color(0xFF131F18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? team.secondaryColor : const Color(0xFF233B2E),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: team.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: team.secondaryColor, width: 2),
                            ),
                            child: Icon(team.logoIcon, color: team.secondaryColor, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        team.name,
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 17,
                                          color: const Color(0xFFF1EBDD),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: Color(0xFFE5A93C), size: 18),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  team.motto,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFA9A396),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B2C22),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Purse: ₹120.0 Cr',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFFE5A93C),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      team.personality.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF718096),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _engine.startMarqueePhase());
                  },
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: Text(
                    'PROCEED TO MARQUEE DRAFT (1/4)',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: const Color(0xFF0F1E16),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 2: MARQUEE PLAYER SELECTION
  // ==========================================
  Widget _buildMarqueeDraftView() {
    final marquees = _engine.marqueePool;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _engine.humanTeam.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_engine.humanTeam.logoIcon, color: _engine.humanTeam.secondaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP 1: SELECT YOUR MARQUEE ICON',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD)),
                      ),
                      Text(
                        '${_engine.humanTeam.name} — Exactly 1 Marquee Player per franchise. Cost: ₹18.00 Cr.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFE5A93C)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Marquee Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 460,
                  mainAxisExtent: 180,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: marquees.length,
                itemBuilder: (context, index) {
                  final player = marquees[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF131F18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF233B2E)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: player.avatarColor,
                              child: Text(
                                player.name.substring(0, 1),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: const Color(0xFFF1EBDD),
                                    ),
                                  ),
                                  Text(
                                    '${player.country} • ${player.primaryRole}',
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A93C).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Rating: ${player.overallRating}',
                                style: const TextStyle(
                                  color: Color(0xFFE5A93C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          player.shortDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8E887B)),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹18.00 Cr',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF48BB78),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _engine.selectHumanMarquee(player);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5A93C),
                                foregroundColor: const Color(0xFF0F1E16),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('SELECT ICON', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 3: RETENTIONS PHASE
  // ==========================================
  Widget _buildRetentionView() {
    final available = _engine.getAvailablePlayersForRetention();
    final humanRetentions = _engine.humanTeam.retentions;
    final nextCost = _engine.getNextRetentionCost(_engine.humanTeam);
    final canRetainMore = _engine.canRetainMore(_engine.humanTeam);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP 2: RETENTION STRATEGY (MAX 4 PLAYERS)',
                style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFFF1EBDD)),
              ),
              const SizedBox(height: 4),
              Text(
                'Marquee counts as Retention #1. Retain up to 3 more core players using IPL salary slabs, or skip to enter the live auction with a huge purse!',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFA9A396)),
              ),
              const SizedBox(height: 16),

              // Current Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131F18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF233B2E)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Retentions: ${humanRetentions.length} / 4',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                          const SizedBox(height: 4),
                          Text(
                            humanRetentions.map((p) => '${p.name} (₹${p.soldPrice?.toStringAsFixed(1)} Cr)').join(', '),
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE5A93C)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Purse Remaining', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                        Text('₹${_engine.humanTeam.purseRemaining.toStringAsFixed(1)} Cr',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Text(
                    'RETAIN ADDITIONAL TALENT (Next Slot: ₹${nextCost.toStringAsFixed(1)} Cr)',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _engine.finalizeRetentionsAndStartLiveAuction();
                        if (_autoRun) _startAuctionTimer();
                      });
                    },
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('ENTER LIVE AUCTION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF48BB78),
                      foregroundColor: const Color(0xFF0F1E16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Available retention list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: available.take(20).length,
                itemBuilder: (context, index) {
                  final player = available[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131F18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF233B2E)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: player.avatarColor,
                          child: Text(player.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(player.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                              Text('${player.country} • ${player.role} • Rating ${player.overallRating}',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: canRetainMore
                              ? () {
                                  setState(() {
                                    _engine.retainPlayerForHuman(player);
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A93C),
                            foregroundColor: const Color(0xFF0F1E16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          ),
                          child: Text('Retain (₹${nextCost.toStringAsFixed(1)} Cr)'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 4: LIVE AUCTION DASHBOARD
  // ==========================================
  Widget _buildLiveAuctionView() {
    final player = _engine.currentPlayer;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Stats Banner
              _buildLiveAuctionTopBanner(),
              const SizedBox(height: 16),

              // Main Live Auction Grid (Player Card + Bidding Arena + Team Strip)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;

                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: _buildCurrentLotCard(player)),
                            const SizedBox(width: 20),
                            Expanded(flex: 4, child: _buildFranchisesTickerPanel()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCurrentLotCard(player),
                            const SizedBox(height: 20),
                            _buildFranchisesTickerPanel(),
                          ],
                        );
                },
              ),

              const SizedBox(height: 20),
              // Live Activity & Commentary Ticker
              _buildActivityFeed(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveAuctionTopBanner() {
    final human = _engine.humanTeam;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131F18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF233B2E)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: human.primaryColor,
            radius: 18,
            child: Icon(human.logoIcon, color: human.secondaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                human.name,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD), fontSize: 15),
              ),
              Text(
                'Squad: ${human.squadSize}/25 (Min 18) • Overseas: ${human.overseasCount}/8',
                style: GoogleFonts.inter(color: const Color(0xFFA9A396), fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('PURSE REMAINING', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396))),
              Text(
                '₹${human.purseRemaining.toStringAsFixed(2)} Cr',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF48BB78),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLotCard(AuctionPlayer? player) {
    if (player == null) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: const Color(0xFF131F18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF233B2E)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE5A93C)),
        ),
      );
    }

    final canBid = _engine.canHumanBid();
    final nextBid = _engine.nextBidAmount;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233B2E), width: 1.5),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category & Status Chips
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  player.category.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5A93C),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: player.isOverseas ? const Color(0xFF4299E1).withOpacity(0.15) : const Color(0xFF48BB78).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  player.isOverseas ? 'OVERSEAS' : 'INDIAN (${player.cappedStatus})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: player.isOverseas ? const Color(0xFF4299E1) : const Color(0xFF48BB78),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Base: ₹${player.basePrice.toStringAsFixed(2)} Cr',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Player Profile Spotlight
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: player.avatarColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: player.avatarColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    player.name.substring(0, 1),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFFF1EBDD)),
                    ),
                    Text(
                      '${player.country} • ${player.primaryRole}',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFE5A93C), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.battingStyle} | ${player.bowlingStyle}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            player.shortDescription,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC3BCAC), height: 1.4),
          ),

          const SizedBox(height: 16),
          // Ratings Metric Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRatingBadge('OVERALL', player.overallRating, const Color(0xFFE5A93C)),
              _buildRatingBadge('BATTING', player.battingRating, const Color(0xFF4299E1)),
              _buildRatingBadge('BOWLING', player.bowlingRating, const Color(0xFFED8936)),
              _buildRatingBadge('FIELDING', player.fieldingRating, const Color(0xFF48BB78)),
            ],
          ),

          const SizedBox(height: 22),
          const Divider(color: Color(0xFF233B2E)),
          const SizedBox(height: 14),

          // Current Bid Leader & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT BID', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                  Text(
                    '₹${_engine.currentBid.toStringAsFixed(2)} Cr',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE5A93C),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('HIGHEST BIDDER', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                  Text(
                    _engine.currentBidLeader?.name ?? 'No Bids Yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _engine.currentBidLeader == null
                          ? const Color(0xFF718096)
                          : _engine.currentBidLeader!.isHuman
                              ? const Color(0xFF48BB78)
                              : const Color(0xFFF1EBDD),
                    ),
                  ),
                  if (_engine.hammerStage > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53E3E).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _engine.hammerStage == 1
                            ? 'GOING ONCE... 🔨'
                            : _engine.hammerStage == 2
                                ? 'GOING TWICE... 🔨🔨'
                                : 'SOLD! 🔨🔨🔨',
                        style: const TextStyle(
                          color: Color(0xFFE53E3E),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Human Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: canBid
                      ? () {
                          setState(() {
                            _engine.placeHumanBid();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.touch_app, size: 20),
                  label: Text(
                    'BID ₹${nextBid.toStringAsFixed(2)} Cr',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: const Color(0xFF0F1E16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _engine.humanPassedCurrentPlayer
                      ? null
                      : () {
                          setState(() {
                            _engine.humanPass();
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53E3E),
                    side: const BorderSide(color: Color(0xFFE53E3E)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('PASS / DROP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Simulation Speed & Timer Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _toggleAutoRun,
                icon: Icon(_autoRun ? Icons.pause : Icons.play_arrow, size: 16, color: const Color(0xFFA9A396)),
                label: Text(
                  _autoRun ? 'Pause Auto-Bidding' : 'Resume Auto-Bidding',
                  style: const TextStyle(color: Color(0xFFA9A396), fontSize: 12),
                ),
              ),
              if (!_autoRun)
                TextButton.icon(
                  onPressed: _manualStep,
                  icon: const Icon(Icons.skip_next, size: 16, color: Color(0xFFE5A93C)),
                  label: const Text('Next Bid Tick', style: TextStyle(color: Color(0xFFE5A93C), fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396))),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildFranchisesTickerPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233B2E)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '10-FRANCHISE PURSE TRACKER',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _engine.franchises.length,
            itemBuilder: (context, index) {
              final team = _engine.franchises[index];
              final isLeader = team.id == _engine.currentBidLeader?.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isLeader ? const Color(0xFFE5A93C).withOpacity(0.15) : const Color(0xFF1B2C22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLeader ? const Color(0xFFE5A93C) : const Color(0xFF284835),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: team.primaryColor,
                      child: Icon(team.logoIcon, color: team.secondaryColor, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isLeader ? FontWeight.bold : FontWeight.w500,
                              color: isLeader ? const Color(0xFFE5A93C) : const Color(0xFFF1EBDD),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Squad: ${team.squadSize}/25 (OS: ${team.overseasCount})',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${team.purseRemaining.toStringAsFixed(1)} Cr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF48BB78),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF233B2E)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: Color(0xFFE5A93C), size: 18),
              const SizedBox(width: 8),
              Text(
                'LIVE AUCTIONEER COMMENTARY',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: _engine.activityLog.take(8).length,
              itemBuilder: (context, index) {
                final log = _engine.activityLog[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    log,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: index == 0 ? const Color(0xFFF1EBDD) : const Color(0xFF718096),
                      fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 5: FINAL SQUAD & SUMMARY
  // ==========================================
  Widget _buildSquadSummaryView() {
    final human = _engine.humanTeam;
    final xiResult = _engine.selectBestPlayingXI(human);
    final awards = _engine.generateAuctionAwards();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF131F18),
          elevation: 0,
          toolbarHeight: 0,
          bottom: TabBar(
            indicatorColor: const Color(0xFFE5A93C),
            labelColor: const Color(0xFFE5A93C),
            unselectedLabelColor: const Color(0xFFA9A396),
            tabs: const [
              Tab(icon: Icon(Icons.sports_cricket), text: 'PLAYING XI & IMPACT'),
              Tab(icon: Icon(Icons.groups), text: 'FULL SQUAD'),
              Tab(icon: Icon(Icons.emoji_events), text: 'LEAGUE RANKINGS & AWARDS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Playing XI
            _buildPlayingXITab(human, xiResult),
            // TAB 2: Full Squad
            _buildFullSquadTab(human),
            // TAB 3: League Rankings & Awards
            _buildLeagueRankingsTab(awards),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingXITab(AuctionTeam team, PlayingXIResult xiResult) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OFFICIAL PLAYING XI + IMPACT PLAYER',
                style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD)),
              ),
              const SizedBox(height: 4),
              Text(
                'Optimal balanced 11 players selected within the IPL maximum 4 overseas regulation.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
              ),
              const SizedBox(height: 16),

              // XI List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: xiResult.playingXI.length,
                itemBuilder: (context, index) {
                  final p = xiResult.playingXI[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131F18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF233B2E)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B2C22),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5A93C))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: p.avatarColor,
                          child: Text(p.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                                  if (p.isOverseas) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.flight, color: Color(0xFF4299E1), size: 14),
                                  ],
                                ],
                              ),
                              Text('${p.role} • ${p.battingStyle}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                            ],
                          ),
                        ),
                        Text('Rating: ${p.overallRating}', style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),

              if (xiResult.impactPlayer != null) ...[
                const SizedBox(height: 16),
                Text('DESIGNATED IMPACT PLAYER', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF48BB78).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF48BB78)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.electric_bolt, color: Color(0xFF48BB78), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(xiResult.impactPlayer!.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                            Text('${xiResult.impactPlayer!.role} • Tactical Game Changer', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                          ],
                        ),
                      ),
                      Text('Rating: ${xiResult.impactPlayer!.overallRating}', style: const TextStyle(color: Color(0xFF48BB78), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullSquadTab(AuctionTeam team) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${team.name} SQUAD ROSTER (${team.squadSize} Players)', style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD))),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: team.squad.length,
                itemBuilder: (context, index) {
                  final p = team.squad[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131F18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF233B2E)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: p.avatarColor,
                          child: Text(p.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                              Text('${p.country} • ${p.role} • ${p.status.name.toUpperCase()}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                            ],
                          ),
                        ),
                        Text(
                          '₹${p.soldPrice?.toStringAsFixed(2) ?? "0.00"} Cr',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF48BB78)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueRankingsTab(Map<String, dynamic> awards) {
    final sortedTeams = List<AuctionTeam>.from(_engine.franchises)
      ..sort((a, b) => b.overallSquadScore.compareTo(a.overallSquadScore));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LEAGUE SQUAD POWER RANKINGS', style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFFF1EBDD))),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedTeams.length,
                itemBuilder: (context, index) {
                  final t = sortedTeams[index];
                  final isHuman = t.isHuman;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isHuman ? const Color(0xFFE5A93C).withOpacity(0.15) : const Color(0xFF131F18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isHuman ? const Color(0xFFE5A93C) : const Color(0xFF233B2E)),
                    ),
                    child: Row(
                      children: [
                        Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5A93C), fontSize: 16)),
                        const SizedBox(width: 14),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: t.primaryColor,
                          child: Icon(t.logoIcon, color: t.secondaryColor, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(t.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                        ),
                        Text(
                          'Squad Score: ${t.overallSquadScore.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF48BB78)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.home),
                  label: const Text('RETURN TO CRICKET HUB'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: const Color(0xFF0F1E16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131F18),
          title: Text(
            'IPL Mini Auction Rules',
            style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFF1EBDD)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ruleItem('Purse', 'Each franchise starts with ₹120.0 Crore. Purse can never go negative.'),
                _ruleItem('Squad Size', 'Minimum 18 players, Maximum 25 players.'),
                _ruleItem('Overseas Cap', 'Maximum 8 overseas players in squad; maximum 4 in Playing XI.'),
                _ruleItem('Marquee Icon', 'Every franchise drafts 1 Marquee player for ₹18.00 Cr before auction starts.'),
                _ruleItem('Retentions', 'Max 4 retentions total (Marquee counts as #1). Slabs: ₹18 Cr, ₹14 Cr, ₹11 Cr, ₹9 Cr.'),
                _ruleItem('Increments', '<1 Cr: +20L | 1-2 Cr: +25L | 2-5 Cr: +50L | 5-10 Cr: +50L | 10+ Cr: +1.0 Cr.'),
                _ruleItem('Reserve Buffer', 'Teams must maintain at least ₹0.20 Cr for each unfilled slot to reach 18 players.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GOT IT', style: TextStyle(color: Color(0xFFE5A93C))),
            ),
          ],
        );
      },
    );
  }

  Widget _ruleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: '• $title: ',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C), fontSize: 12),
          children: [
            TextSpan(
              text: desc,
              style: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFFC3BCAC), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
