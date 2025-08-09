import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absentExcused, absentUnexcused, late, holiday }

class AttendanceRecord extends Equatable {
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final DateTime date;
  final AttendanceStatus status;

  const AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.date,
    required this.status,
  });

  @override
  List<Object?> get props =>
      [studentId, studentName, classId, className, date, status];

  // Helper to convert string from Firestore to Enum
  static AttendanceStatus _statusFromString(String status) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => AttendanceStatus.absentUnexcused, // A safe default
    );
  }

  // Factory constructor to create an instance from raw data.
  // This is what auth_service.dart is looking for.
  factory AttendanceRecord.fromMap(
    String statusData,
    String classId,
    String studentUid, // The service uses studentUid
    String dateKey, {
    String studentName = 'Unknown Student',
    String className = 'Unknown Class',
  }) {
    return AttendanceRecord(
      studentId: studentUid, // Map studentUid to studentId
      studentName: studentName,
      classId: classId,
      className: className,
      date: DateTime.parse(dateKey),
      status: _statusFromString(statusData),
    );
  }

  // Method to convert instance to a map for Firestore
  Map<String, dynamic> toMap() {
    // We only store the status, as other info is part of the path
    return {
      'status': status.name, // 'present', 'absent', etc.
    };
  }

  AttendanceRecord copyWith({
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    DateTime? date,
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}
