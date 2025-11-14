import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ai_models.dart';
import 'auth_service.dart';

class AiService {
  static const String _baseUrl = AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  Map<String, String> _getHeaders() {
    final token = _authService.authToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ask the AI assistant a question
  Future<AIResponse> askAI(String question, {String? contextFilter}) async {
    final query = AIQuery(
      question: question,
      contextFilter: contextFilter,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/ai/ask'),
      headers: _getHeaders(),
      body: json.encode(query.toJson()),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AIResponse.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to get AI response');
    }
  }

  /// Search knowledge base directly
  Future<List<SearchResult>> searchKnowledge(
    String query, {
    String? contentType,
    int limit = 5,
  }) async {
    final searchQuery = KnowledgeSearchQuery(
      query: query,
      contentType: contentType,
      limit: limit,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/ai/search'),
      headers: _getHeaders(),
      body: json.encode(searchQuery.toJson()),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => SearchResult.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to search knowledge base');
    }
  }

  /// Get user's AI conversations
  Future<List<dynamic>> getConversations({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ai/conversations?limit=$limit'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to get conversations');
    }
  }

  /// Rewrite content using AI
  Future<String> rewriteContent(String content) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/ai/rewrite'),
      headers: _getHeaders(),
      body: json.encode({'content': content}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['rewritten_content'] ?? content;
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to rewrite content');
    }
  }

  /// Get AI system statistics
  Future<Map<String, dynamic>> getAIStats() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ai/stats'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to get AI stats');
    }
  }
}
