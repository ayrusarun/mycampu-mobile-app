class Alert {
  final int id;
  final String title;
  final String message;
  final String alertType;
  final DateTime? expiresAt;
  final int? postId;
  final int userId;
  final bool isEnabled;
  final bool isRead;
  final int collegeId;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String creatorName;
  final String? postTitle;
  final String timeAgo;
  final bool isExpired;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.alertType,
    this.expiresAt,
    this.postId,
    required this.userId,
    required this.isEnabled,
    required this.isRead,
    required this.collegeId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.creatorName,
    this.postTitle,
    required this.timeAgo,
    required this.isExpired,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      alertType: json['alert_type'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      postId: json['post_id'],
      userId: json['user_id'],
      isEnabled: json['is_enabled'] == 'true' || json['is_enabled'] == true,
      isRead: json['is_read'] == 'true' || json['is_read'] == true,
      collegeId: json['college_id'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      creatorName: json['creator_name'],
      postTitle: json['post_title'],
      timeAgo: json['time_ago'],
      isExpired: json['is_expired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'alert_type': alertType,
      'expires_at': expiresAt?.toIso8601String(),
      'post_id': postId,
      'user_id': userId,
      'is_enabled': isEnabled.toString(),
      'is_read': isRead.toString(),
      'college_id': collegeId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'creator_name': creatorName,
      'post_title': postTitle,
      'time_ago': timeAgo,
      'is_expired': isExpired,
    };
  }

  Alert copyWith({
    int? id,
    String? title,
    String? message,
    String? alertType,
    DateTime? expiresAt,
    int? postId,
    int? userId,
    bool? isEnabled,
    bool? isRead,
    int? collegeId,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorName,
    String? postTitle,
    String? timeAgo,
    bool? isExpired,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      alertType: alertType ?? this.alertType,
      expiresAt: expiresAt ?? this.expiresAt,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      isEnabled: isEnabled ?? this.isEnabled,
      isRead: isRead ?? this.isRead,
      collegeId: collegeId ?? this.collegeId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorName: creatorName ?? this.creatorName,
      postTitle: postTitle ?? this.postTitle,
      timeAgo: timeAgo ?? this.timeAgo,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

class AlertListResponse {
  final List<Alert> alerts;
  final int totalCount;
  final int unreadCount;
  final int page;
  final int pageSize;

  AlertListResponse({
    required this.alerts,
    required this.totalCount,
    required this.unreadCount,
    required this.page,
    required this.pageSize,
  });

  factory AlertListResponse.fromJson(Map<String, dynamic> json) {
    return AlertListResponse(
      alerts: (json['alerts'] as List)
          .map((alertJson) => Alert.fromJson(alertJson))
          .toList(),
      totalCount: json['total_count'],
      unreadCount: json['unread_count'],
      page: json['page'],
      pageSize: json['page_size'],
    );
  }
}

class AlertCreate {
  final String title;
  final String message;
  final String alertType;
  final DateTime? expiresAt;
  final int? postId;
  final int userId;

  AlertCreate({
    required this.title,
    required this.message,
    this.alertType = 'GENERAL',
    this.expiresAt,
    this.postId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'alert_type': alertType,
      'expires_at': expiresAt?.toIso8601String(),
      'post_id': postId,
      'user_id': userId,
    };
  }
}

class AlertUpdate {
  final String? title;
  final String? message;
  final String? alertType;
  final bool? isEnabled;
  final bool? isRead;
  final DateTime? expiresAt;

  AlertUpdate({
    this.title,
    this.message,
    this.alertType,
    this.isEnabled,
    this.isRead,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (message != null) data['message'] = message;
    if (alertType != null) data['alert_type'] = alertType;
    if (isEnabled != null) data['is_enabled'] = isEnabled.toString();
    if (isRead != null) data['is_read'] = isRead.toString();
    if (expiresAt != null) data['expires_at'] = expiresAt!.toIso8601String();
    return data;
  }
}

// Alert type constants
class AlertType {
  static const String eventNotification = 'EVENT_NOTIFICATION';
  static const String feeReminder = 'FEE_REMINDER';
  static const String announcement = 'ANNOUNCEMENT';
  static const String deadlineReminder = 'DEADLINE_REMINDER';
  static const String academicUpdate = 'ACADEMIC_UPDATE';
  static const String systemNotification = 'SYSTEM_NOTIFICATION';
  static const String general = 'GENERAL';

  static List<String> get all => [
        eventNotification,
        feeReminder,
        announcement,
        deadlineReminder,
        academicUpdate,
        systemNotification,
        general,
      ];

  static String getDisplayName(String type) {
    switch (type) {
      case eventNotification:
        return 'Event Notification';
      case feeReminder:
        return 'Fee Reminder';
      case announcement:
        return 'Announcement';
      case deadlineReminder:
        return 'Deadline Reminder';
      case academicUpdate:
        return 'Academic Update';
      case systemNotification:
        return 'System Notification';
      case general:
        return 'General';
      default:
        return type;
    }
  }
}
