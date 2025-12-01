class ClassSection {
  final int id;
  final int cohortId;
  final String section;
  final int totalStudents;
  final DateTime createdAt;

  ClassSection({
    required this.id,
    required this.cohortId,
    required this.section,
    required this.totalStudents,
    required this.createdAt,
  });

  factory ClassSection.fromJson(Map<String, dynamic> json) {
    // Try section_code first, then section_name, then fall back to section
    String sectionValue = (json['section_code'] as String?) ??
        (json['section_name'] as String?) ??
        (json['section'] as String?) ??
        '';

    return ClassSection(
      id: json['id'] as int,
      cohortId: json['cohort_id'] as int? ?? 0,
      section: sectionValue,
      totalStudents: json['total_students'] as int? ??
          json['current_strength'] as int? ??
          0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cohort_id': cohortId,
      'section': section,
      'total_students': totalStudents,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For creating new class
  Map<String, dynamic> toCreateJson() {
    return {
      'cohort_id': cohortId,
      'section': section,
    };
  }

  String get displayName => section.isEmpty ? 'Unknown Section' : section;
}
