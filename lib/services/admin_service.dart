import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AdminService {
  static const String baseUrl = AppConfig.baseUrl;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // List all users in the college
  Future<List<Map<String, dynamic>>> listUsers(
      {int skip = 0, int limit = 100}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users?skip=$skip&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  // Update user role
  Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/role'),
        headers: headers,
        body: json.encode({'role': role}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  // Update user status (activate/deactivate)
  Future<Map<String, dynamic>> updateUserStatus(
      int userId, bool isActive) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/status'),
        headers: headers,
        body: json.encode({'is_active': isActive}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // Get user permissions detail
  Future<Map<String, dynamic>> getUserPermissions(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/$userId/permissions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load permissions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load permissions: $e');
    }
  }

  // Remove custom permission from user
  Future<void> removeCustomPermission(int userId, String permissionName) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId/permissions/$permissionName'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove permission: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to remove permission: $e');
    }
  }

  // List all available permissions
  Future<List<Map<String, dynamic>>> listPermissions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/permissions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        print('🔍 Raw permissions response: $decodedData');
        print('🔍 Response type: ${decodedData.runtimeType}');

        // Handle categorized permissions response
        if (decodedData is Map) {
          List<Map<String, dynamic>> allPermissions = [];

          print('🔍 Processing Map with ${decodedData.length} categories');

          // Iterate through categories (posts, alerts, files, etc.)
          decodedData.forEach((category, permissions) {
            print('🔍 Category: $category, Type: ${permissions.runtimeType}');

            if (permissions is List) {
              print(
                  '🔍   Found ${permissions.length} permissions in $category');
              // Add each permission from this category
              for (var perm in permissions) {
                if (perm is Map) {
                  allPermissions.add({
                    'category': category,
                    'id': perm['id'],
                    'name': perm['name'],
                    'action': perm['action'],
                    'description': perm['description'],
                  });
                }
              }
            }
          });

          print('🔍 Total permissions parsed: ${allPermissions.length}');
          return allPermissions;
        } else if (decodedData is List) {
          return decodedData.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw Exception('Failed to load permissions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in listPermissions: $e');
      throw Exception('Failed to load permissions: $e');
    }
  }

  // List all roles
  Future<List<Map<String, dynamic>>> listRoles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/roles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        // Handle both Map and List responses
        if (decodedData is List) {
          return decodedData.cast<Map<String, dynamic>>();
        } else if (decodedData is Map) {
          // If it's a map with a 'roles' key, extract that
          if (decodedData.containsKey('roles')) {
            final List<dynamic> rolesList = decodedData['roles'];
            return rolesList.cast<Map<String, dynamic>>();
          }
          // Otherwise, wrap the single map in a list
          return [decodedData.cast<String, dynamic>()];
        }
        return [];
      } else {
        throw Exception('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load roles: $e');
    }
  }

  // Create a new user
  Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String fullName,
    required int departmentId,
    required String className,
    required String academicYear,
    required String password,
    required int collegeId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
        body: json.encode({
          'username': username,
          'email': email,
          'full_name': fullName,
          'department_id': departmentId,
          'class_name': className,
          'academic_year': academicYear,
          'password': password,
          'college_id': collegeId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to create user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Delete a user
  Future<void> deleteUser(int userId, {bool force = false}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/admin/users/$userId').replace(
        queryParameters: {'force': force.toString()},
      );

      final response = await http.delete(
        uri,
        headers: headers,
      );

      print('🗑️ Delete user response status: ${response.statusCode}');
      print('🗑️ Delete user response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success - 200 OK or 204 No Content
        return;
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Server returned ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('❌ Delete user error: $e');
      throw Exception('Failed to delete user: $e');
    }
  }
}
