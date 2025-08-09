import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/teacher/student_profile_page.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_service.dart';

enum StudentSortType { byRollNumber, byName }

class ClassStudentListPage extends StatefulWidget {
  final SchoolClass schoolClass;
  final String currentUserRole;

  const ClassStudentListPage(
      {super.key, required this.schoolClass, required this.currentUserRole});

  @override
  State<ClassStudentListPage> createState() => _ClassStudentListPageState();
}

class _ClassStudentListPageState extends State<ClassStudentListPage> {
  final AuthService _authService = AuthService();
  late Future<List<StudentTable>> _studentsFuture;
  StudentSortType _sortType = StudentSortType.byRollNumber;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStudents() {
    _studentsFuture = _authService.fetchStudentsForClass(
      widget.schoolClass.classId,
    );
  }

  void _refreshStudents() {
    setState(() {
      _loadStudents();
    });
  }

  void _showEditRollNumberDialog(
    BuildContext context,
    StudentTable student,
    List<StudentTable> allStudents,
  ) {
    final formKey = GlobalKey<FormState>();
    final rollNumberController = TextEditingController(
      text: student.rollNumber?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Roll Number for ${student.fullName}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: rollNumberController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Roll Number',
                hintText: 'Enter a positive number',
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Empty is allowed to clear the roll number
                }
                final number = int.tryParse(value);
                if (number == null) {
                  return 'Please enter a valid number.';
                }
                if (number <= 0) {
                  return 'Roll number must be positive.';
                }
                // Check if the roll number is already taken by another student in the class.
                final isDuplicate = allStudents.any(
                  (s) => s.uid != student.uid && s.rollNumber == number,
                );
                if (isDuplicate) {
                  return 'Roll number $number is already taken.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newRollNumber = int.tryParse(rollNumberController.text);
                  try {
                    await _authService.updateStudentRollNumber(
                      studentUid: student.uid,
                      rollNumber: newRollNumber,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Roll number updated!')),
                    );
                    _refreshStudents(); // Refresh list
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Update failed: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students in ${widget.schoolClass.className}'),
        actions: [
          IconButton(
            icon: Icon(
              _sortType == StudentSortType.byRollNumber
                  ? Icons.sort_by_alpha
                  : Icons.format_list_numbered,
            ),
            tooltip:
                'Sort by ${_sortType == StudentSortType.byRollNumber ? "Name" : "Roll Number"}',
            onPressed: () {
              setState(() {
                _sortType = _sortType == StudentSortType.byRollNumber
                    ? StudentSortType.byName
                    : StudentSortType.byRollNumber;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Students',
                hintText: 'Enter name or roll number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
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
          Expanded(
            child: FutureBuilder<List<StudentTable>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No students found in this class.'),
                  );
                }

                final students = snapshot.data!;

                final filteredStudents = students.where((student) {
                  final query = _searchQuery.toLowerCase();
                  final nameMatches = student.fullName.toLowerCase().contains(
                        query,
                      );
                  final rollNumberMatches =
                      student.rollNumber?.toString().contains(query) ?? false;
                  return nameMatches || rollNumberMatches;
                }).toList();

                // Sort students based on the selected sort type.
                filteredStudents.sort((a, b) {
                  if (_sortType == StudentSortType.byRollNumber) {
                    final rollA = a.rollNumber;
                    final rollB = b.rollNumber;

                    if (rollA == null && rollB == null) {
                      return a.fullName.compareTo(
                        b.fullName,
                      ); // Secondary sort by name
                    }
                    if (rollA == null)
                      return 1; // Students without roll numbers go last
                    if (rollB == null)
                      return -1; // Students without roll numbers go last
                    return rollA.compareTo(
                      rollB,
                    ); // Sort by roll number ascending
                  } else {
                    return a.fullName.toLowerCase().compareTo(
                          b.fullName.toLowerCase(),
                        );
                  }
                });

                if (filteredStudents.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No students in this class.'
                          : 'No students match your search.',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshStudents(),
                  child: ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          onTap: () async {
                            // Await the result of the push. When the profile page is popped,
                            // this will resume.
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentProfilePage(
                                    studentProfile: student,
                                    userRole: widget.currentUserRole),
                              ),
                            );
                            // After returning, refresh the student list to show any updates.
                            _refreshStudents();
                          },
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            backgroundImage: student.imageUrl != null &&
                                    student.imageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(student.imageUrl!)
                                : null,
                            child: student.imageUrl == null ||
                                    student.imageUrl!.isEmpty
                                ? Text(
                                    student.fullName.isNotEmpty
                                        ? student.fullName[0].toUpperCase()
                                        : 'S',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('Roll No: ${student.rollNumber ?? 'N/A'}'),
                              if (student.studentId != null &&
                                  student.studentId!.isNotEmpty)
                                Text('Student ID: ${student.studentId}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_note),
                            tooltip: 'Edit Roll Number',
                            onPressed: () => _showEditRollNumberDialog(
                              context,
                              student,
                              students,
                            ),
                          ),
                          isThreeLine: student.studentId != null &&
                              student.studentId!.isNotEmpty,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
