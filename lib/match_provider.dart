import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batsman_model.dart';
import '../models/bowler_model.dart';
import '../models/team_model.dart';

enum ExtraType { wide, bye, legBye, noBall, none }

class MatchProvider with ChangeNotifier {
  TeamModel teamA;
  TeamModel teamB;
  bool isTeamABatting;
  String? lastEvent;
  List<Map<String, dynamic>> savedMatches = [];
  int totalOvers = 0;
  bool _isLoadingMatches = false;
  VoidCallback? _onMatchComplete;
  String? _lastBowlerName;

  MatchProvider({
    required this.teamA,
    required this.teamB,
    this.isTeamABatting = true,
    this.lastEvent,
    this.savedMatches = const [],
    this.totalOvers = 0,
  });

  TeamModel get battingTeam => isTeamABatting ? teamA : teamB;
  TeamModel get bowlingTeam => isTeamABatting ? teamB : teamA;

  static const _prefsKey = 'cricket_match_state_v1';



  bool get isFirstInningComplete {
    if (totalOvers == 0) return false;

    final currentInnings = battingTeam;
    final oversBowled = currentInnings.ballsBowled ~/ 6;
    final ballsInOver = currentInnings.ballsBowled % 6;

    return (oversBowled >= totalOvers && ballsInOver >= 0) || currentInnings.wicketsLost >= 10;
  }

  bool get isSecondInning => !isTeamABatting;

  int get target {
    if (isSecondInning) {
      return teamA.totalRuns + 1;
    }
    return 0;
  }

  double get requiredRunRate {
    if (!isSecondInning || target == 0) return 0.0;

    final runsNeeded = target - battingTeam.totalRuns;
    final ballsRemaining = (totalOvers * 6) - battingTeam.ballsBowled;
    final oversRemaining = ballsRemaining / 6;

    if (oversRemaining > 0 && runsNeeded > 0) {
      return runsNeeded / oversRemaining;
    }
    return 0.0;
  }

