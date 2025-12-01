import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/department_model.dart';
import '../models/api_exception.dart';
import 'auth_service.dart';

class DepartmentService {
  final AuthService _authService = AuthService();
  static const String _baseUrl = AppConfig.baseUrl;

  Map<String, String> _getHeaders() {
    final token = _authService.authToken;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Get all departments for the logged-in user's college
  Future<List<Department>> getDepartments() async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/departments/');

      print('📚 Fetching departments from: $uri');
      final response = await http.get(uri, headers: headers);

      print('📚 Response status: ${response.statusCode}');
      print('📚 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Department.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to fetch departments: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('📚 Error fetching departments: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get departments with statistics
  Future<List<DepartmentStats>> getDepartmentsWithStats() async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/departments/with-stats');

      print('📊 Fetching departments with stats from: $uri');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DepartmentStats.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to fetch department stats: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('📊 Error fetching department stats: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get specific department by ID
  Future<Department?> getDepartmentById(int departmentId) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/departments/$departmentId');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Department.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to fetch department: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('📚 Error fetching department by ID: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Create custom department (Admin only)
  Future<Department?> createDepartment({
    required String code,
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/departments/');

      final body = json.encode({
        'code': code,
        'name': name,
        'description': description ?? '',
        'is_active': isActive,
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Department.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw ApiException('Admin access required');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to create department: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('📚 Error creating department: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Update department (Admin only)
  Future<Department?> updateDepartment(
    int departmentId, {
    String? code,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/departments/$departmentId');

      final Map<String, dynamic> bodyData = {};
      if (code != null) bodyData['code'] = code;
      if (name != null) bodyData['name'] = name;
      if (description != null) bodyData['description'] = description;
      if (isActive != null) bodyData['is_active'] = isActive;

      final body = json.encode(bodyData);

      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Department.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw ApiException('Admin access required');
      } else if (response.statusCode == 404) {
        throw ApiException('Department not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to update department: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('📚 Error updating department: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Delete (deactivate) department (Admin only)
  Future<Map<String, dynamic>?> deleteDepartment(int departmentId) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/departments/$departmentId');

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw ApiException('Admin access required');
      } else if (response.statusCode == 404) {
        throw ApiException('Department not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to delete department: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('📚 Error deleting department: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Activate department (Admin only)
  Future<Department?> activateDepartment(int departmentId) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/departments/$departmentId/activate');

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Department.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw ApiException('Admin access required');
      } else if (response.statusCode == 404) {
        throw ApiException('Department not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to activate department: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('📚 Error activating department: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }
}
