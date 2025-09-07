import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationType { success, warning, error, info }

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the plugin (must be called before showing notifications)
  Future<void> init() async {
    if (_isInitialized) return; // Prevent double initialization

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Linux settings
    final linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open App');

    // macOS/iOS settings
    const macSettings = DarwinInitializationSettings();

    // Windows settings ✅ required to avoid crash
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Swift Cloud Backup',
      appUserModelId: 'com.swiftcloud.backup',
      guid: 'f1304478-b402-420d-9640-bffbae228ae6',
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: macSettings,
      macOS: macSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Called when user clicks notification
        print('Notification clicked: ${response.payload}');
        // TODO: Bring app to foreground or navigate to page
      },
    );

    _isInitialized = true;
  }

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.info,
  }) async {
    // Ensure initialization before showing notification
    if (!_isInitialized) {
      print('NotificationService not initialized. Initializing now...');
      await init();
    }

    // Android channel details based on type
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

    // Linux, macOS/iOS, Windows details
    final linuxDetails = LinuxNotificationDetails();
    const macDetails = DarwinNotificationDetails();
    const windowsDetails = WindowsNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
      iOS: macDetails,
      macOS: macDetails,
      windows: windowsDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
        payload: body, // can pass additional data
      );
    } catch (e) {
      print('Failed to show notification: $e');
    }
  }
}
