class Reward {
  final int id;
  final int receiverId;
  final int giverId;
  final int collegeId;
  final int points;
  final String rewardType;
  final String title;
  final String? description;
  final int? postId;
  final DateTime createdAt;
  final String giverName;
  final String receiverName;
  final String giverDepartment;
  final String receiverDepartment;
  final String? postTitle;

  Reward({
    required this.id,
    required this.receiverId,
    required this.giverId,
    required this.collegeId,
    required this.points,
    required this.rewardType,
    required this.title,
    this.description,
    this.postId,
    required this.createdAt,
    required this.giverName,
    required this.receiverName,
    required this.giverDepartment,
    required this.receiverDepartment,
    this.postTitle,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      receiverId: json['receiver_id'],
      giverId: json['giver_id'],
      collegeId: json['college_id'],
      points: json['points'],
      rewardType: json['reward_type'],
      title: json['title'],
      description: json['description'],
      postId: json['post_id'],
      createdAt: DateTime.parse(json['created_at']),
      giverName: json['giver_name'],
      receiverName: json['receiver_name'],
      giverDepartment: json['giver_department'],
      receiverDepartment: json['receiver_department'],
      postTitle: json['post_title'],
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get rewardTypeDisplayName {
    switch (rewardType) {
      case 'HELPFUL_POST':
        return 'Helpful Post';
      case 'ACADEMIC_EXCELLENCE':
        return 'Academic Excellence';
      case 'COMMUNITY_PARTICIPATION':
        return 'Community Participation';
      case 'PEER_RECOGNITION':
        return 'Peer Recognition';
      case 'EVENT_PARTICIPATION':
        return 'Event Participation';
      case 'MENTORSHIP':
        return 'Mentorship';
      case 'LEADERSHIP':
        return 'Leadership';
      default:
        return 'Other';
    }
  }
}

class RewardSummary {
  final int totalPoints;
  final int rewardsGiven;
  final int rewardsReceived;
  final List<Reward> recentRewards;

  RewardSummary({
    required this.totalPoints,
    required this.rewardsGiven,
    required this.rewardsReceived,
    required this.recentRewards,
  });

  factory RewardSummary.fromJson(Map<String, dynamic> json) {
    return RewardSummary(
      totalPoints: json['total_points'],
      rewardsGiven: json['rewards_given'],
      rewardsReceived: json['rewards_received'],
      recentRewards: (json['recent_rewards'] as List)
          .map((reward) => Reward.fromJson(reward))
          .toList(),
    );
  }
}

class RewardLeaderboard {
  final int userId;
  final String userName;
  final String department;
  final int totalPoints;
  final int rank;

  RewardLeaderboard({
    required this.userId,
    required this.userName,
    required this.department,
    required this.totalPoints,
    required this.rank,
  });

  factory RewardLeaderboard.fromJson(Map<String, dynamic> json) {
    return RewardLeaderboard(
      userId: json['user_id'],
      userName: json['user_name'],
      department: json['department'],
      totalPoints: json['total_points'],
      rank: json['rank'],
    );
  }

  String get initials {
    final names = userName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }
}

class RewardPoints {
  final int id;
  final int userId;
  final int totalPoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userName;
  final String userDepartment;

  RewardPoints({
    required this.id,
    required this.userId,
    required this.totalPoints,
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
    required this.userDepartment,
  });

  factory RewardPoints.fromJson(Map<String, dynamic> json) {
    return RewardPoints(
      id: json['id'],
      userId: json['user_id'],
      totalPoints: json['total_points'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user_name'],
      userDepartment: json['user_department'],
    );
  }
}
