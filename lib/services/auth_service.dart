import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _authToken;
  User? _currentUser;

  String? get authToken => _authToken;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null;

  // Initialize service - load stored token
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);

    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        // Clear invalid user data
        await prefs.remove(_userKey);
      }
    }

    // Don't validate token on startup to avoid logout when backend is down
    // Token will be validated when making API calls
  }

  // Direct login with username and password using the new API
  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      // Step 1: Call the new login API endpoint
      final loginResponse = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (loginResponse.statusCode == 200) {
        final tokenData = jsonDecode(loginResponse.body);
        _authToken = tokenData['access_token'];

        // Step 2: Fetch user profile from /users/me
        final userProfile = await getUserProfile();
        if (userProfile != null) {
          // Create User object from profile data
          _currentUser = User(
            id: userProfile.id.toString(),
            email: userProfile.email,
            name: userProfile.fullName,
            tenantId: userProfile.collegeId.toString(),
            roles: [],
          );

          // Step 3: Store token, user data, and credentials
          await _storeAuthData(username, password);

          // Step 4: Register device for push notifications
          await _registerDeviceForNotifications();

          return true;
        }
      } else if (loginResponse.statusCode == 401) {
        // Invalid credentials
        print('Login failed: Invalid credentials');
        return false;
      } else {
        // Other error
        print(
            'Login failed: ${loginResponse.statusCode} - ${loginResponse.body}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }

    return false;
  }

  // Redirect to backend auth endpoint (which then redirects to Keycloak)
  Future<void> redirectToKeycloak() async {
    final loginUrl =
        Uri.parse('${AppConfig.baseUrl}${AppConfig.loginEndpoint}');

    print('Launching auth URL: $loginUrl');

    if (await canLaunchUrl(loginUrl)) {
      await launchUrl(loginUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch login URL: $loginUrl');
    }
  }

  // Handle OAuth callback with token
  Future<bool> handleOAuthCallback(String token) async {
    try {
      _authToken = token;

      // Decode token to get user info
      final payload = _decodeJWT(token);
      if (payload != null) {
        _currentUser = User.fromJWT(payload);

        // Store token and user
        await _storeAuthData();

        // Register device for push notifications
        await _registerDeviceForNotifications();

        return true;
      }
      return false;
    } catch (e) {
      print('Error handling OAuth callback: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    // Delete FCM token
    await NotificationService().deleteToken();

    _authToken = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
  }

  // Register device for push notifications
  Future<void> _registerDeviceForNotifications() async {
    try {
      final notificationService = NotificationService();
      final fcmToken = notificationService.fcmToken;

      if (fcmToken != null) {
        print(
            '📱 Device token available, will be registered automatically by NotificationService');
      } else {
        print('⚠️ FCM token not yet available');
      }
    } catch (e) {
      print('❌ Error registering device for notifications: $e');
    }
  }

  // Get user profile from API
  Future<UserProfile?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/me'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        // No profile exists yet
        return null;
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading profile: $e');
      return null;
    }
  }

  // Update user profile (if needed in future)
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    if (!isAuthenticated) return false;

    try {
      // Note: The current API doesn't have a PUT endpoint for user profile
      // This method is kept for future use
      print('Update profile not yet implemented in API');
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Update password
  Future<Map<String, dynamic>> updatePassword(
      String currentPassword, String newPassword) async {
    if (!isAuthenticated) {
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/auth/update-password'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        // Update stored password if credentials are saved
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString(_usernameKey);
        if (username != null) {
          await prefs.setString(_passwordKey, newPassword);
        }

        return {
          'success': true,
          'message': 'Password updated successfully',
        };
      } else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Current password is incorrect',
        };
      } else if (response.statusCode == 422) {
        return {
          'success': false,
          'message':
              'Invalid password format. Password must meet requirements.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update password. Please try again.',
        };
      }
    } catch (e) {
      print('Error updating password: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Private methods
  Future<void> _storeAuthData([String? username, String? password]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _authToken!);
    if (_currentUser != null) {
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    }
    // Store credentials for auto-login (only when provided)
    if (username != null && password != null) {
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);
    }
  }

  Map<String, dynamic>? _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));

      return jsonDecode(decoded);
    } catch (e) {
      return null;
    }
  }
}
