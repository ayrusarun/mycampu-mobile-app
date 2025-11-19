import 'package:flutter/material.dart';
import '../services/reward_service.dart';
import '../services/auth_service.dart';
import '../models/reward_model.dart';
import '../config/theme_config.dart';

class RewardsScreen extends StatefulWidget {
  final bool showGiveRewardDialogOnInit;

  const RewardsScreen({super.key, this.showGiveRewardDialogOnInit = false});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  final RewardService _rewardService = RewardService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  RewardSummary? _summary;
  List<RewardLeaderboard> _leaderboard = [];
  int? _poolBalance;

  bool _isLoadingSummary = false;
  bool _isLoadingLeaderboard = false;
  bool _isLoadingPoolBalance = false;
  bool _showPersonalStats = false; // Collapsed by default for admin

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();

    // Show give reward dialog if requested
    if (widget.showGiveRewardDialogOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showGiveRewardDialog();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final futures = [
      _loadSummary(),
      _loadLeaderboard(),
    ];

    // Load pool balance if user is admin
    if (_isAdmin()) {
      futures.add(_loadPoolBalance());
    }

    await Future.wait(futures);
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

  Future<void> _loadPoolBalance() async {
    setState(() {
      _isLoadingPoolBalance = true;
    });

    try {
      final balanceData = await _rewardService.getPoolBalance();
      setState(() {
        _poolBalance = balanceData['available_balance'] ??
            balanceData['total_balance'] ??
            0;
      });
    } catch (e) {
      print('Error loading pool balance: $e');
    } finally {
      setState(() {
        _isLoadingPoolBalance = false;
      });
    }
  }

  bool _isAdmin() {
    final userRoles = _authService.currentUser?.roles ?? [];
    return userRoles.contains('admin');
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium,
            color: Colors.amber.shade600,
            size: 40,
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
    final isAdmin = _isAdmin();

    return Column(
      children: [
        // Admin Pool Management Section (if admin)
        if (isAdmin) ...[
          _buildPoolManagementSection(),
          const SizedBox(height: 16),
          // Collapsible Personal Stats Section for Admin
          _buildPersonalStatsToggle(),
          if (_showPersonalStats) ...[
            const SizedBox(height: 12),
            _buildPersonalStatsContent(),
          ],
        ] else ...[
          // Always show for non-admin users
          _buildPersonalStatsContent(),
        ],
      ],
    );
  }

  Widget _buildPersonalStatsToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _showPersonalStats = !_showPersonalStats;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                'MY PERSONAL STATS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(
                _showPersonalStats
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalStatsContent() {
    return Column(
      children: [
        // Personal Rewards Stats
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

  Widget _buildPoolManagementSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward Pool',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'College-wide credits',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoadingPoolBalance
                          ? 'Loading...'
                          : '${_poolBalance?.toString() ?? '0'} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _showLoadCreditsDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Load\nCredits',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 140,
                    child: OutlinedButton.icon(
                      onPressed: _showTransactionHistory,
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('History'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side:
                            const BorderSide(color: Colors.white70, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color[700],
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
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
            backgroundColor: AppTheme.redeemButtonColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppTheme.redeemButtonColor.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.card_giftcard_rounded, size: 22),
          label: const Text(
            'Redeem',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
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
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(
            text: 'Leaderboard',
            height: 40,
          ),
          Tab(
            text: 'Overview',
            height: 40,
          ),
          Tab(
            text: 'My Rewards',
            height: 40,
          ),
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
      padding: const EdgeInsets.fromLTRB(
          16.0, 16.0, 16.0, 180.0), // Extra bottom padding for nav bar
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
                  Icons.workspace_premium_outlined,
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
              Icons.workspace_premium_outlined,
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
      padding: const EdgeInsets.fromLTRB(
          16.0, 16.0, 16.0, 180.0), // Extra bottom padding for nav bar
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
      padding: const EdgeInsets.fromLTRB(
          16.0, 16.0, 16.0, 180.0), // Extra bottom padding for nav bar
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
              Icons.workspace_premium,
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
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reward.rewardTypeDisplayName,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
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
      rankIcon = Icons.workspace_premium;
    } else if (entry.rank == 2) {
      rankColor = Colors.grey.shade600;
      rankIcon = Icons.workspace_premium;
    } else if (entry.rank == 3) {
      rankColor = Colors.brown.shade600;
      rankIcon = Icons.workspace_premium;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
        border: entry.rank <= 3
            ? Border.all(
                color: rankColor!.withOpacity(0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor?.withOpacity(0.1) ?? Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 16)
                  : Text(
                      '${entry.rank}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: rankColor ?? Colors.grey.shade600,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // User Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  entry.department,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars,
                  size: 14,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 3),
                Text(
                  '${entry.totalPoints}',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showGiveRewardDialog() async {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: Colors.amber.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Give Reward',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                                  color: AppTheme.primaryColor,
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

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isCreating ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isCreating
                            ? null
                            : () async {
                                if (selectedUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please select a user')),
                                  );
                                  return;
                                }

                                if (titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please enter a title')),
                                  );
                                  return;
                                }

                                final points =
                                    int.tryParse(pointsController.text);
                                if (points == null ||
                                    points <= 0 ||
                                    points > 100) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please enter valid points (1-100)')),
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
                                    description: descriptionController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : descriptionController.text.trim(),
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Reward given successfully!'),
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
                                        content:
                                            Text('Failed to give reward: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.giveRewardsButtonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isCreating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Give Reward'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoadCreditsDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Load Credits to Pool',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Add points to the college reward pool. These points will be used when giving rewards to students.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // Current Pool Balance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Pool Balance',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_poolBalance ?? 0} points',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Input
                const Text(
                  'Amount to Add',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter points (e.g., 1000)',
                    prefixIcon: Icon(Icons.add_circle_outline,
                        color: AppTheme.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Input
                const Text(
                  'Description (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a note about this credit...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final amountText = amountController.text.trim();
                                if (amountText.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter an amount'),
                                    ),
                                  );
                                  return;
                                }

                                final amount = int.tryParse(amountText);
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please enter a valid positive number'),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                });

                                try {
                                  await _rewardService.creditPool(
                                    amount: amount,
                                    description: descriptionController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : descriptionController.text.trim(),
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Successfully added $amount points to pool!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Reload pool balance
                                    _loadPoolBalance();
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isLoading = false;
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to load credits: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Load Credits'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionHistory() async {
    List<Map<String, dynamic>> transactions = [];
    bool isLoading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Load transactions on first build
          if (isLoading && transactions.isEmpty) {
            _rewardService.getPoolTransactions(limit: 50).then((data) {
              setDialogState(() {
                transactions = data;
                isLoading = false;
              });
            }).catchError((e) {
              setDialogState(() {
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load transactions: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction History',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pool credits & debits',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Transaction List
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : transactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = transactions[index];
                                final transactionType =
                                    transaction['transaction_type'] ?? 'CREDIT';
                                final amount = transaction['amount'] ?? 0;
                                final description =
                                    transaction['description'] ?? '';
                                final createdAt = transaction['created_at'];
                                final adminName =
                                    transaction['admin_name'] ?? 'Admin';

                                final isCredit = transactionType == 'CREDIT';
                                final date = createdAt != null
                                    ? DateTime.parse(createdAt)
                                    : DateTime.now();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isCredit
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isCredit
                                              ? Icons.add_circle_outline
                                              : Icons.remove_circle_outline,
                                          color: isCredit
                                              ? Colors.green
                                              : Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isCredit
                                                  ? 'Credits Added'
                                                  : 'Reward Given',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                description,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  adminName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDate(date),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isCredit ? '+' : '-'}$amount',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isCredit
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'pts',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
