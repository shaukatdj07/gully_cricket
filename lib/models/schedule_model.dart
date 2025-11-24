class ScheduledMatch {
  final String id;
  final String teamA;
  final String teamB;
  final DateTime dateTime;
  final String location;
  final String tournamentName;

  ScheduledMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.dateTime,
    required this.location,
    required this.tournamentName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamA': teamA,
      'teamB': teamB,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'tournamentName': tournamentName,
    };
  }

  factory ScheduledMatch.fromJson(Map<String, dynamic> json) {
    return ScheduledMatch(
      id: json['id'],
      teamA: json['teamA'],
      teamB: json['teamB'],
      dateTime: DateTime.parse(json['dateTime']),
      location: json['location'],
      tournamentName: json['tournamentName'],
    );
  }
}