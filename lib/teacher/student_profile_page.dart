import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/widgets/gradient_container.dart';

class StudentProfilePage extends StatefulWidget {
  final StudentTable studentProfile;
  final String userRole;

  const StudentProfilePage(
      {super.key, required this.studentProfile, required this.userRole});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final AuthService _authService = AuthService();
  late StudentTable _studentProfile;
  bool _isGeneratingId = false;

  @override
  void initState() {
    super.initState();
    _studentProfile = widget.studentProfile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_studentProfile.fullName)),
      body: LoadingOverlay(
        isLoading: _isGeneratingId,
        message: 'Generating ID...',
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileHeader(context, _studentProfile),
            const SizedBox(height: 16),
            _buildAcademicCard(context, _studentProfile),
            _buildPersonalCard(context, _studentProfile),
            _buildParentInfoCard(context, _studentProfile),
            _buildContactCard(context, _studentProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    StudentTable studentProfile,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: studentProfile.imageUrl != null &&
                  studentProfile.imageUrl!.isNotEmpty
              ? CachedNetworkImageProvider(
                  studentProfile.imageUrl!,
                )
              : null,
          child: studentProfile.imageUrl == null ||
                  studentProfile.imageUrl!.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          studentProfile.fullName,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        Text(
          studentProfile.email,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _generateId() async {
    setState(() => _isGeneratingId = true);
    try {
      final newId =
          await _authService.generateAndAssignStudentId(_studentProfile.uid);
      if (mounted) {
        setState(() {
          _studentProfile = _studentProfile.copyWith(studentId: newId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student ID generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate ID: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingId = false);
      }
    }
  }

  Widget _buildAcademicCard(BuildContext context, StudentTable studentProfile) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            _buildStudentIdSection(studentProfile),
            _buildProfileInfoRow(Icons.format_list_numbered, 'Roll Number',
                studentProfile.rollNumber?.toString()),
            _buildProfileInfoRow(
                Icons.class_, 'Class ID', studentProfile.classId),
            _buildProfileInfoRow(
                Icons.group_work, 'Section', studentProfile.section),
            _buildProfileInfoRow(
                Icons.calendar_today, 'Session', studentProfile.session),
            _buildProfileInfoRow(
                Icons.book, 'Subject(s)', studentProfile.subject),
            _buildProfileInfoRow(
                Icons.check_circle_outline, 'Status', studentProfile.status),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalCard(BuildContext context, StudentTable studentProfile) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Information',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildProfileInfoRow(
                Icons.person_outline, 'Full Name', studentProfile.fullName),
            _buildProfileInfoRow(
                Icons.cake_outlined, 'Date of Birth', studentProfile.dob),
            _buildProfileInfoRow(
                Icons.wc_outlined, 'Gender', studentProfile.gender),
            _buildProfileInfoRow(Icons.bloodtype_outlined, 'Blood Group',
                studentProfile.bloodGroup),
            _buildProfileInfoRow(Icons.school_outlined, 'Admission Year',
                studentProfile.admissionYear),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, StudentTable studentProfile) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Information',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildProfileInfoRow(
                Icons.email_outlined, 'Email', studentProfile.email),
            _buildProfileInfoRow(
                Icons.phone_outlined, 'Mobile No.', studentProfile.mob),
            _buildProfileInfoRow(Icons.location_on_outlined, 'Present Address',
                studentProfile.presentAddress),
            _buildProfileInfoRow(Icons.home_outlined, 'Permanent Address',
                studentProfile.permanentAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildParentInfoCard(
      BuildContext context, StudentTable studentProfile) {
    // This card will only be built if there is at least one piece of parent info.
    if ((studentProfile.fatherName == null ||
            studentProfile.fatherName!.isEmpty) &&
        (studentProfile.motherName == null ||
            studentProfile.motherName!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Parent's Information",
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildProfileInfoRow(
                Icons.male, "Father's Name", studentProfile.fatherName),
            _buildProfileInfoRow(
                Icons.phone, "Father's Mobile", studentProfile.fatherMobile),
            _buildProfileInfoRow(
                Icons.female, "Mother's Name", studentProfile.motherName),
            _buildProfileInfoRow(
                Icons.phone, "Mother's Mobile", studentProfile.motherMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentIdSection(StudentTable studentProfile) {
    final hasId = studentProfile.studentId != null &&
        studentProfile.studentId!.isNotEmpty;

    if (hasId) {
      return _buildProfileInfoRow(
          Icons.badge_outlined, 'Student ID', studentProfile.studentId);
    } else {
      // Only show the 'Generate ID' button to admin users.
      if (widget.userRole == 'admin') {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Generate Student ID'),
              onPressed: _isGeneratingId ? null : _generateId,
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer),
            ),
          ),
        );
      } else {
        // For other users (like teachers), just show 'Not Assigned'.
        return _buildProfileInfoRow(
            Icons.badge_outlined, 'Student ID', 'Not Assigned');
      }
    }
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink(); // Don't show empty fields
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
