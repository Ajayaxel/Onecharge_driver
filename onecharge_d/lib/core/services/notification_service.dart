import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../network/api_constants.dart';
import '../storage/auth_storage.dart';

/// Top-level function required for background FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 [FCM] Background message received: ${message.messageId}');
  print('🔔 [FCM] Title: ${message.notification?.title}');
  print('🔔 [FCM] Body: ${message.notification?.body}');
  // The notification is automatically displayed by the system when
  // the message contains a 'notification' payload.
  // No need to show local notification here — Android/iOS handles it.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Android notification channel for ticket alerts
  static const AndroidNotificationChannel _ticketChannel =
      AndroidNotificationChannel(
        'ticket_alerts', // id
        'Ticket Alerts', // name
        description: 'Notifications for new ticket offers and updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  /// Initialize the notification service.
  /// Call this AFTER Firebase.initializeApp() and AFTER user is authenticated.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 [FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('🔔 [FCM] Notifications permission denied by user.');
      return;
    }

    // 2. Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_ticketChannel);

    // 3. Initialize flutter_local_notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 4. Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 5. Handle notification tap when app is in background/killed
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 6. Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🔔 [FCM] App opened from terminated state via notification');
      _onMessageOpenedApp(initialMessage);
    }

    // 7. Get and save FCM token
    await _getAndSaveToken();

    // 8. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔔 [FCM] Token refreshed: $newToken');
      _saveTokenToBackend(newToken);
    });

    _isInitialized = true;
    print('🔔 [FCM] NotificationService initialized successfully ✅');
  }

  /// Handle foreground messages — show a local notification
  void _onForegroundMessage(RemoteMessage message) {
    print('🔔 [FCM] Foreground message: ${message.messageId}');
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title ?? 'New Ticket',
        body: notification.body ?? 'You have a new ticket offer',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _ticketChannel.id,
            _ticketChannel.name,
            channelDescription: _ticketChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap when app is in background
  void _onMessageOpenedApp(RemoteMessage message) {
    print('🔔 [FCM] Notification tapped: ${message.data}');
    // The app will naturally navigate to the tickets screen
    // since on auth, tickets are fetched automatically.
    // If you need specific navigation, handle message.data here.
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 [FCM] Local notification tapped: ${response.payload}');
    // Handle navigation based on payload if needed
  }

  /// Get FCM token and save to backend
  Future<void> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print('🔔 [FCM] Token: $token');
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      print('🔔 [FCM] Error getting token: $e');
    }
  }

  /// Save FCM token to the PHP backend
  Future<void> _saveTokenToBackend(String fcmToken) async {
    try {
      final authToken = await AuthStorage.getToken();
      if (authToken == null) {
        print('🔔 [FCM] No auth token, skipping FCM token save.');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.saveFcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'device_type': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        }),
      );

      if (response.statusCode == 200) {
        print('🔔 [FCM] Token saved to backend ✅');
      } else {
        print(
          '🔔 [FCM] Failed to save token: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('🔔 [FCM] Error saving token to backend: $e');
    }
  }

  /// Get current FCM token (for debugging)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
