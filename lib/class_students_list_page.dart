import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';

class ClassStudentsListPage extends StatefulWidget {
  final SchoolClass schoolClass;

  const ClassStudentsListPage({super.key, required this.schoolClass});

  @override
  State<ClassStudentsListPage> createState() => _ClassStudentsListPageState();
}

class _ClassStudentsListPageState extends State<ClassStudentsListPage> {
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
      final fetchedStudents = await _authService.fetchStudentsByClassAndSection(
        widget.schoolClass.className,
        widget.schoolClass.section,
      );
      setState(() {
        _students = fetchedStudents;
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshStudents() {
    _fetchStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Students in Class ${widget.schoolClass.className}-${widget.schoolClass.section}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStudents,
            tooltip: 'Refresh Students',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading students...',
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_students == null || _students!.isEmpty) {
      return const Center(child: Text('No students found in this class.'));
    }

    return ListView.builder(
      itemCount: _students!.length,
      itemBuilder: (context, index) {
        final student = _students![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  (student.imageUrl != null && student.imageUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(student.imageUrl!)
                      : null,
              child: (student.imageUrl == null || student.imageUrl!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(student.fullName ?? 'Unknown Student'),
            subtitle: Text(
                'Email: ${student.email ?? 'N/A'}\nStudent ID: ${student.studentId ?? 'N/A'}'),
            isThreeLine: true,
            onTap: () {
              // TODO: Navigate to student detail page if needed
            },
          ),
        );
      },
    );
  }
}
