import 'batsman_model.dart';
import 'bowler_model.dart';

class TeamModel {
  String name;
  List<BatsmanModel> batsmen;
  List<BowlerModel> bowlers;
  List<String> fallOfWickets;
  int totalRuns;
  int wicketsLost;
  int ballsBowled;
  int currentBowlerIndex;

  // Extra runs properties
  int wides;
  int noBalls;
  int byes;
  int legByes;

  TeamModel({
    required this.name,
    required this.batsmen,
    required this.bowlers,
    List<String>? fallOfWickets,
    this.totalRuns = 0,
    this.wicketsLost = 0,
    this.ballsBowled = 0,
    this.currentBowlerIndex = -1,
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
  }) : fallOfWickets = fallOfWickets ?? [];

  // Calculate total extras
  int get totalExtras => wides + noBalls + byes + legByes;

  String get oversString {
    final overs = ballsBowled ~/ 6;
    final balls = ballsBowled % 6;
    return '$overs.$balls';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'batsmen': batsmen.map((b) => b.toJson()).toList(),
    'bowlers': bowlers.map((b) => b.toJson()).toList(),
    'fallOfWickets': fallOfWickets,
    'totalRuns': totalRuns,
    'wicketsLost': wicketsLost,
    'ballsBowled': ballsBowled,
    'currentBowlerIndex': currentBowlerIndex,
    'wides': wides,
    'noBalls': noBalls,
    'byes': byes,
    'legByes': legByes,
  };

  factory TeamModel.fromJson(Map<String, dynamic> j) => TeamModel(
    name: j['name'],
    batsmen: (j['batsmen'] as List).map((e) => BatsmanModel.fromJson(e)).toList(),
    bowlers: (j['bowlers'] as List).map((e) => BowlerModel.fromJson(e)).toList(),
    fallOfWickets: List<String>.from(j['fallOfWickets'] ?? []),
    totalRuns: j['totalRuns'] ?? 0,
    wicketsLost: j['wicketsLost'] ?? 0,
    ballsBowled: j['ballsBowled'] ?? 0,
    currentBowlerIndex: j['currentBowlerIndex'] ?? -1,
    wides: j['wides'] ?? 0,
    noBalls: j['noBalls'] ?? 0,
    byes: j['byes'] ?? 0,
    legByes: j['legByes'] ?? 0,
  );
}