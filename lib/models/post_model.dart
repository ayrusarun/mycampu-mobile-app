class Post {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String postType;
  final int authorId;
  final int collegeId;

  // DEPRECATED: Old department targeting (keeping for backward compatibility)
  final int? targetDepartmentId;
  final String? targetDepartmentCode;
  final String? targetDepartmentName;

  // NEW: Academic targeting
  final int? targetProgramId;
  final int? targetCohortId;
  final int? targetClassId;

  // NEW: Denormalized academic targeting display names
  final String? targetProgramName;
  final String? targetProgramCode;
  final String? targetCohortName;
  final String? targetCohortCode;
  final String? targetClassSection;
  final int? targetAdmissionYear;

  final Map<String, dynamic> postMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorName;
  final String authorDepartment;
  final String timeAgo;
  final int likeCount;
  final int commentCount;
  final int igniteCount;
  final bool userHasLiked;
  final bool userHasIgnited;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.postType,
    required this.authorId,
    required this.collegeId,
    // Old targeting (deprecated)
    this.targetDepartmentId,
    this.targetDepartmentCode,
    this.targetDepartmentName,
    // New academic targeting
    this.targetProgramId,
    this.targetCohortId,
    this.targetClassId,
    this.targetProgramName,
    this.targetProgramCode,
    this.targetCohortName,
    this.targetCohortCode,
    this.targetClassSection,
    this.targetAdmissionYear,
    required this.postMetadata,
    required this.createdAt,
    required this.updatedAt,
    required this.authorName,
    required this.authorDepartment,
    required this.timeAgo,
    this.likeCount = 0,
    this.commentCount = 0,
    this.igniteCount = 0,
    this.userHasLiked = false,
    this.userHasIgnited = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image_url'],
      postType: json['post_type'] ?? 'GENERAL',
      authorId: json['author_id'],
      collegeId: json['college_id'],
      // Old targeting (deprecated but maintained for backward compatibility)
      targetDepartmentId: json['target_department_id'],
      targetDepartmentCode: json['target_department_code'],
      targetDepartmentName: json['target_department_name'],
      // New academic targeting
      targetProgramId: json['target_program_id'],
      targetCohortId: json['target_cohort_id'],
      targetClassId: json['target_class_id'],
      targetProgramName: json['target_program_name'],
      targetProgramCode: json['target_program_code'],
      targetCohortName: json['target_cohort_name'],
      targetCohortCode: json['target_cohort_code'],
      targetClassSection: json['target_class_section'],
      targetAdmissionYear: json['target_admission_year'],
      postMetadata: Map<String, dynamic>.from(json['post_metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorName: json['author_name'],
      authorDepartment: json['author_department'],
      timeAgo: json['time_ago'],
      // Use top-level engagement fields (post_metadata will be deprecated)
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      igniteCount: json['ignite_count'] ?? 0,
      userHasLiked: json['user_has_liked'] ?? false,
      userHasIgnited: json['user_has_ignited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'post_type': postType,
      'author_id': authorId,
      'college_id': collegeId,
      // Old targeting
      'target_department_id': targetDepartmentId,
      'target_department_code': targetDepartmentCode,
      'target_department_name': targetDepartmentName,
      // New academic targeting
      'target_program_id': targetProgramId,
      'target_cohort_id': targetCohortId,
      'target_class_id': targetClassId,
      'target_program_name': targetProgramName,
      'target_program_code': targetProgramCode,
      'target_cohort_name': targetCohortName,
      'target_cohort_code': targetCohortCode,
      'target_class_section': targetClassSection,
      'target_admission_year': targetAdmissionYear,
      'post_metadata': postMetadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'author_name': authorName,
      'author_department': authorDepartment,
      'time_ago': timeAgo,
      'like_count': likeCount,
      'comment_count': commentCount,
      'ignite_count': igniteCount,
      'user_has_liked': userHasLiked,
      'user_has_ignited': userHasIgnited,
    };
  }

  // Helper getters for metadata
  int get likes => postMetadata['likes'] ?? 0;
  int get comments => postMetadata['comments'] ?? 0;
  int get shares => postMetadata['shares'] ?? 0;

  // Get initials from author name
  String get authorInitials {
    final parts = authorName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A';
  }

  // Get target audience text for display
  String get targetAudienceText {
    // If class is targeted, show most specific targeting
    if (targetClassSection != null) {
      final program = targetProgramCode ?? targetProgramName ?? '';
      final cohort = targetCohortCode ?? targetCohortName ?? '';
      return 'For: $program $cohort - Section $targetClassSection';
    }

    // If cohort is targeted
    if (targetCohortName != null) {
      final program = targetProgramCode ?? targetProgramName ?? '';
      return 'For: $program ${targetCohortName}';
    }

    // If program is targeted
    if (targetProgramName != null) {
      return 'For: $targetProgramName';
    }

    // Backward compatibility: department targeting
    if (targetDepartmentName != null) {
      return 'For: $targetDepartmentName';
    }

    // No targeting - visible to everyone
    return 'For: Everyone';
  }

  // Check if post has academic targeting
  bool get hasAcademicTargeting {
    return targetProgramId != null ||
        targetCohortId != null ||
        targetClassId != null;
  }

  // Check if post has any targeting (including legacy)
  bool get hasTargeting {
    return hasAcademicTargeting || targetDepartmentId != null;
  }
}
