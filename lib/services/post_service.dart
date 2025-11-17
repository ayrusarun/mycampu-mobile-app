import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/post_model.dart';
import '../models/api_exception.dart';
import 'auth_service.dart';

class PostService {
  final AuthService _authService = AuthService();

  // Get all posts
  Future<List<Post>> getPosts({int skip = 0, int limit = 50}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/posts/?skip=$skip&limit=$limit'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading posts: $e');
      rethrow;
    }
  }

  // Get posts by type
  Future<List<Post>> getPostsByType(String postType,
      {int skip = 0, int limit = 50}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/posts/type/$postType?skip=$skip&limit=$limit'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading posts: $e');
      rethrow;
    }
  }

  // Toggle like on a post
  Future<Map<String, dynamic>?> toggleLike(int postId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // Return error details for bad request or forbidden
        try {
          final errorData = jsonDecode(response.body);
          return {
            'error': true,
            'message': errorData['detail'] ?? 'Failed to toggle like'
          };
        } catch (e) {
          return {
            'error': true,
            'message': 'Failed to toggle like: ${response.statusCode}'
          };
        }
      } else {
        throw Exception('Failed to toggle like: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling like: $e');
      return null;
    }
  }

  // Check if user has liked a post
  Future<bool> isLiked(int postId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/is-liked'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_liked'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Toggle ignite on a post
  Future<Map<String, dynamic>?> toggleIgnite(int postId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/ignite'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // Return error details for bad request or forbidden
        try {
          final errorData = jsonDecode(response.body);
          return {
            'error': true,
            'message': errorData['detail'] ?? 'Failed to toggle ignite'
          };
        } catch (e) {
          return {
            'error': true,
            'message': 'Failed to toggle ignite: ${response.statusCode}'
          };
        }
      } else {
        throw Exception('Failed to toggle ignite: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling ignite: $e');
      return null;
    }
  }

  // Check if user has ignited a post
  Future<bool> isIgnited(int postId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/is-ignited'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_ignited'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking ignite status: $e');
      return false;
    }
  }

  // Get comments for a post
  Future<Map<String, dynamic>?> getComments(int postId,
      {int page = 1, int pageSize = 20}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/posts/$postId/comments?page=$page&page_size=$pageSize'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading comments: $e');
      return null;
    }
  }

  // Add a comment to a post
  Future<Map<String, dynamic>?> addComment(int postId, String content) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  // Like a post
  Future<bool> likePost(int postId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  // Update post metadata (likes, comments, shares)
  Future<Post?> updatePostMetadata(int postId,
      {int? likes, int? comments, int? shares}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> body = {};
      if (likes != null) body['likes'] = likes;
      if (comments != null) body['comments'] = comments;
      if (shares != null) body['shares'] = shares;

      final response = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId/metadata'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return Post.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update metadata: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating metadata: $e');
      return null;
    }
  }

  // Create a post
  Future<Post?> createPost({
    required String title,
    required String content,
    String? imageUrl,
    String postType = 'GENERAL',
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/posts/'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'image_url': imageUrl,
          'post_type': postType,
        }),
      );

      if (response.statusCode == 200) {
        return Post.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        // Check if it's an inappropriate content error
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map<String, dynamic> &&
              errorBody.containsKey('detail')) {
            final detail = errorBody['detail'].toString().toLowerCase();
            if (detail.contains('inappropriate') ||
                detail.contains('foul language') ||
                detail.contains('offensive')) {
              // Throw custom exception with the detail message
              throw InappropriateContentException(errorBody['detail']);
            }
          }
        } catch (e) {
          if (e is InappropriateContentException) {
            rethrow;
          }
        }
        throw ApiException('Failed to create post: ${response.body}',
            statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to create post: ${response.statusCode}',
            statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Update a post
  Future<Post?> updatePost({
    required int postId,
    String? title,
    String? content,
    String? imageUrl,
    String? postType,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      // Build update body with only provided fields
      final Map<String, dynamic> body = {};
      if (title != null) body['title'] = title;
      if (content != null) body['content'] = content;
      if (imageUrl != null) body['image_url'] = imageUrl;
      if (postType != null) body['post_type'] = postType;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/posts/$postId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return Post.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        // Check if it's an inappropriate content error
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map<String, dynamic> &&
              errorBody.containsKey('detail')) {
            final detail = errorBody['detail'].toString().toLowerCase();
            if (detail.contains('inappropriate') ||
                detail.contains('foul language') ||
                detail.contains('offensive')) {
              throw InappropriateContentException(errorBody['detail']);
            }
          }
        } catch (e) {
          if (e is InappropriateContentException) {
            rethrow;
          }
        }
        throw ApiException('Failed to update post: ${response.body}',
            statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to update post: ${response.statusCode}',
            statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }
}
