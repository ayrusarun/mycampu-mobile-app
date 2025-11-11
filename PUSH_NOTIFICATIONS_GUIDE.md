# Push Notifications Implementation Guide

## Overview
This guide explains how to implement push notifications for new posts in the MyCampus Mobile App.

## How Push Notifications Work

### Architecture
```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────────┐
│   User A    │      │   Backend    │      │     FCM     │      │   User B     │
│  (Posts)    │─────▶│   Server     │─────▶│   Server    │─────▶│  (Receives)  │
└─────────────┘      └──────────────┘      └─────────────┘      └──────────────┘
     Creates              Triggers            Delivers            Shows
     Post                 Notification        to Devices          Notification
```

### Components

1. **Firebase Cloud Messaging (FCM)**
   - Google's free push notification service
   - Works on Android, iOS, and Web
   - Handles message delivery and queueing

2. **Device Token**
   - Unique identifier for each app installation
   - Generated when app first launches
   - Stored in backend database linked to user

3. **Backend Server**
   - Stores user device tokens
   - Sends notification requests to FCM when posts are created
   - Can target specific users, groups, or broadcast to all

4. **Flutter App**
   - Receives and displays notifications
   - Handles notification taps (deep linking)
   - Requests user permission for notifications

## Implementation Steps

### Phase 1: Firebase Setup (One-time setup)

#### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "MyCampus Mobile App"
4. Enable Google Analytics (optional)
5. Create project

#### 1.2 Add Android App
1. In Firebase Console, click Android icon
2. Enter package name: `com.mycampus.mobile_app` (from android/app/build.gradle.kts)
3. Download `google-services.json`
4. Place in `android/app/` directory

#### 1.3 Add iOS App
1. Click iOS icon in Firebase Console
2. Enter bundle ID: `com.mycampus.mobileApp` (from ios/Runner.xcodeproj)
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/` directory

#### 1.4 Install FlutterFire CLI
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase for Flutter project
flutterfire configure
```

### Phase 2: Flutter App Implementation

#### 2.1 Add Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.6
  flutter_local_notifications: ^16.3.0
```

#### 2.2 Platform-Specific Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest>
    <application>
        <!-- Add this inside <application> tag -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
    </application>
</manifest>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
- Enable Push Notifications in Xcode capabilities
- Request notification permissions

#### 2.3 Create Notification Service
Create `lib/services/notification_service.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Get FCM token
    _fcmToken = await _messaging.getToken();
    print('FCM Token: $_fcmToken');
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      // TODO: Send updated token to backend
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    print('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
    
    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Navigate to specific screen based on data
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
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
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.title}');
}
```

#### 2.4 Update Main.dart
```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService().initialize();
  
  runApp(const MyApp());
}
```

#### 2.5 Send Token to Backend
Update `auth_service.dart` after successful login:
```dart
// After successful login
final notificationService = NotificationService();
if (notificationService.fcmToken != null) {
  await _sendTokenToBackend(notificationService.fcmToken!);
}
```

### Phase 3: Backend Implementation

#### 3.1 Database Schema
Add to User model:
```python
class User(Base):
    # ... existing fields ...
    fcm_tokens = Column(JSON, default=list)  # Array of device tokens
    notification_enabled = Column(Boolean, default=True)
```

#### 3.2 Token Registration Endpoint
```python
@router.post("/users/register-device")
async def register_device_token(
    token: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Add token to user's token list (if not already present)
    if current_user.fcm_tokens is None:
        current_user.fcm_tokens = []
    
    if token not in current_user.fcm_tokens:
        current_user.fcm_tokens.append(token)
        db.commit()
    
    return {"status": "success"}
```

#### 3.3 FCM Service (Python)
Install: `pip install firebase-admin`

```python
import firebase_admin
from firebase_admin import credentials, messaging

# Initialize Firebase Admin SDK
cred = credentials.Certificate("path/to/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

async def send_notification(
    tokens: List[str],
    title: str,
    body: str,
    data: dict = None
):
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data or {},
        tokens=tokens,
    )
    
    response = messaging.send_multicast(message)
    print(f'Successfully sent: {response.success_count}')
    print(f'Failed: {response.failure_count}')
    
    return response
```

#### 3.4 Trigger on Post Creation
```python
@router.post("/posts/")
async def create_post(
    post: PostCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Create post
    new_post = Post(
        title=post.title,
        content=post.content,
        author_id=current_user.id,
        # ... other fields
    )
    db.add(new_post)
    db.commit()
    
    # Send notifications (async task)
    await notify_new_post(db, new_post, current_user)
    
    return new_post

async def notify_new_post(db: Session, post: Post, author: User):
    # Get all users in the same college (except author)
    users = db.query(User).filter(
        User.college_id == author.college_id,
        User.id != author.id,
        User.notification_enabled == True
    ).all()
    
    # Collect all tokens
    tokens = []
    for user in users:
        if user.fcm_tokens:
            tokens.extend(user.fcm_tokens)
    
    if tokens:
        await send_notification(
            tokens=tokens,
            title=f"New {post.post_type} Post",
            body=f"{author.full_name}: {post.title[:50]}...",
            data={
                "post_id": str(post.id),
                "type": "new_post",
                "author_id": str(author.id),
            }
        )
```

### Phase 4: Advanced Features

#### 4.1 Topic-Based Notifications
Subscribe users to topics (departments, clubs, etc.):
```dart
// Subscribe to topics
await FirebaseMessaging.instance.subscribeToTopic('computer_science');
await FirebaseMessaging.instance.subscribeToTopic('announcements');
```

Backend sends to topic:
```python
message = messaging.Message(
    notification=messaging.Notification(
        title='Department Update',
        body='New announcement posted'
    ),
    topic='computer_science'
)
```

#### 4.2 Notification Preferences
Let users control what notifications they receive:
- New posts in their department
- Announcements only
- Event reminders
- Chat messages

#### 4.3 Smart Notifications
- Don't send if user is currently active in app
- Batch notifications (max 1 per minute)
- Quiet hours (no notifications at night)
- Priority notifications for IMPORTANT posts

## Testing

### 1. Test Token Registration
```bash
# In Flutter app, check console for FCM token
# Verify token is sent to backend
```

### 2. Test Notification from Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and body
4. Select your device token
5. Send notification

### 3. Test Post Notification
1. Create a new post
2. Check if notification appears on other devices
3. Tap notification → verify navigation works

## Best Practices

1. **Handle Token Refresh**: FCM tokens can change, always update backend
2. **Clean Old Tokens**: Remove invalid tokens after failed sends
3. **Rate Limiting**: Don't spam users with too many notifications
4. **Privacy**: Only send notifications to relevant users
5. **Battery Efficiency**: Use FCM topics instead of individual sends when possible
6. **Testing**: Test on both Android and iOS
7. **Error Handling**: Gracefully handle permission denials

## Cost Considerations

- **FCM is FREE** for unlimited notifications
- Firebase has generous free tier
- Costs only apply if using Firebase Database/Analytics heavily

## Troubleshooting

1. **Notifications not received**:
   - Check app permissions
   - Verify FCM token is valid
   - Check Firebase Console for delivery status

2. **iOS not working**:
   - Enable Push Notifications capability in Xcode
   - Upload APNs certificate to Firebase

3. **Background notifications not showing**:
   - Check notification channel importance
   - Verify app is not in battery optimization

## Next Steps

1. Set up Firebase project
2. Add dependencies and initialize
3. Implement NotificationService
4. Update backend to send notifications
5. Test on multiple devices
6. Add notification preferences UI
7. Implement deep linking for notification taps

## Resources

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
