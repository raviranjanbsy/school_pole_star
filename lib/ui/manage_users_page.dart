import 'package:flutter/material.dart';
import 'package:school_management/main.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/utils/string_extensions.dart'; // New import for capitalize
import 'package:school_management/signup.dart';
import 'package:school_management/ui/edit_user_page.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'dart:developer' as developer;

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Alluser> _allUsers = []; // Master list of all users
  List<Alluser> _filteredUsers = [];
  bool _isLoading = true;
  bool _isLoadingAction = false;
  String _selectedRole = 'All'; // New state for the role filter
  String _selectedStatus = 'All'; // New state for the status filter
  String _sortColumn = 'name'; // Default sort column
  bool _sortAscending = true; // Default sort direction
  bool _isBulkSelecting = false; // New state for bulk selection mode
  Set<String> _selectedUserUids =
      {}; // Stores UIDs of selected users for bulk actions

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.fetchAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users; // Populate the master list
          _isLoading = false;
        });
        _filterUsers(); // Apply initial filters
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
        developer.log('Failed to load users: $e', name: 'ManageUsersPage');
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // Always start with the master list
      List<Alluser> tempUsers = _allUsers;

      // Role filter logic
      if (_selectedRole != 'All') {
        tempUsers =
            tempUsers.where((user) => user.role == _selectedRole).toList();
      }

      // Status filter logic
      if (_selectedStatus != 'All') {
        tempUsers =
            tempUsers.where((user) => user.status == _selectedStatus).toList();
      }

      // Search query filter logic
      if (query.isNotEmpty) {
        tempUsers = tempUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      }

      // --- SORTING LOGIC ---
      tempUsers.sort((a, b) {
        int compare;
        switch (_sortColumn) {
          case 'email':
            compare = a.email.toLowerCase().compareTo(b.email.toLowerCase());
            break;
          case 'role':
            compare = a.role.toLowerCase().compareTo(b.role.toLowerCase());
            break;
          case 'status':
            compare = a.status.toLowerCase().compareTo(b.status.toLowerCase());
            break;
          case 'name':
          default:
            compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
        }
        return _sortAscending ? compare : -compare;
      });

      // Update the UI list, ensuring selection state is correctly applied
      _filteredUsers = tempUsers.map((user) {
        return user.copyWith(isSelected: _selectedUserUids.contains(user.uid));
      }).toList();
    });
  }

  Future<void> _addUser() async {
    // This now opens a dialog instead of navigating to the Signup page.
    await _showAddUserDialog();
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'teacher'; // Default role

    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Add New User'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter a name' : null,
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter an email' : null,
                      ),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Initial Password',
                        ),
                        obscureText: true,
                        validator: (v) => v!.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'teacher',
                            child: Text('Teacher'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            dialogSetState(() => selectedRole = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: _buildDialogActions(
                formKey,
                nameController,
                emailController,
                passwordController,
                () => selectedRole,
              ),
            );
          },
        );
      },
    );
  }

  void _toggleBulkSelectionMode() {
    setState(() {
      _isBulkSelecting = !_isBulkSelecting;
      _selectedUserUids.clear(); // Clear selections when toggling mode
      // Re-filter to update isSelected state on all users
      _filterUsers();
    });
  }

  void _toggleUserSelection(Alluser user) {
    setState(() {
      final wasSelected = _selectedUserUids.contains(user.uid);
      if (wasSelected) {
        _selectedUserUids.remove(user.uid);
      } else {
        _selectedUserUids.add(user.uid);
      }
      // Update the isSelected state of the specific user in _filteredUsers
      final index = _filteredUsers.indexWhere((u) => u.uid == user.uid);
      if (index != -1) {
        _filteredUsers[index] = user.copyWith(isSelected: !wasSelected);
      }
    });
  }

  void _selectAllUsers() {
    setState(() {
      if (_selectedUserUids.length == _filteredUsers.length) {
        // If all are selected, deselect all
        _selectedUserUids.clear();
      } else {
        // Select all currently filtered users
        _selectedUserUids = _filteredUsers.map((user) => user.uid).toSet();
      }
      // Update isSelected state for all filtered users
      _filteredUsers = _filteredUsers
          .map(
            (user) =>
                user.copyWith(isSelected: _selectedUserUids.contains(user.uid)),
          )
          .toList();
    });
  }

  Future<void> _bulkUpdateSelectedUsersStatus(String newStatus) async {
    if (_selectedUserUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users selected for bulk update.')),
      );
      return;
    }

    final int selectionCount = _selectedUserUids.length;
    final List<String> uidsToUpdate = _selectedUserUids.toList();

    setState(() => _isLoadingAction = true);
    try {
      await _authService.updateUsersStatus(uidsToUpdate, newStatus);
      _selectedUserUids.clear(); // Clear selections after update
      _loadUsers(); // Refresh the entire list to reflect changes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully updated status for $selectionCount users to $newStatus.',
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk update failed: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAction = false);
        _isBulkSelecting = false; // Exit bulk selection mode
      }
    }
  }

  Future<void> _editUser(Alluser user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditUserPage(userToEdit: user)),
    );
    if (result == true) {
      _loadUsers(); // Refresh list on successful edit
    }
  }

  Future<void> _changeUserRole(Alluser user) async {
    const roles = ['admin', 'teacher', 'student'];
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${user.name}'),
        content: DropdownButton<String>(
          value: user.role,
          isExpanded: true,
          items: roles
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.capitalize()),
                ),
              )
              .toList(),
          onChanged: (value) {
            Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != user.role) {
      // Add a confirmation dialog before proceeding
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Role Change'),
          content: Text(
            'Are you sure you want to change ${user.name}\'s role to ${newRole.capitalize()}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      // If the user did not confirm, abort the operation
      if (confirm != true) return;

      setState(() => _isLoadingAction = true);
      try {
        await _authService.updateUserRole(user, newRole);
        _loadUsers(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${user.name}'s role updated to $newRole.")),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to change role: ${e.message}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingAction = false);
        }
      }
    }
  }

  Future<void> _updateUserStatus(String uid, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    setState(() => _isLoadingAction = true);
    try {
      await _authService.updateUserStatus(uid, newStatus);
      _loadUsers(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User status updated to $newStatus.')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAction = false);
      }
    }
  }

  Future<void> _deleteUser(Alluser user) async {
    // --- ADD THIS GUARD CLAUSE ---
    if (user.role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Admin users cannot be deleted.'),
        ),
      );
      return; // Stop the function here
    }
    // --- END OF GUARD CLAUSE ---
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete user "${user.email}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoadingAction = true);
      try {
        await _authService.deleteUser(user);
        _loadUsers(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully.')),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete user: ${e.message}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingAction = false);
        }
      }
    }
  }

  Future<void> _resetPassword(Alluser user) async {
    // First, confirm the action with the admin.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Password Reset'),
        content: Text(
            'Are you sure you want to send a password reset email to ${user.name} (${user.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );

    if (confirm != true) return; // Abort if not confirmed

    setState(() => _isLoadingAction = true);
    try {
      // This function is void. It triggers a Cloud Function to send the email.
      await _authService.createPasswordResetLink(email: user.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  List<Widget> _buildDialogActions(
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController emailController,
    TextEditingController passwordController,
    String Function() getRole,
  ) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            setState(() => _isLoadingAction = true);
            Navigator.of(context).pop(); // Close dialog

            try {
              await _authService.createAdminOrTeacher(
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
                fullName: nameController.text.trim(),
                role: getRole(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User created successfully!')),
              );
              _loadUsers(); // Refresh the list
            } on AuthException catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
            } finally {
              if (mounted) setState(() => _isLoadingAction = false);
            }
          }
        },
        child: const Text('Create User'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Manage Users'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _isLoadingAction ? null : _addUser,
              tooltip: 'Add New User',
            ),
            IconButton(
              icon: Icon(_isBulkSelecting ? Icons.check_box : Icons.select_all),
              onPressed: _toggleBulkSelectionMode,
              tooltip: _isBulkSelecting ? 'Exit Bulk Select' : 'Bulk Select',
            ),
            if (_isBulkSelecting)
              IconButton(
                icon: const Icon(Icons.check_box_outline_blank),
                onPressed: _selectAllUsers,
                tooltip: 'Select All/Deselect All',
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadUsers,
          child: ListView(
            children: [
              _buildStatsCard(),
              _buildFilters(),
              _isLoading
                  ? const Center(
                      // Correctly apply heightFactor to Center
                      heightFactor: 5,
                      child: CircularProgressIndicator(),
                    )
                  : _buildUserList(),
              if (_isBulkSelecting && _selectedUserUids.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingAction
                              ? null
                              : () => _bulkUpdateSelectedUsersStatus('active'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark Active'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor:
                                Colors.white, // For better contrast
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingAction
                              ? null
                              : () =>
                                  _bulkUpdateSelectedUsersStatus('inactive'),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Mark Inactive'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor:
                                Colors.white, // For better contrast
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Card(
        elevation: 2,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // Role Filter Chips
              _buildFilterChipGroup(
                title: 'Filter by Role:',
                options: const ['All', 'admin', 'teacher', 'student'],
                selectedOption: _selectedRole,
                onSelected: (role) {
                  setState(() => _selectedRole = role);
                  _filterUsers();
                },
              ),
              const SizedBox(height: 12),
              // Status Filter Chips
              _buildFilterChipGroup(
                title: 'Filter by Status:',
                options: const ['All', 'active', 'inactive'],
                selectedOption: _selectedStatus,
                onSelected: (status) {
                  setState(() => _selectedStatus = status);
                  _filterUsers();
                },
              ),
              const Divider(height: 24),
              _buildSortControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Sort by:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortColumn,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Name')),
                DropdownMenuItem(value: 'email', child: Text('Email')),
                DropdownMenuItem(value: 'role', child: Text('Role')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortColumn = value);
                  _filterUsers(); // Re-sort
                }
              },
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
          ),
          onPressed: () {
            setState(() => _sortAscending = !_sortAscending);
            _filterUsers(); // Re-sort
          },
          tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
        ),
      ],
    );
  }

  Widget _buildFilterChipGroup({
    required String title,
    required List<String> options,
    required String selectedOption,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option.capitalize()),
              selected: selectedOption == option,
              onSelected: (isSelected) =>
                  isSelected ? onSelected(option) : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.builder(
      shrinkWrap: true, // Allows the ListView to size itself to its content
      physics:
          const NeverScrollableScrollPhysics(), // Disables scrolling for the inner list
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              // Conditionally show checkbox or status icon
              child: _isBulkSelecting
                  ? Checkbox(
                      value: user.isSelected,
                      onChanged: (bool? value) => _toggleUserSelection(user),
                    )
                  : Icon(
                      user.status == 'active' ? Icons.person : Icons.person_off,
                      color: user.status == 'active'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
              backgroundColor: _isBulkSelecting
                  ? Colors.transparent // Checkbox handles selection visual
                  : user.status == 'active'
                      ? Colors.green.shade100
                      : Colors.red.shade100,
            ),
            // Original leading logic (removed as it's now inside CircleAvatar)
            /*leading: CircleAvatar(
              backgroundColor: user.status == 'active'
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              child: Icon(
                user.status == 'active' ? Icons.person : Icons.person_off,
                color: user.status == 'active'
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),*/
            // ),
            title: Text(user.name.isNotEmpty ? user.name : user.email),
            subtitle: Text(
              '${user.role.toUpperCase()} | Status: ${user.status.toUpperCase()}',
            ),
            trailing: _isLoadingAction
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editUser(user);
                      } else if (value == 'toggle_status') {
                        _updateUserStatus(user.uid, user.status);
                      } else if (value == 'change_role') {
                        _changeUserRole(user);
                      } else if (value == 'delete') {
                        _deleteUser(user);
                      } else if (value == 'reset_password') {
                        _resetPassword(user);
                      }
                    },
                    itemBuilder: (context) {
                      final bool isAdmin = user.role == 'admin';
                      return [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit User'),
                        ),
                        const PopupMenuItem(
                          value: 'change_role',
                          child: Text('Change Role'),
                        ),
                        const PopupMenuItem(
                          value: 'reset_password',
                          child: Text('Reset Password'),
                        ),
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Text(
                            user.status == 'active' ? 'Deactivate' : 'Activate',
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          enabled: !isAdmin, // Disable if admin
                          child: Text(
                            'Delete User',
                            style: TextStyle(
                              color: !isAdmin ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
            onTap: _isBulkSelecting
                ? () => _toggleUserSelection(user)
                : null, // Tap to select in bulk mode
          ),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    final totalUsers = _allUsers.length;
    final activeUsers = _allUsers.where((u) => u.status == 'active').length;
    final inactiveUsers = totalUsers - activeUsers;
    final adminCount = _allUsers.where((u) => u.role == 'admin').length;
    final teacherCount = _allUsers.where((u) => u.role == 'teacher').length;
    final studentCount = _allUsers.where((u) => u.role == 'student').length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Statistics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              _buildStatRow('Total Users', totalUsers),
              _buildStatRow('Active Users', activeUsers, color: Colors.green),
              _buildStatRow('Inactive Users', inactiveUsers, color: Colors.red),
              _buildStatRow('Admins', adminCount),
              _buildStatRow('Teachers', teacherCount),
              _buildStatRow('Students', studentCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
