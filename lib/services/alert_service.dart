import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/alert_model.dart';
import 'auth_service.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final AuthService _authService = AuthService();

  String get _baseUrl => '${AppConfig.baseUrl}/alerts';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${_authService.authToken}',
        'Content-Type': 'application/json',
      };

  /// Get user alerts with pagination and filtering
  Future<AlertListResponse> getAlerts({
    int page = 1,
    int pageSize = 20,
    bool showRead = true,
    bool showDisabled = false,
    bool showExpired = false,
    String? alertType,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'show_read': showRead.toString(),
        'show_disabled': showDisabled.toString(),
        'show_expired': showExpired.toString(),
        if (alertType != null) 'alert_type': alertType,
      });

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AlertListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading alerts: $e');
    }
  }

  /// Get count of unread alerts
  Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/unread-count'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting unread count: $e');
      return 0; // Return 0 on error to avoid breaking UI
    }
  }

  /// Create a new alert
  Future<Alert> createAlert(AlertCreate alertCreate) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(alertCreate.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Alert.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to create alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating alert: $e');
    }
  }

  /// Update an alert (mark as read, enable/disable, etc.)
  Future<Alert> updateAlert(int alertId, AlertUpdate alertUpdate) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$alertId'),
        headers: _headers,
        body: jsonEncode(alertUpdate.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Alert.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Alert not found');
      } else {
        throw Exception('Failed to update alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating alert: $e');
    }
  }

  /// Mark a specific alert as read
  Future<Alert> markAsRead(int alertId) async {
    return updateAlert(alertId, AlertUpdate(isRead: true));
  }

  /// Mark all alerts as read
  Future<void> markAllAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mark-all-read'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to mark all as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }

  /// Delete an alert
  Future<void> deleteAlert(int alertId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$alertId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Alert not found');
      } else {
        throw Exception('Failed to delete alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting alert: $e');
    }
  }

  /// Get alerts by type
  Future<AlertListResponse> getAlertsByType(
    String alertType, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getAlerts(
      page: page,
      pageSize: pageSize,
      alertType: alertType,
    );
  }

  /// Get only unread alerts
  Future<AlertListResponse> getUnreadAlerts({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getAlerts(
      page: page,
      pageSize: pageSize,
      showRead: false,
    );
  }

  /// Enable/disable an alert
  Future<Alert> toggleAlert(int alertId, bool enabled) async {
    return updateAlert(alertId, AlertUpdate(isEnabled: enabled));
  }
}
