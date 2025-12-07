import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/device_model.dart';
import '../main.dart' show navigatorKey;
import 'auth_service.dart';

// Top-level function for background message handling
// Must be top-level or static
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;
  RemoteMessage? _pendingNotification;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _requestPermissions();
      await _initializeLocalNotifications();

      _fcmToken = await _messaging.getToken();

      if (_authService.isAuthenticated && _fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }

      _messaging.onTokenRefresh.listen(_handleTokenRefresh);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _pendingNotification = initialMessage;
      }

      _initialized = true;
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    _fcmToken = newToken;
    if (_authService.isAuthenticated) {
      final result = await _sendTokenToBackend(newToken);
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_registered_fcm_token', newToken);
      }
    }
  }

  /// Handle pending notification from terminated state
  Future<void> handlePendingNotification() async {
    if (_pendingNotification == null) return;

    final notification = _pendingNotification;
    _pendingNotification = null;

    await Future.delayed(const Duration(milliseconds: 500));

    final postId = notification!.data['post_id'];
    if (postId != null) {
      final navigator = _getNavigator();
      navigator?.pushNamed('/post-detail',
          arguments: int.parse(postId.toString()));
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handleNotificationPayload(details.payload!);
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  /// Handle notification tap from background state
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data.isEmpty) {
      _navigateToHome();
      return;
    }
    _waitForNavigatorAndHandle(message.data);
  }

  /// Wait for navigator to be ready
  void _waitForNavigatorAndHandle(Map<String, dynamic> data,
      {int attempts = 0}) {
    if (attempts > 10) return;

    final navigator = _getNavigator();
    if (navigator != null) {
      _handleNotificationPayload(jsonEncode(data));
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        _waitForNavigatorAndHandle(data, attempts: attempts + 1);
      });
    }
  }

  /// Handle notification payload
  void _handleNotificationPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      final postId = data['post_id'];

      if (postId != null) {
        _navigateToPost(int.parse(postId.toString()));
      } else {
        _navigateToHome();
      }
    } catch (e) {
      _navigateToHome();
    }
  }

  /// Navigate to post detail
  void _navigateToPost(int postId) {
    final navigator = _getNavigator();
    if (navigator != null) {
      navigator.pushNamed('/post-detail', arguments: postId);
    } else {
      Future.delayed(const Duration(seconds: 1), () => _navigateToPost(postId));
    }
  }

  /// Navigate to home
  void _navigateToHome() {
    _getNavigator()?.pushNamedAndRemoveUntil('/home', (route) => false);
  }

  /// Get navigator state
  NavigatorState? _getNavigator() {
    try {
      return navigatorKey.currentState;
    } catch (e) {
      return null;
    }
  }

  /// Show local notification in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
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
            channelDescription: 'Important notifications.',
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
      print('❌ Error showing notification: $e');
    }
  }

  /// Send FCM token to backend
  Future<DeviceResponse?> _sendTokenToBackend(String token) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final deviceName = Platform.isAndroid ? 'Android Device' : 'iOS Device';

      final request = DeviceRegisterRequest(
        token: token,
        platform: platform,
        deviceName: deviceName,
      );

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.devicesEndpoint}'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final deviceResponse =
            DeviceResponse.fromJson(jsonDecode(response.body));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        await prefs.setInt('device_id', deviceResponse.id);

        return deviceResponse;
      }
      return null;
    } catch (e) {
      print('❌ Error sending token to backend: $e');
      return null;
    }
  }

  /// Get all registered devices
  Future<List<DeviceResponse>> getMyDevices() async {
    if (!_authService.isAuthenticated) return [];

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.devicesEndpoint}'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> devicesJson = jsonDecode(response.body);
        return devicesJson
            .map((json) => DeviceResponse.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting devices: $e');
      return [];
    }
  }

  /// Register current device
  Future<DeviceResponse?> registerCurrentDevice() async {
    if (!_authService.isAuthenticated) return null;

    _fcmToken ??= await _messaging.getToken();
    return _fcmToken != null ? await _sendTokenToBackend(_fcmToken!) : null;
  }

  /// Unregister device by token
  Future<bool> unregisterDeviceByToken(String token) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final request = DeviceUnregisterRequest(deviceToken: token);

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.devicesEndpoint}'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 204) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('fcm_token');
        await prefs.remove('device_id');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error unregistering device: $e');
      return false;
    }
  }

  /// Unregister device by ID
  Future<bool> unregisterDeviceById(int deviceId) async {
    if (!_authService.isAuthenticated) return false;

    try {
      final response = await http.delete(
        Uri.parse(
            '${AppConfig.baseUrl}${AppConfig.deviceByIdEndpoint(deviceId)}'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        final prefs = await SharedPreferences.getInstance();
        final storedDeviceId = prefs.getInt('device_id');
        if (storedDeviceId == deviceId) {
          await prefs.remove('fcm_token');
          await prefs.remove('device_id');
        }
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error unregistering device: $e');
      return false;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Check if permission is granted
  Future<bool> isPermissionGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteToken() async {
    try {
      if (_fcmToken != null && _authService.isAuthenticated) {
        await unregisterDeviceByToken(_fcmToken!);
      }

      await _messaging.deleteToken();
      _fcmToken = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      await prefs.remove('device_id');
      await prefs.remove('last_registered_fcm_token');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }
}
