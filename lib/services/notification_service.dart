import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';  // Disabled due to SDK compatibility
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

// Top-level function for background message handling
// Must be top-level or static
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();  // Disabled due to SDK compatibility
  final AuthService _authService = AuthService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;

  /// Initialize the notification service
  /// Call this in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permissions first
      await _requestPermissions();

      // Initialize local notifications for showing notifications when app is in foreground
      // await _initializeLocalNotifications();  // Disabled due to SDK compatibility

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      print('📱 FCM Token obtained: ${_fcmToken?.substring(0, 20)}...');

      // Send token to backend if user is authenticated
      if (_authService.isAuthenticated && _fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        print('📱 FCM Token refreshed');
        if (_authService.isAuthenticated) {
          await _sendTokenToBackend(newToken);
        }
      });

      // Handle foreground messages (when app is open)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  /// Request notification permissions from the user
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ Notification permission granted (provisional)');
    } else {
      print('❌ Notification permission denied');
    }
  }

  /// Initialize local notifications for foreground display
  /// Disabled due to Android SDK compatibility issues
  /* Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
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
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap from local notification
        print('📱 Local notification tapped: ${details.payload}');
        if (details.payload != null) {
          _handleNotificationPayload(details.payload!);
        }
      },
    );

    // Create high importance notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  } */

  /// Handle messages received while app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground message received');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Show local notification - disabled due to SDK compatibility
    // _showLocalNotification(message);

    // Note: Notifications will still appear when app is in background
    // For foreground notifications, upgrade to latest packages when SDK compatibility is resolved
  }

  /// Handle notification tap (when opening app from notification)
  void _handleNotificationTap(RemoteMessage message) {
    print('📱 Notification tapped, opening app');
    print('   Data: ${message.data}');

    final data = message.data;
    _handleNotificationPayload(jsonEncode(data));
  }

  /// Handle notification payload and navigate to appropriate screen
  void _handleNotificationPayload(String payload) {
    try {
      final data = jsonDecode(payload);

      // Handle different notification types
      final type = data['type'];
      switch (type) {
        case 'new_post':
          final postId = data['post_id'];
          print('📱 Navigate to post: $postId');
          // TODO: Implement navigation to post details
          // Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailScreen(postId: postId)));
          break;

        case 'new_message':
          final chatId = data['chat_id'];
          print('📱 Navigate to chat: $chatId');
          // TODO: Implement navigation to chat
          break;

        case 'announcement':
          print('📱 Navigate to announcements');
          // TODO: Implement navigation to announcements
          break;

        default:
          print('📱 Unknown notification type: $type');
      }
    } catch (e) {
      print('❌ Error handling notification payload: $e');
    }
  }

  /// Show local notification when app is in foreground
  /// Disabled due to SDK compatibility issues
  /* Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  } */

  /// Send FCM token to backend for storage
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/register-device'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        print('✅ Device token registered with backend');
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      } else {
        print('⚠️ Failed to register device token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }

  /// Subscribe to a topic (e.g., department, club, etc.)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Get notification permission status
  Future<bool> isPermissionGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      print('✅ FCM token deleted');

      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }
}
