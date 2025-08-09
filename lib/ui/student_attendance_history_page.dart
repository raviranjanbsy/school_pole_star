import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/attendance_record.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:school_management/widgets/gradient_container.dart';

class StudentAttendanceHistoryPage extends StatefulWidget {
  final String studentUid;
  final String studentName;
  final String classId;

  const StudentAttendanceHistoryPage({
    super.key,
    required this.studentUid,
    required this.studentName,
    required this.classId,
  });

  @override
  State<StudentAttendanceHistoryPage> createState() =>
      _StudentAttendanceHistoryPageState();
}

class _StudentAttendanceHistoryPageState
    extends State<StudentAttendanceHistoryPage> {
  final AuthService _authService = AuthService();
  late Future<List<AttendanceRecord>> _attendanceHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  void _loadAttendanceHistory() {
    _attendanceHistoryFuture = _authService.fetchStudentAttendanceForClass(
      widget.studentUid,
      widget.classId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('${widget.studentName}\'s Attendance'),
          subtitle: Text('Class ID: ${widget.classId}'),
        ),
        body: FutureBuilder<List<AttendanceRecord>>(
          future: _attendanceHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No attendance records found for this student.'),
              );
            }

            final records = snapshot.data!;

            // Process data for the chart: count statuses
            final presentCount =
                records.where((r) => r.status == 'present').length;
            final absentCount =
                records.where((r) => r.status == 'absent').length;
            final lateCount = records.where((r) => r.status == 'late').length;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Attendance Chart
                  SizedBox(
                    height: 200, // Adjust height as needed
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: presentCount.toDouble(),
                            title: 'Present',
                            color: Colors.green,
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: absentCount.toDouble(),
                            title: 'Absent',
                            color: Colors.red,
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: lateCount.toDouble(),
                            title: 'Late',
                            color: Colors.orange,
                            radius: 50,
                          ),
                        ],
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Detailed Attendance List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(DateFormat.yMMMd().format(record.date)),
                            trailing: Text(record.status.toUpperCase(),
                                style: TextStyle(
                                    color: record.status == 'present'
                                        ? Colors.green
                                        : Colors.red)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
