class BatsmanModel {
  String name;
  int runs;
  int ballsFaced;
  int fours;
  int sixes;
  bool isOnStrike;
  bool isOut;
  String? dismissedBy;
  String? dismissalType;
  final int highestScore;

  BatsmanModel({
    required this.name,
    required this.runs,
    required this.ballsFaced,
    required this.fours,
    required this.sixes,
    required this.highestScore,
    this.isOnStrike = false,
    this.isOut = false,
    this.dismissedBy,
    this.dismissalType,
  });

  double get strikeRate {
    if (ballsFaced == 0) return 0.0;
    return (runs / ballsFaced) * 100;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'runs': runs,
    'ballsFaced': ballsFaced,
    'fours': fours,
    'sixes': sixes,
    'highestScore': highestScore,
    'isOnStrike': isOnStrike,
    'isOut': isOut,
    'dismissedBy': dismissedBy,
    'dismissalType': dismissalType,
  };

  factory BatsmanModel.fromJson(Map<String, dynamic> j) => BatsmanModel(
    name: j['name'],
    runs: j['runs'] ?? 0,
    ballsFaced: j['ballsFaced'] ?? 0,
    fours: j['fours'] ?? 0,
    sixes: j['sixes'] ?? 0,
    highestScore: j['highestScore'] ?? 0,
    isOnStrike: j['isOnStrike'] ?? false,
    isOut: j['isOut'] ?? false,
    dismissedBy: j['dismissedBy'],
    dismissalType: j['dismissalType'],
  );
}