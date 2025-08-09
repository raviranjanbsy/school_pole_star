import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/model_class/attendance_record.dart';
import 'package:school_management/providers/auth_provider.dart';

// This provider will fetch the attendance records for a student in a specific class.
// We use a family provider to pass the classId.
final studentAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, String>((ref, classId) {
      final authService = ref.watch(authServiceProvider);
      final studentUid = authService.getAuth().currentUser?.uid;

      if (studentUid == null) {
        // If there's no logged-in user, return an empty list.
        return Future.value([]);
      }

      // Fetch the attendance data using the auth service.
      return authService.fetchStudentAttendanceForClass(studentUid, classId);
    });
