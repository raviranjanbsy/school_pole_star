import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/model_class/attendance_record.dart';

/// A model to summarize a student's attendance for reporting purposes.
class StudentAttendanceSummary {
  final StudentTable student;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final List<AttendanceRecord>
      records; // Optional: to show detailed records if needed

  StudentAttendanceSummary({
    required this.student,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.records = const [],
  });
}
