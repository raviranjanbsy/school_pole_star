// d:\work\flutter\Sample_app\Flutter-School-Management-System-main\flutter\school_management\lib\providers\teacher_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// FutureProvider to fetch the TeacherProfile
final teacherProfileProvider = FutureProvider<TeacherProfile?>((ref) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return null;
  }

  try {
    final profileRef =
        FirebaseDatabase.instance.ref('teacher_profiles/${currentUser.uid}');
    final DataSnapshot snapshot = await profileRef.get();

    if (snapshot.exists && snapshot.value != null) {
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      return TeacherProfile.fromMap(userData, currentUser.uid);
    } else {
      return null; // Profile not found in database
    }
  } catch (e) {
    print("Error fetching teacher profile in provider: $e");
    // In a real app, you might want to handle this error more gracefully,
    // e.g., by showing a specific error message to the user.
    throw Exception('Failed to load teacher profile: $e');
  }
});
