import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:table_calendar/table_calendar.dart';
import 'package:school_management/model_class/attendance_record.dart'; // Import AttendanceRecord
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_service.dart';
import 'dart:developer' as developer;

class TakeAttendancePage extends StatefulWidget {
  final String classId;
  final String className;

  const TakeAttendancePage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  final AuthService _authService = AuthService();
  late Future<List<StudentTable>> _studentsFuture;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  // Map<studentUid, status>
  final Map<String, AttendanceStatus> _attendanceStatus = {};
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isHoliday = false;
  List<StudentTable> _students = []; // To hold the list of students
  DateTimeRange? _selectedDateRange;
  bool _isExporting = false;
  bool _isGeneratingReport = false;

  // State for holding generated report data
  Map<String, int>? _reportSummaryData;
  Map<DateTime, int>? _absenteeTrendData;

  Map<DateTime, List<AttendanceRecord>> _events = {};

  @override
  void initState() {
    super.initState();
    final currentUser = _authService.getAuth().currentUser;
    if (currentUser == null) {
      // Handle unauthenticated user, maybe navigate back to login
      developer.log(
        'User not authenticated when trying to fetch students for attendance.',
        name: 'TakeAttendancePage',
      );
      _studentsFuture = Future.error("User not authenticated.");
      // Optionally, show a snackbar or navigate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to take attendance.'),
          ),
        );
        Navigator.of(context).pop(); // Go back to previous screen
      });
    } else {
      developer.log(
        'Fetching students for classId: ${widget.classId}',
        name: 'TakeAttendancePage',
      );
      _studentsFuture = _authService.fetchStudentsForClass(widget.classId);
      _loadAllAttendanceForCalendar(); // Load all attendance for calendar markers
      _loadAttendanceForSelectedDate();
    }
  }

  Future<void> _loadAttendanceForSelectedDate() async {
    // Clear previous statuses
    _attendanceStatus.clear();
    // Show loading state for the list
    setState(() {
      // Re-fetch students to show a loading indicator for the list part
      _studentsFuture = _authService.fetchStudentsForClass(widget.classId);
    });

    try {
      final records = await _authService.fetchAttendanceForDate(
        widget.classId,
        _selectedDate,
      );
      setState(() {
        _isEditing = records.isNotEmpty;
        // If ANY record for the day is a holiday, we treat the whole day as a holiday.
        _isHoliday =
            records.any((record) => record.status == AttendanceStatus.holiday);

        // If it's not a holiday, load the individual statuses.
        // Otherwise, the FutureBuilder will handle setting all statuses to holiday.
        if (!_isHoliday) {
          for (var record in records) {
            _attendanceStatus[record.studentId] = record.status;
          }
        }
      });
    } catch (e) {
      developer.log(
        'Failed to load attendance for date: $_selectedDate',
        name: 'TakeAttendancePage',
        error: e,
      );
      // If loading for a specific date fails, still try to load students
      _studentsFuture = _authService.fetchStudentsForClass(widget.classId);
    }
  }

  Future<void> _loadAllAttendanceForCalendar() async {
    try {
      final allAttendanceData = await _authService.fetchAllAttendanceForClass(
        widget.classId,
      );
      final Map<DateTime, List<AttendanceRecord>> newEvents = {};

      allAttendanceData.forEach((studentUid, datesMap) {
        datesMap.forEach((dateKey, status) {
          // The fromMap factory handles parsing and default values.
          final record = AttendanceRecord.fromMap(
            status,
            widget.classId,
            studentUid,
            dateKey,
            className: widget.className,
          );
          // The key for _events should be a normalized date (without time).
          final normalizedDate = DateTime.utc(
              record.date.year, record.date.month, record.date.day);
          newEvents.putIfAbsent(normalizedDate, () => []).add(record);
        });
      });
      setState(() {
        _events = newEvents;
      });
    } catch (e) {
      developer.log(
        'Failed to load all attendance for calendar: $e',
        name: 'TakeAttendancePage',
        error: e,
      );
      _studentsFuture = _authService.fetchStudentsForClass(widget.classId);
    }
  }

  void _toggleHolidayStatus() {
    setState(() {
      _isHoliday = !_isHoliday;
      if (_isHoliday) {
        // Mark all students as holiday
        for (var student in _students) {
          _attendanceStatus[student.uid] = AttendanceStatus.holiday;
        }
      } else {
        // Clear holiday status, revert to present for all
        // This allows the teacher to start taking attendance normally
        for (var student in _students) {
          _attendanceStatus[student.uid] = AttendanceStatus.present;
        }
      }
    });
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _exportToCsv() async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range first.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // 1. Fetch all necessary data
      final students = await _authService.fetchStudentsForClass(widget.classId);
      final attendanceData = await _authService.fetchAttendanceSummaryForClass(
        widget.classId,
        _selectedDateRange!.start,
        _selectedDateRange!.end,
      );

      // 2. Process data into a list of lists for the CSV
      final List<String> dateHeaders = [];
      for (var i = 0; i <= _selectedDateRange!.duration.inDays; i++) {
        final date = _selectedDateRange!.start.add(Duration(days: i));
        dateHeaders.add(DateFormat('yyyy-MM-dd').format(date));
      }

      List<List<dynamic>> csvData = [];
      // Add header row
      csvData.add(['Roll No', 'Student Name', ...dateHeaders]);

      // Add a row for each student
      for (final student in students) {
        List<dynamic> row = [student.rollNumber ?? 'N/A', student.fullName];
        final studentAttendance = attendanceData[student.uid] ?? {};
        for (final dateHeader in dateHeaders) {
          final status = studentAttendance[dateHeader];
          row.add(_getShortStatus(status));
        }
        csvData.add(row);
      }

      // 3. Generate CSV file and share it
      final csvString = const ListToCsvConverter().convert(csvData);
      final directory = await getTemporaryDirectory();
      final fileName =
          'attendance_report_${widget.className.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(csvString);

      await Share.shareXFiles([XFile(path)],
          text: 'Attendance Report for ${widget.className}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _updateStatus(String studentId, AttendanceStatus status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    final attendanceToSave = _attendanceStatus.map(
      (studentId, status) => MapEntry(studentId, status.name),
    );
    try {
      await _authService.saveAttendance(
        widget.classId,
        _selectedDate,
        attendanceToSave,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Attendance updated successfully!'
                  : 'Attendance saved successfully!',
            ),
          ),
        );
        // Refresh calendar markers and stay on the page for further edits.
        await _loadAllAttendanceForCalendar();
        setState(() {
          _isEditing = true; // After saving, we are now in "edit" mode.
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Edit Attendance: ${widget.className}'
            : 'Take Attendance for ${widget.className}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _focusedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              calendarFormat: CalendarFormat.month,
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDate, selectedDay)) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDate = focusedDay;
                  });
                  _loadAttendanceForSelectedDate();
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDate = focusedDay;
              },
              eventLoader: _getEventsForDay, // Add event loader
              calendarBuilders: CalendarBuilders(
                // Customize the appearance of the markers
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;

                  final bool isHoliday = events.any((event) =>
                      event is AttendanceRecord &&
                      event.status == AttendanceStatus.holiday);

                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isHoliday ? Colors.purple : Colors.blue[700],
                        shape: BoxShape.circle,
                      ),
                      width: 8.0,
                      height: 8.0,
                    ),
                  );
                },
                // You can also customize other parts like:
                // selectedBuilder, todayBuilder, defaultBuilder, etc.
              ),
            ),
            const Divider(),
            _buildReportExporter(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: OutlinedButton.icon(
                icon: Icon(
                    _isHoliday ? Icons.cancel_outlined : Icons.celebration),
                label:
                    Text(_isHoliday ? 'Clear Holiday' : 'Mark Day as Holiday'),
                onPressed: _students.isEmpty ? null : _toggleHolidayStatus,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isHoliday
                      ? Colors.grey[700]
                      : Theme.of(context).primaryColor,
                  side: BorderSide(
                    color: _isHoliday
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            FutureBuilder<List<StudentTable>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No students found in this class.'),
                  );
                }

                final students = snapshot.data!;
                _students = students; // Store for use in _toggleHolidayStatus

                // Initialize statuses based on whether it's a holiday or not
                if (_isHoliday) {
                  for (var student in students) {
                    _attendanceStatus[student.uid] = AttendanceStatus.holiday;
                  }
                } else {
                  // Initialize all students as 'present' by default if no record exists
                  for (var student in students) {
                    _attendanceStatus.putIfAbsent(
                        student.uid, () => AttendanceStatus.present);
                  }
                }

                if (_isHoliday) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('This day is marked as a holiday.',
                          style: TextStyle(fontSize: 16, color: Colors.purple)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatusRadio(
                                  'Present',
                                  AttendanceStatus.present,
                                  student.uid,
                                  Colors.green,
                                ),
                                _buildStatusRadio(
                                  'Absent',
                                  AttendanceStatus.absentUnexcused,
                                  student.uid,
                                  Colors.red,
                                ),
                                _buildStatusRadio(
                                  'Late',
                                  AttendanceStatus.late,
                                  student.uid,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed:
              _isSaving || _attendanceStatus.isEmpty ? null : _saveAttendance,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(_isEditing ? 'Update Attendance' : 'Save Attendance'),
        ),
      ),
    );
  }

  Widget _buildStatusRadio(
    String title,
    AttendanceStatus value,
    String studentId,
    Color color,
  ) {
    return Flexible(
      child: RadioListTile<AttendanceStatus>(
        title: Text(title, style: TextStyle(color: color)),
        value: value,
        groupValue: _attendanceStatus[studentId],
        onChanged: (AttendanceStatus? newValue) {
          if (newValue != null) {
            _updateStatus(studentId, newValue);
          }
        },
        activeColor: color,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // Function to provide events to the calendar
  List<AttendanceRecord> _getEventsForDay(DateTime day) {
    // Normalize the day to remove time components for accurate map lookup
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Widget _buildReportExporter() {
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Export Report',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.date_range_outlined, color: Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedDateRange == null
                        ? 'Select a date range'
                        : '${DateFormat.yMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMd().format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: _selectDateRange,
                  tooltip: 'Select Date Range',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_for_offline_outlined),
                label: Text(_isExporting ? 'Exporting...' : 'Export to CSV'),
                onPressed: _isExporting || _selectedDateRange == null
                    ? null
                    : _exportToCsv,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getShortStatus(String? status) {
    if (status == null) return '-'; // No record for this day
    final statusEnum = AttendanceStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => AttendanceStatus.absentUnexcused);
    switch (statusEnum) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absentUnexcused:
        return 'A';
      case AttendanceStatus.absentExcused:
        return 'AE';
      case AttendanceStatus.late:
        return 'L';
      case AttendanceStatus.holiday:
        return 'H';
    }
  }
}
