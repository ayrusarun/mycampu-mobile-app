import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/group_model.dart';
import 'auth_service.dart';

class GroupService {
  final AuthService _authService = AuthService();

  /// Get all groups the current user is a member of
  Future<List<Group>> getMyGroups() async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/groups/my-groups'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final userGroupsResponse = UserGroupsResponse.fromJson(jsonData);
        return userGroupsResponse.groups;
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading groups: $e');
      rethrow;
    }
  }

  /// Get all available groups (for exploration)
  Future<List<Group>> getAllGroups() async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/groups/'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Group.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading all groups: $e');
      rethrow;
    }
  }

  /// Get a specific group by ID
  Future<Group?> getGroupById(int groupId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/groups/$groupId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        return Group.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load group: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading group: $e');
      return null;
    }
  }

  /// Join a group
  Future<bool> joinGroup(int groupId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/groups/$groupId/join'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error joining group: $e');
      return false;
    }
  }
}
