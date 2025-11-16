import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/folder_model.dart';
import '../models/api_exception.dart';
import 'auth_service.dart';

class FolderService {
  final AuthService _authService = AuthService();
  static const String _baseUrl = AppConfig.baseUrl;

  Map<String, String> _getHeaders() {
    final token = _authService.authToken;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Create a new folder
  Future<FolderItem> createFolder(FolderCreate folderCreate) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/folders/create');

      final body = json.encode(folderCreate.toJson());
      print(
          '🗂️ Creating folder: ${folderCreate.name} at ${folderCreate.parentPath}');
      print('🗂️ Request body: $body');

      final response = await http.post(uri, headers: headers, body: body);

      print('🗂️ Response status: ${response.statusCode}');
      print('🗂️ Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('🗂️ Parsed data: $data');
        return FolderItem.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ApiException(
          errorData['detail'] ?? 'Folder already exists or invalid name',
        );
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to create folder: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('🗂️ Error creating folder: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Browse folder contents
  Future<FolderContentsResponse> browseFolderContents({
    String folderPath = '/',
  }) async {
    try {
      print('🗂️ Browsing folder: $folderPath');
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/folders/browse').replace(
        queryParameters: {'folder_path': folderPath},
      );

      print('🗂️ Browse URL: $uri');
      final response = await http.get(uri, headers: headers);

      print('🗂️ Browse response status: ${response.statusCode}');
      print('🗂️ Browse response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🗂️ Parsed browse data: $data');
        return FolderContentsResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 404) {
        throw ApiException('Folder not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to browse folder: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('🗂️ Error browsing folder: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Delete a folder
  Future<Map<String, dynamic>> deleteFolder({
    required String folderPath,
    bool recursive = false,
  }) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/folders/delete').replace(
        queryParameters: {
          'folder_path': folderPath,
          'recursive': recursive.toString(),
        },
      );

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ApiException(
          errorData['detail'] ?? 'Folder not empty. Use recursive delete.',
        );
      } else if (response.statusCode == 404) {
        throw ApiException('Folder not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to delete folder: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Move a folder
  Future<FolderItem> moveFolder({
    required String sourcePath,
    required String destinationPath,
  }) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/folders/move').replace(
        queryParameters: {
          'source_path': sourcePath,
          'destination_path': destinationPath,
        },
      );

      final response = await http.put(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FolderItem.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ApiException(
          errorData['detail'] ?? 'Invalid move operation',
        );
      } else if (response.statusCode == 404) {
        throw ApiException('Source folder not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to move folder: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }
}
