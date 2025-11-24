class PlayerStats {
  final String playerName;
  final String teamName;
  final int matchesPlayed;
  final DateTime lastUpdated;

  PlayerStats({
    required this.playerName,
    required this.teamName,
    required this.matchesPlayed,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'teamName': teamName,
      'matchesPlayed': matchesPlayed,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerName: json['playerName'],
      teamName: json['teamName'],
      matchesPlayed: json['matchesPlayed'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

class BatsmanStats extends PlayerStats {
  final int runs;
  final int ballsFaced;
  final double strikeRate;
  final int fours;
  final int sixes;
  final int fifties;
  final int hundreds;
  final double average;
  final int previousPosition;

  BatsmanStats({
    required String playerName,
    required String teamName,
    required int matchesPlayed,
    required DateTime lastUpdated,
    required this.runs,
    required this.ballsFaced,
    required this.strikeRate,
    required this.fours,
    required this.sixes,
    required this.fifties,
    required this.hundreds,
    required this.average,
    required this.previousPosition,
  }) : super(
    playerName: playerName,
    teamName: teamName,
    matchesPlayed: matchesPlayed,
    lastUpdated: lastUpdated,
  );

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'runs': runs,
      'ballsFaced': ballsFaced,
      'strikeRate': strikeRate,
      'fours': fours,
      'sixes': sixes,
      'fifties': fifties,
      'hundreds': hundreds,
      'average': average,
      'previousPosition': previousPosition,
    };
  }

  factory BatsmanStats.fromJson(Map<String, dynamic> json) {
    return BatsmanStats(
      playerName: json['playerName'],
      teamName: json['teamName'],
      matchesPlayed: json['matchesPlayed'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      runs: json['runs'],
      ballsFaced: json['ballsFaced'],
      strikeRate: json['strikeRate'].toDouble(),
      fours: json['fours'],
      sixes: json['sixes'],
      fifties: json['fifties'],
      hundreds: json['hundreds'],
      average: json['average'].toDouble(),
      previousPosition: json['previousPosition'],
    );
  }

  int get positionChange => previousPosition == 0 ? 0 : previousPosition;
}

class BowlerStats extends PlayerStats {
  final int wickets;
  final int ballsBowled;
  final int runsGiven;
  final double economy;
  final double average;
  final double strikeRate;
  final int threeWickets;
  final int fiveWickets;
  final int previousPosition;

  BowlerStats({
    required String playerName,
    required String teamName,
    required int matchesPlayed,
    required DateTime lastUpdated,
    required this.wickets,
    required this.ballsBowled,
    required this.runsGiven,
    required this.economy,
    required this.average,
    required this.strikeRate,
    required this.threeWickets,
    required this.fiveWickets,
    required this.previousPosition,
  }) : super(
    playerName: playerName,
    teamName: teamName,
    matchesPlayed: matchesPlayed,
    lastUpdated: lastUpdated,
  );

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'wickets': wickets,
      'ballsBowled': ballsBowled,
      'runsGiven': runsGiven,
      'economy': economy,
      'average': average,
      'strikeRate': strikeRate,
      'threeWickets': threeWickets,
      'fiveWickets': fiveWickets,
      'previousPosition': previousPosition,
    };
  }

  factory BowlerStats.fromJson(Map<String, dynamic> json) {
    return BowlerStats(
      playerName: json['playerName'],
      teamName: json['teamName'],
      matchesPlayed: json['matchesPlayed'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      wickets: json['wickets'],
      ballsBowled: json['ballsBowled'],
      runsGiven: json['runsGiven'],
      economy: json['economy'].toDouble(),
      average: json['average'].toDouble(),
      strikeRate: json['strikeRate'].toDouble(),
      threeWickets: json['threeWickets'],
      fiveWickets: json['fiveWickets'],
      previousPosition: json['previousPosition'],
    );
  }

  int get positionChange => previousPosition == 0 ? 0 : previousPosition;
}