import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Import Cloud Functions
import 'package:flutter/material.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/widgets/gradient_container.dart';

class AllUsersPage extends StatefulWidget {
  const AllUsersPage({super.key});

  @override
  State<AllUsersPage> createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  List<Alluser>? _users;
  bool _isLoading = true;
  String? _error;
  String _searchTerm = ''; // Add search term state
  final AuthService _authService = AuthService(); // Instantiate AuthService

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ref = FirebaseDatabase.instance.ref('users');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
        final List<Alluser> users = [];
        usersMap.forEach((uid, userData) {
          final userMap = Map<String, dynamic>.from(userData as Map);
          users.add(Alluser.fromMap(userMap, uid));
        });
        users.sort((a, b) =>
            a.name.compareTo(b.name)); // Sort users for consistent display
        setState(() {
          _users = users;
        });
      } else {
        setState(() {
          _users = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshUsers() {
    _fetchAllUsers();
  }

  Future<void> _confirmDeleteUser(Alluser userToDelete) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: Text(
                'Are you sure you want to permanently delete the user "${userToDelete.name}"?\n\nThis action is irreversible and will delete their authentication account, all database records, and stored files.'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() => _isLoading = true);
      try {
        // Call the Cloud Function
        HttpsCallable callable =
            FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
        final result = await callable.call(<String, dynamic>{
          'uid': userToDelete.uid,
        });

        // Remove user from the local list to update UI instantly
        setState(() {
          _users?.removeWhere((user) => user.uid == userToDelete.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.data['message'] ?? 'User deleted successfully.'),
        ));
      } on FirebaseFunctionsException catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditRoleDialog(Alluser userToEdit) async {
    String? selectedRole = userToEdit.role; // Initialize with current role
    final List<String> availableRoles = [
      'student',
      'teacher',
      'admin'
    ]; // Define available roles

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to update dialog state
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Role for ${userToEdit.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Select Role',
                      border: OutlineInputBorder(),
                    ),
                    items: availableRoles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role[0].toUpperCase() + role.substring(1)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        // Update dialog's internal state
                        selectedRole = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (selectedRole != null &&
                        selectedRole != userToEdit.role) {
                      Navigator.of(context)
                          .pop(true); // Pop with true to indicate save
                    } else {
                      Navigator.of(context)
                          .pop(false); // No change or invalid selection
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave == true && selectedRole != null) {
      setState(() => _isLoading = true); // Show loading overlay on main page
      try {
        await _authService.updateUserRole(userToEdit, selectedRole!);

        // Update the local list with the new role
        setState(() {
          final index =
              _users?.indexWhere((user) => user.uid == userToEdit.uid);
          if (index != null && index != -1) {
            _users![index] = Alluser(
              uid: userToEdit.uid,
              username: userToEdit.username,
              name: userToEdit.name,
              email: userToEdit.email,
              image: userToEdit.image,
              role: selectedRole!, // Update the role
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Role for ${userToEdit.name} updated to $selectedRole.')),
        );
      } on AuthException catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('All Registered Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Refresh Users',
          ),
          // Add Search Field
          SizedBox(
            width: 200,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search Users',
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => _searchTerm = value),
            ),
          ),
        ],
      ),
      body: GradientContainer(
        child: LoadingOverlay(
          isLoading: _isAssigning,
          message: 'Assigning...',
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _users == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_users == null || _users!.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    // Filter users based on search term
    final filteredUsers = _users!
        .where((user) =>
            user.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();

    return Stack(
      children: [
        ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      (user.image != null && user.image!.isNotEmpty)
                          ? CachedNetworkImageProvider(user.image!)
                          : null,
                  child: (user.image == null || user.image!.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user.name),
                subtitle: Text('${user.email}\nRole: ${user.role}'),
                isThreeLine: true,
                trailing: Row(
                  // Use a Row for multiple trailing icons
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditRoleDialog(user),
                      tooltip: 'Edit Role',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteUser(user),
                      tooltip: 'Delete User Data',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_isLoading && _users != null)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
