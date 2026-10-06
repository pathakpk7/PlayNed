import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final int _timerSpeedMs = 2000; // 2 seconds per tick

  AuctionCategory? _scoutedSlotCategory;
  String? _browseSquadTeamId;
  String? _tradeUserPlayerId;
  String? _tradeTargetTeamId;
  String? _tradeTargetPlayerId;
  TradeMode _tradeMode = TradeMode.sameAmount;
  double _tradeCashAdjustment = 0.0;

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
            icon: const Icon(Icons.groups_outlined, color: Color(0xFFE5A93C)),
            tooltip: 'View Squad Categories',
            onPressed: _showCategorizedSquadModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFA9A396)),
            tooltip: 'Restart Auction',
            onPressed: () {
              setState(() {
                _auctionTimer?.cancel();
                _engine = AuctionEngine();
                _scoutedSlotCategory = null;
                _tradeUserPlayerId = null;
                _tradeTargetTeamId = null;
                _tradeTargetPlayerId = null;
                _tradeMode = TradeMode.sameAmount;
                _tradeCashAdjustment = 0.0;
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
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Stats Banner with Squad Categories Quick Access
              _buildLiveAuctionTopBanner(),
              const SizedBox(height: 14),

              // Main Live Auction Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 840;

                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildCurrentLotCard(player),
                                  const SizedBox(height: 14),
                                  _buildSlotPlayersPanel(player),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _buildFranchisesTickerPanel(),
                                  const SizedBox(height: 14),
                                  _buildActivityFeed(),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCurrentLotCard(player),
                            const SizedBox(height: 14),
                            _buildSlotPlayersPanel(player),
                            const SizedBox(height: 14),
                            _buildFranchisesTickerPanel(),
                            const SizedBox(height: 14),
                            _buildActivityFeed(),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveAuctionTopBanner() {
    final human = _engine.humanTeam;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  human.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD), fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Squad: ${human.squadSize}/25 (Min 18) • OS: ${human.overseasCount}/8',
                  style: GoogleFonts.inter(color: const Color(0xFFA9A396), fontSize: 11),
                ),
              ],
            ),
          ),
          // View Squad Categories Button
          ElevatedButton.icon(
            onPressed: _showCategorizedSquadModal,
            icon: const Icon(Icons.groups, size: 15),
            label: Text(
              'VIEW SQUAD (${human.squadSize})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2C22),
              foregroundColor: const Color(0xFFE5A93C),
              side: const BorderSide(color: Color(0xFF284835)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('PURSE', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFFA9A396), fontWeight: FontWeight.bold)),
              Text(
                '₹${human.purseRemaining.toStringAsFixed(2)} Cr',
                style: GoogleFonts.inter(
                  fontSize: 16,
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
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF131F18),
          borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF233B2E), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category & Status Chips
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  player.category.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5A93C),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: player.isOverseas
                      ? const Color(0xFF4299E1).withOpacity(0.15)
                      : const Color(0xFF48BB78).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  player.isOverseas ? 'OVERSEAS' : 'INDIAN (${player.cappedStatus})',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: player.isOverseas ? const Color(0xFF4299E1) : const Color(0xFF48BB78),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Base: ₹${player.basePrice.toStringAsFixed(2)} Cr',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396), fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Player Avatar + Details + Rating Badges
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: player.avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    player.name.substring(0, 1),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${player.country})',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                        ),
                      ],
                    ),
                    Text(
                      '${player.primaryRole} • ${player.battingStyle}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE5A93C), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Compact Rating Badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactRatingBadge('OVR', player.overallRating, const Color(0xFFE5A93C)),
                  const SizedBox(width: 4),
                  _buildCompactRatingBadge('BAT', player.battingRating, const Color(0xFF4299E1)),
                  const SizedBox(width: 4),
                  _buildCompactRatingBadge('BWL', player.bowlingRating, const Color(0xFFED8936)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            player.shortDescription,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB0A898), height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),
          const Divider(color: Color(0xFF233B2E), height: 1),
          const SizedBox(height: 10),

          // Row 3: Current Bid Leader & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT LOT BID', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396), fontWeight: FontWeight.w600)),
                  Text(
                    '₹${_engine.currentBid.toStringAsFixed(2)} Cr',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE5A93C),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('HIGHEST BIDDER', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396), fontWeight: FontWeight.w600)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _engine.currentBidLeader?.name ?? 'No Bids Yet',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _engine.currentBidLeader == null
                              ? const Color(0xFF718096)
                              : _engine.currentBidLeader!.isHuman
                                  ? const Color(0xFF48BB78)
                                  : const Color(0xFFF1EBDD),
                        ),
                      ),
                      if (_engine.hammerStage > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _engine.hammerStage == 1
                                ? 'ONCE... 🔨'
                                : _engine.hammerStage == 2
                                    ? 'TWICE... 🔨🔨'
                                    : 'SOLD! 🔨🔨🔨',
                            style: const TextStyle(
                              color: Color(0xFFE53E3E),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 4: Action Buttons
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
                  icon: const Icon(Icons.touch_app, size: 16),
                  label: Text(
                    'BID ₹${nextBid.toStringAsFixed(2)} Cr',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: const Color(0xFF0F1E16),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('PASS / DROP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Simulation Speed & Timer Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _toggleAutoRun,
                icon: Icon(_autoRun ? Icons.pause : Icons.play_arrow, size: 14, color: const Color(0xFFA9A396)),
                label: Text(
                  _autoRun ? 'Pause Auto-Bidding' : 'Resume Auto-Bidding',
                  style: const TextStyle(color: Color(0xFFA9A396), fontSize: 11),
                ),
              ),
              if (!_autoRun)
                TextButton.icon(
                  onPressed: _manualStep,
                  icon: const Icon(Icons.skip_next, size: 14, color: Color(0xFFE5A93C)),
                  label: const Text('Next Bid Tick', style: TextStyle(color: Color(0xFFE5A93C), fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRatingBadge(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
          Text('$value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSlotPlayersPanel(AuctionPlayer? currentPlayer) {
    final activeCategory = _scoutedSlotCategory ?? currentPlayer?.category ?? AuctionCategory.batters;
    final slotPlayers = _engine.getPlayersInSlot(activeCategory);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF233B2E)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: Color(0xFFE5A93C), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SLOT TARGETS: ${activeCategory.displayName}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5A93C),
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<AuctionCategory>(
                  value: activeCategory,
                  dropdownColor: const Color(0xFF1B2C22),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE5A93C), size: 18),
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFF1EBDD), fontWeight: FontWeight.w600),
                  onChanged: (cat) {
                    if (cat != null) {
                      setState(() => _scoutedSlotCategory = cat);
                    }
                  },
                  items: [
                    AuctionCategory.batters,
                    AuctionCategory.wicketkeepers,
                    AuctionCategory.allRounders,
                    AuctionCategory.fastBowlers,
                    AuctionCategory.spinBowlers,
                    AuctionCategory.uncapped,
                    AuctionCategory.overseas,
                    AuctionCategory.emerging,
                  ].map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.displayName, style: const TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${slotPlayers.length} players in slot. Star targets to plan bidding strategy.',
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: ListView.builder(
              itemCount: slotPlayers.length,
              itemBuilder: (context, index) {
                final p = slotPlayers[index];
                final isCurrent = p.id == currentPlayer?.id;
                final isTargeted = _engine.isPlayerTargeted(p.id);

                Color statusColor;
                String statusText;
                if (isCurrent) {
                  statusColor = const Color(0xFFE5A93C);
                  statusText = '🔴 LIVE LOT';
                } else if (p.status == PlayerAuctionStatus.unauctioned) {
                  statusColor = const Color(0xFF4299E1);
                  statusText = 'UPCOMING • Base ₹${p.basePrice.toStringAsFixed(1)} Cr';
                } else if (p.status == PlayerAuctionStatus.sold) {
                  statusColor = const Color(0xFF48BB78);
                  statusText = 'SOLD ₹${p.soldPrice?.toStringAsFixed(1)} Cr (${p.soldToTeamName})';
                } else if (p.status == PlayerAuctionStatus.unsold) {
                  statusColor = const Color(0xFFE53E3E);
                  statusText = 'UNSOLD';
                } else {
                  statusColor = const Color(0xFFA9A396);
                  statusText = 'RETAINED (${p.soldToTeamName})';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFFE5A93C).withOpacity(0.12)
                        : (isTargeted ? const Color(0xFFE5A93C).withOpacity(0.06) : const Color(0xFF1B2C22)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFFE5A93C)
                          : (isTargeted ? const Color(0xFFE5A93C).withOpacity(0.5) : const Color(0xFF284835)),
                      width: isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _engine.togglePlayerTarget(p.id));
                        },
                        child: Icon(
                          isTargeted ? Icons.star : Icons.star_border,
                          color: isTargeted ? const Color(0xFFE5A93C) : const Color(0xFF718096),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: p.avatarColor,
                        child: Text(p.name.substring(0, 1), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                    color: isCurrent ? const Color(0xFFE5A93C) : const Color(0xFFF1EBDD),
                                  ),
                                ),
                                if (p.isOverseas) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.flight, color: Color(0xFF4299E1), size: 11),
                                ],
                              ],
                            ),
                            Text(
                              statusText,
                              style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131F18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF284835)),
                        ),
                        child: Text(
                          '★ ${p.overallRating}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE5A93C)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategorizedSquadModal() {
    final human = _engine.humanTeam;
    final batters = human.batters;
    final paceBowlers = human.fastBowlers;
    final spinners = human.spinners;
    final wks = human.wicketkeepers;
    final allRounders = human.allRounders;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131F18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 5,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF233B2E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: human.primaryColor,
                      radius: 18,
                      child: Icon(human.logoIcon, color: human.secondaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${human.name} SQUAD CATEGORIES',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 19,
                              color: const Color(0xFFF1EBDD),
                            ),
                          ),
                          Text(
                            'Squad: ${human.squadSize}/25 (OS: ${human.overseasCount}/8) • Purse: ₹${human.purseRemaining.toStringAsFixed(2)} Cr',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE5A93C)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFA9A396)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  isScrollable: true,
                  indicatorColor: const Color(0xFFE5A93C),
                  labelColor: const Color(0xFFE5A93C),
                  unselectedLabelColor: const Color(0xFFA9A396),
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'BATTERS (${batters.length})'),
                    Tab(text: 'BOWLERS (${paceBowlers.length})'),
                    Tab(text: 'SPINNERS (${spinners.length})'),
                    Tab(text: 'WK (${wks.length})'),
                    Tab(text: 'ALL-ROUNDERS (${allRounders.length})'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSquadCategoryPlayerList(batters, 'Batter', Icons.sports_cricket),
                      _buildSquadCategoryPlayerList(paceBowlers, 'Fast Bowler', Icons.speed),
                      _buildSquadCategoryPlayerList(spinners, 'Spinner', Icons.rotate_right),
                      _buildSquadCategoryPlayerList(wks, 'Wicketkeeper', Icons.sports_handball),
                      _buildSquadCategoryPlayerList(allRounders, 'All-Rounder', Icons.all_inclusive),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquadCategoryPlayerList(List<AuctionPlayer> players, String roleName, IconData icon) {
    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF284835)),
            const SizedBox(height: 10),
            Text(
              'No $roleName acquired yet',
              style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
            ),
            const SizedBox(height: 4),
            Text(
              'Target $roleName talent in the live auction slots to build a balanced squad.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final p = players[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2C22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF284835)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: p.avatarColor,
                child: Text(p.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                          const Icon(Icons.flight, color: Color(0xFF4299E1), size: 13),
                        ],
                      ],
                    ),
                    Text(
                      '${p.country} • ${p.primaryRole} • ${p.battingStyle}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${p.soldPrice?.toStringAsFixed(2) ?? "0.00"} Cr',
                    style: const TextStyle(color: Color(0xFF48BB78), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Rating: ${p.overallRating}',
                    style: const TextStyle(color: Color(0xFFE5A93C), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
      length: 4,
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
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              const Tab(icon: Icon(Icons.sports_cricket), text: 'PLAYING XI & IMPACT'),
              const Tab(icon: Icon(Icons.groups), text: 'FULL SQUAD'),
              Tab(
                icon: const Icon(Icons.swap_horizontal_circle),
                text: 'TRADE WINDOW (${_engine.remainingTrades}/2)',
              ),
              const Tab(icon: Icon(Icons.emoji_events), text: 'LEAGUE RANKINGS & AWARDS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Playing XI
            _buildPlayingXITab(human, xiResult),
            // TAB 2: Full Squad
            _buildFullSquadTab(human),
            // TAB 3: Trade Window
            _buildTradeWindowTab(human),
            // TAB 4: League Rankings & Awards
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

  Widget _buildTradeWindowTab(AuctionTeam human) {
    _browseSquadTeamId ??= _engine.franchises.firstWhere((t) => !t.isHuman).id;
    final browsedTeam = _engine.franchises.firstWhere(
      (t) => t.id == _browseSquadTeamId,
      orElse: () => _engine.franchises.first,
    );

    final otherTeams = _engine.franchises.where((t) => !t.isHuman).toList();
    _tradeUserPlayerId ??= human.squad.isNotEmpty ? human.squad.first.id : null;
    _tradeTargetTeamId ??= otherTeams.isNotEmpty ? otherTeams.first.id : null;
    final targetTeam = _engine.franchises.firstWhere(
      (t) => t.id == _tradeTargetTeamId,
      orElse: () => otherTeams.first,
    );
    _tradeTargetPlayerId ??= targetTeam.squad.isNotEmpty ? targetTeam.squad.first.id : null;

    final userPlayer = human.squad.cast<AuctionPlayer?>().firstWhere(
          (p) => p?.id == _tradeUserPlayerId,
          orElse: () => null,
        );
    final targetPlayer = targetTeam.squad.cast<AuctionPlayer?>().firstWhere(
          (p) => p?.id == _tradeTargetPlayerId,
          orElse: () => null,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banner with Trade Rules & Status
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B2C22), Color(0xFF131F18)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF233B2E)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A93C).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.swap_horizontal_circle, color: Color(0xFFE5A93C), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IPL POST-AUCTION TRADE WINDOW',
                            style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFFF1EBDD)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Exchange up to 2 players across the 10 franchises. Choose Direct Swap at pick amount, or Mutual Decision with player + purse money.',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('EXCHANGES REMAINING', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396), fontWeight: FontWeight.bold)),
                        Text(
                          '${_engine.remainingTrades} / ${AuctionEngine.maxTradesAllowed}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _engine.remainingTrades > 0 ? const Color(0xFFE5A93C) : const Color(0xFFE53E3E),
                          ),
                        ),
                        Text(
                          'Purse: ₹${human.purseRemaining.toStringAsFixed(2)} Cr',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF48BB78), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Interactive Trade Proposal Form (If exchanges remaining)
              if (_engine.remainingTrades > 0) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131F18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.handshake, color: Color(0xFFE5A93C), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'PROPOSE A PLAYER TRADE',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFE5A93C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Selection Columns: Your Player <-> Target Team & Player
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          final humanSquad = human.squad;
                          final targetSquad = targetTeam.squad;

                          final leftCol = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('1. Your Player to Release:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B2C22),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF284835)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: humanSquad.any((p) => p.id == _tradeUserPlayerId) ? _tradeUserPlayerId : (humanSquad.firstOrNull?.id),
                                    dropdownColor: const Color(0xFF1B2C22),
                                    style: GoogleFonts.inter(color: const Color(0xFFF1EBDD), fontSize: 13),
                                    items: humanSquad.map((p) {
                                      return DropdownMenuItem<String>(
                                        value: p.id,
                                        child: Text(
                                          '${p.name} (★${p.overallRating} • ₹${p.soldPrice?.toStringAsFixed(1) ?? "0"} Cr • ${p.role})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _tradeUserPlayerId = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );

                          final rightCol = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('2. Target Franchise & Player:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B2C22),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF284835)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: otherTeams.any((t) => t.id == _tradeTargetTeamId) ? _tradeTargetTeamId : otherTeams.firstOrNull?.id,
                                          dropdownColor: const Color(0xFF1B2C22),
                                          style: GoogleFonts.inter(color: const Color(0xFFF1EBDD), fontSize: 12),
                                          items: otherTeams.map((t) {
                                            return DropdownMenuItem<String>(
                                              value: t.id,
                                              child: Text(t.name, overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _tradeTargetTeamId = val;
                                                final newTarget = _engine.franchises.firstWhere((t) => t.id == val);
                                                _tradeTargetPlayerId = newTarget.squad.firstOrNull?.id;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B2C22),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF284835)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: targetSquad.any((p) => p.id == _tradeTargetPlayerId) ? _tradeTargetPlayerId : targetSquad.firstOrNull?.id,
                                          dropdownColor: const Color(0xFF1B2C22),
                                          style: GoogleFonts.inter(color: const Color(0xFFF1EBDD), fontSize: 12),
                                          items: targetSquad.map((p) {
                                            return DropdownMenuItem<String>(
                                              value: p.id,
                                              child: Text(
                                                '${p.name} (★${p.overallRating} • ₹${p.soldPrice?.toStringAsFixed(1) ?? "0"} Cr • ${p.role})',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) setState(() => _tradeTargetPlayerId = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );

                          return isWide
                              ? Row(
                                  children: [
                                    Expanded(child: leftCol),
                                    const SizedBox(width: 14),
                                    const Icon(Icons.compare_arrows, color: Color(0xFFE5A93C), size: 24),
                                    const SizedBox(width: 14),
                                    Expanded(child: rightCol),
                                  ],
                                )
                              : Column(
                                  children: [
                                    leftCol,
                                    const SizedBox(height: 12),
                                    const Center(child: Icon(Icons.arrow_downward, color: Color(0xFFE5A93C), size: 20)),
                                    const SizedBox(height: 12),
                                    rightCol,
                                  ],
                                );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Trade Mode Selection
                      Text('3. Trade Valuation Mode:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _tradeMode = TradeMode.sameAmount),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _tradeMode == TradeMode.sameAmount ? const Color(0xFFE5A93C).withOpacity(0.15) : const Color(0xFF1B2C22),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _tradeMode == TradeMode.sameAmount ? const Color(0xFFE5A93C) : const Color(0xFF284835),
                                    width: _tradeMode == TradeMode.sameAmount ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _tradeMode == TradeMode.sameAmount ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: const Color(0xFFE5A93C),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Same Pick Amount (Direct Swap)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Trade at each player\'s original auction buy price. Purse difference is automatically settled.',
                                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _tradeMode = TradeMode.mutualDecision),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _tradeMode == TradeMode.mutualDecision ? const Color(0xFFE5A93C).withOpacity(0.15) : const Color(0xFF1B2C22),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _tradeMode == TradeMode.mutualDecision ? const Color(0xFFE5A93C) : const Color(0xFF284835),
                                    width: _tradeMode == TradeMode.mutualDecision ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _tradeMode == TradeMode.mutualDecision ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: const Color(0xFFE5A93C),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Mutual Decision (Player + Money)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sweeten the offer with purse money or request cash. AI team evaluates and agrees only if beneficial.',
                                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // If Mutual Decision: Cash Adjustment Slider
                      if (_tradeMode == TradeMode.mutualDecision) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2C22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF284835)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cash Sweetener Offered from Your Purse:',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFF1EBDD)),
                                  ),
                                  Text(
                                    '₹${_tradeCashAdjustment.toStringAsFixed(1)} Cr',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF48BB78)),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _tradeCashAdjustment.clamp(0.0, human.purseRemaining.clamp(0.0, 30.0)),
                                min: 0.0,
                                max: human.purseRemaining > 0 ? (human.purseRemaining > 30.0 ? 30.0 : human.purseRemaining) : 0.0,
                                divisions: 60,
                                activeColor: const Color(0xFFE5A93C),
                                inactiveColor: const Color(0xFF233B2E),
                                onChanged: human.purseRemaining > 0
                                    ? (val) => setState(() => _tradeCashAdjustment = val)
                                    : null,
                              ),
                              Text(
                                'Your available purse: ₹${human.purseRemaining.toStringAsFixed(2)} Cr',
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Submit Proposal Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: (userPlayer != null && targetPlayer != null)
                              ? () => _handleProposeTrade(human, userPlayer, targetTeam, targetPlayer)
                              : null,
                          icon: const Icon(Icons.handshake_outlined, size: 18),
                          label: Text(
                            'PROPOSE TRADE TO ${targetTeam.name.toUpperCase()}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A93C),
                            foregroundColor: const Color(0xFF0F1E16),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE53E3E)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Color(0xFFE53E3E), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Trade Window Closed: Your franchise has completed the maximum allowed 2 player exchanges.',
                          style: GoogleFonts.inter(color: const Color(0xFFF1EBDD), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // 3. Full Squad Browser for ALL 10 TEAMS
              Text(
                'ALL 10 FRANCHISES SQUAD ROSTERS',
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFFF1EBDD)),
              ),
              const SizedBox(height: 4),
              Text(
                'Inspect the complete squad and purse of all 10 teams after auction completion to scout targets:',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA9A396)),
              ),
              const SizedBox(height: 14),

              // 10 Team selector chips
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _engine.franchises.length,
                  itemBuilder: (context, index) {
                    final t = _engine.franchises[index];
                    final isSelected = t.id == browsedTeam.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        selectedColor: const Color(0xFFE5A93C),
                        backgroundColor: const Color(0xFF1B2C22),
                        avatar: CircleAvatar(
                          backgroundColor: t.primaryColor,
                          radius: 10,
                          child: Icon(t.logoIcon, color: t.secondaryColor, size: 12),
                        ),
                        label: Text(
                          t.isHuman ? '${t.shortName} (YOU)' : t.shortName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF0F1E16) : const Color(0xFFF1EBDD),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _browseSquadTeamId = t.id;
                            if (!t.isHuman) {
                              _tradeTargetTeamId = t.id;
                              _tradeTargetPlayerId = t.squad.firstOrNull?.id;
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Selected Team Squad Detail Card
              Container(
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
                          radius: 16,
                          backgroundColor: browsedTeam.primaryColor,
                          child: Icon(browsedTeam.logoIcon, color: browsedTeam.secondaryColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${browsedTeam.name} (${browsedTeam.squadSize} Players)',
                                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFFF1EBDD)),
                              ),
                              Text(
                                '${browsedTeam.motto} • Overseas: ${browsedTeam.overseasCount}/8',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Purse Remaining', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396))),
                            Text(
                              '₹${browsedTeam.purseRemaining.toStringAsFixed(2)} Cr',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF48BB78), fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF233B2E), height: 1),
                    const SizedBox(height: 12),

                    // Squad list for browsed team
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: browsedTeam.squad.length,
                      itemBuilder: (context, index) {
                        final p = browsedTeam.squad[index];
                        final isHumanTeam = browsedTeam.isHuman;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2C22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF284835)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: p.avatarColor,
                                child: Text(p.name.substring(0, 1), style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(p.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1EBDD))),
                                        if (p.isOverseas) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.flight, color: Color(0xFF4299E1), size: 12),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${p.role} • ${p.primaryRole}',
                                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA9A396)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131F18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('★ ${p.overallRating}', style: const TextStyle(color: Color(0xFFE5A93C), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '₹${p.soldPrice?.toStringAsFixed(1) ?? "0"} Cr',
                                style: const TextStyle(color: Color(0xFF48BB78), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              if (!isHumanTeam && _engine.remainingTrades > 0) ...[
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _tradeTargetTeamId = browsedTeam.id;
                                      _tradeTargetPlayerId = p.id;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Selected ${p.name} (${browsedTeam.name}) as trade target!'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: const Color(0xFF1B2C22),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE5A93C),
                                    side: const BorderSide(color: Color(0xFFE5A93C)),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Target', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProposeTrade(
    AuctionTeam human,
    AuctionPlayer humanPlayer,
    AuctionTeam targetTeam,
    AuctionPlayer targetPlayer,
  ) {
    final eval = _engine.evaluateTradeProposal(
      humanTeam: human,
      humanPlayer: humanPlayer,
      targetTeam: targetTeam,
      targetPlayer: targetPlayer,
      mode: _tradeMode,
      cashOffered: _tradeCashAdjustment,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131F18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: eval.isAccepted ? const Color(0xFF48BB78) : const Color(0xFFE53E3E)),
          ),
          title: Row(
            children: [
              Icon(
                eval.isAccepted ? Icons.check_circle : Icons.cancel,
                color: eval.isAccepted ? const Color(0xFF48BB78) : const Color(0xFFE53E3E),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                eval.isAccepted ? 'Trade Proposal Accepted!' : 'Trade Declined',
                style: GoogleFonts.dmSerifDisplay(
                  color: eval.isAccepted ? const Color(0xFF48BB78) : const Color(0xFFE53E3E),
                  fontSize: 19,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eval.reason,
                style: GoogleFonts.inter(color: const Color(0xFFF1EBDD), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2C22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF284835)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Releasing:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                        Text('${humanPlayer.name} (★${humanPlayer.overallRating})', style: const TextStyle(color: Color(0xFFE53E3E), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Acquiring:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                        Text('${targetPlayer.name} (★${targetPlayer.overallRating})', style: const TextStyle(color: Color(0xFF48BB78), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Purse Adjustment:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9A396))),
                        Text(
                          eval.cashAdjustment >= 0
                              ? '-₹${eval.cashAdjustment.toStringAsFixed(2)} Cr'
                              : '+₹${(-eval.cashAdjustment).toStringAsFixed(2)} Cr',
                          style: TextStyle(
                            color: eval.cashAdjustment <= 0 ? const Color(0xFF48BB78) : const Color(0xFFE5A93C),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (eval.isAccepted) ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Color(0xFFA9A396))),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _engine.executeTrade(
                      humanTeam: human,
                      humanPlayer: humanPlayer,
                      targetTeam: targetTeam,
                      targetPlayer: targetPlayer,
                      mode: _tradeMode,
                      cashOffered: _tradeCashAdjustment,
                    );
                    _tradeUserPlayerId = human.squad.firstOrNull?.id;
                    _tradeTargetPlayerId = targetTeam.squad.firstOrNull?.id;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Trade successfully completed with ${targetTeam.name}!'),
                      backgroundColor: const Color(0xFF48BB78),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF48BB78),
                  foregroundColor: const Color(0xFF0F1E16),
                ),
                child: const Text('CONFIRM & EXECUTE TRADE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('MODIFY OFFER', style: TextStyle(color: Color(0xFFE5A93C))),
              ),
            ],
          ],
        );
      },
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
