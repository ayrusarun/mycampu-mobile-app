class User {
  final String id;
  final String email;
  final String? name;
  final String? tenantId;
  final List<String> roles;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.tenantId,
    this.roles = const [],
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['sub'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ??
          json['display_name'] ??
          json['preferred_username']?.split('@')[0],
      tenantId: json['tenant_id'],
      roles: List<String>.from(json['roles'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  factory User.fromJWT(Map<String, dynamic> payload) {
    return User(
      id: payload['sub'] ?? '',
      email: payload['email'] ?? payload['preferred_username'] ?? '',
      name: payload['name'] ?? payload['preferred_username']?.split('@')[0],
      tenantId: payload['tenant_id'],
      roles: _extractRoles(payload),
      createdAt: null, // JWT doesn't typically contain creation date
    );
  }

  static List<String> _extractRoles(Map<String, dynamic> payload) {
    final resourceAccess = payload['resource_access'];
    if (resourceAccess is Map && resourceAccess['mycampus'] is Map) {
      final roles = resourceAccess['mycampus']['roles'];
      if (roles is List) {
        return List<String>.from(roles);
      }
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'tenant_id': tenantId,
      'roles': roles,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get displayName => name ?? email.split('@')[0];
  String get initials =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
}

class UserProfile {
  // Core user info from API
  final int id;
  final String username;
  final String email;
  final String fullName;
  final int? departmentId;
  final String? departmentName;

  // NEW: Academic fields (denormalized from academic tables)
  final int? admissionYear;
  final int? programId;
  final String? programName;
  final String? programCode;
  final int? cohortId;
  final String? cohortName;
  final String? cohortCode;
  final int? classId;
  final String? classSection;

  final int collegeId;
  final String collegeName;
  final String collegeSlug;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> permissions;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.departmentId,
    this.departmentName,
    // Academic fields
    this.admissionYear,
    this.programId,
    this.programName,
    this.programCode,
    this.cohortId,
    this.cohortName,
    this.cohortCode,
    this.classId,
    this.classSection,
    required this.collegeId,
    required this.collegeName,
    required this.collegeSlug,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.permissions = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      // NEW: Academic fields
      admissionYear: json['admission_year'],
      programId: json['program_id'],
      programName: json['program_name'],
      programCode: json['program_code'],
      cohortId: json['cohort_id'],
      cohortName: json['cohort_name'],
      cohortCode: json['cohort_code'],
      classId: json['class_id'],
      classSection: json['class_section'],
      collegeId: json['college_id'],
      collegeName: json['college_name'],
      collegeSlug: json['college_slug'],
      role: json['role'] ?? 'student',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'department_id': departmentId,
      'department_name': departmentName,
      // Academic fields
      'admission_year': admissionYear,
      'program_id': programId,
      'program_name': programName,
      'program_code': programCode,
      'cohort_id': cohortId,
      'cohort_name': cohortName,
      'cohort_code': cohortCode,
      'class_id': classId,
      'class_section': classSection,
      'college_id': collegeId,
      'college_name': collegeName,
      'college_slug': collegeSlug,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'permissions': permissions,
    };
  }

  // Helper getters
  String get displayName => fullName;
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }

  // Calculate year of study based on cohort year
  int? get yearOfStudy {
    if (cohortCode == null) return null;

    try {
      final cohortYear = int.tryParse(cohortCode!);
      if (cohortYear == null) return null;

      final currentYear = DateTime.now().year;
      final yearsSinceJoining = currentYear - cohortYear;

      // Adjust for academic year (if before July, still in previous academic year)
      final adjustedYears =
          DateTime.now().month < 7 ? yearsSinceJoining : yearsSinceJoining + 1;

      return adjustedYears > 0 ? adjustedYears : 1;
    } catch (e) {
      return null;
    }
  }

  // Get formatted year of study text
  String? get yearOfStudyText {
    final year = yearOfStudy;
    if (year == null) return null;

    switch (year) {
      case 1:
        return '1st Year';
      case 2:
        return '2nd Year';
      case 3:
        return '3rd Year';
      case 4:
        return '4th Year';
      case 5:
        return '5th Year';
      default:
        return '${year}th Year';
    }
  }

  // Get complete academic info text
  String get academicInfoText {
    final parts = <String>[];

    if (yearOfStudyText != null) {
      parts.add(yearOfStudyText!);
    }

    if (programCode != null && classSection != null) {
      // Format: BTECH-CS-2025 - B
      final programWithYear =
          admissionYear != null ? '$programCode-$admissionYear' : programCode!;
      parts.add('$programWithYear - $classSection');
    } else if (programCode != null) {
      // Format: BTECH-CS-2025
      final programWithYear =
          admissionYear != null ? '$programCode-$admissionYear' : programCode!;
      parts.add(programWithYear);
    } else if (classSection != null) {
      parts.add('Section $classSection');
    }

    if (parts.isEmpty && departmentName != null) {
      return departmentName!;
    }

    return parts.isEmpty ? 'Student' : parts.join(', ');
  }

  // Permission helper methods
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool canRead(String resource) {
    return hasPermission('read:$resource');
  }

  bool canWrite(String resource) {
    return hasPermission('write:$resource');
  }

  bool canDelete(String resource) {
    return hasPermission('delete:$resource');
  }

  bool canUpdate(String resource) {
    return hasPermission('update:$resource');
  }
}

// Academic Info class for /auth/me endpoint response
class AcademicInfo {
  final int? admissionYear;
  final int? programId;
  final String? programName;
  final String? programCode;
  final int? cohortId;
  final String? cohortName;
  final String? cohortCode;
  final int? classId;
  final String? classSection;
  final int? yearOfStudy;

  AcademicInfo({
    this.admissionYear,
    this.programId,
    this.programName,
    this.programCode,
    this.cohortId,
    this.cohortName,
    this.cohortCode,
    this.classId,
    this.classSection,
    this.yearOfStudy,
  });

  factory AcademicInfo.fromJson(Map<String, dynamic> json) {
    return AcademicInfo(
      admissionYear: json['admission_year'],
      programId: json['program_id'],
      programName: json['program_name'],
      programCode: json['program_code'],
      cohortId: json['cohort_id'],
      cohortName: json['cohort_name'],
      cohortCode: json['cohort_code'],
      classId: json['class_id'],
      classSection: json['class_section'],
      yearOfStudy: json['year_of_study'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admission_year': admissionYear,
      'program_id': programId,
      'program_name': programName,
      'program_code': programCode,
      'cohort_id': cohortId,
      'cohort_name': cohortName,
      'cohort_code': cohortCode,
      'class_id': classId,
      'class_section': classSection,
      'year_of_study': yearOfStudy,
    };
  }

  String get displayText {
    final parts = <String>[];

    if (yearOfStudy != null) {
      final yearText = _getYearText(yearOfStudy!);
      parts.add(yearText);
    }

    if (programCode != null && classSection != null) {
      parts.add('$programCode - Section $classSection');
    } else if (programCode != null) {
      parts.add(programCode!);
    } else if (classSection != null) {
      parts.add('Section $classSection');
    }

    return parts.isEmpty ? 'Student' : parts.join(', ');
  }

  String _getYearText(int year) {
    switch (year) {
      case 1:
        return '1st Year';
      case 2:
        return '2nd Year';
      case 3:
        return '3rd Year';
      case 4:
        return '4th Year';
      case 5:
        return '5th Year';
      default:
        return '${year}th Year';
    }
  }
}
