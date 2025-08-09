import 'package:flutter/material.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'dart:developer' as developer;

class AssignClassTeacherPage extends StatefulWidget {
  const AssignClassTeacherPage({super.key});

  @override
  State<AssignClassTeacherPage> createState() => _AssignClassTeacherPageState();
}

class _AssignClassTeacherPageState extends State<AssignClassTeacherPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<SchoolClass> _allClasses = [];
  List<TeacherProfile> _allTeachers = [];
  String? _error;

  // Map<classId, teacherId>
  final Map<String, String?> _assignments = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final classes = await _authService.fetchAllSchoolClasses();
      final teachers = await _authService.fetchAllTeachers();
      setState(() {
        _allClasses = classes;
        _allTeachers = teachers;
        // Populate the initial assignments from the fetched class data
        for (var schoolClass in classes) {
          _assignments[schoolClass.classId] = schoolClass.teacherId;
        }
      });
    } catch (e) {
      developer.log('Failed to load data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAssignments() async {
    setState(() => _isLoading = true);
    try {
      final List<Future<void>> updateFutures = [];

      for (var schoolClass in _allClasses) {
        final newTeacherId = _assignments[schoolClass.classId];
        // Only update if the teacher assignment has changed
        if (schoolClass.teacherId != newTeacherId) {
          final teacher = newTeacherId != null
              ? _allTeachers.firstWhere((t) => t.uid == newTeacherId)
              : null;

          final updatedClass = schoolClass.copyWith(
            teacherId: newTeacherId,
            teacherName: teacher?.name,
          );
          // Assumes `updateSchoolClass` can handle the new fields
          updateFutures.add(_authService.updateSchoolClass(updatedClass));
        }
      }

      await Future.wait(updateFutures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignments saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInitialData(); // Refresh data to show the latest state
      }
    } catch (e) {
      developer.log('Failed to save assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save assignments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Assign Class Teacher'),
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: _buildBody(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saveAssignments,
          icon: const Icon(Icons.save),
          label: const Text('Save Assignments'),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_allClasses.isEmpty) {
      return const Center(child: Text('No classes found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding for FAB
      itemCount: _allClasses.length,
      itemBuilder: (context, index) {
        final schoolClass = _allClasses[index];
        final assignedTeacherId = _assignments[schoolClass.classId];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class: ${schoolClass.className}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: assignedTeacherId,
                  hint: const Text('Select a Teacher'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                    ..._allTeachers.map((teacher) {
                      return DropdownMenuItem<String>(
                        value: teacher.uid,
                        child: Text(teacher.name),
                      );
                    }),
                  ],
                  onChanged: (teacherId) {
                    setState(() {
                      _assignments[schoolClass.classId] = teacherId;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
