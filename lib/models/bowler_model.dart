class BowlerModel {
  String name;
  int oversBowled;
  int balls;
  int runsGiven;
  int wickets;
  final int bestBowling;

  BowlerModel({
    required this.name,
    required this.oversBowled,
    required this.balls,
    required this.runsGiven,
    this.wickets = 0,
    required this.bestBowling,
  });

  double get economyRate {
    int totalBalls = (oversBowled * 6) + balls;
    if (totalBalls == 0) return 0;
    return runsGiven / (totalBalls / 6);
  }

  void addBall(int runs, {bool isWicket = false, bool isLegal = true}) {
    runsGiven += runs;
    if (isLegal) {
      balls++;
      if (balls == 6) {
        oversBowled++;
        balls = 0;
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'oversBowled': oversBowled,
    'balls': balls,
    'runsGiven': runsGiven,
    'wickets': wickets,
    'bestBowling': bestBowling,
  };

  factory BowlerModel.fromJson(Map<String, dynamic> j) => BowlerModel(
      name: j['name'],
      oversBowled: j['oversBowled'] ?? 0,
      balls: j['balls'] ?? 0,
      runsGiven: j['runsGiven'] ?? 0,
      wickets: j['wickets'] ?? 0,
      bestBowling: j['bestBowling'] ?? 0
  );
}