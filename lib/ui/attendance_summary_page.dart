import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'dart:developer' as developer;

class AttendanceSummaryPage extends StatefulWidget {
  final String classId;
  final String className;

  const AttendanceSummaryPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  final AuthService _authService = AuthService();
  late Future<List<StudentTable>> _studentsFuture;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, Map<String, String>> _attendanceSummary = {};
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _authService.fetchStudentsForClass(widget.classId);
    _loadAttendanceSummary();
  }

  Future<void> _loadAttendanceSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _attendanceSummary = {}; // Clear previous summary
    });
    try {
      final summary = await _authService.fetchAttendanceSummaryForClass(
        widget.classId,
        _startDate,
        _endDate,
      );
      setState(() {
        _attendanceSummary = summary;
      });
    } catch (e) {
      developer.log('Failed to load attendance summary: $e',
          name: 'AttendanceSummaryPage', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summary: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAttendanceSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Attendance Summary for ${widget.className}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _selectDateRange,
              tooltip: 'Select Date Range',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'From: ${DateFormat.yMMMd().format(_startDate)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'To: ${DateFormat.yMMMd().format(_endDate)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            _isLoadingSummary
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: FutureBuilder<List<StudentTable>>(
                      future: _studentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('No students found in this class.'));
                        }

                        final students = snapshot.data!;
                        return ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final studentAttendance =
                                _attendanceSummary[student.uid] ?? {};

                            int presentCount = 0;
                            int absentCount = 0;
                            int lateCount = 0;

                            studentAttendance.values.forEach((status) {
                              if (status == 'present') {
                                presentCount++;
                              } else if (status == 'absent') {
                                absentCount++;
                              } else if (status == 'late') {
                                lateCount++;
                              }
                            });

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              child: ListTile(
                                title: Text(student.fullName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Present: $presentCount'),
                                    Text('Absent: $absentCount'),
                                    Text('Late: $lateCount'),
                                  ],
                                ),
                                trailing: Text(
                                  'Total: ${presentCount + absentCount + lateCount}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
