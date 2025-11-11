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
  final String department;
  final String className;
  final String academicYear;
  final int collegeId;
  final String collegeName;
  final String collegeSlug;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.department,
    required this.className,
    required this.academicYear,
    required this.collegeId,
    required this.collegeName,
    required this.collegeSlug,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      department: json['department'],
      className: json['class_name'],
      academicYear: json['academic_year'],
      collegeId: json['college_id'],
      collegeName: json['college_name'],
      collegeSlug: json['college_slug'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'department': department,
      'class_name': className,
      'academic_year': academicYear,
      'college_id': collegeId,
      'college_name': collegeName,
      'college_slug': collegeSlug,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
}
