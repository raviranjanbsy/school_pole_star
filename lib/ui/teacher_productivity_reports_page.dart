import 'package:flutter/material.dart';
import 'dart:io';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/model_class/submission.dart';
import 'package:school_management/services/auth_service.dart';
import 'dart:developer' as developer;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class TeacherProductivityReportsPage extends StatefulWidget {
  const TeacherProductivityReportsPage({super.key});

  @override
  State<TeacherProductivityReportsPage> createState() =>
      _TeacherProductivityReportsPageState();
}

class _TeacherProductivityReportsPageState
    extends State<TeacherProductivityReportsPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;

  // Data
  List<Alluser> _allUsers = [];
  List<Alluser> _teachers = [];
  List<SchoolClass> _allClasses = [];
  List<StreamItem> _allStreamItems = [];
  List<Submission> _allSubmissions = [];

  // Filter
  String? _selectedTeacherId;

  // Metrics
  int _classesAssigned = 0;
  int _assignmentsGiven = 0;
  double _averageSubmissionRate = 0.0;
  int _examsCreated = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _authService.fetchAllUsers(),
        _authService.fetchAllSchoolClasses(),
        _authService.fetchAllStreamItems(),
        _authService.fetchAllSubmissions(),
      ]);

      if (mounted) {
        setState(() {
          _allUsers = results[0] as List<Alluser>;
          _teachers =
              _allUsers.where((user) => user.role == 'teacher').toList();
          _allClasses = results[1] as List<SchoolClass>;
          _allStreamItems = results[2] as List<StreamItem>;
          _allSubmissions = results[3] as List<Submission>;
        });
      }
    } catch (e) {
      developer.log('Failed to load productivity data: $e',
          name: 'TeacherProductivity');
      if (mounted) {
        setState(() {
          _error = 'Failed to load report data.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateMetricsForTeacher(String teacherId) {
    // 1. Classes Assigned
    _classesAssigned =
        _allClasses.where((c) => c.teacherId == teacherId).length;

    // Get all class IDs for the selected teacher
    final teacherClassIds = _allClasses
        .where((c) => c.teacherId == teacherId)
        .map((c) => c.classId)
        .toSet();

    // 2. Assignments Given
    final teacherAssignments = _allStreamItems
        .where((item) =>
            teacherClassIds.contains(item.classId) && item.type == 'assignment')
        .toList();
    _assignmentsGiven = teacherAssignments.length;

    // 3. Submission Rate (Real Calculation)
    // This calculation assumes:
    // - `StreamItem` has a unique `id` field.
    // - `Alluser` (for students) has a `classId` field.
    if (_assignmentsGiven > 0) {
      double totalSubmissionRateValue = 0.0;
      int assignmentsWithStudents = 0;

      for (final assignment in teacherAssignments) {
        // Count students in the assignment's class.
        final studentCount = _allUsers
            .where(
                (u) => u.role == 'student' && u.classId == assignment.classId)
            .length;

        if (studentCount > 0) {
          // Count submissions for this specific assignment.
          final submissionCount = _allSubmissions
              .where((s) => s.assignmentId == assignment.id)
              .length;

          // Add the rate for this assignment (e.g., 0.8 for 80%)
          totalSubmissionRateValue += (submissionCount / studentCount);
          assignmentsWithStudents++;
        }
      }

      if (assignmentsWithStudents > 0) {
        // Average the rates and convert to a percentage.
        _averageSubmissionRate =
            (totalSubmissionRateValue / assignmentsWithStudents) * 100;
      } else {
        _averageSubmissionRate = 0.0;
      }
    } else {
      _averageSubmissionRate = 0.0;
    }
    // 4. Exams Created
    // Assuming 'exam' is a type in StreamItem, similar to 'assignment'
    _examsCreated = _allStreamItems
        .where((item) =>
            teacherClassIds.contains(item.classId) && item.type == 'exam')
        .length;

    setState(() {});
  }

  Future<void> _exportToCsv() async {
    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a teacher to export data.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final selectedTeacher =
          _teachers.firstWhere((t) => t.uid == _selectedTeacherId);
      final List<List<dynamic>> rows = [];

      // Header
      rows.add(['Metric', 'Value', 'Details']);

      // Data
      rows.add(['Teacher Name', selectedTeacher.name, '']);
      rows.add(['Classes Assigned', _classesAssigned, '']);
      rows.add(['Assignments Given', _assignmentsGiven, '']);
      rows.add([
        'Avg. Submission Rate (%)',
        _averageSubmissionRate.toStringAsFixed(1),
        'Based on real submission data'
      ]);
      rows.add([
        'Exam Papers Created',
        _examsCreated,
        "Based on 'exam' type stream items"
      ]);

      final String csv = const ListToCsvConverter().convert(rows);

      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/teacher_productivity_${selectedTeacher.uid}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final File file = File(path);
      await file.writeAsString(csv);

      final xfile = XFile(path,
          name:
              'teacher_report_${selectedTeacher.name.replaceAll(' ', '_')}.csv');
      await Share.shareXFiles([xfile],
          text: 'Productivity Report for ${selectedTeacher.name}');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Productivity'), actions: [
        if (_isExporting)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white)),
          )
        else
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _selectedTeacherId == null ? null : _exportToCsv,
            tooltip: 'Export to CSV',
          ),
      ]),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildTeacherSelector(),
        const SizedBox(height: 16),
        if (_selectedTeacherId != null) _buildMetricsDisplay(),
      ],
    );
  }

  Widget _buildTeacherSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedTeacherId,
      hint: const Text('Select a Teacher'),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Teacher',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_search),
      ),
      items: _teachers.map((teacher) {
        return DropdownMenuItem<String>(
          value: teacher.uid,
          child: Text(teacher.name.isNotEmpty ? teacher.name : teacher.email),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedTeacherId = value;
          });
          _calculateMetricsForTeacher(value);
        }
      },
    );
  }

  Widget _buildMetricsDisplay() {
    return Column(
      children: [
        _buildMetricCard(
          icon: Icons.class_outlined,
          title: 'Classes Assigned',
          value: _classesAssigned.toString(),
          color: Colors.blue,
        ),
        _buildMetricCard(
          icon: Icons.event_busy_outlined,
          title: 'Attendance & Leave',
          value: 'N/A',
          color: Colors.grey,
          subtitle: 'Requires teacher attendance data',
        ),
        _buildMetricCard(
          icon: Icons.assignment_ind_outlined,
          title: 'Assignments Given',
          value: _assignmentsGiven.toString(),
          color: Colors.orange,
        ),
        _buildMetricCard(
          icon: Icons.rate_review_outlined,
          title: 'Avg. Submission Rate',
          value: '${_averageSubmissionRate.toStringAsFixed(1)}%',
          color: Colors.green,
        ),
        _buildMetricCard(
          icon: Icons.history_edu_outlined,
          title: 'Exam Papers Created',
          value: _examsCreated.toString(),
          color: Colors.purple,
          subtitle: "Based on 'exam' type stream items",
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
