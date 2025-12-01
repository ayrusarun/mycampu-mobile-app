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
  final String className;
  final String academicYear;
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
    required this.className,
    required this.academicYear,
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
      className: json['class_name'],
      academicYear: json['academic_year'],
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
      'class_name': className,
      'academic_year': academicYear,
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
