class Cohort {
  final int id;
  final int programId;
  final String name;
  final String code;
  final int admissionYear;
  final int totalStudents;
  final DateTime createdAt;

  Cohort({
    required this.id,
    required this.programId,
    required this.name,
    required this.code,
    required this.admissionYear,
    required this.totalStudents,
    required this.createdAt,
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      id: json['id'] as int,
      programId: json['program_id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      admissionYear: json['admission_year'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'program_id': programId,
      'name': name,
      'code': code,
      'admission_year': admissionYear,
      'total_students': totalStudents,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For creating new cohort
  Map<String, dynamic> toCreateJson() {
    return {
      'program_id': programId,
      'name': name,
      'code': code,
      'admission_year': admissionYear,
    };
  }

  String get displayName => '$name ($code)';
}
