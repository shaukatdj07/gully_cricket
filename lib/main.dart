// Bismillah
import 'package:flutter/material.dart';
import 'package:gully_cricket/providers/batsman_provider.dart';
import 'package:gully_cricket/providers/bowler_provider.dart';
import 'package:gully_cricket/providers/match_provider.dart';
import 'package:gully_cricket/providers/player_state_provider.dart';
import 'package:gully_cricket/providers/schedule_provider.dart';
import 'package:gully_cricket/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'models/team_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => BatsmanProvider()..loadFromLocalDb()),
        ChangeNotifierProvider(create: (_) => BowlerProvider()..loadFromLocalDb()),
        ChangeNotifierProvider(create: (_) => PlayerStatsProvider()),
        ChangeNotifierProvider(
          create: (_) => MatchProvider(
            teamA: TeamModel(
              name: 'Team A',
              batsmen: [],
              bowlers: [],
            ),
            teamB: TeamModel(
              name: 'Team B',
              batsmen: [],
              bowlers: [],
            ),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}
