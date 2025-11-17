import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_model.dart';
import '../config/app_config.dart';

class RewardService {
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

  // Get all rewards in the college
  Future<List<Reward>> getRewards({int skip = 0, int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/?skip=$skip&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((reward) => Reward.fromJson(reward)).toList();
      } else {
        throw Exception('Failed to load rewards: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load rewards: $e');
    }
  }

  // Get current user's reward summary
  Future<RewardSummary> getMyRewards() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RewardSummary.fromJson(data);
      } else {
        throw Exception(
            'Failed to load reward summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load reward summary: $e');
    }
  }

  // Get leaderboard
  Future<List<RewardLeaderboard>> getLeaderboard({int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/leaderboard?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => RewardLeaderboard.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load leaderboard: $e');
    }
  }

  // Get reward points for a specific user
  Future<RewardPoints> getUserPoints(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/points/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RewardPoints.fromJson(data);
      } else {
        throw Exception('Failed to load user points: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user points: $e');
    }
  }

  // Get available reward types
  Future<List<String>> getRewardTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/types'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Failed to load reward types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load reward types: $e');
    }
  }

  // Create a new reward (give reward to someone)
  Future<Reward> createReward({
    required int receiverId,
    required int points,
    required String rewardType,
    required String title,
    String? description,
    int? postId,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'receiver_id': receiverId,
        'points': points,
        'reward_type': rewardType,
        'title': title,
        if (description != null) 'description': description,
        if (postId != null) 'post_id': postId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/rewards/'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Reward.fromJson(data);
      } else {
        throw Exception('Failed to create reward: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create reward: $e');
    }
  }

  // Get users (for selecting who to give rewards to)
  Future<List<Map<String, dynamic>>> getUsers(
      {int skip = 0, int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/?skip=$skip&limit=$limit'),
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

  // Get reward pool balance
  Future<Map<String, dynamic>> getPoolBalance() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/pool/balance'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load pool balance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load pool balance: $e');
    }
  }

  // Credit pool (Admin only)
  Future<Map<String, dynamic>> creditPool({
    required int amount,
    String? description,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'amount': amount,
        if (description != null) 'description': description,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/pool/credit'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to credit pool');
      }
    } catch (e) {
      throw Exception('Failed to credit pool: $e');
    }
  }

  // Get pool transactions
  Future<List<Map<String, dynamic>>> getPoolTransactions({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/pool/transactions?skip=$skip&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load pool transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load pool transactions: $e');
    }
  }
}
