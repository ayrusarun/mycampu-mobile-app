import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import '../config/theme_config.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _searchController = TextEditingController();

  List<Group> _allGroups = [];
  List<Group> _filteredGroups = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final groups = await _groupService.getAllGroups();
      setState(() {
        _allGroups = groups;
        _filteredGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load groups: $e';
        _isLoading = false;
      });
    }
  }

  void _filterGroups(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = _allGroups;
      } else {
        _filteredGroups = _allGroups.where((group) {
          return group.name.toLowerCase().contains(query.toLowerCase()) ||
              (group.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }

  Future<void> _joinGroup(Group group) async {
    try {
      final success = await _groupService.joinGroup(group.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${group.name}'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload groups to update membership status
        _loadGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveGroup(Group group) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave ${group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Note: You'll need to implement leaveGroup in GroupService
      // For now, we'll show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave group functionality coming soon'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterGroups,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterGroups('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Groups List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadGroups,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredGroups.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'No groups available'
                                  : 'No groups found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadGroups,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredGroups.length,
                              itemBuilder: (context, index) {
                                final group = _filteredGroups[index];
                                return _buildGroupCard(group);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    final isMember = group.myRole != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Group Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.purple.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getGroupInitials(group.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Group Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMember)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            group.myRole!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (group.description != null &&
                      group.description!.isNotEmpty)
                    Text(
                      group.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberCount ?? 0} members',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        group.isOpen ? Icons.public : Icons.lock,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        group.isOpen ? 'Open' : 'Private',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Join/Leave Button
            if (isMember)
              OutlinedButton(
                onPressed: () => _leaveGroup(group),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Leave',
                  style: TextStyle(fontSize: 12),
                ),
              )
            else
              ElevatedButton(
                onPressed: () => _joinGroup(group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '+ Join',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getGroupInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'G';
  }
}
