class Group {
  final int id;
  final String name;
  final String groupType;
  final String? description;
  final String? logo;
  final String? bannerUrl;
  final bool isOpen;
  final bool requiresApproval;
  final int collegeId;
  final Map<String, dynamic> groupMetadata;
  final List<String> allowedPostRoles;
  final int? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int? memberCount;
  final String? myRole;
  final bool? canPost;
  final List<String>? availableContexts;

  Group({
    required this.id,
    required this.name,
    required this.groupType,
    this.description,
    this.logo,
    this.bannerUrl,
    this.isOpen = true,
    this.requiresApproval = false,
    required this.collegeId,
    this.groupMetadata = const {},
    this.allowedPostRoles = const [],
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.memberCount,
    this.myRole,
    this.canPost,
    this.availableContexts,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      groupType: json['group_type'],
      description: json['description'],
      logo: json['logo'],
      bannerUrl: json['banner_url'],
      isOpen: json['is_open'] ?? true,
      requiresApproval: json['requires_approval'] ?? false,
      collegeId: json['college_id'],
      groupMetadata: Map<String, dynamic>.from(json['group_metadata'] ?? {}),
      allowedPostRoles: List<String>.from(json['allowed_post_roles'] ?? []),
      createdById: json['created_by_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'],
      memberCount: json['member_count'],
      myRole: json['my_role'],
      canPost: json['can_post'],
      availableContexts: json['available_contexts'] != null
          ? List<String>.from(json['available_contexts'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group_type': groupType,
      'description': description,
      'logo': logo,
      'banner_url': bannerUrl,
      'is_open': isOpen,
      'requires_approval': requiresApproval,
      'college_id': collegeId,
      'group_metadata': groupMetadata,
      'allowed_post_roles': allowedPostRoles,
      'created_by_id': createdById,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'member_count': memberCount,
      'my_role': myRole,
      'can_post': canPost,
      'available_contexts': availableContexts,
    };
  }
}

class UserGroupsResponse {
  final int userId;
  final List<Group> groups;
  final int totalGroups;

  UserGroupsResponse({
    required this.userId,
    required this.groups,
    required this.totalGroups,
  });

  factory UserGroupsResponse.fromJson(Map<String, dynamic> json) {
    return UserGroupsResponse(
      userId: json['user_id'],
      groups: (json['groups'] as List).map((g) => Group.fromJson(g)).toList(),
      totalGroups: json['total_groups'],
    );
  }
}
