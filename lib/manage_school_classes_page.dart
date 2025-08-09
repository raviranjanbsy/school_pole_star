import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:school_management/model_class/student_table.dart'; // New import for StudentTable
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/ui/manage_class_students_page.dart'; // Import the correct page
import 'dart:developer' as developer;
import 'package:school_management/widgets/gradient_container.dart';

// Define a class to hold the form data returned from the dialog
class ClassFormData {
  final String classId;
  final String className;
  final List<String> subjects;
  final String? teacherId;
  final String? teacherName;

  ClassFormData({
    required this.classId,
    required this.className,
    required this.subjects,
    this.teacherId,
    this.teacherName,
  });
}

class ManageSchoolClassesPage extends StatefulWidget {
  const ManageSchoolClassesPage({super.key});

  @override
  State<ManageSchoolClassesPage> createState() =>
      _ManageSchoolClassesPageState();
}

class _ManageSchoolClassesPageState extends State<ManageSchoolClassesPage> {
  final AuthService _authService = AuthService();
  List<SchoolClass>? _classes;
  List<StudentTable>? _allStudents; // New list to hold all students
  List<TeacherProfile>? _teachers; // List of all teachers for dropdown
  List<SchoolClass>? _allClassesForOverview; // For classroom overview
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<SchoolClass>? _filteredClasses; // New list for filtered classes
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterClasses);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterClasses);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    developer.log('[_loadData] Fetching all school classes...');
    try {
      final classes = await _authService.fetchAllSchoolClasses();
      developer.log('[_loadData] Fetched ${classes.length} classes.');

      developer.log('[_loadData] Fetching all teacher profiles...');
      final teachers = await _authService.fetchAllTeachers();

      developer.log('[_loadData] Fetching all student profiles...');
      final students =
          await _authService.fetchAllStudents(); // Fetch all students
      setState(() {
        _classes = classes;
        _teachers = teachers;
        _allClassesForOverview =
            classes; // Use the fetched classes for overview
        _allStudents = students; // Store all students
        _filteredClasses = classes; // Initialize filtered list with all classes
      });
      developer.log(
          '[_loadData] Data loaded successfully. Teachers count: ${_teachers?.length}');
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
      developer.log('[_loadData] AuthException: ${e.message}');
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: ${e.toString()}';
      });
      developer.log('[_loadData] Unexpected error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
      developer.log('[_loadData] Loading finished. _isLoading: $_isLoading');
    }
  }

  void _refreshData() {
    _loadData();
  }

  void _filterClasses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_classes != null) {
        _filteredClasses = _classes!.where((schoolClass) {
          final classNameMatches =
              schoolClass.className.toLowerCase().contains(query);
          // Check if any subject in the list matches the query
          final subjectMatches =
              schoolClass.subjects.any((s) => s.toLowerCase().contains(query));
          return classNameMatches || subjectMatches;
        }).toList();
      }
    });
  }

  Future<void> _showClassFormDialog({SchoolClass? classToEdit}) async {
    developer.log(
        '[_showClassFormDialog] _teachers list count: ${_teachers?.length}');
    if (_teachers == null || _teachers!.isEmpty) {
      developer.log(
          '[_showClassFormDialog] WARNING: No teachers available for selection.');
    }

    final _formKey = GlobalKey<FormState>();

    // Find the currently assigned teacher object to pre-select in the dropdown.
    TeacherProfile? selectedTeacher;
    if (classToEdit?.teacherId != null && _teachers != null) {
      try {
        selectedTeacher =
            _teachers!.firstWhere((t) => t.uid == classToEdit!.teacherId);
      } catch (e) {
        developer.log(
            'Assigned teacher with ID ${classToEdit!.teacherId} not found in the teachers list.',
            name: 'ManageClasses');
      }
    }
    final ClassFormData? formData = await showDialog<ClassFormData?>(
      // Change return type of showDialog
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage dialog's internal state
        // Local state for the dialog
        final TextEditingController classIdController =
            TextEditingController(text: classToEdit?.classId);
        final TextEditingController classNameController =
            TextEditingController(text: classToEdit?.className);
        List<String> subjects =
            classToEdit?.subjects.toList() ?? []; // Manage subjects locally
        final TextEditingController newSubjectController =
            TextEditingController(); // For adding new subjects
        String? subjectErrorText; // For displaying subject-related errors

        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter dialogSetState) {
            // Function to add a subject to the list, defined inside StatefulBuilder
            // to have access to dialogSetState.
            void _addSubject() {
              final subject = newSubjectController.text.trim();
              if (subject.isNotEmpty && !subjects.contains(subject)) {
                dialogSetState(() {
                  subjects.add(subject);
                  subjectErrorText =
                      null; // Clear any previous subject error on successful add
                });
                newSubjectController.clear();
              } else if (subjects.contains(subject)) {
                dialogSetState(() => subjectErrorText =
                    'Subject already exists.'); // Error for duplicates
              } else {
                dialogSetState(() => subjectErrorText =
                    'Please enter a subject.'); // General error
              }
            }

            return AlertDialog(
              title: Text(classToEdit == null
                  ? 'Add New Class'
                  : 'Edit Class ${classToEdit.classId}'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    TextFormField(
                      controller: classIdController,
                      decoration: const InputDecoration(
                          labelText: 'Class ID (e.g., 10-A)'),
                      readOnly: classToEdit !=
                          null, // Class ID cannot be changed for existing classes
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a Class ID';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: classNameController,
                      decoration: const InputDecoration(
                          labelText: 'Class Name (e.g., 10)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a Class Name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TeacherProfile?>(
                      value: selectedTeacher,
                      decoration: const InputDecoration(
                        labelText: 'Assign Teacher',
                        border: OutlineInputBorder(),
                      ),
                      // Add a null item for "Not Assigned"
                      items: [
                        const DropdownMenuItem<TeacherProfile?>(
                          value: null,
                          child: Text('Not Assigned'),
                        ),
                        ...(_teachers ?? []).map((teacher) {
                          return DropdownMenuItem<TeacherProfile?>(
                            value: teacher,
                            child: Text(teacher.name),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        dialogSetState(() => selectedTeacher = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Chip display for subjects
                    Wrap(
                      spacing: 8.0,
                      children: subjects.map((subject) {
                        return Chip(
                          label: Text(subject),
                          onDeleted: () {
                            dialogSetState(() => subjects.remove(subject));
                          },
                        );
                      }).toList(),
                    ),
                    if (subjects.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('No subjects added yet.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    // Text form field and button for adding new subjects
                    TextFormField(
                      controller: newSubjectController,
                      decoration: InputDecoration(
                        labelText: 'Add Subject',
                        hintText: 'e.g., Physics',
                        errorText: subjectErrorText,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addSubject,
                        ),
                      ),
                      onFieldSubmitted: (value) => _addSubject(),
                    ),
                  ]),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext)
                      .pop(null), // Pop with null on cancel
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Create ClassFormData object with current values
                      final dataToReturn = ClassFormData(
                        classId: classIdController.text
                            .trim(), // ID is not part of the map, but needed for creation
                        className: classNameController.text
                            .trim(), // The name of the class, e.g., "Grade 10"
                        subjects: subjects, // Use the managed list of subjects
                        teacherId: selectedTeacher?.uid,
                        teacherName: selectedTeacher?.name,
                      );
                      Navigator.of(dialogContext)
                          .pop(dataToReturn); // Pop with the data
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (formData != null) {
      // Check if formData was returned (not null from cancel)
      setState(() => _isLoading = true);
      try {
        final newClass = SchoolClass(
          classId: formData.classId,
          className: formData.className,
          subjects: formData.subjects,
          status: classToEdit?.status ?? 'active', // Default to active
          createdAt:
              classToEdit?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
          teacherId: formData.teacherId,
          teacherName: formData.teacherName,
        );

        if (classToEdit == null) {
          await _authService.createSchoolClass(newClass);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Class ${newClass.classId} added successfully!')),
          );
        } else {
          await _authService.updateSchoolClass(newClass);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Class ${newClass.classId} updated successfully!')),
          );
        }
        _refreshData(); // Refresh the list after saving
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

  Future<void> _deleteClass(SchoolClass schoolClass) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete class "${schoolClass.className}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _authService.deleteSchoolClass(schoolClass.classId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Class ${schoolClass.className} deleted successfully!')),
        );
        _refreshData(); // Refresh the list after deletion
      } on AuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete class: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Builds the Classroom Overview Card displaying statistics about classes.
  Widget _buildClassroomOverviewCard() {
    if (_allClassesForOverview == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    final totalActiveClasses =
        _allClassesForOverview!.where((c) => c.status == 'active').length;
    final archivedClasses =
        _allClassesForOverview!.where((c) => c.status == 'archived').length;
    // Define "recently created" as classes created in the last 7 days
    final recentlyCreatedClasses = _allClassesForOverview!.where((c) {
      final creationDate = DateTime.fromMillisecondsSinceEpoch(c.createdAt);
      return creationDate
          .isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).length;

    // Calculate subject distribution
    final Map<String, int> subjectDistribution = {};
    for (var classroom in _allClassesForOverview!) {
      for (var subject in classroom.subjects) {
        subjectDistribution.update(subject, (value) => value + 1,
            ifAbsent: () => 1);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Classroom Overview',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Divider(),
              _buildStatRow('Total Active Classes', totalActiveClasses,
                  color: Colors.blue),
              _buildStatRow(
                  'Recently Created (last 7 days)', recentlyCreatedClasses,
                  color: Colors.purple),
              _buildStatRow('Archived Classes', archivedClasses,
                  color: Colors.orange),
              const SizedBox(height: 10),
              Text('Subject Distribution',
                  style: Theme.of(context).textTheme.titleMedium),
              ...subjectDistribution.entries
                  .map((entry) => _buildStatRow(entry.key, entry.value)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Manage School Classes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh Classes',
            ),
          ],
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Loading classes...',
          child: _buildBody(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              _showClassFormDialog(), // Call without argument to add new
          child: const Icon(Icons.add),
          tooltip: 'Add New Class',
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_filteredClasses == null || _filteredClasses!.isEmpty) {
      return const Center(child: Text('No classes found. Add a new class!'));
    }

    return ListView(
      children: [
        _buildClassroomOverviewCard(), // Display the overview card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search classes by name or subject',
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
        ListView.builder(
          shrinkWrap: true, // Allows the ListView to size itself to its content
          physics:
              const NeverScrollableScrollPhysics(), // Disables scrolling for the inner list
          itemCount: _filteredClasses!.length,
          itemBuilder: (context, index) {
            final schoolClass = _filteredClasses![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                isThreeLine: true,
                leading: CircleAvatar(
                  child: Text(schoolClass.className),
                ),
                title: Text(schoolClass.className),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${schoolClass.subjects.length} subjects | ${_allStudents?.where((s) => s.classId == schoolClass.classId).length ?? 0} students'),
                    const SizedBox(height: 4),
                    Text(
                      'Teacher: ${schoolClass.teacherName ?? 'Not Assigned'}',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
                trailing: Row(
                  // Use a Row to hold multiple trailing widgets
                  mainAxisSize:
                      MainAxisSize.min, // Important to prevent overflow
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.group), // Icon for viewing students
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageClassStudentsPage(
                                schoolClass: schoolClass),
                          ),
                        );
                      },
                      tooltip: 'Manage Students',
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showClassFormDialog(classToEdit: schoolClass);
                        } else if (value == 'delete') {
                          _deleteClass(schoolClass);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Class'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Class',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  // Keep onTap for general class details if needed, or remove if secondary actions cover all
                  // You can still use this for a general class detail view if you want,
                  // or remove it if the trailing icons cover all necessary actions.
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
