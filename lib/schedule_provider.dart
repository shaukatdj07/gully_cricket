import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import 'dart:convert';

class ScheduleProvider with ChangeNotifier {
  List<ScheduledMatch> _scheduledMatches = [];

  List<ScheduledMatch> get scheduledMatches => _scheduledMatches;

  static const String _scheduleKey = 'cricket_schedule_v1';

  Future<void> loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = prefs.getString(_scheduleKey);

      if (schedulesJson != null) {
        final List<dynamic> schedulesList = json.decode(schedulesJson);
        _scheduledMatches = schedulesList
            .map((schedule) => ScheduledMatch.fromJson(schedule))
            .toList();
        _sortMatches();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
    }
  }

  Future<void> addSchedule(ScheduledMatch match) async {
    _scheduledMatches.add(match);
    _sortMatches();
    await _saveSchedules();
    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    _scheduledMatches.removeWhere((match) => match.id == id);
    await _saveSchedules();
    notifyListeners();
  }

  void _sortMatches() {
    _scheduledMatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = json.encode(
        _scheduledMatches.map((match) => match.toJson()).toList(),
      );
      await prefs.setString(_scheduleKey, schedulesJson);
    } catch (e) {
      debugPrint('Error saving schedules: $e');
    }
  }
}