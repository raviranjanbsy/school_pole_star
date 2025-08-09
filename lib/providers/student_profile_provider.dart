// d:\work\flutter\Sample_app\Flutter-School-Management-System-main\flutter\school_management\lib\providers\student_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/model_class/Alluser.dart'; // Add this import
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/providers/auth_provider.dart'; // Add this import
import 'package:school_management/services/auth_service.dart'; // Import AuthService
import 'package:firebase_auth/firebase_auth.dart';

// FutureProvider to fetch the StudentTable profile
final currentStudentProfileProvider =
    FutureProvider<StudentTable?>((ref) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return null;
  }

  // Get AuthService instance from its provider
  final authService = ref.watch(authServiceProvider);

  try {
    // Fetch the Alluser data first to get the name/image for profile creation if needed
    // This assumes Alluser data is already loaded or can be fetched.
    // For simplicity, we'll assume Alluser data is available or can be derived.
    // In a real app, you might need a way to get the Alluser object here.
    // For now, we'll pass a dummy Alluser if it's not readily available,
    // as getOrCreateStudentProfile primarily uses firebaseUser.
    // A more robust solution would involve passing the Alluser from the login flow.
    final dummyAllUser = Alluser(
      // Provide 'username' parameter
      uid: currentUser.uid,
      email: currentUser.email!,
      name: currentUser.displayName ?? 'Student',
      role: 'student',
      username: currentUser.email ?? 'unknown', // Added username
    );

    final studentProfile =
        await authService.getOrCreateStudentProfile(currentUser, dummyAllUser);
    return studentProfile;
  } catch (e) {
    print("Error fetching student profile in provider: $e");
    throw Exception('Failed to load student profile: $e');
  }
});
