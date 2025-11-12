# MyCampus Mobile App

A Flutter mobile application for a college community platform with multi-tenant SaaS backend.

## 📱 About

MyCampus is a cross-platform mobile application built with Flutter that serves as a college community hub. This app is designed to connect students, faculty, and staff within college communities, providing a platform for collaboration, communication, and staying updated with campus activities.

## 🚀 Features

- **Welcome Screen**: Clean, modern welcome interface with college community branding
- **Cross-Platform**: Built with Flutter for both iOS and Android
- **Material Design**: Follows Material Design 3 guidelines
- **Responsive**: Optimized for various screen sizes
- **Scalable Architecture**: Designed for multi-tenant SaaS backend integration

## 🏗️ Project Structure

```
mycampus_mobile_app/
├── lib/
│   ├── main.dart              # App entry point
│   └── screens/
│       └── welcome_screen.dart # Welcome screen UI
├── test/
│   └── widget_test.dart       # Widget tests
├── android/                   # Android-specific files
├── ios/                       # iOS-specific files
├── pubspec.yaml              # Dependencies and project config
└── README.md                 # This file
```

## 🛠️ Prerequisites

Before running this project, make sure you have:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.13.0)
- [Dart SDK](https://dart.dev/get-dart) (>=3.1.0)
- [VS Code](https://code.visualstudio.com/) with Flutter extension
- [Android Studio](https://developer.android.com/studio) (for Android development)
- [Xcode](https://developer.apple.com/xcode/) (for iOS development, macOS only)

## 🚀 Getting Started

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repository-url>
   cd mycampus-mobile-app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Build APK**:
   ```bash
   # Debug APK (for testing)
   flutter build apk --debug
   
   # Release APK (for production)
   flutter build apk --release
   
   # Split APKs by architecture (recommended for Play Store)
   flutter build apk --split-per-abi
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

5. **Analyze code**:
   ```bash
   flutter analyze
   ```

## 📱 Running on Different Platforms

### Android
```bash
flutter run -d android
```

### iOS (macOS only)
```bash
flutter run -d ios
```

### Web
```bash
flutter run -d web
```

## 🧪 Testing

Run the test suite:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## 🎨 Design System

The app uses a consistent design system based on Material Design 3:

- **Primary Color**: Deep Purple
- **Typography**: Material Design typography scale
- **Spacing**: 8px grid system
- **Border Radius**: 12px for buttons, 24px for cards

## 🔮 Future Enhancements

- [ ] User authentication and onboarding
- [ ] College selection and multi-tenant support
- [ ] Student dashboard
- [ ] Campus events and announcements
- [ ] Chat and messaging features
- [ ] Academic calendar integration
- [ ] Campus map and navigation
- [ ] Student clubs and organizations
- [ ] Dark mode support

## 🤝 Contributing

This project follows a layer-by-layer development approach. When contributing:

1. Follow Flutter best practices
2. Maintain Material Design consistency
3. Write tests for new features
4. Update documentation as needed

## 📝 Development Notes

- **Current Phase**: Welcome screen implementation
- **Architecture**: Clean architecture with feature-based organization
- **State Management**: To be implemented (Consider Provider, Riverpod, or Bloc)
- **Backend Integration**: Prepared for multi-tenant SaaS backend

## 📄 License

This project is part of a college community platform development initiative.

---

**Note**: This is the initial version with a basic welcome screen. More features will be added progressively as the app develops layer by layer.