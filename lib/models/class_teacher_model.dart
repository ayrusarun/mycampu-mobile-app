class ClassTeacher {
  final int id;
  final int classId;
  final int teacherId;
  final String? teacherName;
  final String? subject;
  final bool isClassTeacher;
  final DateTime assignedAt;

  ClassTeacher({
    required this.id,
    required this.classId,
    required this.teacherId,
    this.teacherName,
    this.subject,
    required this.isClassTeacher,
    required this.assignedAt,
  });

  factory ClassTeacher.fromJson(Map<String, dynamic> json) {
    return ClassTeacher(
      id: json['id'],
      classId: json['class_id'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      subject: json['subject'],
      isClassTeacher: json['is_class_teacher'] ?? false,
      assignedAt: DateTime.parse(json['assigned_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'subject': subject,
      'is_class_teacher': isClassTeacher,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }

  // For assigning teacher to class
  Map<String, dynamic> toCreateJson() {
    return {
      'teacher_id': teacherId,
      'subject': subject,
      'is_class_teacher': isClassTeacher,
    };
  }

  String get displayName {
    final name = teacherName ?? 'Teacher #$teacherId';
    if (subject != null) {
      return '$name - $subject';
    }
    return name;
  }

  String get roleText => isClassTeacher ? 'Class Teacher' : 'Subject Teacher';
}
