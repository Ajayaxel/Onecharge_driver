import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level function required for background FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 [FCM] Background message received: ${message.messageId}');

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize for the background isolate
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(settings: initSettings);

  final notification = message.notification;
  final data = message.data;

  if (notification == null && data.isNotEmpty) {
    print('🔔 [FCM] Data-only background message. Showing manual alert.');
    await flutterLocalNotificationsPlugin.show(
      id: message.hashCode,
      title: data['title'] ?? 'New Ticket Offered!',
      body: data['body'] ?? 'You have a new ticket offer. Check the app.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ticket_alerts',
          'Ticket Alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }
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
        importance: Importance.max, // Set to max for background popups
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

    // 7. Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      print('🔔 [FCM] Token: $token');
    }

    // 8. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔔 [FCM] Token refreshed: $newToken');
    });

    _isInitialized = true;
    print('🔔 [FCM] NotificationService initialized successfully ✅');
  }

  /// Handle foreground messages — show a local notification
  void _onForegroundMessage(RemoteMessage message) {
    print('🔔 [FCM] Foreground message: ${message.messageId}');
    final notification = message.notification;

    if (notification != null) {
      showLocalNotification(
        id: notification.hashCode,
        title: notification.title ?? 'New Ticket',
        body: notification.body ?? 'You have a new ticket offer',
        data: message.data,
      );
    }
  }

  /// Manually show a local notification (e.g., from Reverb events)
  void showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _ticketChannel.id,
          _ticketChannel.name,
          channelDescription: _ticketChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
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

  /// Get current FCM token (for debugging)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