  Future<void> saveToLocalDb() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'teamA': teamA.toJson(),
      'teamB': teamB.toJson(),
      'isTeamABatting': isTeamABatting,
      'lastEvent': lastEvent,
      'totalOvers': totalOvers,
      'lastBowlerName':_lastBowlerName,
    };
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> saveCurrentMatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedMatchesJson = prefs.getStringList('saved_matches') ?? [];

      // Create a clean, serializable match object with proper data validation
      final matchData = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'timestamp': DateTime.now().toIso8601String(),
        'result': _getCurrentMatchResult(),
        'totalOvers': totalOvers,
        'teamA': _serializeTeam(teamA),
        'teamB': _serializeTeam(teamB),
      };

      // Validate the match data before saving
      _validateMatchData(matchData);

      // Convert to JSON string
      final matchJson = jsonEncode(matchData);
      savedMatchesJson.add(matchJson);

      // Save to SharedPreferences
      await prefs.setStringList('saved_matches', savedMatchesJson);

      // Update the local state by loading the saved matches
      await loadSavedMatches();

      debugPrint('Match saved successfully! Total saved matches: ${savedMatches.length}');

    } catch (e) {
      debugPrint('Error saving match: $e');
      throw Exception('Failed to save match: $e');
    }
  }

  Map<String, dynamic> _serializeTeam(TeamModel team) {
    try {
      return {
        'name': team.name ,
        'totalRuns': team.totalRuns,
        'wicketsLost': team.wicketsLost,
        'ballsBowled': team.ballsBowled,
        'fallOfWickets': team.fallOfWickets.map((f) => f.toString()).toList(),
        'currentBowlerIndex': team.currentBowlerIndex,
        'batsmen': team.batsmen.map((batsman) => _serializeBatsman(batsman)).toList(),
        'bowlers': team.bowlers.map((bowler) => _serializeBowler(bowler)).toList(),
      };
    } catch (e) {
      debugPrint('Error serializing team: $e');
      return {
        'name': 'Corrupted Team',
        'totalRuns': 0,
        'wicketsLost': 0,
        'ballsBowled': 0,
        'fallOfWickets': [],
        'currentBowlerIndex': -1,
        'batsmen': [],
        'bowlers': [],
      };
    }
  }

  Map<String, dynamic> _serializeBatsman(BatsmanModel batsman) {
    return {
      'name': batsman.name,
      'runs': batsman.runs,
      'ballsFaced': batsman.ballsFaced,
      'fours': batsman.fours,
      'sixes': batsman.sixes,
      'isOut': batsman.isOut,
      'isOnStrike': batsman.isOnStrike,
      'dismissedBy': batsman.dismissedBy,
      'dismissalType': batsman.dismissalType,
    };
  }

  Map<String, dynamic> _serializeBowler(BowlerModel bowler) {
    return {
      'name': bowler.name,
      'oversBowled': bowler.oversBowled,
      'balls': bowler.balls,
      'runsGiven': bowler.runsGiven,
      'wickets': bowler.wickets,
    };
  }

  void _validateMatchData(Map<String, dynamic> matchData) {
    final requiredFields = ['id', 'timestamp', 'result', 'totalOvers', 'teamA', 'teamB'];

    for (final field in requiredFields) {
      if (!matchData.containsKey(field)) {
        throw Exception('Missing required field: $field');
      }
    }

    if (matchData['teamA'] == null || matchData['teamB'] == null) {
      throw Exception('Team data is null');
    }

    if (matchData['id'] == null) {
      throw Exception('Match ID is null');
    }
  }

  String _getCurrentMatchResult() {
    if (!isMatchComplete) {
      if (isSecondInning) {
        final runsNeeded = target - teamB.totalRuns;
        //final wicketsLeft = 10 - teamB.wicketsLost;
        return '${teamB.name} need $runsNeeded runs to win';
      } else {
        return '${teamA.name} batting - ${teamA.totalRuns}/${teamA.wicketsLost}';
      }
    } else {
      if (teamA.totalRuns > teamB.totalRuns) {
        return '${teamA.name} won by ${teamA.totalRuns - teamB.totalRuns} runs';
      } else if (teamB.totalRuns > teamA.totalRuns) {
        final wicketsLeft = 10 - teamB.wicketsLost;
        return '${teamB.name} won by $wicketsLeft wickets';
      } else {
        return 'Match tied';
      }
    }
  }

  Future<void> loadSavedMatches() async {
    if (_isLoadingMatches) {
      return;
    }

    _isLoadingMatches = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMatchesJson = prefs.getStringList('saved_matches') ?? [];

      final List<Map<String, dynamic>> matches = [];

      for (final matchJson in savedMatchesJson) {
        try {
          final matchData = jsonDecode(matchJson) as Map<String, dynamic>;

          if (_isValidMatchData(matchData)) {
            matches.add(matchData);
          }
        } catch (e) {
          continue;
        }
      }

      savedMatches = matches;
      notifyListeners();
      debugPrint('Loaded ${savedMatches.length} saved matches from storage');

    } catch (e) {
      debugPrint('Error loading saved matches: $e');
      savedMatches = [];
      notifyListeners();
    } finally {
      _isLoadingMatches = false;
    }
  }

  bool _isValidMatchData(Map<String, dynamic> matchData) {
    try {
      final requiredFields = ['id', 'timestamp', 'result', 'totalOvers', 'teamA', 'teamB'];

      for (final field in requiredFields) {
        if (!matchData.containsKey(field)) {
          debugPrint('Missing field in match data: $field');
          return false;
        }
      }

      // Check if team data exists and has basic structure
      final teamA = matchData['teamA'] as Map<String, dynamic>?;
      final teamB = matchData['teamB'] as Map<String, dynamic>?;

      if (teamA == null || teamB == null) {
        debugPrint('Team data is null');
        return false;
      }

      if (teamA['name'] == null || teamB['name'] == null) {
        debugPrint('Team names are null');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating match data: $e');
      return false;
    }
  }

  Future<void> deleteMatch(int matchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedMatchesJson = prefs.getStringList('saved_matches') ?? [];

      // Remove the match with the given ID
      final updatedMatches = savedMatchesJson.where((matchJson) {
        try {
          final matchData = jsonDecode(matchJson) as Map<String, dynamic>;
          return matchData['id'] != matchId;
        } catch (e) {
          debugPrint('Error parsing match during deletion: $e');
          return true; // Keep corrupted entries
        }
      }).toList();

      // Save the updated list back to SharedPreferences
      await prefs.setStringList('saved_matches', updatedMatches);

      // Reload the saved matches to update the UI
      await loadSavedMatches();

      debugPrint('Match $matchId deleted successfully. Remaining matches: ${savedMatches.length}');

    } catch (e) {
      debugPrint('Error deleting match: $e');
      rethrow;
    }
  }

  // Map<String, dynamic> _copyTeamData(TeamModel team) {
  //   return {
  //     'name': team.name,
  //     'totalRuns': team.totalRuns,
  //     'wicketsLost': team.wicketsLost,
  //     'ballsBowled': team.ballsBowled,
  //     'fallOfWickets': List<String>.from(team.fallOfWickets),
  //     'currentBowlerIndex': team.currentBowlerIndex,
  //     'batsmen': team.batsmen.map((batsman) => batsman.toJson()).toList(),
  //     'bowlers': team.bowlers.map((bowler) => bowler.toJson()).toList(),
  //   };
  // }

  String _calculateResult() {
    if (teamA.totalRuns > teamB.totalRuns) {
      final runsDifference = teamA.totalRuns - teamB.totalRuns;
      return '${teamA.name} won by $runsDifference runs';
    } else if (teamB.totalRuns > teamA.totalRuns) {
      final wicketsLeft = 10 - teamB.wicketsLost;
      return '${teamB.name} won by $wicketsLeft wickets';
    } else {
      return 'Match tied';
    }
  }

  static Future<MatchProvider> loadFromLocalDb() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKey);

    MatchProvider provider;
    if (s == null) {
      final tA = TeamModel(name: 'Team A', batsmen: [], bowlers: []);
      final tB = TeamModel(name: 'Team B', batsmen: [], bowlers: []);
      provider = MatchProvider(teamA: tA, teamB: tB);
    } else {
      final data = jsonDecode(s);
      final tA = TeamModel.fromJson(data['teamA']);
      final tB = TeamModel.fromJson(data['teamB']);
      provider = MatchProvider(
        teamA: tA,
        teamB: tB,
        isTeamABatting: data['isTeamABatting'] ?? true,
        lastEvent: data['lastEvent'],
        totalOvers: data['totalOvers'] ?? 0,
      );
      provider._lastBowlerName = data['lastBowlerName'];
    }

    await provider.loadSavedMatches();
    return provider;
  }

  void _setLastEvent(String e) {
    lastEvent = e;
    notifyListeners();
    saveToLocalDb(); // Save state after every event
  }

  void setLastEvent(String e) {
    _setLastEvent(e);
  }

  void setTotalOvers(int overs) {
    totalOvers = overs;
    saveToLocalDb(); // Save state
    notifyListeners();
  }

  void addTeam(String name, {bool toTeamA = true}) {
    if (toTeamA) {
      teamA = TeamModel(name: name, batsmen: teamA.batsmen, bowlers: teamA.bowlers);
    } else {
      teamB = TeamModel(name: name, batsmen: teamB.batsmen, bowlers: teamB.bowlers);
    }
    saveToLocalDb(); // Save state
    notifyListeners();
  }

  void addBatsmanToTeam(bool toTeamA, BatsmanModel b) {
    final t = toTeamA ? teamA : teamB;
    t.batsmen.add(b);

    // Auto-assign strike if this is the first batsman
    if (t.batsmen.length == 1) {
      b.isOnStrike = true;
    }

    saveToLocalDb(); // Save state
    notifyListeners();
  }

  void addBowlerToTeam(bool toTeamA, BowlerModel b) {
    final t = toTeamA ? teamA : teamB;
    t.bowlers.add(b);
    saveToLocalDb(); // Save state
    notifyListeners();
  }

  void setCurrentBowler(int index) {
    final selectedBowler = bowlingTeam.bowlers[index];

    // Prevent same bowler from bowling consecutive overs
    if (_lastBowlerName == selectedBowler.name) {
      _setLastEvent('Cannot select ${selectedBowler.name} for consecutive overs');
      return;
    }

    bowlingTeam.currentBowlerIndex = index;
    _setLastEvent('Bowler selected: ${selectedBowler.name}');
  }

  BowlerModel? get currentBowler {
    final idx = bowlingTeam.currentBowlerIndex;
    if (idx >= 0 && idx < bowlingTeam.bowlers.length) return bowlingTeam.bowlers[idx];
    return null;
  }

  bool get canStartMatch {
    return battingTeam.batsmen.isNotEmpty &&
        bowlingTeam.bowlers.isNotEmpty &&
        currentBowler != null &&
        totalOvers > 0;
  }

  bool get isMatchComplete {
    if (totalOvers == 0) return false;

    if (isSecondInning) {
      final currentInnings = battingTeam;
      final oversBowled = currentInnings.ballsBowled ~/ 6;

      return oversBowled >= totalOvers ||
          currentInnings.wicketsLost >= 10 ||
          currentInnings.totalRuns >= target;
    }

    return false;
  }

  void addLegalDeliveryOffBat(int runs) {
    if (!canStartMatch) {
      _setLastEvent('Cannot add runs: Complete match setup first');
      return;
    }

    if (isMatchComplete) {
      _setLastEvent('Match complete! Cannot add more runs');
      return;
    }

    final t = battingTeam;
    if (t.batsmen.isEmpty) return;

    // Ensure there's a striker
    if (t.batsmen.every((b) => !b.isOnStrike)) {
      t.batsmen[0].isOnStrike = true;
    }

    final striker = t.batsmen.firstWhere((b) => b.isOnStrike);

    striker.runs += runs;
    striker.ballsFaced++;
    if (runs == 4) striker.fours++;
    if (runs == 6) striker.sixes++;

    t.totalRuns += runs;
    t.ballsBowled++;

    final bowler = currentBowler;
    if (bowler != null) {
      bowler.addBall(runs, isWicket: false, isLegal: true);
    }

    if (runs % 2 == 1) _changeStrike();

    _setLastEvent('${striker.name} scored $runs');
    _afterDeliveryCheck();
  }

  void addDotBall() {
    if (!canStartMatch) {
      _setLastEvent('Cannot add dot ball: Complete match setup first');
      return;
    }

    if (isMatchComplete) {
      _setLastEvent('Match complete! Cannot add more balls');
      return;
    }

    final t = battingTeam;
    if (t.batsmen.isEmpty) return;

    // Ensure there's a striker and increment their balls faced
    if (t.batsmen.every((b) => !b.isOnStrike)) {
      t.batsmen[0].isOnStrike = true;
    }

    final striker = t.batsmen.firstWhere((b) => b.isOnStrike);
    striker.ballsFaced++;

    t.ballsBowled++;
    final bowler = currentBowler;
    if (bowler != null) bowler.addBall(0, isWicket: false, isLegal: true);

    _setLastEvent('Dot ball');
    _afterDeliveryCheck();
  }

  void completeMatch() {
    if (isMatchComplete) {
      debugPrint('Match completed! Triggering stats processing...');
      _processMatchCompletion();
    } else {
      debugPrint('Match not complete yet. Current state:');
      debugPrint('  - Second Inning: $isSecondInning');
      debugPrint('  - Overs: ${battingTeam.ballsBowled ~/ 6}.${battingTeam.ballsBowled % 6}/$totalOvers');
      debugPrint('  - Wickets: ${battingTeam.wicketsLost}/10');
      if (isSecondInning) {
        debugPrint('  - Runs: ${battingTeam.totalRuns}/$target');
      }
    }
  }

  Future<void> addExtras
      (ExtraType type, int runs,
      {bool noBallHasBatsmanRuns = false, int batsmanRunsOnNoBall = 0})
  async {
    if (!canStartMatch) {
      _setLastEvent('Cannot add extras: Complete match setup first');
      return;
    }

    if (isMatchComplete) {
      _setLastEvent('Match complete! Cannot add more extras');
      return;
    }

    final t = battingTeam;
    final bowler = currentBowler;

    switch (type) {
      case ExtraType.wide:
        final penaltyRun = 1;
        final totalWideRuns = penaltyRun + runs;


        t.wides += penaltyRun;
        t.totalRuns += totalWideRuns;

        if (bowler != null) {
          bowler.runsGiven += penaltyRun;
          bowler.addBall(0, isWicket: false, isLegal: false);
        }

        if (totalWideRuns % 2 != 1) {
          _changeStrike();
        }

        if (runs > 0) {
          _setLastEvent('Wide +$totalWideRuns ($runs runs)');
        } else {
          _setLastEvent('Wide');
        }
        break;

      case ExtraType.noBall:
        final penaltyRun = 1;
        final totalNoBallRuns = penaltyRun + (noBallHasBatsmanRuns ? batsmanRunsOnNoBall : 0);

        t.noBalls += penaltyRun;
        t.totalRuns += totalNoBallRuns;

        if (bowler != null) {
          bowler.runsGiven += totalNoBallRuns;
          bowler.addBall(0, isWicket: false, isLegal: false);
        }
        if (t.batsmen.isNotEmpty) {
          final striker = t.batsmen.firstWhere((b) => b.isOnStrike);
          striker.ballsFaced++;

          if (noBallHasBatsmanRuns && batsmanRunsOnNoBall > 0) {
            striker.runs += batsmanRunsOnNoBall;
            if (batsmanRunsOnNoBall == 4) striker.fours++;
            if (batsmanRunsOnNoBall == 6) striker.sixes++;

            if (totalNoBallRuns % 2 != 1) {
              _changeStrike();
            }
            _setLastEvent(
                'No ball +$totalNoBallRuns ($batsmanRunsOnNoBall by ${striker
                    .name})');
          }
        }
        else {
          _setLastEvent('No ball');
        }
        break;

      case ExtraType.bye:
        t.byes += runs;
        t.totalRuns += runs;
        t.ballsBowled++;

        if (bowler != null) {
          bowler.addBall(0, isWicket: false, isLegal: true);
        }

        if (t.batsmen.isNotEmpty) {
          final striker = t.batsmen.firstWhere((b) => b.isOnStrike);
          striker.ballsFaced++;

          if (runs % 2 == 1) {
            _changeStrike();
          }
        }

        _setLastEvent('Bye +$runs');
        _afterDeliveryCheck();
        break;

      case ExtraType.legBye:
        t.legByes += runs;
        t.totalRuns += runs;
        t.ballsBowled++;

        if (bowler != null) {
          bowler.addBall(0, isWicket: false, isLegal: true);
        }

        if (t.batsmen.isNotEmpty) {
          final striker = t.batsmen.firstWhere((b) => b.isOnStrike);
          striker.ballsFaced++;

          if (runs % 2 == 1) {
            _changeStrike();
          }
        }

        _setLastEvent('Leg bye +$runs');
        _afterDeliveryCheck();
        break;

      case ExtraType.none:
        _setLastEvent('No extras added');
        break;
    }

    saveToLocalDb();
    notifyListeners();
  }


  Future<void> addWicket(String dismissalInfo) async {
    if (!canStartMatch) {
      _setLastEvent('Cannot add wicket: Complete match setup first');
      return;
    }

    if (isMatchComplete) {
      _setLastEvent('Match complete! Cannot add more wickets');
      return;
    }

    final t = battingTeam;

    // Find the striker who got out
    final strikerIndex = t.batsmen.indexWhere((b) => b.isOnStrike);
    if (strikerIndex == -1) {
      if (t.batsmen.isNotEmpty) {
        t.batsmen[0].isOnStrike = true;
      } else {
        return;
      }
    }

    final outBatsman = t.batsmen.firstWhere((b) => b.isOnStrike);

    // Get bowler name for the wicket
    final bowlerName = currentBowler?.name ?? 'Unknown';

    // Create fall of wicket entry with bowler name
    final fo = '${t.wicketsLost + 1}. ${outBatsman.name} ${outBatsman.runs} (${t.totalRuns}/${t.wicketsLost}) at ${t.oversString} - $dismissalInfo b $bowlerName';
    t.fallOfWickets.add(fo);

    // Store bowler name with batsman
    outBatsman.dismissedBy = bowlerName;
    outBatsman.dismissalType = dismissalInfo;

    // Update team wickets
    t.wicketsLost++;

    // Update bowler wickets (only if not run out)
    final bowler = currentBowler;
    if (bowler != null && !dismissalInfo.toLowerCase().contains('run out')) {
      bowler.wickets++;
      bowler.addBall(0, isWicket: true, isLegal: true);
    } else if (bowler != null) {
      // For run out, just count the ball but not the wicket
      bowler.addBall(0, isWicket: false, isLegal: true);
    }

    // Update team balls
    t.ballsBowled++;

    // Mark batsman as out
    outBatsman.isOut = true;
    outBatsman.isOnStrike = false;

    // Set next available batsman on strike
    final availableBatsmen = t.batsmen.where((b) => !b.isOut).toList();
    if (availableBatsmen.isNotEmpty) {
      availableBatsmen.first.isOnStrike = true;
    }

    _setLastEvent('WICKET! ${outBatsman.name} ${outBatsman.runs} - $dismissalInfo');
    _afterDeliveryCheck();
  }

  Future<void> addRunOut(int runsScored, String batsmanOut) async {
    if (!canStartMatch) {
      _setLastEvent('Cannot add run out: Complete match setup first');
      return;
    }

    if (isMatchComplete) {
      _setLastEvent('Match complete! Cannot add more actions');
      return;
    }

    final t = battingTeam;

    // Add the runs first (if any)
    if (runsScored > 0) {
      // Ensure there's a striker
      if (t.batsmen.every((b) => !b.isOnStrike)) {
        t.batsmen[0].isOnStrike = true;
      }

      final striker = t.batsmen.firstWhere((b) => b.isOnStrike);

      // Update batsman stats
      striker.runs += runsScored;
      striker.ballsFaced++;
      if (runsScored == 4) striker.fours++;
      if (runsScored == 6) striker.sixes++;

      // Update team
      t.totalRuns += runsScored;
      t.ballsBowled++; // Count the ball for runs

      // Update bowler
      final bowler = currentBowler;
      if (bowler != null) {
        bowler.addBall(runsScored, isWicket: false, isLegal: true);
      }

      // Change strike for odd runs
      if (runsScored % 2 == 1) _changeStrike();
    } else {
      // If no runs scored, still count the ball
      t.ballsBowled++;
      final bowler = currentBowler;
      if (bowler != null) {
        bowler.addBall(0, isWicket: false, isLegal: true);
      }
    }

    // Now add the wicket
    final outBatsman = t.batsmen.firstWhere((b) => b.name == batsmanOut, orElse: () => t.batsmen.firstWhere((b) => b.isOnStrike));

    // Create fall of wicket entry for run out
    final fo = '${t.wicketsLost + 1}. ${outBatsman.name} ${outBatsman.runs} (${t.totalRuns}/${t.wicketsLost}) at ${t.oversString} - Run Out';
    t.fallOfWickets.add(fo);

    // Store dismissal info
    outBatsman.dismissedBy = 'Run Out';
    outBatsman.dismissalType = 'Run Out';

    // Update team wickets
    t.wicketsLost++;

    // Mark batsman as out
    outBatsman.isOut = true;
    outBatsman.isOnStrike = false;

    // Set next available batsman on strike
    final availableBatsmen = t.batsmen.where((b) => !b.isOut).toList();
    if (availableBatsmen.isNotEmpty) {
      availableBatsmen.first.isOnStrike = true;
    }

    _setLastEvent('RUN OUT! ${outBatsman.name} run out after scoring $runsScored runs');
    _afterDeliveryCheck();
  }

  void changeStrikeManually(int batsmanIndex) {
    final t = battingTeam;
    if (batsmanIndex < 0 || batsmanIndex >= t.batsmen.length) return;

    for (var batsman in t.batsmen) {
      batsman.isOnStrike = false;
    }

    t.batsmen[batsmanIndex].isOnStrike = true;

    _setLastEvent('Strike manually changed to ${t.batsmen[batsmanIndex].name}');
    saveToLocalDb(); // Save state
    notifyListeners();
  }

  void _changeStrike() {
    final t = battingTeam;
    if (t.batsmen.length < 2) return;

    final strikerIdx = t.batsmen.indexWhere((b) => b.isOnStrike && !b.isOut);
    if (strikerIdx == -1) {
      final firstAvailable = t.batsmen.indexWhere((b) => !b.isOut);
      if (firstAvailable != -1) {
        t.batsmen[firstAvailable].isOnStrike = true;
      }
      return;
    }

    for (int i = 0; i < t.batsmen.length; i++) {
      if (i != strikerIdx && !t.batsmen[i].isOut) {
        t.batsmen[strikerIdx].isOnStrike = false;
        t.batsmen[i].isOnStrike = true;
        break;
      }
    }

    saveToLocalDb(); // Save state
    notifyListeners();
  }

  void _checkAndSwitchInnings() {
    if (isFirstInningComplete && !isSecondInning) {
      // First inning completed, switch to second inning
      switchInnings();

      // Reset second innings stats but keep team structure
      final secondInningsTeam = battingTeam;
      secondInningsTeam.totalRuns = 0;
      secondInningsTeam.wicketsLost = 0;
      secondInningsTeam.ballsBowled = 0;
      secondInningsTeam.fallOfWickets.clear();

      // Reset batsmen for second innings
      for (var batsman in secondInningsTeam.batsmen) {
        batsman.runs = 0;
        batsman.ballsFaced = 0;
        batsman.fours = 0;
        batsman.sixes = 0;
        batsman.isOut = false;
        batsman.isOnStrike = false;
        batsman.dismissedBy = null;
        batsman.dismissalType = null;
      }

      // Set first two batsmen on strike/non-strike
      if (secondInningsTeam.batsmen.length >= 2) {
        secondInningsTeam.batsmen[0].isOnStrike = true;
        secondInningsTeam.batsmen[1].isOnStrike = false;
      } else if (secondInningsTeam.batsmen.isNotEmpty) {
        secondInningsTeam.batsmen[0].isOnStrike = true;
      }

      // Reset bowlers for second innings
      for (var bowler in bowlingTeam.bowlers) {
        bowler.oversBowled = 0;
        bowler.balls = 0;
        bowler.runsGiven = 0;
        bowler.wickets = 0;
      }

      bowlingTeam.currentBowlerIndex = -1;

      _setLastEvent('First innings complete! Target: $target runs. Required RR: ${requiredRunRate.toStringAsFixed(2)}');
    }
  }

  void _afterDeliveryCheck() {
    final t = battingTeam;
    final overBalls = t.ballsBowled % 6;

    if (overBalls == 0) {
      _changeStrike();

      // Track the current bowler as the last bowler before resetting
      final currentBowler = this.currentBowler;
      if (currentBowler != null) {
        _lastBowlerName = currentBowler.name;
      }

      // Reset current bowler for next over
      bowlingTeam.currentBowlerIndex = -1;

      _setLastEvent('Over complete, choose next bowler');
    }

    _checkAndSwitchInnings();

    if (isMatchComplete) {
      _setLastEvent('Match complete! ${_calculateResult()}');
      _processMatchCompletion();
    }

    saveToLocalDb();
    notifyListeners();
  }

  void switchInnings() {
    isTeamABatting = !isTeamABatting;

    // Reset bowler tracking for new innings
    _lastBowlerName = null;
    bowlingTeam.currentBowlerIndex = -1;

    if (battingTeam.batsmen.isNotEmpty) {
      for (var batsman in battingTeam.batsmen) {
        batsman.isOnStrike = false;
      }
      final firstAvailable = battingTeam.batsmen.indexWhere((b) => !b.isOut);
      if (firstAvailable != -1) {
        battingTeam.batsmen[firstAvailable].isOnStrike = true;
      }
    }

    _setLastEvent('Innings switched, now batting: ${battingTeam.name}');
  }

  Future<void> resetMatch() async {
    teamA = TeamModel(
      name: teamA.name, // Keep team name
      batsmen: [],
      bowlers: [],
      totalRuns: 0,
      wicketsLost: 0,
      ballsBowled: 0,
      fallOfWickets: [],
      currentBowlerIndex: -1,
    );

    teamB = TeamModel(
      name: teamB.name, // Keep team name
      batsmen: [],
      bowlers: [],
      totalRuns: 0,
      wicketsLost: 0,
      ballsBowled: 0,
      fallOfWickets: [],
      currentBowlerIndex: -1,
    );

    isTeamABatting = true;
    lastEvent = null;
    totalOvers = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  void setOnMatchCompleteCallback(VoidCallback callback) {
    _onMatchComplete = callback;
    debugPrint('Match completion callback set');
  }

  void _processMatchCompletion() {
    debugPrint('Checking match completion...');
    debugPrint('  - isMatchComplete: $isMatchComplete');
    debugPrint('  - isSecondInning: $isSecondInning');
    debugPrint('  - _onMatchComplete callback: ${_onMatchComplete != null}');

    if (isMatchComplete) {
      debugPrint('MATCH COMPLETE! Calling callback...');
      _onMatchComplete?.call();
      debugPrint('Callback executed');
    } else {
      debugPrint('Match not complete, skipping callback');
    }
  }

  void debugCallbackStatus() {
    debugPrint('CALLBACK STATUS:');
    debugPrint('  - _onMatchComplete is null: ${_onMatchComplete == null}');
    debugPrint('  - _onMatchComplete is set: ${_onMatchComplete != null}');
  }
}