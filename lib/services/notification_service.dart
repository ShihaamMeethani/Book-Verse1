import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

/// Top-level background message handler for Firebase Cloud Messaging.
/// Must be outside any class and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  debugPrint('BookVerse FCM background message received: ${message.messageId}');
}

/// Wraps Firebase Cloud Messaging (remote push) together with
/// flutter_local_notifications for instant foreground notifications,
/// order confirmations, and background handling.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String _channelId = 'bookverse_channel';
  static const String _channelName = 'BookVerse Notifications';
  static const String _channelDescription = 'Order updates, promotions and reading reminders';

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Request FCM permissions
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // 2. Set foreground presentation options for iOS/macOS/web
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Set top-level background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Initialize local notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _local.initialize(
        const InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // 5. Create Android Notification Channel & Request Android 13+ permission
      if (Platform.isAndroid) {
        final androidPlugin = _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(_androidChannel);
          await androidPlugin.requestNotificationsPermission();
        }
      }

      // 6. Listen for incoming foreground push messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title'] ?? 'BookVerse';
        final body = notification?.body ?? message.data['body'] ?? '';
        if (title.isNotEmpty || body.isNotEmpty) {
          showInstant(title: title, body: body);
        }
      });

      // 7. Listen for notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM message opened app: ${message.data}');
      });

      // 8. Check if app was opened from terminated state via notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated notification: ${initialMessage.data}');
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Fires an immediate local notification (e.g. order confirmation, add to cart).
  Future<void> showInstant({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _local.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Schedules a reminder notification in the future.
  Future<void> scheduleReminder({
    required String title,
    required String body,
    required Duration delay,
  }) async {
    Future.delayed(delay, () => showInstant(title: title, body: body));
  }
}
