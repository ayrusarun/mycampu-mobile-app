class Post {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String postType;
  final int authorId;
  final int collegeId;
  final int? targetDepartmentId;
  final String? targetDepartmentCode;
  final String? targetDepartmentName;
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
    this.targetDepartmentId,
    this.targetDepartmentCode,
    this.targetDepartmentName,
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
      targetDepartmentId: json['target_department_id'],
      targetDepartmentCode: json['target_department_code'],
      targetDepartmentName: json['target_department_name'],
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
      'target_department_id': targetDepartmentId,
      'target_department_code': targetDepartmentCode,
      'target_department_name': targetDepartmentName,
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
}
