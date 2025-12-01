import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Simple local notification wrapper using `flutter_local_notifications`.
///
/// Note: add `flutter_local_notifications: ^12.0.4` (or latest) to `pubspec.yaml`
/// and run `flutter pub get`. On iOS you must request permissions in AppDelegate
/// and for Android ensure proper notification channel configuration (handled here).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings,
        onDidReceiveNotificationResponse: (response) {
      // handle tap on local notification if needed
      if (kDebugMode) debugPrint('Local notification tapped: ${response.payload}');
    });

    // create default channel for Android
    const androidChannel = AndroidNotificationChannel(
      'cvht_default',
      'CVHT Notifications',
      description: 'Thông báo từ ứng dụng CVHT',
      importance: Importance.defaultImportance,
    );

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    } catch (_) {}

    _initialized = true;
  }

  Future<void> showNotification({required int id, required String title, String? body, String? payload}) async {
    try {
      await init();

      const androidDetails = AndroidNotificationDetails(
        'cvht_default',
        'CVHT Notifications',
        channelDescription: 'Thông báo từ ứng dụng CVHT',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();

      final platform = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.show(id, title, body, platform, payload: payload);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to show local notification: $e');
    }
  }
}
