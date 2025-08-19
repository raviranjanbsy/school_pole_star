import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/create_post_dialog.dart';
import 'package:school_management/widgets/gradient_container.dart';

class PreviousAssignmentsPage extends StatefulWidget {
  final String teacherId;

  const PreviousAssignmentsPage({super.key, required this.teacherId});

  @override
  State<PreviousAssignmentsPage> createState() => _PreviousAssignmentsPageState();
}

class _PreviousAssignmentsPageState extends State<PreviousAssignmentsPage> {
  final AuthService _authService = AuthService();
  Map<String, List<StreamItem>> _assignmentsBySubject = {};
  bool _isLoading = true;
  String? _error;
  List<SchoolClass> _teacherClasses = [];
  TeacherProfile? _teacherProfile;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final assignments = await _authService.fetchAssignmentsForTeacher(widget.teacherId);
      final groupedAssignments = <String, List<StreamItem>>{};
      for (var assignment in assignments) {
        final subject = assignment.subjectName ?? 'Uncategorized';
        if (groupedAssignments.containsKey(subject)) {
          groupedAssignments[subject]!.add(assignment);
        } else {
          groupedAssignments[subject] = [assignment];
        }
      }

      final teacherClasses = await _authService.fetchAssignedClasses(widget.teacherId);
      final teacherProfile = await _authService.getTeacherProfile(widget.teacherId);

      setState(() {
        _assignmentsBySubject = groupedAssignments;
        _teacherClasses = teacherClasses;
        _teacherProfile = teacherProfile;
      });
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Previous Assignments'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _assignmentsBySubject.isEmpty
                    ? const Center(child: Text('No previous assignments found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _assignmentsBySubject.keys.length,
                        itemBuilder: (context, index) {
                          final subject = _assignmentsBySubject.keys.elementAt(index);
                          final assignments = _assignmentsBySubject[subject]!;
                          return ExpansionTile(
                            title: Text(subject, style: Theme.of(context).textTheme.titleLarge),
                            children: assignments.map((assignment) {
                              return ListTile(
                                title: Text(assignment.title ?? 'No Title'),
                                subtitle: Text('Session: ${assignment.session ?? 'N/A'}'),
                                trailing: ElevatedButton(
                                  child: const Text('Reuse'),
                                  onPressed: () {
                                    _showClassSelectionDialog(assignment);
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
      ),
    );
  }

  Future<void> _showClassSelectionDialog(StreamItem assignment) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a class to post this assignment'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _teacherClasses.length,
              itemBuilder: (context, index) {
                final schoolClass = _teacherClasses[index];
                return ListTile(
                  title: Text(schoolClass.className),
                  onTap: () {
                    Navigator.of(context).pop();
                    showCreatePostDialog(
                      context,
                      _teacherProfile!,
                      schoolClass,
                      assignment,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}