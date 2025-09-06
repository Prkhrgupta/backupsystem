import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swift_cloud_backup/core/api/login_auth_api.dart';

class SchedulerService {
  SchedulerService._privateConstructor();
  // Singleton instance for this service
  static final SchedulerService _instance = SchedulerService._privateConstructor();
  factory SchedulerService() => _instance;
  Timer? _timer;

  Future<void> start() async {
    _timer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    final frequency = prefs.getString("frequency") ?? "Daily";
    final hour = prefs.getInt("time_hour") ?? 0;
    final minute = prefs.getInt("time_minute") ?? 0;

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = TimeOfDay.now();
      if (now.hour == hour && now.minute == minute) {
        if (_shouldRunToday(frequency, prefs)) {
          runBackup(prefs.getString("selectedDirectory") ?? "");
        }
      }
    });
  }

  bool _shouldRunToday(String frequency, SharedPreferences prefs) {
    final today = DateTime.now();

    if (frequency == "Daily") return true;
    if (frequency == "Weekly") {
      final selectedDay = prefs.getString("day");
      return selectedDay == _weekdayToString(today.weekday);
    }
    if (frequency == "Monthly") {
      final selectedDate = prefs.getInt("date");
      return today.day == selectedDate;
    }
    return false;
  }

  String _weekdayToString(int weekday) {
    return [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ][weekday - 1];
  }

  /// ✅ Public method so you can call from anywhere
  void runBackup(String path) {
    debugPrint("Running backup to $path ✅");
    AdminApi adminApi = AdminApi();
    adminApi.runBackup();
  }
}
