import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bowler_model.dart';

class BowlerProvider with ChangeNotifier {
  List<BowlerModel> _bowlers = [];

  List<BowlerModel> get bowlers => _bowlers;

  // Add bowler
  void addBowler(BowlerModel bowler) {
    _bowlers.add(bowler);
    saveToLocalDb();
    notifyListeners();
  }

  // Delete bowler
  void deleteBowler(int index) {
    _bowlers.removeAt(index);
    saveToLocalDb();
    notifyListeners();
  }

  // Edit bowler
  void editBowler(int index, BowlerModel updated) {
    _bowlers[index] = updated;
    saveToLocalDb();
    notifyListeners();
  }

  // Add ball bowled
  void addBall(int index, int runs, {bool isWicket = false}) {
    _bowlers[index].addBall(runs, isWicket: isWicket);
    saveToLocalDb();
    notifyListeners();
  }

  // Save to local DB
  Future<void> saveToLocalDb() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _bowlers.map((b) {
      return jsonEncode({
        'name': b.name,
        'oversBowled': b.oversBowled,
        'balls': b.balls,
        'runsGiven': b.runsGiven,
        'wickets': b.wickets,
      });
    }).toList();
    await prefs.setStringList('bowlers', jsonList);
  }

  // Load from local DB
  Future<void> loadFromLocalDb() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('bowlers') ?? [];
    _bowlers = jsonList.map((item) {
      final data = jsonDecode(item);
      return BowlerModel(
          name: data['name'],
          oversBowled: data['oversBowled'],
          balls: data['balls'],
          runsGiven: data['runsGiven'],
          wickets: data['wickets'],
          bestBowling: data['bestBowling']
      );
    }).toList();
    notifyListeners();
  }

  // Clear all
  Future<void> clearAll() async {
    _bowlers.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bowlers');
    notifyListeners();
  }
}
