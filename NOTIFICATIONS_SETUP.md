# Push Notifications - Quick Start Guide

## ✅ What I've Created For You

1. **PUSH_NOTIFICATIONS_GUIDE.md** - Complete implementation guide
2. **lib/services/notification_service.dart** - Ready-to-use notification service

## 🚀 Setup Instructions (Step-by-Step)

### Step 1: Add Dependencies

Update `pubspec.yaml` to include:

```yaml
dependencies:
  # Existing dependencies...
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.6
  flutter_local_notifications: ^16.3.0
```

Then run:
```bash
flutter pub get
```

### Step 2: Setup Firebase Project

#### Option A: Using FlutterFire CLI (Recommended)
```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase (this will create firebase_options.dart automatically)
flutterfire configure --project=mycampus-mobile-app
```

#### Option B: Manual Setup
1. Go to https://console.firebase.google.com/
2. Create new project "MyCampus Mobile App"
3. Add Android app:
   - Package name: `com.mycampus.mobile_app`
   - Download `google-services.json` → place in `android/app/`
4. Add iOS app:
   - Bundle ID: from your `ios/Runner.xcodeproj`
   - Download `GoogleService-Info.plist` → place in `ios/Runner/`

### Step 3: Update Android Configuration

**android/build.gradle.kts**:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

**android/app/build.gradle.kts** (add at bottom):
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

**android/app/src/main/AndroidManifest.xml** (inside `<application>` tag):
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

### Step 4: Update iOS Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Click "+ Capability" → Add "Push Notifications"
4. Click "+ Capability" → Add "Background Modes"
5. Check "Remote notifications" under Background Modes

### Step 5: Update main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This will be created by flutterfire configure
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );
  
  // Initialize notifications
  await NotificationService().initialize();
  
  runApp(const MyApp());
}
```

### Step 6: Update AuthService

After successful login, register the device token:

```dart
// In auth_service.dart, after successful login
final notificationService = NotificationService();
if (notificationService.fcmToken != null) {
  // Token will be automatically sent to backend by NotificationService
  print('Device registered for notifications');
}
```

On logout, delete the token:

```dart
// In logout method
await NotificationService().deleteToken();
```

### Step 7: Backend Setup

#### Create the endpoint to receive device tokens:

```python
# Add to your FastAPI backend

from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

class DeviceToken(BaseModel):
    token: str

