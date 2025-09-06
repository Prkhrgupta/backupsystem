import 'package:flutter/material.dart';
import 'package:swift_cloud_backup/utils/scheduler_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter engine is ready

  SchedulerService schedulerService = SchedulerService();
  await schedulerService.start(); // if start() is async
  runApp(const App());
}
