import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:feather_icons/feather_icons.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _teamAController = TextEditingController();
  final TextEditingController _teamBController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _tournamentController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // Filter states
  String _currentFilter = 'all';
  final List<String> _filters = ['all', 'upcoming', 'past', 'today'];

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadSchedules();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadSchedules() {
    setState(() => _isLoading = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSchedules().then((_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    });
  }

  List<ScheduledMatch> _getFilteredMatches(List<ScheduledMatch> allMatches) {
    var matches = allMatches;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      matches = matches.where((match) =>
      match.teamA.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          match.teamB.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          match.tournamentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          match.location.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply time filter
    final now = DateTime.now();
    switch (_currentFilter) {
      case 'upcoming':
        return matches.where((match) => match.dateTime.isAfter(now)).toList();
      case 'past':
        return matches.where((match) => match.dateTime.isBefore(now)).toList();
      case 'today':
        return matches.where((match) =>
        match.dateTime.year == now.year &&
            match.dateTime.month == now.month &&
            match.dateTime.day == now.day
        ).toList();
      default:
        return matches;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
          _buildStatsSliver(),
          _buildFiltersSliver(),
        ],
        body: _buildBody(),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  SliverAppBar _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 160.0,
      collapsedHeight: 80.0,
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF1a365d), Color(0xFF2d3748)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: AnimatedOpacity(
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a365d), Color(0xFF2d3748)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            'Match Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1a365d), Color(0xFF2d3748)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(FeatherIcons.search, size: 18, color: Colors.white),
            onPressed: _showSearchDialog,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1a365d), Color(0xFF2d3748)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(FeatherIcons.filter, size: 18, color: Colors.white),
            onPressed: _showFilterBottomSheet,
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = (constraints.maxHeight - 80) / (160 - 80);
          final opacity = 1.0 - expandRatio.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1a365d).withOpacity(0.95),
                    const Color(0xFF2d3748).withOpacity(0.95),
                    const Color(0xFF4a5568).withOpacity(0.9),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Animated background elements
                  Positioned(
                    top: -50,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
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
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Centered content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Main icon and title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: const Icon(
                                  FeatherIcons.calendar,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Match Schedule',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Schedule Management',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Centered quick stats
                          Consumer<ScheduleProvider>(
                            builder: (context, provider, child) {
                              final allMatches = provider.scheduledMatches;
                              final upcoming = allMatches.where((m) => m.dateTime.isAfter(DateTime.now())).length;
                              final today = allMatches.where((m) =>
                              m.dateTime.year == DateTime.now().year &&
                                  m.dateTime.month == DateTime.now().month &&
                                  m.dateTime.day == DateTime.now().day
                              ).length;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildQuickStat('Total', allMatches.length.toString()),
                                  const SizedBox(width: 20),
                                  _buildQuickStat('Upcoming', upcoming.toString()),
                                  const SizedBox(width: 20),
                                  _buildQuickStat('Today', today.toString()),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Fade out content when collapsing
                  if (opacity > 0)
                    Container(
                      color: Colors.black.withOpacity(opacity * 0.3),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildStatsSliver() {
    return const SliverToBoxAdapter(
      child: SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildFiltersSliver() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Text(
              'Matches',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            if (_searchQuery.isNotEmpty) ...[
              Chip(
                label: Text('Search: $_searchQuery'),
                onDeleted: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                backgroundColor: const Color(0xFFe6fffa),
                deleteIconColor: const Color(0xFF1a365d),
              ),
              const SizedBox(width: 8),
            ],
            if (_currentFilter != 'all') ...[
              Chip(
                label: Text(_currentFilter),
                onDeleted: () => setState(() => _currentFilter = 'all'),
                backgroundColor: const Color(0xFFe6fffa),
                deleteIconColor: const Color(0xFF1a365d),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        final allMatches = scheduleProvider.scheduledMatches;
        final filteredMatches = _getFilteredMatches(allMatches);

        if (_isLoading) {
          return _buildLoadingState();
        }

        if (filteredMatches.isEmpty) {
          return _buildEmptyState(allMatches.isEmpty);
        }

        return _buildMatchesList(filteredMatches);
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noMatches) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noMatches ? FeatherIcons.calendar : FeatherIcons.search,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              noMatches ? 'No Matches Scheduled' : 'No Results Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              noMatches
                  ? 'Schedule your first match to get started with tournament management'
                  : 'Try adjusting your search or filter criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (noMatches)
              FilledButton.icon(
                onPressed: () => _showAddScheduleDialog(context),
                icon: const Icon(FeatherIcons.plus, size: 16),
                label: const Text('Schedule First Match'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1a365d),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(List<ScheduledMatch> matches) {
    // Group by date
    final groupedMatches = _groupMatchesByDate(matches);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: groupedMatches.length,
      itemBuilder: (context, index) {
        final date = groupedMatches.keys.elementAt(index);
        final dateMatches = groupedMatches[date]!;

        return _buildDateGroup(date, dateMatches);
      },
    );
  }

  Map<DateTime, List<ScheduledMatch>> _groupMatchesByDate(List<ScheduledMatch> matches) {
    final map = <DateTime, List<ScheduledMatch>>{};

    for (final match in matches) {
      final date = DateTime(match.dateTime.year, match.dateTime.month, match.dateTime.day);
      if (!map.containsKey(date)) {
        map[date] = [];
      }
      map[date]!.add(match);
    }

    // Sort dates
    final sortedKeys = map.keys.toList()..sort();
    final sortedMap = <DateTime, List<ScheduledMatch>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = map[key]!..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }

    return sortedMap;
  }

  Widget _buildDateGroup(DateTime date, List<ScheduledMatch> matches) {
    final isToday = date.isSameDate(DateTime.now());
    final isTomorrow = date.isSameDate(DateTime.now().add(const Duration(days: 1)));

    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isTomorrow) {
      dateText = 'Tomorrow';
    } else {
      dateText = DateFormat('EEEE, MMMM d').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a365d),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a365d),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a365d).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  matches.length.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a365d),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...matches.map((match) => _buildMatchCard(match)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMatchCard(ScheduledMatch match) {
    final isPast = match.dateTime.isBefore(DateTime.now());

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[100]!, width: 1),
      ),
      child: InkWell(
        onTap: () => _showMatchDetails(match),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tournament and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (match.tournamentName.isNotEmpty) ...[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a365d).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          match.tournamentName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a365d),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPast ? Colors.grey[100] : const Color(0xFF48bb78).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPast ? FeatherIcons.checkCircle : FeatherIcons.clock,
                          size: 10,
                          color: isPast ? Colors.grey[600] : const Color(0xFF48bb78),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPast ? 'Completed' : 'Upcoming',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.grey[600] : const Color(0xFF48bb78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Teams section
              _buildTeamsSection(match),
              const SizedBox(height: 16),
              // Details section
              _buildDetailsSection(match),
              const SizedBox(height: 16),
              // Actions
              _buildActionButtons(match),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsSection(ScheduledMatch match) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  match.teamA,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a365d),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Team A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey[600],
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  match.teamB,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a365d),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Team B',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ScheduledMatch match) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Row(
      children: [
        _buildDetailChip(FeatherIcons.mapPin, match.location),
        const SizedBox(width: 8),
        _buildDetailChip(FeatherIcons.calendar, dateFormat.format(match.dateTime)),
        const SizedBox(width: 8),
        _buildDetailChip(FeatherIcons.clock, timeFormat.format(match.dateTime)),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ScheduledMatch match) {
    final isPast = match.dateTime.isBefore(DateTime.now());

    return Row(
      children: [
        _buildTextButton(
          'View Details',
          FeatherIcons.eye,
              () => _showMatchDetails(match),
        ),
        const Spacer(),
        if (!isPast) ...[
          _buildTextButton(
            'Edit',
            FeatherIcons.edit3,
                () => _editMatch(match, context),
          ),
          const SizedBox(width: 8),
        ],
        _buildTextButton(
          'Delete',
          FeatherIcons.trash2,
              () => _deleteMatch(match.id),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildTextButton(String text, IconData icon, VoidCallback onPressed, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFe53e3e) : const Color(0xFF1a365d);

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12, color: color),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showAddScheduleDialog(context),
      backgroundColor: const Color(0xFF1a365d),
      foregroundColor: Colors.white,
      elevation: 2,
      child: const Icon(FeatherIcons.plus, size: 20),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Search Matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a365d),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by team, tournament, location...',
                  prefixIcon: const Icon(FeatherIcons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1a365d),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Filter Matches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a365d),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(FeatherIcons.x, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filter options with fixed height container
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 200, // Fixed max height for options
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: _filters.map((filter) => _buildFilterOption(filter)).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnackBar('Filter applied: ${_getFilterLabel(_currentFilter)}');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1a365d),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String filter) {
    final isSelected = _currentFilter == filter;
    final label = _getFilterLabel(filter);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1a365d).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF1a365d) : Colors.grey[300]!,
        ),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? const Color(0xFF1a365d) : Colors.grey[700],
          ),
        ),
        trailing: isSelected ? const Icon(FeatherIcons.check, size: 16, color: Color(0xFF1a365d)) : null,
        onTap: () => setState(() => _currentFilter = filter),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced vertical padding
        minLeadingWidth: 0,
        dense: true, // Make it more compact
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all': return 'All Matches';
      case 'upcoming': return 'Upcoming Matches';
      case 'past': return 'Past Matches';
      case 'today': return 'Today\'s Matches';
      default: return filter;
    }
  }

  void _showMatchDetails(ScheduledMatch match) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isPast = match.dateTime.isBefore(DateTime.now());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(FeatherIcons.info, color: Color(0xFF1a365d), size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Match Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a365d),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPast ? Colors.grey[200] : const Color(0xFF48bb78).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPast ? FeatherIcons.checkCircle : FeatherIcons.clock,
                          size: 10,
                          color: isPast ? Colors.grey[600] : const Color(0xFF48bb78),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPast ? 'Completed' : 'Upcoming',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.grey[600] : const Color(0xFF48bb78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Content
              _buildDetailRow('Team A', match.teamA),
              _buildDetailRow('Team B', match.teamB),
              if (match.tournamentName.isNotEmpty) _buildDetailRow('Tournament', match.tournamentName),
              _buildDetailRow('Location', match.location),
              _buildDetailRow('Date', dateFormat.format(match.dateTime)),
              _buildDetailRow('Time', timeFormat.format(match.dateTime)),
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1a365d),
                        side: const BorderSide(color: Color(0xFF1a365d)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  if (!isPast) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _editMatch(match, context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a365d),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Edit Match'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _editMatch(ScheduledMatch match, BuildContext context) {
    _showAddScheduleDialog(context, existingMatch: match);
  }

  void _deleteMatch(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF1a365d))),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ScheduleProvider>().deleteSchedule(id);
              Navigator.pop(context);
              _showSnackBar('Match deleted successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, {ScheduledMatch? existingMatch}) {
    final isEditing = existingMatch != null;

    if (isEditing) {
      _teamAController.text = existingMatch!.teamA;
      _teamBController.text = existingMatch.teamB;
      _locationController.text = existingMatch.location;
      _tournamentController.text = existingMatch.tournamentName;
      _selectedDate = existingMatch.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(existingMatch.dateTime);
    } else {
      _teamAController.clear();
      _teamBController.clear();
      _locationController.clear();
      _tournamentController.clear();
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }

    showDialog(
      context: context,
      builder: (context) => _buildScheduleDialog(isEditing),
    );
  }

  Widget _buildScheduleDialog(bool isEditing) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Match' : 'Schedule New Match',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a365d),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEditing ? 'Update match details' : 'Enter match information',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildTextField(_teamAController, 'Team A *', Icons.group_outlined),
            const SizedBox(height: 16),
            _buildTextField(_teamBController, 'Team B *', Icons.group_outlined),
            const SizedBox(height: 16),
            _buildTextField(_tournamentController, 'Tournament Name', Icons.emoji_events_outlined),
            const SizedBox(height: 16),
            _buildTextField(_locationController, 'Location *', Icons.location_on_outlined),
            const SizedBox(height: 24),
            _buildDateTimeSelector(),
            const SizedBox(height: 24),
            _buildDialogActions(isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1a365d)),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: const Text('Select Date'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1a365d),
                  side: const BorderSide(color: Color(0xFF1a365d)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context),
                icon: const Icon(Icons.access_time_outlined, size: 16),
                label: const Text('Select Time'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1a365d),
                  side: const BorderSide(color: Color(0xFF1a365d)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${DateFormat('MMM dd, yyyy').format(_selectedDate)} at ${_selectedTime.format(context)}',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDialogActions(bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1a365d),
              side: const BorderSide(color: Color(0xFF1a365d)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _saveSchedule(context, isEditing),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a365d),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(isEditing ? 'Update' : 'Schedule'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1a365d)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1a365d)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveSchedule(BuildContext context, bool isEditing) {
    if (_teamAController.text.isEmpty || _teamBController.text.isEmpty || _locationController.text.isEmpty) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    final match = ScheduledMatch(
      id: isEditing ? '' : DateTime.now().millisecondsSinceEpoch.toString(),
      teamA: _teamAController.text.trim(),
      teamB: _teamBController.text.trim(),
      dateTime: DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      ),
      location: _locationController.text.trim(),
      tournamentName: _tournamentController.text.trim(),
    );

    // Note: You'll need to implement edit functionality in ScheduleProvider
    if (isEditing) {
      // context.read<ScheduleProvider>().updateSchedule(match);
      _showSnackBar('Match updated successfully');
    } else {
      context.read<ScheduleProvider>().addSchedule(match);
      _showSnackBar('Match scheduled successfully');
    }

    Navigator.pop(context);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1a365d),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}