import 'package:flutter/material.dart';
import '../services/reward_service.dart';
import '../models/reward_model.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  final RewardService _rewardService = RewardService();
  late TabController _tabController;

  RewardSummary? _summary;
  List<RewardLeaderboard> _leaderboard = [];

  bool _isLoadingSummary = false;
  bool _isLoadingLeaderboard = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSummary(),
      _loadLeaderboard(),
    ]);
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _errorMessage = null;
    });

    try {
      final summary = await _rewardService.getMyRewards();
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load reward summary: $e';
      });
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoadingLeaderboard = true;
    });

    try {
      final leaderboard = await _rewardService.getLeaderboard();
      setState(() {
        _leaderboard = leaderboard;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
    } finally {
      setState(() {
        _isLoadingLeaderboard = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Summary Cards
              if (!_isLoadingSummary && _summary != null) _buildSummaryCards(),

              // Tab Bar
              _buildTabBar(),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardTab(),
                    _buildOverviewTab(),
                    _buildRewardsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGiveRewardDialog,
        backgroundColor: Colors.amber.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emoji_events),
        label: const Text('Give Reward'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events,
              color: Colors.amber.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rewards',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Your achievements and recognition',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Points',
                  _summary!.totalPoints.toString(),
                  Icons.stars,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Received',
                  _summary!.rewardsReceived.toString(),
                  Icons.card_giftcard,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Given',
                  _summary!.rewardsGiven.toString(),
                  Icons.volunteer_activism,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildRedeemButton(),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color[700],
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed('/marketplace');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade600,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.purple.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.shopping_bag, size: 24),
          label: Text(
            'Redeem Points - Visit Marketplace',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Leaderboard'),
          Tab(text: 'Overview'),
          Tab(text: 'My Rewards'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingSummary) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSummary,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_summary == null) {
      return const Center(child: Text('No data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Recent Rewards Section
        const Text(
          'Recent Rewards',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        if (_summary!.recentRewards.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent rewards',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          ...(_summary!.recentRewards.take(5).map(
                (reward) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRewardCard(reward),
                ),
              )),
      ],
    );
  }

  Widget _buildRewardsTab() {
    if (_isLoadingSummary) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_summary?.recentRewards.isEmpty ?? true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No rewards yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your rewards will appear here',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _summary!.recentRewards.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRewardCard(_summary!.recentRewards[index]),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLoadingLeaderboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No leaderboard data',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final entry = _leaderboard[index];
        return _buildLeaderboardCard(entry, index);
      },
    );
  }

  Widget _buildRewardCard(Reward reward) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events,
              color: Colors.amber.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reward.giverName} → ${reward.receiverName}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reward.rewardTypeDisplayName,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      reward.timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${reward.points}',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(RewardLeaderboard entry, int index) {
    Color? rankColor;
    IconData? rankIcon;

    if (entry.rank == 1) {
      rankColor = Colors.amber.shade700;
      rankIcon = Icons.emoji_events;
    } else if (entry.rank == 2) {
      rankColor = Colors.grey.shade600;
      rankIcon = Icons.workspace_premium;
    } else if (entry.rank == 3) {
      rankColor = Colors.brown.shade600;
      rankIcon = Icons.workspace_premium;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: entry.rank <= 3
            ? Border.all(
                color: rankColor!.withOpacity(0.3),
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor?.withOpacity(0.1) ?? Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 20)
                  : Text(
                      '${entry.rank}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor ?? Colors.grey.shade600,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // User Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  entry.department,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.totalPoints}',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGiveRewardDialog() async {
    // Load reward types and users
    List<String> rewardTypes = [];
    List<Map<String, dynamic>> users = [];

    try {
      final results = await Future.wait([
        _rewardService.getRewardTypes(),
        _rewardService.getUsers(),
      ]);

      rewardTypes = results[0] as List<String>;
      users = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController(text: '10');

    String selectedRewardType =
        rewardTypes.isNotEmpty ? rewardTypes.first : 'OTHER';
    Map<String, dynamic>? selectedUser;
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Give Reward'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Select User
                const Text(
                  'Select User',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: selectedUser,
                      hint: const Text('Choose a user'),
                      isExpanded: true,
                      items: users.map((user) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: user,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    _getUserInitials(
                                        user['full_name'] ?? 'User'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['full_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      user['department'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (user) {
                        setDialogState(() {
                          selectedUser = user;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reward Type
                const Text(
                  'Reward Type',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRewardType,
                      isExpanded: true,
                      items: rewardTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(_getRewardTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (type) {
                        setDialogState(() {
                          selectedRewardType = type!;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Points
                const Text(
                  'Points',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter points (1-100)',
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                const Text(
                  'Title',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Reward title',
                  ),
                ),

                const SizedBox(height: 16),

                // Description (optional)
                const Text(
                  'Description (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Additional details...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (selectedUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a user')),
                        );
                        return;
                      }

                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title')),
                        );
                        return;
                      }

                      final points = int.tryParse(pointsController.text);
                      if (points == null || points <= 0 || points > 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please enter valid points (1-100)')),
                        );
                        return;
                      }

                      setDialogState(() {
                        isCreating = true;
                      });

                      try {
                        await _rewardService.createReward(
                          receiverId: selectedUser!['id'],
                          points: points,
                          rewardType: selectedRewardType,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reward given successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Refresh data
                          _loadData();
                        }
                      } catch (e) {
                        setDialogState(() {
                          isCreating = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to give reward: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Give Reward'),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserInitials(String fullName) {
    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  String _getRewardTypeDisplayName(String rewardType) {
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
