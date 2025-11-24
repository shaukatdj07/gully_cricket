import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../models/batsman_model.dart';
import '../models/bowler_model.dart';
import '../models/team_model.dart';
import '../providers/match_provider.dart';
import '../providers/player_state_provider.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _teamNameCtrl = TextEditingController();
  final TextEditingController _playerNameCtrl = TextEditingController();
  final TextEditingController _oversCtrl = TextEditingController();

  // Controllers for setup screen
  final TextEditingController _teamAController = TextEditingController();
  final TextEditingController _teamBController = TextEditingController();

  String? _tossWinner;
  String? _battingChoice;
  String? _selectedStriker;
  String? _selectedNonStriker;
  String? _selectedBowler;

  List<String> _teamAPlayers = [];
  List<String> _teamBPlayers = [];

  bool _showSetupScreen = true;

  late AnimationController _animationController;
  late Animation<double> _wicketAnimation;
  late Animation<Offset> _ballAnimation;
  late Animation<Offset> _runoutAnimation;

  bool _showWicketAnimation = false;
  bool _showRunoutAnimation = false;
  bool _showAddBatsmanPrompt = false;
  bool _showCelebration = false;
  String _currentDismissalType = '';

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _wicketAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _ballAnimation =
        Tween<Offset>(
          begin: const Offset(-2.0, -0.5),
          end: const Offset(0.0, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.fastOutSlowIn,
          ),
        );

    _runoutAnimation =
        Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.bounceOut,
          ),
        );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_showWicketAnimation) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _showWicketAnimation = false;
              });
            }
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      final playerStatsProvider = Provider.of<PlayerStatsProvider>(
        context,
        listen: false,
      );

      print('🔄 Setting up match completion callback...');

      matchProvider.setOnMatchCompleteCallback(() {
        print('🎯 CALLBACK TRIGGERED: Processing completed match!');
        print(
          '🎯 Team A: ${matchProvider.teamA.name} with ${matchProvider.teamA.batsmen.length} batsmen',
        );
        print(
          '🎯 Team B: ${matchProvider.teamB.name} with ${matchProvider.teamB.batsmen.length} batsmen',
        );

        playerStatsProvider.processCompletedMatch(
          matchProvider.teamA,
          matchProvider.teamB,
        );

        print('✅ Player stats processed!');
      });

      print('✅ Callback setup complete');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.stop();
    _confettiController.dispose();
    super.dispose();
  }

  Widget _buildSetupScreen(MatchProvider mp) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Names
            _buildTeamInputSection(),

            const SizedBox(height: 20),

            // Toss Section
            if (_teamAController.text.isNotEmpty &&
                _teamBController.text.isNotEmpty)
              _buildTossSection(),

            // Player Selection
            if (_tossWinner != null && _battingChoice != null)
              _buildPlayerSelectionSection(mp),

            // Overs Selection
            if (_selectedStriker != null &&
                _selectedNonStriker != null &&
                _selectedBowler != null)
              _buildOversSection(),

            // Start Match Button
            if (_oversCtrl.text.isNotEmpty) _buildStartButton(mp),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Names',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamAController,
              decoration: const InputDecoration(
                labelText: 'Team A Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teamBController,
              decoration: const InputDecoration(
                labelText: 'Team B Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTossSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toss',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Who won the toss?'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: Text(_teamAController.text),
                    value: _teamAController.text,
                    groupValue: _tossWinner,
                    onChanged: (value) {
                      setState(() {
                        _tossWinner = value;
                        _battingChoice = null;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: Text(_teamBController.text),
                    value: _teamBController.text,
                    groupValue: _tossWinner,
                    onChanged: (value) {
                      setState(() {
                        _tossWinner = value;
                        _battingChoice = null;
                      });
                    },
                  ),
                ),
              ],
            ),

            if (_tossWinner != null) ...[
              const SizedBox(height: 12),
              const Text('Choose to:'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text('Bat'),
                      value: 'Bat',
                      groupValue: _battingChoice,
                      onChanged: (value) =>
                          setState(() => _battingChoice = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text('Bowl'),
                      value: 'Bowl',
                      groupValue: _battingChoice,
                      onChanged: (value) =>
                          setState(() => _battingChoice = value),
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

  Widget _buildPlayerSelectionSection(MatchProvider mp) {
    final battingTeamName = _getBattingTeam();
    final bowlingTeamName = _getBowlingTeam();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Player Selection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildAddPlayersSection(battingTeamName, bowlingTeamName),

            const SizedBox(height: 16),

            if (_teamAPlayers.isNotEmpty && _teamBPlayers.isNotEmpty) ...[
              const Text(
                'Select Batsmen:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Striker',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedStriker,
                      items: _getBattingTeamPlayers(battingTeamName)
                          .toSet()
                          .toList()
                          .map((player) {
                            return DropdownMenuItem(
                              value: player,
                              child: Text(player),
                            );
                          })
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedStriker = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Non-Striker',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedNonStriker,
                      items: _getBattingTeamPlayers(battingTeamName)
                          .toSet()
                          .where((player) => player != _selectedStriker)
                          .toList()
                          .map((player) {
                            return DropdownMenuItem(
                              value: player,
                              child: Text(player),
                            );
                          })
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedNonStriker = value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'Select Bowler:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Bowler',
                  border: OutlineInputBorder(),
                ),
                value: _selectedBowler,
                items: _getBowlingTeamPlayers(bowlingTeamName)
                    .toSet()
                    .toList()
                    .map((player) {
                      return DropdownMenuItem(
                        value: player,
                        child: Text(player),
                      );
                    })
                    .toList(),
                onChanged: (value) => setState(() => _selectedBowler = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddPlayersSection(String battingTeam, String bowlingTeam) {
    return Column(
      children: [
        const Text(
          'Add Players to Teams:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$battingTeam (Batting)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildAddPlayerField(battingTeam == _teamAController.text),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$bowlingTeam (Bowling)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildAddPlayerField(bowlingTeam == _teamAController.text),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (_teamAPlayers.isNotEmpty)
              Chip(
                label: Text(
                  '${_teamAPlayers.length} players in ${_teamAController.text}',
                ),
              ),
            if (_teamBPlayers.isNotEmpty)
              Chip(
                label: Text(
                  '${_teamBPlayers.length} players in ${_teamBController.text}',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddPlayerField(bool isTeamA) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Player name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final playerName = controller.text.trim();
            if (playerName.isNotEmpty) {
              setState(() {
                if (isTeamA) {
                  if (!_teamAPlayers.contains(playerName))
                    _teamAPlayers.add(playerName);
                } else {
                  if (!_teamBPlayers.contains(playerName))
                    _teamBPlayers.add(playerName);
                }
                controller.clear();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildOversSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Match Overs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _oversCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Overs',
                border: OutlineInputBorder(),
                hintText: 'e.g., 20',
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 20, 50].map((overs) {
                return ElevatedButton(
                  onPressed: () =>
                      setState(() => _oversCtrl.text = overs.toString()),
                  child: Text('$overs'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(MatchProvider mp) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _initializeMatch(mp);
          setState(() => _showSetupScreen = false);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        ),
        child: const Text('Start Match'),
      ),
    );
  }

  String _getBattingTeam() {
    if (_tossWinner == _teamAController.text && _battingChoice == 'Bat')
      return _teamAController.text;
    if (_tossWinner == _teamBController.text && _battingChoice == 'Bat')
      return _teamBController.text;
    if (_tossWinner == _teamAController.text && _battingChoice == 'Bowl')
      return _teamBController.text;
    return _teamAController.text;
  }

  String _getBowlingTeam() {
    final battingTeam = _getBattingTeam();
    return battingTeam == _teamAController.text
        ? _teamBController.text
        : _teamAController.text;
  }

  List<String> _getBattingTeamPlayers(String battingTeam) {
    return battingTeam == _teamAController.text ? _teamAPlayers : _teamBPlayers;
  }

  List<String> _getBowlingTeamPlayers(String bowlingTeam) {
    return bowlingTeam == _teamAController.text ? _teamAPlayers : _teamBPlayers;
  }

  void _initializeMatch(MatchProvider mp) {
    // Set team names
    mp.addTeam(_teamAController.text, toTeamA: true);
    mp.addTeam(_teamBController.text, toTeamA: false);

    // Set overs
    mp.setTotalOvers(int.tryParse(_oversCtrl.text) ?? 20);

    // Add players to teams
    final battingTeam = _getBattingTeam();

    for (String player in _teamAPlayers.toSet()) {
      mp.addBatsmanToTeam(
        true,
        BatsmanModel(
          name: player,
          runs: 0,
          ballsFaced: 0,
          fours: 0,
          sixes: 0,
          highestScore: 0,
          isOnStrike:
              player == _selectedStriker &&
              _teamAController.text == battingTeam,
        ),
      );
      mp.addBowlerToTeam(
        true,
        BowlerModel(
          name: player,
          oversBowled: 0,
          balls: 0,
          runsGiven: 0,
          bestBowling: 0,
        ),
      );
    }

    for (String player in _teamBPlayers.toSet()) {
      mp.addBatsmanToTeam(
        false,
        BatsmanModel(
          name: player,
          runs: 0,
          ballsFaced: 0,
          fours: 0,
          sixes: 0,
          highestScore: 0,
          isOnStrike:
              player == _selectedStriker &&
              _teamBController.text == battingTeam,
        ),
      );
      mp.addBowlerToTeam(
        false,
        BowlerModel(
          name: player,
          oversBowled: 0,
          balls: 0,
          runsGiven: 0,
          bestBowling: 0,
        ),
      );
    }

    // Set current bowler
    final bowlerIndex = mp.bowlingTeam.bowlers.indexWhere(
      (b) => b.name == _selectedBowler,
    );
    if (bowlerIndex != -1) mp.setCurrentBowler(bowlerIndex);
  }

  void _playWicketAnimation(String dismissalType) {
    setState(() {
      _showWicketAnimation = true;
      _showRunoutAnimation = false;
      _showAddBatsmanPrompt = false;
      _currentDismissalType = dismissalType;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _playRunoutAnimation() {
    setState(() {
      _showRunoutAnimation = true;
      _showWicketAnimation = false;
      _showAddBatsmanPrompt = false;
    });
    _animationController.reset();
    _animationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showRunoutAnimation = false;
            _showAddBatsmanPrompt = true;
          });
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = Provider.of<MatchProvider>(context, listen: false);
      if (mp.totalOvers == 0) {
        _selectOvers(mp);
      }
    });
  }

  Future<String?> _textInputDialog(String title, {String initial = ''}) {
    _playerNameCtrl.text = initial;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: _playerNameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, _playerNameCtrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectOvers(MatchProvider mp) async {
    _oversCtrl.clear();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Match Overs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose from presets or enter custom overs:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [5, 10, 20, 50]
                  .map(
                    (overs) => ElevatedButton(
                      onPressed: () {
                        mp.setTotalOvers(overs);
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$overs overs match selected'),
                            ),
                          );
                        }
                      },
                      child: Text('$overs'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Or enter custom overs:'),
            TextField(
              controller: _oversCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter overs',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final customOvers = int.tryParse(_oversCtrl.text.trim());
              if (customOvers != null && customOvers > 0) {
                mp.setTotalOvers(customOvers);
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$customOvers overs match selected'),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number of overs'),
                  ),
                );
              }
            },
            child: const Text('Set Custom'),
          ),
        ],
      ),
    );
  }

  Future<int?> _chooseBowler(MatchProvider mp) {
    final bowlers = mp.bowlingTeam.bowlers;
    if (bowlers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No bowlers available. Please add a bowler first.'),
          ),
        );
      }
      return Future.value(null);
    }

    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose bowler'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: bowlers.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(bowlers[i].name),
              subtitle: Text(
                'Overs ${bowlers[i].oversBowled}.${bowlers[i].balls}, R ${bowlers[i].runsGiven}, W ${bowlers[i].wickets}',
              ),
              onTap: () => Navigator.pop(ctx, i),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addBatsman(
    MatchProvider mp,
    bool toTeamA, {
    bool setOnStrike = true,
  }) async {
    final name = await _textInputDialog('Add batsman');
    if (name == null || name.isEmpty) return;

    // Check if batsman with same name already exists
    final team = toTeamA ? mp.teamA : mp.teamB;
    final existingBatsman = team.batsmen
        .where((b) => b.name.toLowerCase() == name.toLowerCase() && !b.isOut)
        .toList();

    if (existingBatsman.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batsman with this name already exists in the team!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final newBatsman = BatsmanModel(
      name: name,
      runs: 0,
      ballsFaced: 0,
      fours: 0,
      sixes: 0,
      highestScore: 0,
      isOnStrike: false,
    );

    mp.addBatsmanToTeam(toTeamA, newBatsman);
    _assignStrikeAfterAdd(mp, toTeamA, setOnStrike: setOnStrike);

    // Hide the add batsman prompt after adding
    setState(() {
      _showAddBatsmanPrompt = false;
    });
  }

  Future<void> _addBowler(MatchProvider mp, bool toTeamA) async {
    final name = await _textInputDialog('Add bowler');
    if (name == null || name.isEmpty) return;

    mp.addBowlerToTeam(
      toTeamA,
      BowlerModel(
        name: name,
        oversBowled: 0,
        balls: 0,
        runsGiven: 0,
        bestBowling: 0,
      ),
    );
  }

  void _assignStrikeAfterAdd(
    MatchProvider mp,
    bool toTeamA, {
    required bool setOnStrike,
  }) {
    final team = toTeamA ? mp.teamA : mp.teamB;
    if (team.batsmen.isEmpty) return;
    final availableBatsmen = team.batsmen.where((b) => !b.isOut).toList();

    if (availableBatsmen.isEmpty) return;
    int strikeCount = 0;
    BatsmanModel? currentStriker;

    for (var batsman in availableBatsmen) {
      if (batsman.isOnStrike) {
        strikeCount++;
        currentStriker = batsman;
      }
    }
    if (setOnStrike || strikeCount == 0) {
      for (var batsman in team.batsmen) {
        batsman.isOnStrike = false;
      }

      final newBatsman = team.batsmen.last;
      if (!newBatsman.isOut) {
        newBatsman.isOnStrike = true;
      }
    }
    // If multiple batsmen are on strike, fix it
    else if (strikeCount > 1) {
      // Turn off all strikes first
      for (var batsman in team.batsmen) {
        batsman.isOnStrike = false;
      }
      // Set only the first available batsman on strike
      availableBatsmen.first.isOnStrike = true;
    }
    // Otherwise, the new batsman is not on strike (strike remains with existing batsman)
    else {
      team.batsmen.last.isOnStrike = false;
    }
  }

  Future<String?> _wicketDialog() {
    _playerNameCtrl.clear();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wicket, dismissal info'),
        content: TextField(
          controller: _playerNameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Dismissal type (Bowled, Caught, Run Out)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              _playerNameCtrl.text.trim().isEmpty
                  ? 'Bowled'
                  : _playerNameCtrl.text.trim(),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleRun(MatchProvider mp, int runs) {
    if (!mp.canStartMatch) {
      _showStartMatchError(mp);
      return;
    }
    mp.addLegalDeliveryOffBat(runs);
  }

  void _handleDot(MatchProvider mp) {
    if (!mp.canStartMatch) {
      _showStartMatchError(mp);
      return;
    }
    mp.addDotBall();
  }

  void _showStartMatchError(MatchProvider mp) {
    String message = 'Cannot start match:';
    if (mp.totalOvers == 0) message += '\n• Select number of overs';
    if (mp.battingTeam.batsmen.isEmpty)
      message += '\n• Add batsmen to batting team';
    if (mp.bowlingTeam.bowlers.isEmpty)
      message += '\n• Add bowlers to bowling team';
    if (mp.currentBowler == null) message += '\n• Select a current bowler';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _changeStrikeManual(MatchProvider mp) async {
    final battingTeam = mp.battingTeam;
    final availableBatsmen = battingTeam.batsmen
        .where((b) => !b.isOut)
        .toList();

    if (availableBatsmen.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 2 batsmen to change strike'),
        ),
      );
      return;
    }

    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Strike'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableBatsmen.length,
            itemBuilder: (_, index) {
              final batsman = availableBatsmen[index];
              return ListTile(
                leading: batsman.isOnStrike
                    ? const Icon(Icons.sports_cricket, color: Colors.green)
                    : null,
                title: Text(batsman.name),
                subtitle: Text('${batsman.runs} (${batsman.ballsFaced})'),
                onTap: () =>
                    Navigator.pop(ctx, battingTeam.batsmen.indexOf(batsman)),
              );
            },
          ),
        ),
      ),
    );

    if (selectedIndex != null) {
      mp.changeStrikeManually(selectedIndex);
    }
  }

  Future<void> _handleRunOut(MatchProvider mp) async {
    if (!mp.canStartMatch) {
      _showStartMatchError(mp);
      return;
    }

    final runsScored = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run Out'),
        content: const Text('How many runs were scored before the run out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('0'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 1),
            child: const Text('1'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 2),
            child: const Text('2'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 3),
            child: const Text('3'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 4),
            child: const Text('4'),
          ),
        ],
      ),
    );

    if (runsScored == null) return;

    final battingTeam = mp.battingTeam;
    final availableBatsmen = battingTeam.batsmen
        .where((b) => !b.isOut)
        .toList();

    final batsmanOut = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run Out'),
        content: const Text('Which batsman was run out?'),
        actions: [
          ...availableBatsmen.map(
            (batsman) => TextButton(
              onPressed: () => Navigator.pop(ctx, batsman.name),
              child: Text(batsman.name),
            ),
          ),
        ],
      ),
    );

    if (batsmanOut != null) {
      _playRunoutAnimation();
      await Future.delayed(const Duration(milliseconds: 1500));

      await mp.addRunOut(runsScored, batsmanOut);
    }
  }

  Future<void> _handleNoBall(MatchProvider mp) async {
    if (!mp.canStartMatch) {
      _showStartMatchError(mp);
      return;
    }

    final hasBatsmanRuns = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Ball'),
        content: const Text('Did the batsman score runs on this no-ball?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    int batsmanRuns = 0;
    if (hasBatsmanRuns == true) {
      final batsmanRunsResult = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Batsman Runs on No-ball'),
          content: const Text('How many runs did the batsman score?'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 1),
              child: const Text('1'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 2),
              child: const Text('2'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 3),
              child: const Text('3'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 4),
              child: const Text('4'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 6),
              child: const Text('6'),
            ),
          ],
        ),
      );
      batsmanRuns = batsmanRunsResult ?? 0;
    }

    await mp.addExtras(
      ExtraType.noBall,
      0, // No extra runs parameter needed for no balls
      noBallHasBatsmanRuns: hasBatsmanRuns == true,
      batsmanRunsOnNoBall: batsmanRuns,
    );
  }

  Future<void> _handleWide(MatchProvider mp) async {
    if (!mp.canStartMatch) {
      _showStartMatchError(mp);
      return;
    }

    // Ask user for any additional runs on the wide
    final additionalRuns = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Additional Runs on Wide'),
        // content: const Text('Select additional runs taken by batsmen (excluding the 1 penalty run):'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('0'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 1),
            child: const Text('1'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 2),
            child: const Text('2'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 3),
            child: const Text('3'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 4),
            child: const Text('4'),
          ),
        ],
      ),
    );

    if (additionalRuns == null) return;

    // Pass only the additional runs (not total runs)
    await mp.addExtras(ExtraType.wide, additionalRuns);

    if (mounted) {
      final totalRuns = 1 + additionalRuns;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            additionalRuns > 0
                ? 'Wide: 1 penalty + $additionalRuns runs (total $totalRuns)'
                : 'Wide: 1 run',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleBye(MatchProvider mp, ExtraType type) async {
    if (!mp.canStartMatch) {
      _showStartMatchError(mp);
      return;
    }
  }

  Future<void> _handleWicket(MatchProvider mp) async {
    if (!mp.canStartMatch) {
      _showStartMatchError(mp);
      return;
    }

    final info = await _wicketDialog();
    if (info == null) return;

    _playWicketAnimation(info);

    await Future.delayed(const Duration(milliseconds: 1500));

    await mp.addWicket(info);

    final addNewBatsman = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batsman Out'),
        content: const Text('Do you want to add a new batsman?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Add New Batsman'),
          ),
        ],
      ),
    );

    if (addNewBatsman == true) {
      await _addBatsman(mp, mp.isTeamABatting, setOnStrike: true);
    }
  }

  Widget _topHeader(MatchProvider mp) {
    final batting = mp.battingTeam;
    final oversBowled = batting.ballsBowled ~/ 6;
    final ballsInOver = batting.ballsBowled % 6;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Target display for second inning
            if (mp.isSecondInning && mp.target > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    Text(
                      'Target: ${mp.target} runs',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Required RR: ${mp.requiredRunRate.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                    Text(
                      'Runs Needed: ${mp.target - batting.totalRuns}',
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            if (mp.isSecondInning && mp.target > 0) const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      _teamNameCtrl.text = batting.name;
                      final n = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Edit team name'),
                          content: TextField(
                            controller: _teamNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Team name',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, null),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, _teamNameCtrl.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (n != null && n.isNotEmpty) {
                        mp.battingTeam.name = n;
                      }
                    },
                    child: Text(
                      batting.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${batting.totalRuns}/${batting.wicketsLost}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Overs $oversBowled.$ballsInOver/${mp.totalOvers}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Batsmen',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 12,
                        children: batting.batsmen
                            .where((b) => !b.isOut)
                            .map(
                              (b) => GestureDetector(
                                onTap: () => _editPlayerName(mp, b, true),
                                child: Chip(
                                  label: Text(
                                    '${b.name} ${b.isOnStrike ? "(*)" : ""}\n${b.runs}(${b.ballsFaced})',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bowler: ${mp.currentBowler?.name ?? 'None'}'),
                    if (!mp.canStartMatch)
                      const Text(
                        '⚠️ Setup required',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final idx = await _chooseBowler(mp);
                        if (idx != null) {
                          mp.setCurrentBowler(idx);
                        }
                      },
                      child: const Text('Select bowler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _changeStrikeManual(mp),
                      child: const Text('Change strike'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraRunItem(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          '$value',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _editPlayerName(
    MatchProvider mp,
    dynamic player,
    bool isBatsman,
  ) async {
    final name = await _textInputDialog(
      'Edit ${isBatsman ? 'batsman' : 'bowler'} name',
      initial: player.name,
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        player.name = name;
      });
    }
  }

  Widget _controls(MatchProvider mp) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                          _runButton(
                            '0',
                            mp.isMatchComplete ? null : () => _handleDot(mp),
                          ),
                          _runButton(
                            '1',
                            mp.isMatchComplete ? null : () => _handleRun(mp, 1),
                          ),
                          _runButton(
                            '2',
                            mp.isMatchComplete ? null : () => _handleRun(mp, 2),
                          ),
                          _runButton(
                            '3',
                            mp.isMatchComplete ? null : () => _handleRun(mp, 3),
                          ),
                          _runButton(
                            '4',
                            mp.isMatchComplete ? null : () => _handleRun(mp, 4),
                          ),
                          _runButton(
                            '5',
                            mp.isMatchComplete ? null : () => _handleRun(mp, 5),
                          ),
                          _runButton(
                            '6',
                            mp.isMatchComplete ? null : () => _handleRun(mp, 6),
                          ),
                          _runButton(
                            'Wide',
                            mp.isMatchComplete
                                ? null
                                : () async {
                                    await _handleWide(mp);
                                  },
                          ),
                          _runButton(
                            'No ball',
                            mp.isMatchComplete
                                ? null
                                : () async {
                                    await _handleNoBall(mp);
                                  },
                          ),
                          _runButton(
                            'Bye',
                            mp.isMatchComplete
                                ? null
                                : () async {
                                    await _handleBye(mp, ExtraType.bye);
                                  },
                          ),
                          _runButton(
                            'Leg bye',
                            mp.isMatchComplete
                                ? null
                                : () async {
                                    await _handleBye(mp, ExtraType.legBye);
                                  },
                          ),
                          _runButton(
                            'Run Out',
                            mp.isMatchComplete
                                ? null
                                : () async {
                                    await _handleRunOut(mp);
                                  },
                          ),
                          _runButton(
                            'Wicket',
                            mp.isMatchComplete
                                ? null
                                : () async {
                                    await _handleWicket(mp);
                                  },
                          ),
                        ]
                        .map(
                          (w) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: w,
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await mp.saveCurrentMatch();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Match saved successfully! You can view it in Saved Matches.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Match'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _runButton(String label, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey : Colors.green[700],
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  Widget _fallOfWicketsWithExtras(
    TeamModel battingTeam,
    TeamModel bowlingTeam,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fall of Wickets & Extra Runs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Extra Runs Summary - SIMPLIFIED
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Extra Runs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildExtraRunItem('Wides', battingTeam.wides),
                      _buildExtraRunItem('No Balls', battingTeam.noBalls),
                      _buildExtraRunItem('Byes', battingTeam.byes),
                      _buildExtraRunItem('Leg Byes', battingTeam.legByes),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Extras: ${battingTeam.totalExtras}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (battingTeam.fallOfWickets.isEmpty)
              const Text(
                'No wickets yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Wicket',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...battingTeam.fallOfWickets.map((wicket) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                wicket,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _bowlersList(TeamModel t) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Bowlers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (t.bowlers.isEmpty)
              const Text(
                'No bowlers added',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...t.bowlers.map(
                (bo) => ListTile(
                  leading: GestureDetector(
                    onTap: () => _editPlayerName(
                      context.read<MatchProvider>(),
                      bo,
                      false,
                    ),
                    child: const Icon(
                      Icons.sports_handball_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    bo.name,
                    style: TextStyle(
                      fontWeight: bo.wickets > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: bo.wickets > 0 ? Colors.green : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Overs: ${bo.oversBowled}.${bo.balls} • Runs: ${bo.runsGiven} • Wickets: ${bo.wickets} • Econ: ${bo.economyRate.toStringAsFixed(2)}',
                  ),
                  trailing: bo.wickets > 0
                      ? Chip(
                          label: Text(
                            '${bo.wickets} W',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _batsmenList(TeamModel t) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Batsmen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (t.batsmen.isEmpty)
              const Text(
                'No batsmen added',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...t.batsmen.map(
                (b) => ListTile(
                  leading: GestureDetector(
                    onTap: () =>
                        _editPlayerName(context.read<MatchProvider>(), b, true),
                    child: b.isOnStrike
                        ? const Icon(Icons.sports_cricket, color: Colors.green)
                        : const Icon(Icons.person, color: Colors.blue),
                  ),
                  title: Row(
                    children: [
                      Text(b.name),
                      if (b.isOut)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Chip(
                            label: const Text(
                              'OUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            backgroundColor: Colors.red,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b.runs}(${b.ballsFaced}), 4s ${b.fours}, 6s ${b.sixes}, SR ${b.strikeRate.toStringAsFixed(2)}',
                      ),
                      if (b.isOut && b.dismissedBy != null)
                        Text(
                          'b ${b.dismissedBy}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
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
  }

  Widget _buildWicketAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return _showWicketAnimation
            ? Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideTransition(
                          position: _ballAnimation,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red,
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Transform.scale(
                          scale: _wicketAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.brown[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sports_cricket,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentDismissalType.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'WICKET!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildRunoutAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return _showRunoutAnimation
            ? Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: SlideTransition(
                      position: _runoutAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange[700],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_run,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'RUN OUT!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildAddBatsmanPrompt(MatchProvider mp) {
    return _showAddBatsmanPrompt
        ? Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add,
                        color: Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Batsman Run Out!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add new batsman to continue',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _addBatsman(
                          mp,
                          mp.isTeamABatting,
                          setOnStrike: true,
                        ),
                        child: const Text('Add New Batsman'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildCelebration() {
    return _showCelebration
        ? Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -pi / 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  maxBlastForce: 100,
                  minBlastForce: 80,
                  gravity: 0.3,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -pi,
                  emissionFrequency: 0.05,
                  numberOfParticles: 10,
                  maxBlastForce: 100,
                  minBlastForce: 80,
                  gravity: 0.3,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 0,
                  emissionFrequency: 0.05,
                  numberOfParticles: 10,
                  maxBlastForce: 100,
                  minBlastForce: 80,
                  gravity: 0.3,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.yellow,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🎉 MATCH COMPLETE! 🎉',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Congratulations!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  _confettiController.stop();
                                  setState(() {
                                    _showCelebration = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Continue'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  Widget _buildMatchResultCard(MatchProvider mp, String result) {
    Color resultColor = Colors.green;

    if (result.contains('won by') && result.contains('runs')) {
      resultColor = Colors.green;
    } else if (result.contains('won by') && result.contains('wickets')) {
      resultColor = Colors.blue;
    } else {
      resultColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.all(12),
      color: resultColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: resultColor, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MATCH RESULT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      mp.teamA.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${mp.teamA.totalRuns}/${mp.teamA.wicketsLost}'),
                    Text('Overs: ${mp.teamA.oversString}'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      mp.teamB.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${mp.teamB.totalRuns}/${mp.teamB.wicketsLost}'),
                    Text('Overs: ${mp.teamB.oversString}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Option to restart match
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Restart Match'),
                    content: const Text('Do you want to restart a new match?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          mp.resetMatch();
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Start New Match'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSetupScreen) {
      final mp = Provider.of<MatchProvider>(context);
      return _buildSetupScreen(mp);
    } else {
      // Your existing build method goes here
      final mp = Provider.of<MatchProvider>(context);
      final batting = mp.battingTeam;
      final bowling = mp.bowlingTeam;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mp.isMatchComplete && !_showCelebration) {}
      });

      String matchResult = '';
      if (mp.isMatchComplete) {
        if (mp.teamA.totalRuns > mp.teamB.totalRuns) {
          final runsDifference = mp.teamA.totalRuns - mp.teamB.totalRuns;
          matchResult = '${mp.teamA.name} won by $runsDifference runs';
        } else if (mp.teamB.totalRuns > mp.teamA.totalRuns) {
          final wicketsLeft = 10 - mp.teamB.wicketsLost;
          matchResult = '${mp.teamB.name} won by $wicketsLeft wickets';
        } else {
          matchResult = 'Match Tied';
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Score Card'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => mp.switchInnings(),
              tooltip: 'Switch innings',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => mp.resetMatch(),
              tooltip: 'Reset match',
            ),
            IconButton(
              icon: const Icon(Icons.timer),
              onPressed: () => _selectOvers(mp),
              tooltip: 'Change overs',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green[50]!, Colors.lightBlue[50]!],
            ),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    if (mp.isMatchComplete)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.yellow,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'MATCH COMPLETE!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              matchResult,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: mp.isMatchComplete
                                  ? null
                                  : () => _addBatsman(mp, mp.isTeamABatting),
                              child: const Text('Add batsman to batting team'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: mp.isMatchComplete
                                  ? null
                                  : () => _addBowler(mp, !mp.isTeamABatting),
                              child: const Text('Add bowler to bowling team'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _topHeader(mp),
                    _controls(mp),
                    _fallOfWicketsWithExtras(batting, bowling),
                    _batsmenList(batting),
                    _bowlersList(bowling),

                    if (mp.isMatchComplete)
                      _buildMatchResultCard(mp, matchResult),

                    const SizedBox(height: 40),
                    if (mp.lastEvent != null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text('Last: ${mp.lastEvent!}'),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              _buildWicketAnimation(),
              _buildRunoutAnimation(),
              _buildAddBatsmanPrompt(mp),
              _buildCelebration(),
            ],
          ),
        ),
      );
    }
  }
}
