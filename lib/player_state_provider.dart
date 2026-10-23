import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_state_model.dart';
import '../models/team_model.dart';
import 'dart:convert';

class PlayerStatsProvider with ChangeNotifier {
  List<BatsmanStats> _batsmenStats = [];
  List<BowlerStats> _bowlersStats = [];

  List<BatsmanStats> get batsmenStats => _batsmenStats;
  List<BowlerStats> get bowlersStats => _bowlersStats;

  static const String _batsmenStatsKey = 'player_stats_batsmen_v1';
  static const String _bowlersStatsKey = 'player_stats_bowlers_v1';

  List<BatsmanStats> get top5Batsmen {
    final sorted = List<BatsmanStats>.from(_batsmenStats)
      ..sort((a, b) => b.runs.compareTo(a.runs));
    return sorted.take(5).toList();
  }

  List<BowlerStats> get top5Bowlers {
    final sorted = List<BowlerStats>.from(_bowlersStats)
      ..sort((a, b) => b.wickets.compareTo(a.wickets));
    return sorted.take(5).toList();
  }

  void processCompletedMatch(TeamModel teamA, TeamModel teamB) {
    _processTeamBatsmen(teamA);
    _processTeamBatsmen(teamB);
    _processTeamBowlers(teamA);
    _processTeamBowlers(teamB);
    _savePlayerStats();
    debugBowlerStats();
    notifyListeners();
  }

  void _processTeamBatsmen(TeamModel team) {
    for (final batsman in team.batsmen) {
      if (batsman.ballsFaced > 0) { // Only process batsmen who actually batted
        final existingStats = _batsmenStats.firstWhere(
              (stats) => stats.playerName == batsman.name && stats.teamName == team.name,
          orElse: () => BatsmanStats(
            playerName: batsman.name,
            teamName: team.name,
            matchesPlayed: 0,
            lastUpdated: DateTime.now(),
            runs: 0,
            ballsFaced: 0,
            strikeRate: 0.0,
            fours: 0,
            sixes: 0,
            fifties: 0,
            hundreds: 0,
            average: 0.0,
            previousPosition: 0,
          ),
        );

        final oldPosition = _getBatsmanPosition(existingStats.runs);

        final newRuns = existingStats.runs + batsman.runs;
        final newBallsFaced = existingStats.ballsFaced + batsman.ballsFaced;
        final newFours = existingStats.fours + batsman.fours;
        final newSixes = existingStats.sixes + batsman.sixes;
        final newMatchesPlayed = existingStats.matchesPlayed + 1;

        // Calculate new stats
        final newStrikeRate = newBallsFaced > 0 ? (newRuns / newBallsFaced * 100) : 0.0;
        final newAverage = newMatchesPlayed > 0 ? newRuns / newMatchesPlayed : 0.0;

        // Count fifties and hundreds
        int newFifties = existingStats.fifties;
        int newHundreds = existingStats.hundreds;
        if (batsman.runs >= 100) {
          newHundreds++;
        } else if (batsman.runs >= 50) {
          newFifties++;
        }

        final updatedStats = BatsmanStats(
          playerName: batsman.name,
          teamName: team.name,
          matchesPlayed: newMatchesPlayed,
          lastUpdated: DateTime.now(),
          runs: newRuns,
          ballsFaced: newBallsFaced,
          strikeRate: newStrikeRate,
          fours: newFours,
          sixes: newSixes,
          fifties: newFifties,
          hundreds: newHundreds,
          average: newAverage,
          previousPosition: oldPosition,
        );

        if (existingStats.runs == 0) {
          _batsmenStats.add(updatedStats);
        } else {
          final index = _batsmenStats.indexWhere(
                  (stats) => stats.playerName == batsman.name && stats.teamName == team.name
          );
          if (index != -1) {
            _batsmenStats[index] = updatedStats;
          }
        }
      }
    }
  }

