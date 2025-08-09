import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/edit_teacher_profile_page.dart';
import 'package:school_management/teacher_classes_page.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:school_management/model_class/Alluser.dart'; // Import Alluser
import 'package:school_management/main.dart'; // Import for MyHomePage
import 'package:school_management/services/auth_exception.dart'; // Import for AuthException
import 'package:school_management/services/auth_service.dart'; // Import for AuthService
import 'package:school_management/providers/teacher_profile_provider.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/utils/logout_helper.dart';
import 'package:school_management/widgets/gradient_container.dart';

class Teacherpanel extends ConsumerStatefulWidget {
  final Alluser currentUser; // Add this line

  const Teacherpanel(
      {super.key, required this.currentUser}); // Update constructor

  @override
  ConsumerState<Teacherpanel> createState() =>
      _TeacherpanelState(); // Corrected type
}

class _TeacherpanelState extends ConsumerState<Teacherpanel> {
  final AuthService _authService = AuthService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(
          teacherProfileProvider); // Invalidate to force initial fetch
    });
  }

  // Function to refresh the profile data
  void _refreshProfile() {
    // Invalidate the provider to force a re-fetch of the teacher profile
    ref.invalidate(teacherProfileProvider);
  }

  Future<void> _logout() async {
    // Use the reusable logout helper
    await showLogoutConfirmationDialog(context, ref);
  }

  // Helper method for profile info display
  Widget _buildProfileInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the teacher profile from the provider
    final teacherProfileAsyncValue = ref.watch(teacherProfileProvider);

    return GradientContainer(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Teacher Panel'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(
                Icons.refresh), // Refresh button to manually trigger re-fetch
            onPressed: _refreshProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: teacherProfileAsyncValue.when(
        data: (teacher) {
          if (teacher == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Teacher profile not found.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Profile Header ---
                _buildProfileHeader(teacher),
                const SizedBox(height: 24),

                // --- Actions Card ---
                _buildActionsCard(context, teacher),
                const SizedBox(height: 24),

                // --- Detailed Info Card ---
                _buildDetailedInfoCard(teacher),
              ],
            ),
          );
        },
        loading: () {
          return const LoadingOverlay(
              isLoading: true,
              message: 'Loading Profile...',
              child: SizedBox.shrink());
        },
        error: (error, stack) => Center(
            child:
                Text('Error: ${error.toString()}')), // Corrected error callback
      ),
    ));
  }

  Widget _buildProfileHeader(TeacherProfile teacher) {
    return Column(
      children: [
        Center(
          child: CircleAvatar(
            radius: 60,
            backgroundImage:
                teacher.imageUrl != null && teacher.imageUrl!.isNotEmpty
                    ? NetworkImage(teacher.imageUrl!)
                    : null,
            child: teacher.imageUrl == null || teacher.imageUrl!.isEmpty
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          teacher.name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          teacher.email,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionsCard(BuildContext context, TeacherProfile teacher) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.class_outlined, color: Colors.brown),
            title: const Text('My Classes'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherClassesPage(
                    teacher: teacher,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditTeacherProfilePage(teacherProfile: teacher),
                ),
              );
              if (result == true) {
                _refreshProfile();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoCard(TeacherProfile teacher) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildProfileInfo('Role', teacher.role),
            _buildProfileInfo('Qualification', teacher.qualification),
            _buildProfileInfo('Mobile No.', teacher.mobileNo),
            _buildProfileInfo('Joining Date', teacher.joiningDate),
            _buildProfileInfo('Status', teacher.status),
          ],
        ),
      ),
    );
  }
}
