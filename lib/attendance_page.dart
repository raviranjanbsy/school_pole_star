import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:table_calendar/table_calendar.dart'; // Import table_calendar
import 'package:school_management/model_class/attendance_record.dart';
import 'package:school_management/widgets/gradient_container.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<List<AttendanceRecord>>
      _attendanceFuture; // Holds the initial fetch result

  // Calendar Format
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // Selected Day
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay; // Nullable
  // Events map for the calendar
  final Map<DateTime, List<AttendanceRecord>> _events = {};
  List<AttendanceRecord> _selectedDayEvents =
      []; // Events for the currently selected day

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Initialize selected day to today
    _attendanceFuture = _fetchAttendance();
  }

  // Helper to get hash code for DateTime (required by LinkedHashMap for internal use in TableCalendar)
  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  // Helper to get events for a specific day (required by TableCalendar)
  List<AttendanceRecord> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  // Helper to group records by date for the calendar
  void _groupRecordsForCalendar(List<AttendanceRecord> records) {
    _events.clear(); // Clear previous events
    for (var record in records) {
      final date = DateFormat('yyyy-MM-dd').parse(record.attendanceDate);
      if (_events[date] == null) {
        _events[date] = [];
      }
      _events[date]!.add(record);
    }
    // Update selected day events if a day is already selected
    if (_selectedDay != null) {
      _selectedDayEvents = _getEventsForDay(_selectedDay!);
    }
  }

  // Callback for when a day is selected on the calendar
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedDayEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  Future<List<AttendanceRecord>> _fetchAttendance() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in.");
    }

    final ref = FirebaseDatabase.instance.ref('attendance/${currentUser.uid}');
    final snapshot = await ref.orderByKey().get(); // Order by date

    if (snapshot.exists && snapshot.value != null) {
      final attendanceMap = Map<String, dynamic>.from(snapshot.value as Map);
      final List<AttendanceRecord> records = [];
      attendanceMap.forEach((date, recordData) {
        final recordMap = Map<String, dynamic>.from(recordData as Map);
        records.add(AttendanceRecord.fromMap(recordMap, date));
      });
      // No need to sort here if we're grouping for calendar and then displaying selected day events
      // Sorting might be useful if you display a flat list below the calendar for all records.
      return records;
    } else {
      return []; // Return an empty list if no records are found
    }
  }

  // Function to refresh the profile data
  void _refreshAttendance() {
    // Clear events and selected day events to show loading state
    _events.clear();
    _selectedDayEvents = [];
    setState(() {
      _attendanceFuture = _fetchAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAttendance,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: GradientContainer(
        child: FutureBuilder<List<AttendanceRecord>>(
          future: _attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No attendance records found.'));
            }

            // Data is available, process it for the calendar
            _groupRecordsForCalendar(snapshot.data!);

            return Column(
              children: [
                TableCalendar<AttendanceRecord>(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2050, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader:
                      _getEventsForDay, // Use eventLoader to highlight dates
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary, // Customize marker color
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible:
                        false, // Hide format button if not needed
                    titleCentered: true,
                  ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final record = _selectedDayEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        elevation: 2,
                        child: ListTile(
                          title: Text('Status: ${record.attendanceStatus}'),
                          subtitle: Text(
                              'Class: ${record.className}, Section: ${record.section}'),
                          trailing: _buildStatusChip(record.attendanceStatus),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusLower = status.toLowerCase();
    final color = statusLower == 'present'
        ? Colors.green
        : statusLower == 'absent'
            ? Colors.red
            : statusLower == 'late'
                ? Colors.orange
                : Colors.grey;
    final icon = statusLower == 'present'
        ? Icons.check_circle
        : statusLower == 'absent'
            ? Icons.cancel
            : statusLower == 'late'
                ? Icons.watch_later
                : Icons.help;

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        status,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
