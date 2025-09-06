import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open App');
    const macSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
      iOS: macSettings,
      macOS: macSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // This will be called when user clicks notification
        print('Notification clicked: ${response.payload}');
        // TODO: Bring app to foreground or navigate to page
      },
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.info,
  }) async {
    AndroidNotificationDetails androidDetails;
    switch (type) {
      case NotificationType.success:
        androidDetails = const AndroidNotificationDetails(
          'success_channel',
          'Success Notifications',
          channelDescription: 'Success messages',
          importance: Importance.high,
          color: Colors.green,
        );
        break;
      case NotificationType.warning:
        androidDetails = const AndroidNotificationDetails(
          'warning_channel',
          'Warning Notifications',
          channelDescription: 'Warning messages',
          importance: Importance.high,
          color: Colors.orange,
        );
        break;
      case NotificationType.error:
        androidDetails = const AndroidNotificationDetails(
          'error_channel',
          'Error Notifications',
          channelDescription: 'Error messages',
          importance: Importance.high,
          color: Colors.red,
        );
        break;
      default:
        androidDetails = const AndroidNotificationDetails(
          'info_channel',
          'Info Notifications',
          channelDescription: 'Info messages',
          importance: Importance.defaultImportance,
        );
    }

    const linuxDetails = LinuxNotificationDetails();
    const macDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
      iOS: macDetails,
      macOS: macDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: body, // can pass additional data
    );
  }
}

enum NotificationType { success, warning, error, info }
