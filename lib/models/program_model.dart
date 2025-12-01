class Program {
  final int id;
  final int? departmentId;
  final String name;
  final String code;
  final int durationYears;
  final String? description;
  final DateTime createdAt;

  Program({
    required this.id,
    this.departmentId,
    required this.name,
    required this.code,
    required this.durationYears,
    this.description,
    required this.createdAt,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as int,
      departmentId: json['department_id'] as int?,
      name: (json['name'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      durationYears: json['duration_years'] as int? ?? 4,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_id': departmentId,
      'name': name,
      'code': code,
      'duration_years': durationYears,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For creating new program
  Map<String, dynamic> toCreateJson() {
    return {
      'department_id': departmentId,
      'name': name,
      'code': code,
      'duration_years': durationYears,
      'description': description,
    };
  }

  String get displayName => '$name ($code)';
}
