import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batsman_model.dart';

class BatsmanProvider with ChangeNotifier {
  List<BatsmanModel> _batsmen = [];

  List<BatsmanModel> get batsmen => _batsmen;

  // Add new batsman
  void addBatsman(BatsmanModel batsman) {
    _batsmen.add(batsman);
    saveToLocalDb();
    notifyListeners();
  }

  // Delete batsman by index
  void deleteBatsman(int index) {
    _batsmen.removeAt(index);
    saveToLocalDb();
    notifyListeners();
  }

  // Edit batsman details
  void editBatsman(int index, BatsmanModel updatedBatsman) {
    _batsmen[index] = updatedBatsman;
    saveToLocalDb();
    notifyListeners();
  }

  // Toggle strike
  void toggleStrike(int index) {
    for (int i = 0; i < _batsmen.length; i++) {
      _batsmen[i].isOnStrike = (i == index);
    }
    saveToLocalDb();
    notifyListeners();
  }

  // Save batsmen data locally
  Future<void> saveToLocalDb() async {
    final prefs = await SharedPreferences.getInstance();
    final batsmenJson = _batsmen.map((b) => jsonEncode({
      'name': b.name,
      'runs': b.runs,
      'ballsFaced': b.ballsFaced,
      'fours': b.fours,
      'sixes': b.sixes,
      'isOnStrike': b.isOnStrike,
    })).toList();
    await prefs.setStringList('batsmen', batsmenJson);
  }

  // Load data from local storage
  Future<void> loadFromLocalDb() async {
    final prefs = await SharedPreferences.getInstance();
    final batsmenJson = prefs.getStringList('batsmen') ?? [];
    _batsmen = batsmenJson.map((item) {
      final data = jsonDecode(item);
      return BatsmanModel(
        name: data['name'],
        runs: data['runs'],
        ballsFaced: data['ballsFaced'],
        fours: data['fours'],
        sixes: data['sixes'],
        highestScore: data['highestScore'],
        isOnStrike: data['isOnStrike'],
      );
    }).toList();
    notifyListeners();
  }

  // Clear all
  Future<void> clearAll() async {
    _batsmen.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('batsmen');
    notifyListeners();
  }

  // Add a run (updates runs, balls, fours, sixes, and strike rate)
  void addRun(int index, int run) {
    final b = _batsmen[index];
    b.runs += run;
    b.ballsFaced++;
    if (run == 4) b.fours++;
    if (run == 6) b.sixes++;
    saveToLocalDb();
    notifyListeners();
  }

// Record a dot ball (no run)
  void addBall(int index) {
    final b = _batsmen[index];
    b.ballsFaced++;
    saveToLocalDb();
    notifyListeners();
  }

}
