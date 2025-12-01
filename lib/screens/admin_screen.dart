import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/department_service.dart';
import '../models/department_model.dart';
import '../config/theme_config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final DepartmentService _departmentService = DepartmentService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _permissions = [];
  List<Map<String, dynamic>> _roles = [];
  List<Department> _departments = [];

  bool _isLoadingUsers = false;
  bool _isLoadingPermissions = false;
  bool _isLoadingRoles = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_filterUsers);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUsers(),
      _loadPermissions(),
      _loadRoles(),
      _loadDepartments(),
    ]);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await _adminService.listUsers();
      setState(() {
        _users = users;
        _filterUsers(); // Apply any existing search filter
      });
    } catch (e) {
      _showError('Failed to load users: $e');
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final name = (user['full_name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final username = (user['username'] ?? '').toString().toLowerCase();
          final department =
              (user['department'] ?? '').toString().toLowerCase();
          return name.contains(query) ||
              email.contains(query) ||
              username.contains(query) ||
              department.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoadingPermissions = true;
    });

    try {
      final permissions = await _adminService.listPermissions();
      print('📋 Loaded ${permissions.length} permissions');
      print('📋 Raw permissions data: $permissions');
      if (permissions.isNotEmpty) {
        print('📋 First permission structure: ${permissions[0]}');
      }
      setState(() {
        _permissions = permissions;
      });
    } catch (e) {
      print('❌ Error loading permissions: $e');
      _showError('Failed to load permissions: $e');
    } finally {
      setState(() {
        _isLoadingPermissions = false;
      });
    }
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoadingRoles = true;
    });

    try {
      final roles = await _adminService.listRoles();
      print('🎖️ Loaded ${roles.length} roles: $roles');
      setState(() {
        _roles = roles;
      });
    } catch (e) {
      print('❌ Error loading roles: $e');
      _showError('Failed to load roles: $e');
    } finally {
      setState(() {
        _isLoadingRoles = false;
      });
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _departmentService.getDepartments();
      print('🏢 Loaded ${departments.length} departments');
      setState(() {
        _departments = departments;
      });
    } catch (e) {
      print('❌ Error loading departments: $e');
      // Don't show error to user, departments are optional
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 28),
            SizedBox(width: 12),
            Text('Admin Panel'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.security), text: 'Permissions'),
            Tab(icon: Icon(Icons.badge), text: 'Roles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildPermissionsTab(),
          _buildRolesTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text('No users found'),
      );
    }

    return Column(
      children: [
        // Search bar and Add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: _showAddUserDialog,
                mini: true,
                tooltip: 'Add User',
                child: const Icon(Icons.person_add),
              ),
            ],
          ),
        ),

        // User count indicator
        if (_searchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Found ${_filteredUsers.length} of ${_users.length} users',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
          ),

        // Users list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No users match your search',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['is_active'] ?? true;
    final role = user['role'] ?? 'student';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? AppTheme.primaryColor : Colors.grey,
          child: Text(
            _getInitials(user['full_name'] ?? 'U'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user['full_name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(role.toUpperCase(),
                    role == 'admin' ? Colors.red : Colors.blue),
                const SizedBox(width: 8),
                _buildChip(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  isActive ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Department: ${user['department'] ?? 'N/A'}'),
                Text('Class: ${user['class_name'] ?? 'N/A'}'),
                Text('Username: ${user['username'] ?? 'N/A'}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showChangeRoleDialog(user),
                      icon: const Icon(Icons.badge, size: 18),
                      label: const Text('Change Role'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _toggleUserStatus(user),
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(isActive ? 'Deactivate' : 'Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showUserPermissions(user),
                        icon: const Icon(Icons.security, size: 18),
                        label: const Text('View Permissions'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteUser(user),
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Delete User'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    final availableRoles = ['student', 'staff', 'admin'];
    String selectedRole = user['role'] ?? 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Role: ${user['full_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableRoles.map((role) {
              return RadioListTile<String>(
                title: Text(role.toUpperCase()),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateUserRole(user['id'], selectedRole);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserRole(int userId, String role) async {
    try {
      await _adminService.updateUserRole(userId, role);
      _showSuccess('Role updated successfully');
      await _loadUsers();
    } catch (e) {
      _showError('Failed to update role: $e');
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final isActive = user['is_active'] ?? true;
    final newStatus = !isActive;

    try {
      await _adminService.updateUserStatus(user['id'], newStatus);
      _showSuccess('User status updated successfully');
      await _loadUsers();
    } catch (e) {
      _showError('Failed to update status: $e');
    }
  }

  void _showUserPermissions(Map<String, dynamic> user) async {
    try {
      final permissionsData =
          await _adminService.getUserPermissions(user['id']);

      print('🔍 Permission data for ${user['full_name']}: $permissionsData');

      if (!mounted) return;

      final permissionsList = permissionsData['permissions'] as List? ?? [];

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permissions: ${user['full_name']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Role: ${permissionsData['role'] ?? 'N/A'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (permissionsList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No custom permissions assigned.\nUser has default ${permissionsData['role'] ?? 'role'} permissions.',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...permissionsList.map((perm) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(perm.toString())),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Error loading user permissions: $e');
      _showError('Failed to load permissions: $e');
    }
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final fullNameController = TextEditingController();
    final classNameController = TextEditingController();
    final academicYearController = TextEditingController();
    final passwordController = TextEditingController();

    // Use departments from API
    Department? selectedDepartment;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'e.g., john_doe',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g., John Doe',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'e.g., john.doe@iitm.ac.in',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Department dropdown with departments from API
                  DropdownButtonFormField<Department>(
                    value: selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      hintText: 'Select department',
                    ),
                    items: _departments
                        .map((dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDepartment = value;
                      });
                    },
                    validator: (v) {
                      if (v == null) {
                        return 'Please select a department';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: classNameController,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      hintText: 'e.g., 3rd Year',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: academicYearController,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year',
                      hintText: 'e.g., 2024-2025',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Initial password',
                    ),
                    obscureText: true,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _createUser(
                    username: usernameController.text,
                    email: emailController.text,
                    fullName: fullNameController.text,
                    departmentId: selectedDepartment!.id,
                    className: classNameController.text,
                    academicYear: academicYearController.text,
                    password: passwordController.text,
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createUser({
    required String username,
    required String email,
    required String fullName,
    required int departmentId,
    required String className,
    required String academicYear,
    required String password,
  }) async {
    try {
      // Get college_id from current logged-in user's tenantId
      final authService = AuthService();
      final collegeId =
          int.tryParse(authService.currentUser?.tenantId ?? '1') ?? 1;

      await _adminService.createUser(
        username: username,
        email: email,
        fullName: fullName,
        departmentId: departmentId,
        className: className,
        academicYear: academicYear,
        password: password,
        collegeId: collegeId,
      );
      _showSuccess('User created successfully');
      await _loadUsers();
    } catch (e) {
      _showError('Failed to create user: $e');
    }
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    bool forceDelete = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete ${user['full_name']}?\n\nThis action cannot be undone.',
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: forceDelete,
                onChanged: (value) {
                  setState(() {
                    forceDelete = value ?? false;
                  });
                },
                title: const Text('Force Delete'),
                subtitle: const Text(
                  'Delete even if user has dependencies (posts, rewards, etc.)',
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteUser(user['id'], force: forceDelete);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(int userId, {bool force = false}) async {
    try {
      await _adminService.deleteUser(userId, force: force);
      _showSuccess('User deleted successfully');
      await _loadUsers();
    } catch (e) {
      _showError('Failed to delete user: $e');
    }
  }

  Widget _buildPermissionsTab() {
    if (_isLoadingPermissions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No permissions available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Permissions define what actions users can perform.\nCheck the Roles tab to see role-based permissions.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group permissions by category
    Map<String, List<Map<String, dynamic>>> categorizedPermissions = {};
    for (var perm in _permissions) {
      String category = perm['category']?.toString() ?? 'Other';
      if (!categorizedPermissions.containsKey(category)) {
        categorizedPermissions[category] = [];
      }
      categorizedPermissions[category]!.add(perm);
    }

    return RefreshIndicator(
      onRefresh: _loadPermissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categorizedPermissions.length,
        itemBuilder: (context, index) {
          final category = categorizedPermissions.keys.elementAt(index);
          final permissions = categorizedPermissions[category]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Icon(
                _getCategoryIcon(category),
                color: Colors.blue,
              ),
              title: Text(
                category.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${permissions.length} permissions'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: permissions.map((perm) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _getActionIcon(perm['action']?.toString() ?? ''),
                              color: _getActionColor(
                                  perm['action']?.toString() ?? ''),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    perm['name']?.toString() ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (perm['description'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        perm['description'].toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'posts':
        return Icons.article;
      case 'alerts':
        return Icons.notifications;
      case 'files':
        return Icons.folder;
      case 'folders':
        return Icons.folder_open;
      case 'rewards':
        return Icons.card_giftcard;
      case 'users':
        return Icons.people;
      case 'ai':
        return Icons.psychology;
      case 'store':
        return Icons.store;
      default:
        return Icons.security;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'read':
        return Icons.visibility;
      case 'write':
        return Icons.edit;
      case 'update':
        return Icons.update;
      case 'delete':
        return Icons.delete;
      case 'manage':
        return Icons.admin_panel_settings;
      default:
        return Icons.check_circle;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'read':
        return Colors.blue;
      case 'write':
        return Colors.green;
      case 'update':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      case 'manage':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRolesTab() {
    if (_isLoadingRoles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No roles available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Roles group permissions together (e.g., Admin, Student, Staff)',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRoles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final role = _roles[index];
          final permissions = role['permissions'] as List? ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Icon(
                Icons.badge,
                color: role['name'] == 'admin' ? Colors.red : Colors.blue,
              ),
              title: Text(
                (role['name'] ?? 'Unknown').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${permissions.length} permissions'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permissions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...permissions.map((perm) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check,
                                  color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(perm.toString())),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
