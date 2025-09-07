import 'package:flutter/material.dart';
import 'package:swift_cloud_backup/utils/scheduler_service.dart';
import 'package:swift_cloud_backup/utils/notification_system.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service first
  final notificationService = NotificationService();
  await notificationService.init();

  // Then start scheduler service
  SchedulerService schedulerService = SchedulerService();
  await schedulerService.start();

  runApp(const App());
}