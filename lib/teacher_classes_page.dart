import 'package:flutter/material.dart';
import 'package:school_management/class_detail_page.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:school_management/model_class/Alluser.dart'; // Import Alluser
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/teacher/class_student_list_page.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/widgets/gradient_container.dart';

class TeacherClassesPage extends StatefulWidget {
  final TeacherProfile teacher;
  final Alluser currentUser; // Add currentUser here

  const TeacherClassesPage(
      {super.key, required this.teacher, required this.currentUser});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  final AuthService _authService = AuthService();
  List<SchoolClass>? _assignedClasses;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignedClasses();
  }

  Future<void> _loadAssignedClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final classes =
          await _authService.fetchAssignedClasses(widget.teacher.uid);
      if (mounted) {
        setState(() {
          _assignedClasses = classes;
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'An unexpected error occurred.');
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
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignedClasses,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading classes...',
        child: _buildBody(),
      ),
    ));
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_assignedClasses == null || _assignedClasses!.isEmpty) {
      return const Center(child: Text('You are not assigned to any classes.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      itemCount: _assignedClasses!.length,
      itemBuilder: (context, index) {
        final schoolClass = _assignedClasses![index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Class Info
              Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: Text(
                      schoolClass.className.isNotEmpty
                          ? schoolClass.className.substring(0, 1)
                          : 'C',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Class ${schoolClass.className}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${schoolClass.subjects.length} subjects',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ClassStudentListPage(
                                      schoolClass: schoolClass,
                                      currentUserRole: widget.currentUser.role,
                                    )),
                          ),
                      child: const Text('Students')),
                  TextButton(
                      onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ClassDetailPage(
                                    schoolClass: schoolClass,
                                    currentUser: widget.currentUser,
                                    userRole: 'teacher',
                                    teacherProfile: widget.teacher)),
                          ),
                      child: const Text('Details')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
