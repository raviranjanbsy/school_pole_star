import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/ui/course_analytics_widget.dart';
// Assuming signup page can be used for adding users, but the add user functionality is not implemented here.
// import 'package:school_management/signup.dart';
import 'package:school_management/ui/communication_page.dart';
import 'package:school_management/ui/fee_management_page.dart'; // New import
import 'package:school_management/ui/manage_users_page.dart'; // Import the new user management page
import 'package:school_management/manage_school_classes_page.dart'; // Import the dedicated class management page
import 'package:school_management/ui/curriculum_management_page.dart'; // New import
import 'package:school_management/ui/reports_page.dart';
import 'package:school_management/ui/new_student_admission_page.dart';
import 'package:school_management/main.dart';
import 'package:school_management/utils/logout_helper.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'dart:developer' as developer;

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          automaticallyImplyLeading: false, // This will remove the back button
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context, ref),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadInitialData(ref),
          child: ListView(
            children: [
              _buildManagementToolsGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadInitialData(WidgetRef ref) async {
    try {
      await Future.wait([
        ref.read(authServiceProvider).fetchAllUsers(),
        ref.read(authServiceProvider).fetchAllSchoolClasses(),
      ]);
    } catch (e) {
      developer.log('Failed to load initial data: $e', name: 'AdminHomePage');
    }
  }

  Widget _buildManagementToolsGrid(BuildContext context) {
    final List<_ManagementTool> tools = [
      _ManagementTool(
        label: 'Manage Users',
        icon: Icons.people_outline,
        color: Colors.blue,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ManageUsersPage())),
      ),
      _ManagementTool(
        label: 'Manage Classes',
        icon: Icons.class_outlined,
        color: Colors.orange,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ManageSchoolClassesPage())),
      ),
      _ManagementTool(
        label: 'Fee Management',
        icon: Icons.currency_rupee,
        color: Colors.green,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FeeManagementPage())),
      ),
      _ManagementTool(
        label: 'Course Analytics',
        icon: Icons.school_outlined,
        color: Colors.purple,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CourseAnalyticsWidget())),
      ),
      _ManagementTool(
        label: 'Manage Curriculum',
        icon: Icons.book_outlined,
        color: Colors.teal,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CurriculumManagementPage())),
      ),
      _ManagementTool(
        label: 'Reports & Analytics',
        icon: Icons.analytics_outlined,
        color: Colors.red,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ReportsPage())),
      ),
      _ManagementTool(
        label: 'New Admission',
        icon: Icons.person_add_alt_1_outlined,
        color: Colors.cyan,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NewStudentAdmissionPage())),
      ),
      _ManagementTool(
        label: 'Communication',
        icon: Icons.message_outlined,
        color: Colors.indigo,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const CommunicationPage())),
      ),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0, // Makes the cards square
      ),
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // To disable GridView's scrolling
      padding: const EdgeInsets.all(16.0),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        return _buildManagementToolCard(context, tools[index]);
      },
    );
  }

  Widget _buildManagementToolCard(BuildContext context, _ManagementTool tool) {
    return Card(
      elevation: 4, // Increased elevation for more shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior:
          Clip.antiAlias, // Ensures the gradient respects the border radius
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tool.color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: tool.color.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: tool.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      tool.color.withOpacity(0.2), // Slightly more opaque
                  child: Icon(tool.icon, size: 30, color: tool.color),
                ),
                const SizedBox(height: 16),
                Text(
                  tool.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, // Bolder text
                        color: tool.color.shade800, // Darker text color
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Use the reusable logout helper
    await showLogoutConfirmationDialog(context, ref);
  }
}

/// A helper class to hold the data for each management tool card.
class _ManagementTool {
  final String label;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _ManagementTool(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
}
