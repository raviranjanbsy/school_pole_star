import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/widgets/gradient_container.dart';

class AssignStudentToClassPage extends StatefulWidget {
  const AssignStudentToClassPage({super.key});

  @override
  State<AssignStudentToClassPage> createState() =>
      _AssignStudentToClassPageState();
}

class _AssignStudentToClassPageState extends State<AssignStudentToClassPage> {
  final AuthService _authService = AuthService();

  List<StudentTable>? _students;
  List<SchoolClass>? _classes;
  Set<String> _selectedStudentUids =
      {}; // Changed to Set for multiple selections
  String? _selectedClassId;

  bool _isLoadingData = true;
  bool _isAssigning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });
    try {
      // Fetch students and classes concurrently
      final results = await Future.wait([
        _authService.fetchAllStudents(),
        _authService.fetchAllSchoolClasses(),
      ]);
      if (mounted) {
        setState(() {
          _students = results[0] as List<StudentTable>;
          _classes = results[1] as List<SchoolClass>;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _assignClass() async {
    if (_selectedStudentUids.isEmpty || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one student and a class.')),
      );
      return;
    }

    setState(() => _isAssigning = true); // Keep this for overall loading

    try {
      await _authService.assignStudentsToClass(_selectedStudentUids.toList(),
          _selectedClassId!); // Use new bulk method
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Students successfully assigned to class!'),
          backgroundColor: Colors.green,
        ),
      );
      // Clear class selection after successful assignment
      setState(() {
        _selectedClassId = null; // Only clear the class selection
        _selectedStudentUids.clear(); // Clear selected students
      });
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assignment failed: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  Future<void> _unassignStudent(StudentTable student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unassignment'),
        content: Text(
            'Are you sure you want to unassign "${student.fullName}" from their current class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unassign', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(
          () => _isAssigning = true); // Use _isAssigning for this action too
      try {
        await _authService.removeStudentFromClass(student.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} successfully unassigned!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh the list to reflect the change
      } on AuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unassign: ${e.message}')),
        );
      } finally {
        if (mounted) {
          setState(() => _isAssigning = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Assign Student to Class'),
        ),
        body: LoadingOverlay(
          isLoading: _isAssigning,
          message: 'Assigning...',
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
    }
    if (_students == null || _classes == null) {
      return const Center(child: Text('No students or classes found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display total and unassigned student counts
          Text(
            'Total Students: ${_students!.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Unassigned Students: ${_students!.where((s) => s.classId == null || s.classId!.isEmpty).length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Select All Checkbox
          if (_students != null && _students!.isNotEmpty)
            CheckboxListTile(
              title: const Text('Select All Students'),
              value: _selectedStudentUids.length == _students!.length,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedStudentUids.addAll(_students!.map((s) => s.uid));
                  } else {
                    _selectedStudentUids.clear();
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 12), // Spacing after select all

          // Student List with Checkboxes
          Expanded(
            child: ListView.builder(
              itemCount: _students!.length,
              itemBuilder: (context, index) {
                final student = _students![index];
                final assignedClass = _classes?.firstWhere(
                  (cls) => cls.classId == student.classId,
                  orElse: () {
                    // Return a dummy SchoolClass or null if not found
                    return SchoolClass(
                      classId: '',
                      className: 'Unknown Class',
                      subjects: const [],
                      status: 'unknown',
                      createdAt: 0,
                      teacherId: null,
                      teacherName: null,
                    );
                  },
                );

                String subtitleText = student.email;
                // Check if assignedClass is not the dummy one and has a valid classId
                if (assignedClass != null && assignedClass.classId.isNotEmpty) {
                  subtitleText += '\nAssigned to: ${assignedClass.className}';
                } else if (student.classId != null &&
                    student.classId!.isNotEmpty) {
                  subtitleText +=
                      '\nAssigned to: ${student.classId} (Class details not found)';
                } else {
                  subtitleText += '\nNot assigned to a class';
                }

                // Determine if the unassign option should be available
                // 'canUnassign' is a local variable within this itemBuilder's scope.
                final bool canUnassign =
                    student.classId != null && student.classId!.isNotEmpty;

                return CheckboxListTile(
                  title: Text(student.fullName),
                  subtitle:
                      Text(subtitleText), // Display email and assigned class
                  value: _selectedStudentUids
                      .contains(student.uid), // Check if student is selected
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedStudentUids.add(student.uid);
                      } else {
                        _selectedStudentUids.remove(student.uid);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: canUnassign
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'unassign') {
                              _unassignStudent(student);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'unassign',
                              child: Text('Unassign from Class'),
                            ),
                          ],
                        )
                      : null, // No menu if not assigned
                );
              },
            ),
          ),
          const SizedBox(height: 24), // Spacing after student list

          // Class Dropdown
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            decoration: const InputDecoration(
              labelText: 'Select Class',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_outlined),
            ),
            hint: const Text('Choose a class'),
            items: _classes!.map((schoolClass) {
              return DropdownMenuItem<String>(
                value: schoolClass.classId,
                child: Text(schoolClass.className),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClassId = value;
              });
            },
          ),
          const SizedBox(height: 32), // Spacing after class dropdown

          // Display number of selected students
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Selected Students: ${_selectedStudentUids.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Assign Button
          ElevatedButton.icon(
            onPressed:
                (_selectedStudentUids.isEmpty || _selectedClassId == null)
                    ? null
                    : _assignClass,
            icon: const Icon(Icons.assignment_ind),
            label: const Text('Assign to Class'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
