import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import '../models/batsman_model.dart';
import '../models/bowler_model.dart';
import '../providers/match_provider.dart';
import '../models/team_model.dart';

class MatchSummaryScreen extends StatelessWidget {
  final MatchProvider matchProvider;

  const MatchSummaryScreen({super.key, required this.matchProvider});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0f172a),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildPremiumAppBar(context),
            _buildTabBar(),
          ],
          body: TabBarView(
            children: [
              _buildSavedMatchesList(context),
              _buildCurrentMatchSummary(context),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildPremiumAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      collapsedHeight: 100,
      pinned: true,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.only(left: 12, top: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3b82f6).withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Go Back',
            padding: EdgeInsets.zero,
            splashRadius: 20,
          ),
        ),
      ),
      title: LayoutBuilder(
        builder: (context, constraints) {
          final innerBoxIsScrolled = constraints.maxHeight == 100;
          return AnimatedOpacity(
            opacity: innerBoxIsScrolled ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3b82f6).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                'Match History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          );
        },
      ),
      centerTitle: true,
      actions: [
        Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3b82f6).withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, size: 20, color: Colors.white),
              onPressed: () => _showSearchDialog(context),
              tooltip: 'Search Matches',
            ),
          ),
        ),
        Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.only(right: 12, top: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3b82f6).withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_alt, size: 20, color: Colors.white),
              onPressed: () => _showFilterBottomSheet(context),
              tooltip: 'Filter Matches',
            ),
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = (constraints.maxHeight - 100) / (200 - 100);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1e293b),
                    const Color(0xFF0f172a),
                    const Color(0xFF334155),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Animated background elements
                  Positioned(
                    top: -60,
                    right: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF3b82f6).withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF10b981).withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Main content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated icon and title
                          ScaleTransition(
                            scale: AlwaysStoppedAnimation(0.8 + (expandRatio * 0.4)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3b82f6).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.history,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: AlwaysStoppedAnimation(expandRatio),
                            child: const Column(
                              children: [
                                Text(
                                  'Match History',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Relive your cricket moments',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Search Matches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by team name, tournament...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3b82f6)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3b82f6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Matches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('All Matches', Icons.all_inclusive),
            _buildFilterOption('Completed', Icons.check_circle),
            _buildFilterOption('Upcoming', Icons.upcoming),
            _buildFilterOption('Today', Icons.today),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(),
    );
  }

  Widget _buildSavedMatchesList(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<void>(
          future: _loadMatchesOnce(provider),
          builder: (context, snapshot) {
            if (provider.savedMatches.isEmpty) {
              return _buildPremiumEmptyState();
            }

            return RefreshIndicator(
              backgroundColor: const Color(0xFF1e293b),
              color: const Color(0xFF3b82f6),
              onRefresh: () async {
                await provider.loadSavedMatches();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.savedMatches.length,
                itemBuilder: (context, index) {
                  final matchIndex = provider.savedMatches.length - 1 - index;
                  final match = provider.savedMatches[matchIndex];
                  return _buildPremiumMatchListItem(context, match, matchIndex);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                FeatherIcons.inbox,
                size: 80,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Matches Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Save your current match to\nrelive the moments later',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3b82f6).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon:  Icon(FeatherIcons.plus, size: 18, color: Colors.white),
                label: const Text(
                  'Start New Match',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumMatchListItem(BuildContext context, Map<String, dynamic> match, int originalIndex) {
    try {
      final requiredFields = ['id', 'timestamp', 'teamA', 'teamB'];
      for (final field in requiredFields) {
        if (!match.containsKey(field) || match[field] == null) {
          throw Exception('Missing required field: $field');
        }
      }

      final teamAData = match['teamA'];
      final teamBData = match['teamB'];

      if (teamAData is! Map<String, dynamic> || teamBData is! Map<String, dynamic>) {
        throw Exception('Invalid team data structure');
      }

      final safeTeamAData = _ensureNumericFields(teamAData);
      final safeTeamBData = _ensureNumericFields(teamBData);

      final teamA = TeamModel.fromJson(safeTeamAData);
      final teamB = TeamModel.fromJson(safeTeamBData);
      final result = match['result'] ?? 'Match Completed';

      final timestampString = match['timestamp'].toString();
      final timestamp = DateTime.tryParse(timestampString) ?? DateTime.now();

      final matchId = match['id'] is int ? match['id'] as int : int.tryParse(match['id'].toString()) ?? 0;
      final totalOvers = match['totalOvers']?.toString() ?? 'N/A';

      if (teamA.name.isEmpty || teamB.name.isEmpty) {
        throw Exception('Team names are empty after parsing');
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: InkWell(
            onTap: () => _showPremiumMatchDetails(context, teamA, teamB, result, timestamp, totalOvers),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with teams
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teamA.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Team A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              teamB.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Team B',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Result and details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getResultColor(result),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(FeatherIcons.calendar, size: 12, color: Colors.white.withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(FeatherIcons.clock, size: 12, color: Colors.white.withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text(
                              _formatTime(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const Spacer(),
                            Icon(FeatherIcons.target, size: 12, color: Colors.white.withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text(
                              '$totalOvers Overs',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      _buildActionButton(
                        FeatherIcons.eye,
                        'View Details',
                            () => _showPremiumMatchDetails(context, teamA, teamB, result, timestamp, totalOvers),
                      ),
                      const Spacer(),
                      _buildActionButton(
                        FeatherIcons.trash2,
                        'Delete',
                            () => _showPremiumDeleteConfirmation(context, matchId, originalIndex),
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return _buildPremiumCorruptedMatchCard(context, match, e.toString(), originalIndex);
    }
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFef4444) : const Color(0xFF3b82f6);

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
        ),
      ),
    );
  }

  Widget _buildPremiumCorruptedMatchCard(BuildContext context, Map<String, dynamic> match, String error, int originalIndex) {
    final matchId = match['id'] is int ? match['id'] as int : int.tryParse(match['id'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFef4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(FeatherIcons.alertTriangle, size: 20, color: Color(0xFFef4444)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Corrupted Match Data',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.length > 50 ? '${error.substring(0, 50)}...' : error,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButton(
                FeatherIcons.trash2,
                'Delete',
                    () => _showPremiumDeleteConfirmation(context, matchId, originalIndex),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMatchSummary(BuildContext context) {
    final teamA = matchProvider.teamA;
    final teamB = matchProvider.teamB;

    bool isMatchInProgress = teamA.totalRuns > 0 || teamB.totalRuns > 0 ||
        teamA.wicketsLost > 0 || teamB.wicketsLost > 0;

    final (result, resultColor) = _getCurrentMatchResult();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Match Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1e293b), Color(0xFF334155)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${teamA.name} vs ${teamB.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: resultColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    result,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: resultColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (matchProvider.isSecondInning && !matchProvider.isMatchComplete) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTargetItem('🎯', 'Target', '${matchProvider.target}'),
                        const SizedBox(width: 20),
                        _buildTargetItem('⚡', 'Req. RR', '${matchProvider.requiredRunRate.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Team A Summary
          _buildPremiumTeamSummary(teamA, '${teamA.name} ${matchProvider.isTeamABatting && !matchProvider.isMatchComplete ? "(Batting)" : "(Innings)"}'),
          const SizedBox(height: 20),

          // Team B Summary
          _buildPremiumTeamSummary(teamB, '${teamB.name} ${!matchProvider.isTeamABatting && !matchProvider.isMatchComplete ? "(Batting)" : "(Innings)"}'),

          // Save Match Button
          if (isMatchInProgress)
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10b981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10b981).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _saveCurrentMatch(context),
                icon: const Icon(FeatherIcons.save, size: 20, color: Colors.white),
                label: const Text(
                  'Save Current Match',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTeamSummary(TeamModel team, String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(FeatherIcons.users, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3)),
                ),
                child: Text(
                  '${team.totalRuns}/${team.wicketsLost}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                team.oversString,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Batsmen Section
          _buildSectionHeader('🏏 Batting'),
          const SizedBox(height: 12),
          if (team.batsmen.isEmpty)
            _buildEmptySection('No batsmen data')
          else
            ...team.batsmen.map((batsman) => _buildBatsmanRow(batsman)),

          const SizedBox(height: 20),

          // Bowlers Section
          _buildSectionHeader('🎯 Bowling'),
          const SizedBox(height: 12),
          if (team.bowlers.isEmpty)
            _buildEmptySection('No bowling data')
          else
            ...team.bowlers.map((bowler) => _buildBowlerRow(bowler)),

          // Fall of Wickets
          if (team.fallOfWickets.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('📉 Fall of Wickets'),
            const SizedBox(height: 12),
            ...team.fallOfWickets.map((wicket) => _buildWicketRow(wicket)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptySection(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildBatsmanRow(BatsmanModel batsman) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              batsman.name,
              style: TextStyle(
                fontWeight: batsman.isOut ? FontWeight.normal : FontWeight.w600,
                color: batsman.isOut ? Colors.white.withOpacity(0.6) : Colors.white,
              ),
            ),
          ),
          Text(
            '${batsman.runs} (${batsman.ballsFaced})',
            style: TextStyle(
              fontWeight: batsman.isOut ? FontWeight.normal : FontWeight.w600,
              color: batsman.isOut ? Colors.white.withOpacity(0.6) : Colors.white,
            ),
          ),
          if (batsman.isOut)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFef4444),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'OUT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (batsman.isOnStrike)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981),
                shape: BoxShape.circle,
              ),
              child: const Icon(FeatherIcons.zap, size: 12, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(BowlerModel bowler) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              bowler.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildBowlerStat('${bowler.oversBowled}.${bowler.balls}', 'Overs'),
          _buildBowlerStat('${bowler.runsGiven}', 'Runs'),
          _buildBowlerStat('${bowler.wickets}', 'Wkts'),
          _buildBowlerStat(bowler.economyRate.toStringAsFixed(2), 'Econ'),
        ],
      ),
    );
  }

  Widget _buildBowlerStat(String value, String label) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWicketRow(String wicket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFef4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              wicket,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMatchesOnce(MatchProvider provider) async {
    if (provider.savedMatches.isEmpty) {
      await provider.loadSavedMatches();
    }
  }

  Map<String, dynamic> _ensureNumericFields(Map<String, dynamic> teamData) {
    final safeData = Map<String, dynamic>.from(teamData);

    // Ensure all numeric fields have default values
    final numericFields = [
      'totalRuns', 'wicketsLost', 'ballsBowled', 'currentBowlerIndex'
    ];

    for (final field in numericFields) {
      if (safeData[field] == null) {
        safeData[field] = 0;
      }
    }

    // Ensure batsmen have numeric fields
    if (safeData['batsmen'] is List) {
      safeData['batsmen'] = (safeData['batsmen'] as List).map((batsman) {
        if (batsman is Map<String, dynamic>) {
          final safeBatsman = Map<String, dynamic>.from(batsman);
          final batsmanNumericFields = ['runs', 'ballsFaced', 'fours', 'sixes'];
          for (final field in batsmanNumericFields) {
            if (safeBatsman[field] == null) {
              safeBatsman[field] = 0;
            }
          }
          // Ensure boolean fields
          if (safeBatsman['isOut'] == null) safeBatsman['isOut'] = false;
          if (safeBatsman['isOnStrike'] == null) safeBatsman['isOnStrike'] = false;
          return safeBatsman;
        }
        return batsman;
      }).toList();
    }

    // Ensure bowlers have numeric fields
    if (safeData['bowlers'] is List) {
      safeData['bowlers'] = (safeData['bowlers'] as List).map((bowler) {
        if (bowler is Map<String, dynamic>) {
          final safeBowler = Map<String, dynamic>.from(bowler);
          final bowlerNumericFields = ['oversBowled', 'balls', 'runsGiven', 'wickets'];
          for (final field in bowlerNumericFields) {
            if (safeBowler[field] == null) {
              safeBowler[field] = 0;
            }
          }
          return safeBowler;
        }
        return bowler;
      }).toList();
    }

    // Ensure fallOfWickets is a list
    if (safeData['fallOfWickets'] == null) {
      safeData['fallOfWickets'] = [];
    }

    return safeData;
  }

  void _showPremiumMatchDetails(BuildContext context, TeamModel teamA, TeamModel teamB, String result, DateTime timestamp, dynamic totalOvers) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3b82f6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FeatherIcons.info, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Match Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(FeatherIcons.x, size: 20, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Result
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${teamA.name} vs ${teamB.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getResultColor(result),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FeatherIcons.calendar, size: 12, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(timestamp),
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                        const SizedBox(width: 16),
                        Icon(FeatherIcons.clock, size: 12, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Overs: ${totalOvers ?? 'N/A'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Team Stats
              Row(
                children: [
                  Expanded(child: _buildCompactTeamStats(teamA, teamA.name)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCompactTeamStats(teamB, teamB.name)),
                ],
              ),
              const SizedBox(height: 20),
              // Close Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTeamStats(TeamModel team, String teamName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${team.totalRuns}/${team.wicketsLost} in ${team.oversString}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Top Batsman: ${_getTopBatsman(team)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          Text(
            'Top Bowler: ${_getTopBowler(team)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  String _getTopBatsman(TeamModel team) {
    if (team.batsmen.isEmpty) return 'None';
    team.batsmen.sort((a, b) => b.runs.compareTo(a.runs));
    final topBatsman = team.batsmen.first;
    return '${topBatsman.name} (${topBatsman.runs} runs)';
  }

  String _getTopBowler(TeamModel team) {
    if (team.bowlers.isEmpty) return 'None';
    team.bowlers.sort((a, b) {
      final wicketCompare = b.wickets.compareTo(a.wickets);
      if (wicketCompare != 0) return wicketCompare;
      return a.runsGiven.compareTo(b.runsGiven);
    });
    final topBowler = team.bowlers.first;
    return '${topBowler.name} (${topBowler.wickets}/${topBowler.runsGiven})';
  }

  void _showPremiumDeleteConfirmation(BuildContext context, int matchId, int originalIndex) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFef4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(FeatherIcons.alertTriangle, size: 32, color: Color(0xFFef4444)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Match?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone. The match data will be permanently deleted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await matchProvider.deleteMatch(matchId);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            _showSnackBar(context, 'Match deleted successfully', isError: false);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            _showSnackBar(context, 'Error deleting match: $e', isError: true);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFef4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCurrentMatch(BuildContext context) async {
    try {
      await matchProvider.saveCurrentMatch();
      if (context.mounted) {
        _showSnackBar(context, 'Match saved successfully!', isError: false);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error saving match: $e', isError: true);
      }
      print('Save match error: $e');
    }
  }

  (String, Color) _getCurrentMatchResult() {
    final teamA = matchProvider.teamA;
    final teamB = matchProvider.teamB;

    if (!(teamA.totalRuns > 0 || teamB.totalRuns > 0)) {
      return ('Match not started', Colors.grey);
    } else if (matchProvider.isMatchComplete) {
      if (teamA.totalRuns > teamB.totalRuns) {
        return ('${teamA.name} won by ${teamA.totalRuns - teamB.totalRuns} runs', const Color(0xFF10b981));
      } else if (teamB.totalRuns > teamA.totalRuns) {
        final wicketsLeft = 10 - teamB.wicketsLost;
        return ('${teamB.name} won by $wicketsLeft wickets', const Color(0xFF10b981));
      } else {
        return ('Match tied', const Color(0xFFf59e0b));
      }
    } else {
      if (matchProvider.isSecondInning) {
        final runsNeeded = matchProvider.target - teamB.totalRuns;
        final wicketsLeft = 10 - teamB.wicketsLost;
        return ('${teamB.name} need $runsNeeded runs to win with $wicketsLeft wickets left', const Color(0xFF3b82f6));
      } else {
        return ('${teamA.name} batting - ${teamA.totalRuns}/${teamA.wicketsLost} in ${teamA.oversString}', const Color(0xFF3b82f6));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getResultColor(String result) {
    if (result.toLowerCase().contains('won')) return const Color(0xFF10b981);
    if (result.toLowerCase().contains('tied')) return const Color(0xFFf59e0b);
    return const Color(0xFF3b82f6);
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFef4444) : const Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        indicatorColor: const Color(0xFF3b82f6),
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
        tabs: const [
          Tab(
            icon: Icon(FeatherIcons.archive, size: 18),
            text: 'Saved Matches',
          ),
          Tab(
            icon: Icon(FeatherIcons.playCircle, size: 18),
            text: 'Current Match',
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}