  void _processTeamBowlers(TeamModel team) {
    for (final bowler in team.bowlers) {
      final totalBalls = bowler.balls + (bowler.oversBowled * 6);
      if (totalBalls > 0) {
        final existingStats = _bowlersStats.firstWhere(
              (stats) => stats.playerName == bowler.name && stats.teamName == team.name,
          orElse: () => BowlerStats(
            playerName: bowler.name,
            teamName: team.name,
            matchesPlayed: 0,
            lastUpdated: DateTime.now(),
            wickets: 0,
            ballsBowled: 0,
            runsGiven: 0,
            economy: 0.0,
            average: 0.0,
            strikeRate: 0.0,
            threeWickets: 0,
            fiveWickets: 0,
            previousPosition: 0,
          ),
        );

        final oldPosition = _getBowlerPosition(existingStats.wickets);

        final newWickets = existingStats.wickets + bowler.wickets;
        final newBallsBowled = existingStats.ballsBowled + bowler.balls + (bowler.oversBowled * 6);
        final newRunsGiven = existingStats.runsGiven + bowler.runsGiven;
        final newMatchesPlayed = existingStats.matchesPlayed + 1;

        final newEconomy = newBallsBowled > 0 ? (newRunsGiven / newBallsBowled * 6) : 0.0;
        final newAverage = newWickets > 0 ? newRunsGiven / newWickets : 0.0;
        final newStrikeRate = newWickets > 0 ? newBallsBowled / newWickets : 0.0;

        int newThreeWickets = existingStats.threeWickets;
        int newFiveWickets = existingStats.fiveWickets;
        if (bowler.wickets >= 5) {
          newFiveWickets++;
        } else if (bowler.wickets >= 3) {
          newThreeWickets++;
        }

        final updatedStats = BowlerStats(
          playerName: bowler.name,
          teamName: team.name,
          matchesPlayed: newMatchesPlayed,
          lastUpdated: DateTime.now(),
          wickets: newWickets,
          ballsBowled: newBallsBowled,
          runsGiven: newRunsGiven,
          economy: newEconomy,
          average: newAverage,
          strikeRate: newStrikeRate,
          threeWickets: newThreeWickets,
          fiveWickets: newFiveWickets,
          previousPosition: oldPosition,
        );

        if (existingStats.wickets == 0) {
          _bowlersStats.add(updatedStats);
        } else {
          final index = _bowlersStats.indexWhere(
                  (stats) => stats.playerName == bowler.name && stats.teamName == team.name
          );
          if (index != -1) {
            _bowlersStats[index] = updatedStats;
          }
        }
      }
    }
  }

