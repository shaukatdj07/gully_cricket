import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/player_state_model.dart';
import '../providers/player_state_provider.dart';

class PlayerHistoryScreen extends StatefulWidget {
  const PlayerHistoryScreen({super.key});

  @override
  State<PlayerHistoryScreen> createState() => _PlayerHistoryScreenState();
}

class _PlayerHistoryScreenState extends State<PlayerHistoryScreen>
    with SingleTickerProviderStateMixin{
  late TabController _tabController;
  late ConfettiController _confettiController;

  final List<Color> _gradientColors = [
    const Color(0xFF0D1B2A),
    const Color(0xFF1B263B),
    const Color(0xFF415A77),
    const Color(0xFF778DA9),
  ];

  int _currentPulseIndex = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _startBackgroundAnimation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerStatsProvider>().loadPlayerStats();
    });
  }

  void _startBackgroundAnimation() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _currentPulseIndex = (_currentPulseIndex + 1) % _gradientColors.length;
        });
        _startBackgroundAnimation();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _celebrateTopPlayer() {
    _confettiController.play();
    Future.delayed(const Duration(seconds: 2), () {
      _confettiController.stop();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await context.read<PlayerStatsProvider>().loadPlayerStats();

    setState(() {
      _isRefreshing = false;
    });

    _showSnackBar(context, 'Stats Refreshed! 🔄');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background at the bottom
          AnimatedContainer(
            duration: const Duration(milliseconds: 2000),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gradientColors[_currentPulseIndex],
                  _gradientColors[(_currentPulseIndex + 1) % _gradientColors.length],
                  _gradientColors[(_currentPulseIndex + 2) % _gradientColors.length],
                ],
              ),
            ),
          ),

          // 2. Main Content in the middle
          Column(
            children: [
              // Enhanced App Bar
              _buildEnhancedAppBar(),

              // Tab Bar
              _buildTabBar(),

              // Content Area
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBatsmenRankings(),
                      _buildBowlersRankings(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. Confetti on top (so it shows over content)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -1.0,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1a2a3a).withOpacity(0.95),
            const Color(0xFF0d1b2a).withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA000),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.6),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Go Back',
            padding: EdgeInsets.zero,
            splashRadius: 20,
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA000),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  _tabController.index == 0 ? '🏏 Top Batsmen' : '🎯 Top Bowlers',
                  key: ValueKey(_tabController.index),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Refresh Button with better styling
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF415A77), Color(0xFF1B263B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: _isRefreshing
                ? const Padding(
              padding: EdgeInsets.all(10.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 24),
              onPressed: _refreshData,
              tooltip: 'Refresh Stats',
            ),
          ),

          // Stats Menu with better styling
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF415A77), Color(0xFF1B263B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: Colors.white, size: 24),
              onSelected: (value) {
                if (value == 'clear_stats') {
                  _showClearStatsDialog(context);
                } else if (value == 'export_stats') {
                  _showSnackBar(context, 'Stats Exported! 📊');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'export_stats',
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.upload_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Export Stats',
                            style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear_stats',
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf44336), Color(0xFFda190b)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Clear All Stats',
                            style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFFE0E0E0),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [
            Shadow(
              blurRadius: 5,
              color: Colors.black,
              offset: Offset(1, 1),
            ),
          ],
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.sports_cricket, size: 24),
            text: 'Top Batsmen',
          ),
          Tab(
            icon: Icon(Icons.sports_handball, size: 24),
            text: 'Top Bowlers',
          ),
        ],
      ),
    );
  }

  Widget _buildBatsmenRankings() {
    return Consumer<PlayerStatsProvider>(
      builder: (context, provider, child) {
        final topBatsmen = provider.top5Batsmen;

        if (topBatsmen.isEmpty) {
          return _buildEmptyState(
            'No Batsmen Data Yet',
            Icons.sports_cricket,
            'Complete matches to see batting rankings!',
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: topBatsmen.length,
            itemBuilder: (context, index) {
              final batsman = topBatsmen[index];
              final position = index + 1;
              return _buildBatsmanCard(batsman, position, index);
            },
          );
        }
      },
    );
  }

  Widget _buildBowlersRankings() {
    return Consumer<PlayerStatsProvider>(
      builder: (context, provider, child) {
        final topBowlers = provider.top5Bowlers;

        if (topBowlers.isEmpty) {
          return _buildEmptyState(
            'No Bowlers Data Yet',
            Icons.sports_handball_rounded,
            'Complete matches to see bowling rankings!',
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: topBowlers.length,
            itemBuilder: (context, index) {
              final bowler = topBowlers[index];
              final position = index + 1;
              return _buildBowlerCard(bowler, position, index);
            },
          );
        }
      },
    );
  }

  Widget _buildBatsmanCard(BatsmanStats batsman, int position, int index) {
    try {
      final positionChange = batsman.previousPosition == 0
          ? 0
          : batsman.previousPosition - position;

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: _getCardGradient(position),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildPositionBadge(position, positionChange),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batsman.playerName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              batsman.teamName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    blurRadius: 5,
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildMainStatChip(
                        '${batsman.runs}',
                        'RUNS',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBatsmanStatsGrid(batsman),
                  const SizedBox(height: 16),
                  _buildPerformanceBar(batsman.runs.toDouble(), 1000),
                ],
              ),
            ),
          ),
        ),
      );

    } catch (e) {
      print('❌ ERROR building card for ${batsman.playerName}: $e');

      return Card(
        color: Colors.blue,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'FALLBACK: ${batsman.playerName}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                'Runs: ${batsman.runs}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Position: $position',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBowlerCard(BowlerStats bowler, int position, int index) {
    final positionChange = bowler.previousPosition == 0
        ? 0
        : bowler.previousPosition - position;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: _getCardGradient(position),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildPositionBadge(position, positionChange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bowler.playerName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bowler.teamName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  blurRadius: 5,
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildMainStatChip(
                      '${bowler.wickets}',
                      'WKTS',
                      Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBowlerStatsGrid(bowler),
                const SizedBox(height: 16),
                _buildPerformanceBar(bowler.wickets.toDouble(), 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionBadge(int position, int positionChange) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getPositionColor(position),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '#$position',
            style: TextStyle(
              fontSize: position == 1 ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                const Shadow(
                  blurRadius: 5,
                  color: Colors.black,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          if (positionChange != 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: positionChange > 0 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  positionChange > 0 ? '↑$positionChange' : '↓${-positionChange}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 5,
                  color: Colors.black,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 3,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatsmanStatsGrid(BatsmanStats batsman) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStatTile('Average', batsman.average.toStringAsFixed(2), Icons.trending_up),
          _buildStatTile('Strike Rate', batsman.strikeRate.toStringAsFixed(2), Icons.speed),
          _buildStatTile('4s/6s', '${batsman.fours}/${batsman.sixes}', Icons.bolt),
          _buildStatTile('50/100', '${batsman.fifties}/${batsman.hundreds}', Icons.emoji_events),
          _buildStatTile('Matches', '${batsman.matchesPlayed}', Icons.groups),
          _buildStatTile('Balls Faced', '${batsman.ballsFaced}', Icons.timelapse),
        ],
      ),
    );
  }

  Widget _buildBowlerStatsGrid(BowlerStats bowler) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStatTile('Economy', bowler.economy.toStringAsFixed(2), Icons.savings),
          _buildStatTile('Average', bowler.average.toStringAsFixed(2), Icons.trending_up),
          _buildStatTile('Strike Rate', bowler.strikeRate.toStringAsFixed(2), Icons.speed),
          _buildStatTile('3W/5W', '${bowler.threeWickets}/${bowler.fiveWickets}', Icons.emoji_events),
          _buildStatTile('Matches', '${bowler.matchesPlayed}', Icons.groups),
          _buildStatTile('Runs Conceded', '${bowler.runsGiven}', Icons.flag),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  blurRadius: 3,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(double current, double max) {
    final percentage = (current / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Performance Level',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 5,
                    color: Colors.black,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 5,
                    color: Colors.black,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreenAccent],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
      onSelected: (value) {
        if (value == 'clear_stats') {
          _showClearStatsDialog(context);
        } else if (value == 'export_stats') {
          _showSnackBar(context, 'Stats Exported! 📊');
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export_stats',
          child: Row(
            children: [
              Icon(Icons.upload, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Text('Export Stats', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'clear_stats',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text('Clear All Stats', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 100,
              color: Colors.white,
              shadows: [
                const Shadow(
                  blurRadius: 10,
                  color: Colors.black,
                  offset: Offset(3, 3),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black,
                    offset: Offset(3, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 24),
              label: const Text('Refresh Data', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
                ),
                elevation: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getCardGradient(int position) {
    switch (position) {
      case 1:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFFA0A0A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF415A77), Color(0xFF1B263B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF415A77);
    }
  }

  void _showClearStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        title: const Text(
          'Clear All Statistics?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'This will permanently reset all player statistics and rankings. This action cannot be undone!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PlayerStatsProvider>().clearAllStats();
              Navigator.pop(context);
              _showSnackBar(context, 'All Stats Cleared! 🗑');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Clear All', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}