@router.post("/users/register-device")
async def register_device_token(
    device_token: DeviceToken,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Register FCM device token for push notifications"""
    
    # Initialize fcm_tokens if None
    if current_user.fcm_tokens is None:
        current_user.fcm_tokens = []
    
    # Add token if not already present
    if device_token.token not in current_user.fcm_tokens:
        current_user.fcm_tokens.append(device_token.token)
        db.commit()
        return {"status": "success", "message": "Device registered"}
    
    return {"status": "success", "message": "Device already registered"}
```

#### Update User model to include fcm_tokens:

```python
class User(Base):
    __tablename__ = "users"
    
    # ... existing fields ...
    fcm_tokens = Column(JSON, default=list)  # List of device tokens
    notification_enabled = Column(Boolean, default=True)
```

#### Install Firebase Admin SDK:

```bash
pip install firebase-admin
```

#### Create notification service in backend:

```python
# backend/services/notification_service.py

import firebase_admin
from firebase_admin import credentials, messaging
from typing import List

# Initialize Firebase Admin (do this once at startup)
cred = credentials.Certificate("path/to/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

async def send_post_notification(
    tokens: List[str],
    post_title: str,
    author_name: str,
    post_id: int,
    post_type: str
):
    """Send notification when new post is created"""
    
    if not tokens:
        return
    
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=f"New {post_type} Post",
            body=f"{author_name}: {post_title[:50]}...",
        ),
        data={
            "type": "new_post",
            "post_id": str(post_id),
            "author_name": author_name,
        },
        tokens=tokens,
    )
    
    try:
        response = messaging.send_multicast(message)
        print(f'✅ Sent: {response.success_count}, Failed: {response.failure_count}')
        return response
    except Exception as e:
        print(f'❌ Error sending notification: {e}')
```

#### Trigger notification when post is created:

```python
@router.post("/posts/")
async def create_post(
    post: PostCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    background_tasks: BackgroundTasks
):
    # Create post
    new_post = Post(
        title=post.title,
        content=post.content,
        author_id=current_user.id,
        college_id=current_user.college_id,
        post_type=post.post_type,
    )
    db.add(new_post)
    db.commit()
    db.refresh(new_post)
    
    # Send notifications in background
    background_tasks.add_task(
        notify_users_about_new_post,
        db=db,
        post=new_post,
        author=current_user
    )
    
    return new_post

async def notify_users_about_new_post(db: Session, post: Post, author: User):
    """Send push notifications to relevant users"""
    
    # Get all users in the same college (except author)
    users = db.query(User).filter(
        User.college_id == author.college_id,
        User.id != author.id,
        User.notification_enabled == True
    ).all()
    
    # Collect all FCM tokens
    tokens = []
    for user in users:
        if user.fcm_tokens:
            tokens.extend(user.fcm_tokens)
    
    # Send notification
    if tokens:
        await send_post_notification(
            tokens=tokens,
            post_title=post.title,
            author_name=author.full_name,
            post_id=post.id,
            post_type=post.post_type
        )
```

### Step 8: Get Firebase Admin SDK Key

1. Go to Firebase Console → Project Settings
2. Click "Service Accounts" tab
3. Click "Generate new private key"
4. Save the JSON file securely
5. Reference it in your backend code

### Step 9: Test It!

1. Run your Flutter app:
   ```bash
   flutter run
   ```

2. Check logs for FCM token:
   ```
   📱 FCM Token obtained: ...
   ✅ Device token registered with backend
   ```

3. Test from Firebase Console:
   - Go to Cloud Messaging
   - Send test notification
   - Enter your FCM token

4. Create a post and verify notification is received!

## 🎯 Quick Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Test on Android
flutter run -d android

# Test on iOS
flutter run -d ios

# View logs
flutter logs
```

## 📱 Testing Checklist

- [ ] Firebase project created
- [ ] Dependencies added and installed
- [ ] Android configuration updated
- [ ] iOS configuration updated (if testing on iOS)
- [ ] main.dart updated with Firebase initialization
- [ ] Backend endpoint created for device tokens
- [ ] Firebase Admin SDK installed in backend
- [ ] Notification service created in backend
- [ ] Test notification from Firebase Console works
- [ ] Test notification when creating post works
- [ ] Notification appears when app is in foreground
- [ ] Notification appears when app is in background
- [ ] Tapping notification opens app

## 🐛 Troubleshooting

**Notifications not appearing:**
- Check app has notification permissions
- Verify FCM token is being sent to backend
- Check Firebase Console → Cloud Messaging for delivery status

**iOS not working:**
- Ensure Push Notifications capability is enabled in Xcode
- Verify APNs certificate is uploaded to Firebase

**Build errors:**
- Run `flutter clean`
- Run `flutter pub get`
- Restart IDE

## 📚 Next Steps

After basic notifications work:

1. **Add topic subscriptions** - Users can subscribe to specific departments/clubs
2. **Notification preferences** - Let users choose what notifications they want
3. **Deep linking** - Navigate to specific screens when notification is tapped
4. **Notification history** - Store notifications in app for later viewing
5. **Smart notifications** - Don't send if user is active, batch notifications, etc.

## 💡 Pro Tips

1. FCM is **completely FREE** - unlimited notifications
2. Test on real devices, not just emulators
3. Use topics for broadcasts instead of individual tokens
4. Clean up invalid tokens from database
5. Add notification preferences UI for better UX

Need help? Check the full guide in **PUSH_NOTIFICATIONS_GUIDE.md**!