  int _getBatsmanPosition(int runs) {
    final sorted = List<BatsmanStats>.from(_batsmenStats)
      ..sort((a, b) => b.runs.compareTo(a.runs));

    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].runs == runs) {
        return i + 1;
      }
    }
    return 0;
  }

  int _getBowlerPosition(int wickets) {
    final sorted = List<BowlerStats>.from(_bowlersStats)
      ..sort((a, b) => b.wickets.compareTo(a.wickets));

    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].wickets == wickets) {
        return i + 1;
      }
    }
    return 0;
  }

  Future<void> loadPlayerStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load batsmen stats
      final batsmenJson = prefs.getString(_batsmenStatsKey);
      if (batsmenJson != null) {
        final List<dynamic> batsmenList = json.decode(batsmenJson);
        _batsmenStats = batsmenList
            .map((stats) => BatsmanStats.fromJson(stats))
            .toList();
      }

      // Load bowlers stats
      final bowlersJson = prefs.getString(_bowlersStatsKey);
      if (bowlersJson != null) {
        final List<dynamic> bowlersList = json.decode(bowlersJson);
        _bowlersStats = bowlersList
            .map((stats) => BowlerStats.fromJson(stats))
            .toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading player stats: $e');
    }
  }

  Future<void> _savePlayerStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save batsmen stats
      final batsmenJson = json.encode(
        _batsmenStats.map((stats) => stats.toJson()).toList(),
      );
      await prefs.setString(_batsmenStatsKey, batsmenJson);

      // Save bowlers stats
      final bowlersJson = json.encode(
        _bowlersStats.map((stats) => stats.toJson()).toList(),
      );
      await prefs.setString(_bowlersStatsKey, bowlersJson);
    } catch (e) {
      debugPrint('Error saving player stats: $e');
    }
  }

  Future<void> clearAllStats() async {
    _batsmenStats.clear();
    _bowlersStats.clear();
    await _savePlayerStats();
    notifyListeners();
  }

  void debugCurrentState() {
    debugPrint('=== CURRENT PLAYER STATS STATE ===');
    debugPrint('Total Batsmen in stats: ${_batsmenStats.length}');
    debugPrint('Total Bowlers in stats: ${_bowlersStats.length}');

    if (_batsmenStats.isNotEmpty) {
      debugPrint('BATSMEN:');
      for (var i = 0; i < _batsmenStats.length; i++) {
        final batsman = _batsmenStats[i];
        debugPrint('  $i. ${batsman.playerName} (${batsman.teamName}): ${batsman.runs} runs, ${batsman.matchesPlayed} matches');
      }
    } else {
      debugPrint('No batsmen stats available');
    }

    if (_bowlersStats.isNotEmpty) {
      debugPrint('BOWLERS:');
      for (var i = 0; i < _bowlersStats.length; i++) {
        final bowler = _bowlersStats[i];
        debugPrint('  $i. ${bowler.playerName} (${bowler.teamName}): ${bowler.wickets} wickets, ${bowler.matchesPlayed} matches');
      }
    } else {
      debugPrint('No bowlers stats available');
    }

    debugPrint('Top 5 Batsmen count: ${top5Batsmen.length}');
    debugPrint('Top 5 Bowlers count: ${top5Bowlers.length}');
    debugPrint('=== END DEBUG ===');
  }

  void debugBowlerStats() {
    debugPrint('=== BOWLER STATS DEBUG ===');
    debugPrint('Total bowlers in stats: ${_bowlersStats.length}');

    for (var i = 0; i < _bowlersStats.length; i++) {
      final stats = _bowlersStats[i];
      debugPrint('${i + 1}. ${stats.playerName} (${stats.teamName}):');
      debugPrint('   - Wickets: ${stats.wickets}');
      debugPrint('   - Balls Bowled: ${stats.ballsBowled}');
      debugPrint('   - Matches: ${stats.matchesPlayed}');
    }

    debugPrint('Top 5 Bowlers: ${top5Bowlers.length}');
    for (var i = 0; i < top5Bowlers.length; i++) {
      final bowler = top5Bowlers[i];
      debugPrint('   ${i + 1}. ${bowler.playerName} - ${bowler.wickets} wickets');
    }
    debugPrint('=== END DEBUG ===');
  }
}

extension BatsmanStatsCopyWith on BatsmanStats {
  BatsmanStats copyWith({
    String? playerName,
    String? teamName,
    int? matchesPlayed,
    DateTime? lastUpdated,
    int? runs,
    int? ballsFaced,
    double? strikeRate,
    int? fours,
    int? sixes,
    int? fifties,
    int? hundreds,
    double? average,
    int? previousPosition,
  }) {
    return BatsmanStats(
      playerName: playerName ?? this.playerName,
      teamName: teamName ?? this.teamName,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      runs: runs ?? this.runs,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      strikeRate: strikeRate ?? this.strikeRate,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      fifties: fifties ?? this.fifties,
      hundreds: hundreds ?? this.hundreds,
      average: average ?? this.average,
      previousPosition: previousPosition ?? this.previousPosition,
    );
  }
}

extension BowlerStatsCopyWith on BowlerStats {
  BowlerStats copyWith({
    String? playerName,
    String? teamName,
    int? matchesPlayed,
    DateTime? lastUpdated,
    int? wickets,
    int? ballsBowled,
    int? runsGiven,
    double? economy,
    double? average,
    double? strikeRate,
    int? threeWickets,
    int? fiveWickets,
    int? previousPosition,
  }) {
    return BowlerStats(
      playerName: playerName ?? this.playerName,
      teamName: teamName ?? this.teamName,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      wickets: wickets ?? this.wickets,
      ballsBowled: ballsBowled ?? this.ballsBowled,
      runsGiven: runsGiven ?? this.runsGiven,
      economy: economy ?? this.economy,
      average: average ?? this.average,
      strikeRate: strikeRate ?? this.strikeRate,
      threeWickets: threeWickets ?? this.threeWickets,
      fiveWickets: fiveWickets ?? this.fiveWickets,
      previousPosition: previousPosition ?? this.previousPosition,
    );
  }
}