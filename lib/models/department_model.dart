class Department {
  final int id;
  final int collegeId;
  final String code;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Department({
    required this.id,
    required this.collegeId,
    required this.code,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      collegeId: json['college_id'],
      code: json['code'],
      name: json['name'],
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'college_id': collegeId,
      'code': code,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getter for display in dropdowns
  String get displayName => '$code - $name';
}

class DepartmentStats extends Department {
  final int studentCount;
  final int staffCount;
  final int fileCount;
  final int postCount;

  DepartmentStats({
    required super.id,
    required super.collegeId,
    required super.code,
    required super.name,
    required super.description,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required this.studentCount,
    required this.staffCount,
    required this.fileCount,
    required this.postCount,
  });

  factory DepartmentStats.fromJson(Map<String, dynamic> json) {
    return DepartmentStats(
      id: json['id'],
      collegeId: json['college_id'],
      code: json['code'],
      name: json['name'],
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      studentCount: json['student_count'] ?? 0,
      staffCount: json['staff_count'] ?? 0,
      fileCount: json['file_count'] ?? 0,
      postCount: json['post_count'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'student_count': studentCount,
      'staff_count': staffCount,
      'file_count': fileCount,
      'post_count': postCount,
    });
    return json;
  }

  // Total count for quick stats
  int get totalCount => studentCount + staffCount;
}
