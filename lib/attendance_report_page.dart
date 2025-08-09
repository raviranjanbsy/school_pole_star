import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_management/model_class/student_attendance_summary.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/widgets/gradient_container.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  String? _selectedClass;
  String? _selectedSection;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<StudentAttendanceSummary>? _reportSummaries;

  // Dummy data for classes and sections (replace with dynamic data from DB if available)
  final List<String> _classes = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12'
  ];
  final List<String> _sections = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _selectedClass = _classes.first;
    _selectedSection = _sections.first;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate; // Adjust end date if start date is after it
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate; // Adjust start date if end date is before it
          }
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (_selectedClass == null || _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class and section.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _reportSummaries = null;
    });

    try {
      final summaries = await _authService.generateAttendanceReport(
        _selectedClass!,
        _selectedSection!,
        _startDate,
        _endDate,
      );
      setState(() {
        _reportSummaries = summaries;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportReportToCsv() async {
    if (_reportSummaries == null || _reportSummaries!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data to export.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<List<dynamic>> csvData = [];

      // Add headers
      csvData.add([
        'Full Name',
        'Email',
        'Student ID',
        'Class',
        'Section',
        'Present Count',
        'Absent Count',
        'Late Count',
        'Report Start Date',
        'Report End Date'
      ]);

      // Add data rows
      for (var summary in _reportSummaries!) {
        csvData.add([
          summary.student.fullName ?? 'N/A',
          summary.student.email ?? 'N/A',
          summary.student.studentId ?? 'N/A',
          summary.student.studentClass ?? 'N/A',
          summary.student.section ?? 'N/A',
          summary.presentCount,
          summary.absentCount,
          summary.lateCount,
          DateFormat('yyyy-MM-dd').format(_startDate),
          DateFormat('yyyy-MM-dd').format(_endDate),
        ]);
      }

      String csvString = const ListToCsvConverter().convert(csvData);

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/attendance_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report exported to $path')),
      );
      OpenFilex.open(path); // Open the file
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export report: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalStudents = _reportSummaries?.length ?? 0;
    int totalPresent =
        _reportSummaries?.fold(0, (sum, item) => sum + item.presentCount) ?? 0;
    int totalAbsent =
        _reportSummaries?.fold(0, (sum, item) => sum + item.absentCount) ?? 0;
    int totalLate =
        _reportSummaries?.fold(0, (sum, item) => sum + item.lateCount) ?? 0;

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Attendance Report'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _reportSummaries != null ? _exportReportToCsv : null,
              tooltip: 'Export to CSV',
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Generating report...',
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedClass,
                            decoration:
                                const InputDecoration(labelText: 'Class'),
                            items: _classes
                                .map((cls) => DropdownMenuItem(
                                    value: cls, child: Text(cls)))
                                .toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedClass = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSection,
                            decoration:
                                const InputDecoration(labelText: 'Section'),
                            items: _sections
                                .map((sec) => DropdownMenuItem(
                                    value: sec, child: Text(sec)))
                                .toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedSection = newValue;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                                'Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                                'End Date: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generateReport,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Generate Report'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _reportSummaries == null
                        ? const Center(
                            child: Text('Select criteria and generate report.'))
                        : _reportSummaries!.isEmpty
                            ? const Center(
                                child: Text(
                                    'No students found for this class/section or period.'))
                            : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: Card(
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Total Students: $totalStudents',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('Total Present: $totalPresent',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.green)),
                                            Text('Total Absent: $totalAbsent',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.red)),
                                            Text('Total Late: $totalLate',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.orange)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _reportSummaries!.length,
                                      itemBuilder: (context, index) {
                                        final summary =
                                            _reportSummaries![index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 4),
                                          child: ListTile(
                                            title: Text(
                                                summary.student.fullName ??
                                                    'Unknown Student'),
                                            subtitle: Text(
                                                'Present: ${summary.presentCount}, Absent: ${summary.absentCount}, Late: ${summary.lateCount}'),
                                            // You could add an onTap to show detailed records for this student
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
