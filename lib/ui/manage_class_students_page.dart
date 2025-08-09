import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/teacher/class_student_list_page.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/widgets/gradient_container.dart';

class ManageClassStudentsPage extends StatefulWidget {
  final SchoolClass schoolClass;

  const ManageClassStudentsPage({super.key, required this.schoolClass});

  @override
  State<ManageClassStudentsPage> createState() =>
      _ManageClassStudentsPageState();
}

class _ManageClassStudentsPageState extends State<ManageClassStudentsPage> {
  final AuthService _authService = AuthService();
  List<StudentTable>? _allStudents;
  List<StudentTable>? _filteredStudents; // New list for filtered results
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedStudentUids = {}; // UIDs of students selected for action
  bool _isLoading = true;
  bool _isProcessing = false; // For assign/unassign actions
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final students = await _authService.fetchAllStudents();
      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students; // Initialize filtered list
          // Pre-select students already assigned to this class for convenience
          _selectedStudentUids = students
              .where((s) => s.classId == widget.schoolClass.classId)
              .map((s) => s.uid)
              .toSet();
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted)
        setState(
            () => _error = 'An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_allStudents != null) {
        _filteredStudents = _allStudents!.where((student) {
          final nameMatches = student.fullName.toLowerCase().contains(query);
          final emailMatches = student.email.toLowerCase().contains(query);
          return nameMatches || emailMatches;
        }).toList();
      }
    });
  }

  void _toggleStudentSelection(StudentTable student) {
    setState(() {
      if (_selectedStudentUids.contains(student.uid)) {
        _selectedStudentUids.remove(student.uid);
      } else {
        _selectedStudentUids.add(student.uid);
      }
    });
  }

  Future<void> _assignSelectedStudents() async {
    final studentsToAssign = _selectedStudentUids.where((uid) {
      // Only assign students not already assigned to this class
      final student = _allStudents?.firstWhere((s) => s.uid == uid);
      return student != null && student.classId != widget.schoolClass.classId;
    }).toList();

    if (studentsToAssign.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No new students selected to assign to this class.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await _authService.assignStudentsToClass(
          studentsToAssign, widget.schoolClass.classId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully assigned ${studentsToAssign.length} students.')),
        );
        _loadAllStudents(); // Refresh data to show updated assignments
      }
    } on AuthException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assignment failed: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _unassignSelectedStudents() async {
    final studentsToUnassign = _selectedStudentUids.where((uid) {
      // Only unassign students currently assigned to this class
      final student = _allStudents?.firstWhere((s) => s.uid == uid);
      return student != null && student.classId == widget.schoolClass.classId;
    }).toList();

    if (studentsToUnassign.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No students selected to unassign from this class.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Loop through and unassign each student.
      // A bulk unassign method in AuthService would be more efficient for very large lists.
      for (String uid in studentsToUnassign) {
        await _authService.removeStudentFromClass(uid);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully unassigned ${studentsToUnassign.length} students.')),
        );
        _loadAllStudents(); // Refresh data to show updated assignments
      }
    } on AuthException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unassignment failed: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Students for ${widget.schoolClass.className}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View Class Roster',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassStudentListPage(
                      schoolClass: widget.schoolClass,
                      currentUserRole: 'admin'),
                ),
              );
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isProcessing,
        message: _isLoading ? 'Loading students...' : 'Processing...',
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_filteredStudents == null || _allStudents!.isEmpty) {
      return const Center(child: Text('No students found in the system.'));
    }

    // Case 2: Students exist in the system, but none match the current filter/search
    if (_filteredStudents!.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return const Center(child: Text('No students match your search.'));
      }
      // This case should ideally be caught by the first condition if _allStudents was empty.
      return const Center(child: Text('No students to display.'));
    }

    // Calculate summary counts
    final totalStudentsInSystem = _allStudents!.length;
    final assignedToThisClass = _allStudents!
        .where((s) => s.classId == widget.schoolClass.classId)
        .length;

    return ListView(
      children: [
        // Summary Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildSummaryRow('Total Students in System:',
                      totalStudentsInSystem.toString()),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      'Assigned to this Class:', assignedToThisClass.toString(),
                      color: Colors.green.shade700),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: TextField(
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
        ),
        // Add "Select All" checkbox for filtered results
        if (_filteredStudents != null && _filteredStudents!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CheckboxListTile(
              title: const Text('Select All (Filtered)'),
              // The checkbox is checked if all filtered students are in the selection set.
              value: _filteredStudents!.isNotEmpty &&
                  _selectedStudentUids.containsAll(
                      _filteredStudents!.map((s) => s.uid).toSet()),
              onChanged: (bool? value) {
                setState(() {
                  final filteredUids =
                      _filteredStudents!.map((s) => s.uid).toSet();
                  if (value == true) {
                    _selectedStudentUids.addAll(filteredUids);
                  } else {
                    _selectedStudentUids.removeAll(filteredUids);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ListView.builder(
          shrinkWrap: true, // Allows the ListView to size itself to its content
          physics:
              const NeverScrollableScrollPhysics(), // Disables scrolling for the inner list
          itemCount: _filteredStudents!.length,
          itemBuilder: (context, index) {
            final student = _filteredStudents![index];
            final bool isAssignedToThisClass =
                student.classId == widget.schoolClass.classId;
            final bool isAssignedToAnotherClass = student.classId != null &&
                student.classId!.isNotEmpty &&
                !isAssignedToThisClass;

            String subtitleText = student.email;
            Color? tileColor;
            Icon? trailingIcon;

            if (isAssignedToThisClass) {
              subtitleText += '\nCurrently assigned to THIS class';
              tileColor = Colors.green.shade50;
              trailingIcon =
                  const Icon(Icons.check_circle, color: Colors.green);
            } else if (isAssignedToAnotherClass) {
              subtitleText +=
                  '\nAssigned to another class (ID: ${student.classId})';
              tileColor = Colors.orange.shade50;
              trailingIcon = const Icon(Icons.info, color: Colors.orange);
            } else {
              subtitleText += '\nNot assigned to any class';
              tileColor = Colors.grey.shade50;
              trailingIcon = const Icon(Icons.person_add, color: Colors.blue);
            }

            return Card(
              color: tileColor, // Apply background color to the card
              margin:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: CheckboxListTile(
                title: Text(student.fullName),
                subtitle: Text(subtitleText),
                value: _selectedStudentUids.contains(student.uid),
                onChanged: (bool? value) => _toggleStudentSelection(student),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: trailingIcon, // Use the determined icon
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _assignSelectedStudents,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign Selected'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _unassignSelectedStudents,
                  icon: const Icon(Icons.person_remove),
                  label: const Text('Unassign Selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
