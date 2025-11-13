import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/news_model.dart';
import '../services/auth_service.dart';

class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  final AuthService _authService = AuthService();

  Future<NewsResponse> fetchTechHeadlines() async {
    try {
      final token = _authService.authToken;
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/news/tech-headlines'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return NewsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  // Future method for other news categories if needed
  Future<NewsResponse> fetchNewsByCategory(String category) async {
    try {
      final token = _authService.authToken;
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/news/$category'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return NewsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}