import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/ui/manage_class_students_page.dart'; // New import
import 'package:school_management/widgets/loading_overlay.dart';

class ViewStudentsInClassPage extends StatefulWidget {
  final SchoolClass schoolClass;

  const ViewStudentsInClassPage({super.key, required this.schoolClass});

  @override
  State<ViewStudentsInClassPage> createState() =>
      _ViewStudentsInClassPageState();
}

class _ViewStudentsInClassPageState extends State<ViewStudentsInClassPage> {
  final AuthService _authService = AuthService();
  List<StudentTable>? _students;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final students =
          await _authService.fetchStudentsForClass(widget.schoolClass.classId);
      if (mounted) {
        setState(() {
          _students = students;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Students in ${widget.schoolClass.className}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudents,
            tooltip: 'Refresh Students',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading students...',
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to the student management page for this class
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ManageClassStudentsPage(schoolClass: widget.schoolClass),
            ),
          );
          if (result == true) _fetchStudents(); // Refresh if changes were made
        },
        label: const Text('Manage Students'),
        icon: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_students == null || _students!.isEmpty) {
      return const Center(child: Text('No students assigned to this class.'));
    }

    return ListView.builder(
      itemCount: _students!.length,
      itemBuilder: (context, index) {
        final student = _students![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(student.fullName[0]),
            ),
            title: Text(student.fullName),
            subtitle: Text(student.email),
            // You can add more details or actions here
          ),
        );
      },
    );
  }
}
