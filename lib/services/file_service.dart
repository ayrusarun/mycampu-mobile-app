import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/app_config.dart';
import '../models/file_model.dart';
import '../models/api_exception.dart';
import 'auth_service.dart';

class FileService {
  final AuthService _authService = AuthService();
  static const String _baseUrl = AppConfig.baseUrl;

  Map<String, String> _getHeaders() {
    final token = _authService.authToken;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Map<String, String> _getMultipartHeaders() {
    final token = _authService.authToken;
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // Upload a file
  Future<FileUploadResponse?> uploadFile(
    File file, {
    String? description,
    String folderPath = '/',
  }) async {
    try {
      print('📤 Uploading file to folder: $folderPath');
      final headers = _getMultipartHeaders();
      final uri = Uri.parse('$_baseUrl/files/upload');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);

      // Add folder_path
      request.fields['folder_path'] = folderPath;
      print('📤 Upload fields: ${request.fields}');

      // Add description if provided
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 Upload response status: ${response.statusCode}');
      print('📤 Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return FileUploadResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to upload file: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get files with pagination and filters
  Future<FileListResponse> getFiles({
    int page = 1,
    int pageSize = 20,
    String? department,
    String? fileType,
    String? search,
    String? folderPath,
  }) async {
    try {
      final headers = _getHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }
      if (fileType != null && fileType.isNotEmpty) {
        queryParams['file_type'] = fileType;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (folderPath != null && folderPath.isNotEmpty) {
        queryParams['folder_path'] = folderPath;
      }

      final uri = Uri.parse('$_baseUrl/files/').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FileListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to fetch files: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get file by ID
  Future<FileModel?> getFileById(int fileId) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/$fileId');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FileModel.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to fetch file: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Download file
  Future<http.Response> downloadFile(int fileId) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/$fileId/download');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 404) {
        throw ApiException('File not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to download file: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Upload image specifically for posts
  Future<String?> uploadPostImage(File file,
      {String folderPath = '/posts'}) async {
    try {
      print('📤 Uploading post image: ${file.path}');
      final headers = _getMultipartHeaders();
      final uri = Uri.parse('$_baseUrl/files/posts/upload-image');
      print('📤 Upload URL: $uri');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);
      print('📤 File added to request: ${multipartFile.filename}');

      // Add folder_path
      request.fields['folder_path'] = folderPath;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 Response status: ${response.statusCode}');
      print('📤 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('📤 Upload response data: $data');
        // Return the public URL for the uploaded image
        final filename = data['filename'];
        final imageUrl = '$_baseUrl/files/posts/image/$filename';
        print('📤 Constructed image URL: $imageUrl');
        return imageUrl;
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to upload post image: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('📤 Upload error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get download URL (deprecated - use downloadFile instead)
  Future<String> getDownloadUrl(int fileId) async {
    try {
      // Use new static file serving endpoint
      return '$_baseUrl/files/$fileId/view';
    } catch (e) {
      throw ApiException('Failed to get view URL: ${e.toString()}');
    }
  }

  // Update file description
  Future<FileModel?> updateFile(int fileId, {String? description}) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/$fileId');

      final body = json.encode({
        'description': description,
      });

      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FileModel.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 404) {
        throw ApiException('File not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to update file: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Delete file
  Future<bool> deleteFile(int fileId) async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/$fileId');

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else if (response.statusCode == 404) {
        throw ApiException('File not found');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to delete file: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get list of departments
  Future<List<String>> getDepartments() async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/departments/list');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['departments'] ?? []);
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
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Get file statistics
  Future<Map<String, dynamic>> getFileStats() async {
    try {
      final headers = _getHeaders();
      final uri = Uri.parse('$_baseUrl/files/stats/summary');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw ApiException('Session expired. Please log in again.');
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          'Failed to fetch file stats: ${errorData['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }
}
