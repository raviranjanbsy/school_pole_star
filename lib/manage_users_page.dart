import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Import for Timer
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/widgets/gradient_container.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final AuthService _authService = AuthService();
  final List<Alluser> _users = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreUsers = true;
  String? _lastUserKey;
  static const int _pageSize = 20;

  // Define available roles
  final List<String> _roles = ['admin', 'teacher', 'student'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _users.clear();
      _lastUserKey = null;
      _hasMoreUsers = true;
    });
    try {
      final users = await _authService.fetchAllUsers(pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _users.addAll(users);
          if (users.length < _pageSize) {
            _hasMoreUsers = false;
          }
          if (users.isNotEmpty) {
            _lastUserKey = users.last.uid;
          }
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  void _scrollListener() {
    // Trigger fetch when user scrolls near the end of the list,
    // but only if not searching and there are more users to load.
    if (_searchQuery.isEmpty &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                200 && // a small buffer
        !_isLoadingMore &&
        _hasMoreUsers) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newUsers = await _authService.fetchAllUsers(
          startAfterKey: _lastUserKey, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          if (newUsers.length < _pageSize) {
            _hasMoreUsers = false;
          }
          if (newUsers.isNotEmpty) {
            _lastUserKey = newUsers.last.uid;
            _users.addAll(newUsers);
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _updateUserRole(Alluser user, String newRole) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _authService.updateUserRole(user, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role for ${user.name} updated to $newRole')),
      );
      await _loadUsers(); // Refresh the list to show updated roles
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteUser(Alluser user) async {
    // Prevent an admin from deleting their own account from the list.
    if (user.uid == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot delete your own account.")),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete the user ${user.name}?\n\nThis will remove their profile and data. This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteUser(user);
    }
  }

  Future<void> _deleteUser(Alluser user) async {
    setState(() => _isLoading = true);
    try {
      await _authService.deleteUser(user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User data for ${user.name} has been deleted.')),
      );
      await _loadUsers(); // Refresh the list
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search users by name or email...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged();
                    },
                  )
                : null,
          ),
          style: TextStyle(color: Colors.white),
          cursorColor: Colors.white,
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading users...',
        child: _buildBody(),
      ),
    ));
  }

  Widget _buildBody() {
    if (_isLoading && _users.isEmpty) {
      // Show main loading indicator only on initial load
      return const SizedBox.shrink(); // The LoadingOverlay handles this
    }

    final filteredUsers = _users.where((user) {
      final nameLower = user.name.toLowerCase();
      final emailLower = user.email.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();

      return nameLower.contains(queryLower) || emailLower.contains(queryLower);
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No users found.'
              : 'No matching users found for "${_searchQuery}".',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredUsers.length +
          (_searchQuery.isEmpty && _hasMoreUsers ? 1 : 0),
      itemBuilder: (context, index) {
        // Show a loading indicator at the end of the list if there are more users
        if (_searchQuery.isEmpty &&
            _hasMoreUsers &&
            index == filteredUsers.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final user = filteredUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: user.role,
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newRole) {
                    if (newRole != null && newRole != user.role) {
                      _updateUserRole(user, newRole);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteUser(user),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
