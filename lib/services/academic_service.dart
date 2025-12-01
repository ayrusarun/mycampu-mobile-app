import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/academic_year_model.dart';
import '../models/program_model.dart';
import '../models/cohort_model.dart';
import '../models/class_model.dart';
import '../models/class_teacher_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AcademicService {
  final AuthService _authService = AuthService();

  // ===== ACADEMIC YEARS =====

  /// Get all academic years
  Future<List<AcademicYear>> getAcademicYears() async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/academic/years'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AcademicYear.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load academic years: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading academic years: $e');
      rethrow;
    }
  }

  /// Get academic year by ID
  Future<AcademicYear?> getAcademicYear(int yearId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/academic/years/$yearId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        return AcademicYear.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load academic year: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading academic year: $e');
      rethrow;
    }
  }

  /// Create new academic year
  Future<AcademicYear?> createAcademicYear({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool isCurrent = false,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/academic/years'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'is_current': isCurrent,
        }),
      );

      if (response.statusCode == 200) {
        return AcademicYear.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to create academic year: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating academic year: $e');
      rethrow;
    }
  }

  /// Update academic year
  Future<AcademicYear?> updateAcademicYear(
    int yearId, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (startDate != null) {
        body['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        body['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (isCurrent != null) body['is_current'] = isCurrent;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/academic/years/$yearId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return AcademicYear.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to update academic year: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating academic year: $e');
      rethrow;
    }
  }

  /// Delete academic year
  Future<bool> deleteAcademicYear(int yearId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/academic/years/$yearId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting academic year: $e');
      return false;
    }
  }

  // ===== PROGRAMS =====

  /// Get all programs (optionally filtered by department)
  Future<List<Program>> getPrograms({int? departmentId}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      String url = '${AppConfig.baseUrl}/academic/programs';
      final queryParams = <String, String>{};

      if (departmentId != null) {
        queryParams['department_id'] = departmentId.toString();
      }

      if (queryParams.isNotEmpty) {
        url += '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      print('📚 Fetching programs from: $url');
      print('📚 Department filter: $departmentId');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('📚 Loaded ${jsonList.length} programs');
        return jsonList.map((json) => Program.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load programs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading programs: $e');
      rethrow;
    }
  }

  /// Get program by ID
  Future<Program?> getProgram(int programId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/academic/programs/$programId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        return Program.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load program: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading program: $e');
      rethrow;
    }
  }

  /// Create new program
  Future<Program?> createProgram({
    required String name,
    required String code,
    required int durationYears,
    String? description,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/academic/programs'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'code': code,
          'duration_years': durationYears,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return Program.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create program: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating program: $e');
      rethrow;
    }
  }

  /// Update program
  Future<Program?> updateProgram(
    int programId, {
    String? name,
    String? code,
    int? durationYears,
    String? description,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (code != null) body['code'] = code;
      if (durationYears != null) body['duration_years'] = durationYears;
      if (description != null) body['description'] = description;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/academic/programs/$programId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return Program.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update program: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating program: $e');
      rethrow;
    }
  }

  /// Delete program
  Future<bool> deleteProgram(int programId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/academic/programs/$programId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting program: $e');
      return false;
    }
  }

  // ===== COHORTS =====

  /// Get all cohorts (optionally filtered by program)
  Future<List<Cohort>> getCohorts({int? programId}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      String url = '${AppConfig.baseUrl}/academic/cohorts';
      if (programId != null) {
        url += '?program_id=$programId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Cohort.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cohorts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading cohorts: $e');
      rethrow;
    }
  }

  /// Get cohort by ID
  Future<Cohort?> getCohort(int cohortId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/academic/cohorts/$cohortId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        return Cohort.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load cohort: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading cohort: $e');
      rethrow;
    }
  }

  /// Create new cohort
  Future<Cohort?> createCohort({
    required int programId,
    required String name,
    required String code,
    required int year,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/academic/cohorts'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'program_id': programId,
          'name': name,
          'code': code,
          'year': year,
        }),
      );

      if (response.statusCode == 200) {
        return Cohort.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create cohort: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating cohort: $e');
      rethrow;
    }
  }

  /// Update cohort
  Future<Cohort?> updateCohort(
    int cohortId, {
    int? programId,
    String? name,
    String? code,
    int? year,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> body = {};
      if (programId != null) body['program_id'] = programId;
      if (name != null) body['name'] = name;
      if (code != null) body['code'] = code;
      if (year != null) body['year'] = year;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/academic/cohorts/$cohortId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return Cohort.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update cohort: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating cohort: $e');
      rethrow;
    }
  }

  /// Delete cohort
  Future<bool> deleteCohort(int cohortId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/academic/cohorts/$cohortId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting cohort: $e');
      return false;
    }
  }

  // ===== CLASSES =====

  /// Get all classes (optionally filtered by cohort)
  Future<List<ClassSection>> getClasses({int? cohortId}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      String url = '${AppConfig.baseUrl}/academic/classes';
      if (cohortId != null) {
        url += '?cohort_id=$cohortId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('📚 Classes API response: $jsonList');
        final classes =
            jsonList.map((json) => ClassSection.fromJson(json)).toList();
        print(
            '📚 Parsed classes: ${classes.map((c) => 'ID: ${c.id}, Section: "${c.section}", Display: "${c.displayName}"').toList()}');
        return classes;
      } else {
        throw Exception('Failed to load classes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading classes: $e');
      rethrow;
    }
  }

  /// Get class by ID
  Future<ClassSection?> getClass(int classId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/academic/classes/$classId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        return ClassSection.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load class: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading class: $e');
      rethrow;
    }
  }

  /// Create new class
  Future<ClassSection?> createClass({
    required int cohortId,
    required String section,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/academic/classes'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cohort_id': cohortId,
          'section': section,
        }),
      );

      if (response.statusCode == 200) {
        return ClassSection.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create class: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating class: $e');
      rethrow;
    }
  }

  /// Update class
  Future<ClassSection?> updateClass(
    int classId, {
    int? cohortId,
    String? section,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> body = {};
      if (cohortId != null) body['cohort_id'] = cohortId;
      if (section != null) body['section'] = section;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/academic/classes/$classId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return ClassSection.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update class: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating class: $e');
      rethrow;
    }
  }

  /// Delete class
  Future<bool> deleteClass(int classId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/academic/classes/$classId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting class: $e');
      return false;
    }
  }

  /// Get students in a class
  Future<List<UserProfile>> getClassStudents(int classId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/academic/classes/$classId/students'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => UserProfile.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load class students: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading class students: $e');
      rethrow;
    }
  }

  // ===== CLASS TEACHERS =====

  /// Get teachers for a class
  Future<List<ClassTeacher>> getClassTeachers(int classId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/academic/classes/$classId/teachers'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ClassTeacher.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load class teachers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading class teachers: $e');
      rethrow;
    }
  }

  /// Assign teacher to class
  Future<ClassTeacher?> assignTeacherToClass({
    required int classId,
    required int teacherId,
    String? subject,
    bool isClassTeacher = false,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/academic/classes/$classId/teachers'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'teacher_id': teacherId,
          'subject': subject,
          'is_class_teacher': isClassTeacher,
        }),
      );

      if (response.statusCode == 200) {
        return ClassTeacher.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to assign teacher: ${response.statusCode}');
      }
    } catch (e) {
      print('Error assigning teacher: $e');
      rethrow;
    }
  }

  /// Remove teacher from class
  Future<bool> removeTeacherFromClass(int classId, int teacherId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(
            '${AppConfig.baseUrl}/academic/classes/$classId/teachers/$teacherId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error removing teacher: $e');
      return false;
    }
  }
}
