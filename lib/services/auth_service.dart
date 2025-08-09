import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart'; // Added for DateFormat
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/model_class/attendance_record.dart'; // New import
import 'package:school_management/model_class/FeeStructure.dart'; // New import
import 'package:school_management/model_class/fee_category.dart'; // New import
import 'package:school_management/model_class/Payment.dart'; // New import
import 'package:school_management/model_class/Invoice.dart'; // New import
import 'package:school_management/model_class/teacher_profile.dart';
import 'dart:io';
import 'package:school_management/model_class/submission.dart';
import 'package:school_management/model_class/syllabus.dart';
import 'package:school_management/model_class/exam_schedule.dart';
import 'package:school_management/model_class/subject_mapping.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instance; // Keep this for existing functions if any

  // Expose the FirebaseAuth instance to get the current user
  FirebaseAuth getAuth() => _auth;

  // Login method
  Future<Alluser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    developer.log(
      'Attempting to sign in user: $email',
      name: 'AuthService.signInWithEmailAndPassword',
    );
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user == null) {
        throw AuthException("User not found after authentication.");
      }

      developer.log(
        'Firebase Auth successful for user: ${user.email} (UID: ${user.uid})',
        name: 'AuthService.signInWithEmailAndPassword',
      );
      final DatabaseReference userRef = _db.ref('users/${user.uid}');
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        developer.log(
          'User profile found in DB for ${user.email}',
          name: 'AuthService.signInWithEmailAndPassword',
        );
        return Alluser.fromMap(userData, user.uid);
      } else {
        developer.log(
          'User profile NOT found in DB for ${user.email}',
          name: 'AuthService.signInWithEmailAndPassword',
        );
        throw AuthException("User profile not found in Realtime Database.");
      }
    } on FirebaseAuthException catch (e) {
      developer.log(
        'FirebaseAuthException during login for $email: ${e.code}',
        name: 'AuthService.signInWithEmailAndPassword',
        error: e,
      );
      throw AuthException(
        e.message ?? "An unknown authentication error occurred.",
      );
    } catch (e) {
      developer.log(
        'General error during login for $email',
        name: 'AuthService.signInWithEmailAndPassword',
        error: e,
      );
      throw AuthException("An unexpected error occurred during login.");
    }
  }

  // Signup method
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // This method is intentionally disabled.
    // User creation should only be handled by an administrator through the
    // 'New Student Admission' or 'Manage Users' features. This prevents
    // public, un-authorized sign-ups.
    throw AuthException(
        "Self-registration is not allowed. Please contact an administrator.");
  }

  // Create user profile in Realtime Database
  Future<void> createUserProfile(Alluser userProfile) async {
    developer.log(
      'Attempting to save Alluser profile for UID: ${userProfile.uid}',
      name: 'AuthService.createUserProfile',
    );
    try {
      await _db.ref('users/${userProfile.uid}').set(userProfile.toMap());
      developer.log(
        'User profile saved successfully!',
        name: 'AuthService.createUserProfile',
      );
    } catch (error) {
      developer.log(
        'Failed to save user profile',
        name: 'AuthService.createUserProfile',
        error: error,
      );
      throw AuthException("Failed to save user profile.");
    }
  }

  /// Fetches a user profile from the database using their UID.
  /// Returns null if the profile is not found.
  Future<Alluser?> getUserProfile(String uid) async {
    developer.log(
      'Fetching user profile for UID: $uid',
      name: 'AuthService.getUserProfile',
    );
    try {
      final DatabaseReference userRef = _db.ref('users/$uid');
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        developer.log(
          'User profile found in DB for UID: $uid',
          name: 'AuthService.getUserProfile',
        );
        return Alluser.fromMap(userData, uid);
      } else {
        developer.log(
          'User profile NOT found in DB for UID: $uid',
          name: 'AuthService.getUserProfile',
        );
        return null; // Return null if profile doesn't exist
      }
    } catch (e) {
      developer.log(
        'Error fetching user profile for UID: $uid',
        name: 'AuthService.getUserProfile',
        error: e,
      );
      // It's better to return null and let the caller handle it than to throw an exception
      // that might crash the app during startup.
      return null;
    }
  }

  Future<void> loadAuthPersistence() async {
    developer.log(
      'Loading auth persistence for web.',
      name: 'AuthService.loadAuthPersistence',
    );
    try {
      await _auth.setPersistence(Persistence.LOCAL);
      developer.log(
        'Auth persistence loaded successfully.',
        name: 'AuthService.loadAuthPersistence',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        e.message ?? "Failed to load authentication persistence.",
      );
    }
  }

  Future<void> signInWithStoredCredentials() async {
    developer.log(
      'Attempting to sign in with stored credentials.',
      name: 'AuthService.signInWithStoredCredentials',
    );
    try {
      // Check if there is a current user.
      if (_auth.currentUser != null) {
        developer.log(
          'User already signed in: ${_auth.currentUser!.email}',
          name: 'AuthService.signInWithStoredCredentials',
        );
        return; // Do nothing as user is already signed in.
      }

      // Try to re-authenticate the user if credentials are persisted.
      if (_auth.currentUser == null) {
        developer.log('No stored credentials found',
            name: 'AuthService.signInWithStoredCredentials');
      }
    } on FirebaseAuthException catch (e) {
      developer.log(
        'FirebaseAuthException during auto login: ${e.code}',
        name: 'AuthService.signInWithStoredCredentials',
        error: e,
      );
      throw AuthException(
          e.message ?? "An unknown authentication error occurred.");
    }
  }

// Helper functions to get or create StudentTable and TeacherProfile
  Future<StudentTable> getOrCreateStudentProfile(
    User firebaseUser,
    Alluser allUser,
  ) async {
    developer.log(
      'Attempting to get student profile for UID: ${firebaseUser.uid}',
      name: 'AuthService.getOrCreateStudentProfile',
    );
    final profileRef = _db.ref('student_profiles/${firebaseUser.uid}');
    final DataSnapshot snapshot = await profileRef.get();

    if (snapshot.exists && snapshot.value != null) {
      developer.log(
        'Student profile found for UID: ${firebaseUser.uid}',
        name: 'AuthService.getOrCreateStudentProfile',
      );
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      return StudentTable.fromMap(userData, firebaseUser.uid);
    } else {
      // Profile not found, create a basic one
      final newStudentProfile = StudentTable(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        fullName: allUser.name,
        imageUrl: allUser.image,
        status: 'active', // Default status
      );
      try {
        developer.log(
          'Student profile not found for UID: ${firebaseUser.uid}. Creating new profile...',
          name: 'AuthService.getOrCreateStudentProfile',
        );
        await profileRef.set(newStudentProfile.toMap());
        developer.log(
          "Created new student profile for ${firebaseUser.email}",
          name: 'AuthService.getOrCreateStudentProfile',
        );
      } catch (e) {
        developer.log(
          "Error creating student profile for UID: ${firebaseUser.uid}",
          name: 'AuthService.getOrCreateStudentProfile',
          error: e,
        );
      }
      return newStudentProfile;
    }
  }

  Future<TeacherProfile> getOrCreateTeacherProfile(
    User firebaseUser,
    Alluser allUser,
  ) async {
    developer.log(
      'Attempting to get teacher profile for UID: ${firebaseUser.uid}',
      name: 'AuthService.getOrCreateTeacherProfile',
    );
    final profileRef = _db.ref('teacher_profiles/${firebaseUser.uid}');
    final DataSnapshot snapshot = await profileRef.get();

    if (snapshot.exists && snapshot.value != null) {
      developer.log(
        'Teacher profile found for UID: ${firebaseUser.uid}',
        name: 'AuthService.getOrCreateTeacherProfile',
      );
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      return TeacherProfile.fromMap(userData, firebaseUser.uid);
    } else {
      // Profile not found, create a basic one
      final newTeacherProfile = TeacherProfile(
        uid: firebaseUser.uid,
        name: allUser.name,
        email: firebaseUser.email!,
        role: allUser.role,
        imageUrl: allUser.image,
        status: 'active', // Default status
      );
      developer.log(
        'Teacher profile not found for UID: ${firebaseUser.uid}. Creating new profile...',
        name: 'AuthService.getOrCreateTeacherProfile',
      );
      await profileRef.set(newTeacherProfile.toMap());
      developer.log(
        "Created new teacher profile for ${firebaseUser.email}",
        name: 'AuthService.getOrCreateTeacherProfile',
      );
      return newTeacherProfile;
    }
  }

  // Password Reset method
  Future<void> sendPasswordResetEmail(String email) async {
    developer.log(
      'Attempting to send password reset email to: $email',
      name: 'AuthService.sendPasswordResetEmail',
    );
    try {
      await _auth.sendPasswordResetEmail(email: email);
      developer.log(
        'Password reset email sent successfully to: $email',
        name: 'AuthService.sendPasswordResetEmail',
      );
    } on FirebaseAuthException catch (e) {
      developer.log(
        'FirebaseAuthException during password reset for $email: ${e.code}',
        name: 'AuthService.sendPasswordResetEmail',
        error: e,
      );
      throw AuthException(
        e.message ?? "An unknown error occurred while sending reset email.",
      );
    } catch (e) {
      developer.log(
        'General error during password reset for $email',
        name: 'AuthService.sendPasswordResetEmail',
        error: e,
      );
      throw AuthException(
        "An unexpected error occurred during password reset.",
      );
    }
  }

  // Method to set Firebase Auth persistence
  /// Sets the authentication persistence. This is **only applicable for web platforms.**
  /// On mobile and desktop, Firebase handles persistence automatically and securely.
  /// This method will do nothing if called on a non-web platform.
  Future<void> setAuthPersistence(Persistence persistence) async {
    // Only execute this code on web platforms.
    if (kIsWeb) {
      developer.log(
        'Setting auth persistence to: $persistence for web.',
        name: 'AuthService.setAuthPersistence',
      );
      try {
        await _auth.setPersistence(persistence);
        developer.log(
          'Auth persistence set successfully.',
          name: 'AuthService.setAuthPersistence',
        );
      } on FirebaseAuthException catch (e) {
        throw AuthException(
          e.message ?? "Failed to set authentication persistence.",
        );
      }
    }
  }

  /// Updates a user's role in the 'users' node and manages profile consistency
  /// in 'student_profiles' or 'teacher_profiles' based on role change.
  Future<void> updateUserRole(Alluser user, String newRole) async {
    developer.log(
      'Attempting to update role for user: ${user.email} (UID: ${user.uid}) to $newRole',
      name: 'AuthService.updateUserRole',
    );
    try {
      final userRef = _db.ref('users/${user.uid}');
      await userRef.update({'role': newRole});
      developer.log(
        'Role updated in /users/${user.uid} to $newRole',
        name: 'AuthService.updateUserRole',
      );

      // Handle profile data consistency based on role change
      if (user.role == 'student' && newRole == 'teacher') {
        // Student becoming teacher: delete student profile, create teacher profile
        await _db.ref('student_profiles/${user.uid}').remove();
        developer.log(
          'Deleted student profile for ${user.uid}',
          name: 'AuthService.updateUserRole',
        );
        final newTeacherProfile = TeacherProfile(
          uid: user.uid,
          name: user.name,
          email: user.email,
          role: newRole,
          imageUrl: user.image,
          status: 'active', // Default status for new teacher profile
        );
        await _db
            .ref('teacher_profiles/${user.uid}')
            .set(newTeacherProfile.toMap());
        developer.log(
          'Created teacher profile for ${user.uid}',
          name: 'AuthService.updateUserRole',
        );
      } else if (user.role == 'teacher' && newRole == 'student') {
        // Teacher becoming student: delete teacher profile, create student profile
        await _db.ref('teacher_profiles/${user.uid}').remove();
        developer.log(
          'Deleted teacher profile for ${user.uid}',
          name: 'AuthService.updateUserRole',
        );
        final newStudentProfile = StudentTable(
          uid: user.uid,
          email: user.email,
          fullName: user.name,
          imageUrl: user.image,
          status: 'active', // Default status for new student profile
        );
        await _db
            .ref('student_profiles/${user.uid}')
            .set(newStudentProfile.toMap());
        developer.log(
          'Created student profile for ${user.uid}',
          name: 'AuthService.updateUserRole',
        );
      } else if (newRole == 'admin') {
        // If becoming admin, ensure no student/teacher profile exists (optional, depends on admin data model)
        await _db.ref('student_profiles/${user.uid}').remove();
        await _db.ref('teacher_profiles/${user.uid}').remove();
        developer.log(
          'Removed student/teacher profiles for admin ${user.uid}',
          name: 'AuthService.updateUserRole',
        );
      }
    } catch (e) {
      developer.log(
        'Error updating user role for UID ${user.uid}',
        name: 'AuthService.updateUserRole',
        error: e,
      );
      throw AuthException("Failed to update user role. Please try again.");
    }
  }

  /// Fetches all classes assigned to a specific teacher.
  Future<List<SchoolClass>> fetchAssignedClasses(String teacherId) async {
    developer.log(
      'Fetching classes for teacher UID: $teacherId',
      name: 'AuthService.fetchAssignedClasses',
    );
    try {
      final ref = _db.ref('classes');
      // Query the 'classes' node where the 'teacherId' child matches the provided teacher's UID.
      final snapshot =
          await ref.orderByChild('teacherId').equalTo(teacherId).get();

      final List<SchoolClass> classes = [];
      if (snapshot.exists && snapshot.value != null) {
        final classesMap = Map<String, dynamic>.from(snapshot.value as Map);
        classesMap.forEach((classId, classData) {
          final classMap = Map<String, dynamic>.from(classData as Map);
          classes.add(SchoolClass.fromMap(classMap, classId));
        });
      }
      classes.sort(
        (a, b) => a.classId.compareTo(b.classId),
      ); // Sort for consistent display
      developer.log(
        'Found ${classes.length} classes for teacher UID: $teacherId',
        name: 'AuthService.fetchAssignedClasses',
      );
      return classes;
    } catch (e) {
      developer.log(
        'Error fetching assigned classes',
        name: 'AuthService.fetchAssignedClasses',
        error: e,
      );
      throw AuthException("Failed to fetch assigned classes.");
    }
  }

  /// Fetches all teacher profiles.
  Future<List<TeacherProfile>> fetchAllTeachers() async {
    developer.log(
      'Fetching all teacher profiles.',
      name: 'AuthService.fetchAllTeachers',
    );
    try {
      final ref = _db.ref('teacher_profiles'); //
      final snapshot = await ref.get();

      final List<TeacherProfile> teachers = [];
      if (snapshot.exists && snapshot.value != null) {
        final teachersMap = Map<String, dynamic>.from(snapshot.value as Map);
        teachersMap.forEach((uid, teacherData) {
          final teacherMap = Map<String, dynamic>.from(teacherData as Map);
          teachers.add(TeacherProfile.fromMap(teacherMap, uid));
        });
      }
      developer.log(
        'Raw teachers fetched: ${teachers.map((t) => t.name).toList()}',
        name: 'AuthService.fetchAllTeachers',
      ); // Added for debugging
      teachers.sort((a, b) => a.name.compareTo(b.name)); // Sort by name
      developer.log(
        'Found ${teachers.length} teacher profiles.',
        name: 'AuthService.fetchAllTeachers',
      );
      return teachers;
    } catch (e) {
      developer.log(
        'Error fetching all teachers',
        name: 'AuthService.fetchAllTeachers',
        error: e,
      );
      throw AuthException("Failed to fetch teacher list.");
    }
  }

  /// Fetches all registered users (Alluser profiles).
  Future<List<Alluser>> fetchAllUsers({
    String? startAfterKey,
    int pageSize = 20,
  }) async {
    developer.log(
      'Fetching all user profiles.',
      name: 'AuthService.fetchAllUsers',
    );
    try {
      Query query = _db.ref('users').orderByKey();

      if (startAfterKey != null) {
        // If startAfterKey is provided, fetch the next page starting after that key.
        query = query.startAfter(startAfterKey);
      }

      // Limit the number of users fetched to the page size.
      query = query.limitToFirst(pageSize);
      final snapshot = await query.get();

      final List<Alluser> users = [];
      if (snapshot.exists && snapshot.value != null) {
        final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
        developer.log(
          'Raw users data from Firebase: $usersMap',
          name: 'AuthService.fetchAllUsers',
        );
        usersMap.forEach((uid, userData) {
          final userMap = Map<String, dynamic>.from(userData as Map);
          users.add(Alluser.fromMap(userMap, uid));
        });
      }
      developer.log(
        'Found ${users.length} user profiles.',
        name: 'AuthService.fetchAllUsers',
      );
      return users;
    } catch (e) {
      developer.log(
        'Error fetching all users',
        name: 'AuthService.fetchAllUsers',
        error: e,
      );
      throw AuthException("Failed to fetch user list.");
    }
  }

  /// Fetches all school classes.
  Future<List<SchoolClass>> fetchAllSchoolClasses() async {
    developer.log(
      'Fetching all school classes.',
      name: 'AuthService.fetchAllSchoolClasses',
    );
    try {
      final ref = _db.ref('classes');
      final snapshot = await ref.get();

      final List<SchoolClass> classes = [];
      if (snapshot.exists && snapshot.value != null) {
        final classesMap = Map<String, dynamic>.from(snapshot.value as Map);
        classesMap.forEach((classId, classData) {
          final classMap = Map<String, dynamic>.from(classData as Map);
          classes.add(SchoolClass.fromMap(classMap, classId));
        });
      }
      // Sort by creation date, newest first, for the "Recently Created" stat.
      classes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      developer.log(
        'Found ${classes.length} school classes.',
        name: 'AuthService.fetchAllSchoolClasses',
      );
      return classes;
    } catch (e) {
      developer.log(
        'Error fetching all school classes',
        name: 'AuthService.fetchAllSchoolClasses',
        error: e,
      );
      throw AuthException("Failed to fetch school classes.");
    }
  }

  /// Creates a new school class.
  Future<void> createSchoolClass(SchoolClass schoolClass) async {
    developer.log(
      'Creating school class: ${schoolClass.classId}',
      name: 'AuthService.createSchoolClass',
    );
    try {
      final classRef = _db.ref('classes/${schoolClass.classId}');
      await classRef.set(schoolClass.toMap());
      developer.log(
        'School class ${schoolClass.classId} created successfully.',
        name: 'AuthService.createSchoolClass',
      );
    } catch (e) {
      developer.log(
        'Error creating school class ${schoolClass.classId}',
        name: 'AuthService.createSchoolClass',
        error: e,
      );
      throw AuthException(
        "Failed to create class. Please ensure Class ID is unique.",
      );
    }
  }

  /// Updates an existing school class.
  Future<void> updateSchoolClass(SchoolClass schoolClass) async {
    developer.log(
      'Updating school class: ${schoolClass.classId}',
      name: 'AuthService.updateSchoolClass',
    );
    try {
      final classRef = _db.ref('classes/${schoolClass.classId}');
      await classRef.update(schoolClass.toMap());
      developer.log(
        'School class ${schoolClass.classId} updated successfully.',
        name: 'AuthService.updateSchoolClass',
      );
    } catch (e) {
      developer.log(
        'Error updating school class ${schoolClass.classId}',
        name: 'AuthService.updateSchoolClass',
        error: e,
      );
      throw AuthException("Failed to update class.");
    }
  }

  /// Deletes a school class.
  Future<void> deleteSchoolClass(String classId) async {
    developer.log(
      'Deleting school class: $classId',
      name: 'AuthService.deleteSchoolClass',
    );
    try {
      final classRef = _db.ref('classes/$classId');
      await classRef.remove();
      developer.log(
        'School class $classId deleted successfully.',
        name: 'AuthService.deleteSchoolClass',
      );
    } catch (e) {
      developer.log(
        'Error deleting school class $classId',
        name: 'AuthService.deleteSchoolClass',
        error: e,
      );
      throw AuthException("Failed to delete class.");
    }
  }

  /// Deletes a user's data from the Realtime Database.
  ///
  /// IMPORTANT: This method only deletes database records from `/users`,
  /// `/student_profiles`, and `/teacher_profiles`. It CANNOT delete the user
  /// from Firebase Authentication due to client-side SDK limitations.
  /// Deleting from Firebase Auth requires the Admin SDK, typically in a Cloud Function.
  /// This will leave an orphaned auth user who can still log in.
  Future<void> deleteUser(Alluser userToDelete) async {
    developer.log(
      'Deleting data for user: ${userToDelete.email} (UID: ${userToDelete.uid})',
      name: 'AuthService.deleteUser',
    );

    try {
      // Create a map of paths to delete using a multi-path update.
      final Map<String, dynamic> updates = {};
      updates['/users/${userToDelete.uid}'] = null;

      if (userToDelete.role == 'student') {
        updates['/student_profiles/${userToDelete.uid}'] = null;
      } else if (userToDelete.role == 'teacher') {
        updates['/teacher_profiles/${userToDelete.uid}'] = null;
      }

      await _db.ref().update(updates);
      developer.log(
        'Successfully deleted database entries for UID: ${userToDelete.uid}',
        name: 'AuthService.deleteUser',
      );
    } catch (e) {
      developer.log(
        'Error deleting user data for UID ${userToDelete.uid}',
        name: 'AuthService.deleteUser',
        error: e,
      );
      throw AuthException("Failed to delete user data. Please try again.");
    }
  }

  /// Creates a new item (announcement or assignment) in a class stream.
  Future<void> createStreamItem(StreamItem item) async {
    developer.log(
      'Creating stream item in class: ${item.classId}',
      name: 'AuthService.createStreamItem',
    );
    try {
      final itemRef = _db.ref('streams/${item.classId}').push();
      await itemRef.set(item.toMap());
      developer.log(
        'Stream item created successfully with key: ${itemRef.key}',
        name: 'AuthService.createStreamItem',
      );
    } catch (e) {
      developer.log(
        'Error creating stream item',
        name: 'AuthService.createStreamItem',
        error: e,
      );
      throw AuthException("Failed to post to the class stream.");
    }
  }

  /// Fetches all stream items for a specific class, ordered by timestamp.
  Future<List<StreamItem>> fetchStreamForClass(String classId) async {
    // Add a guard clause to prevent queries with an empty or invalid classId.
    if (classId.isEmpty) {
      developer.log(
        'classId is empty, cannot fetch stream. Returning empty list.',
        name: 'AuthService.fetchStreamForClass',
      );
      return [];
    }

    developer.log(
      'Fetching stream for class ID: $classId',
      name: 'AuthService.fetchStreamForClass',
    );
    try {
      final ref = _db.ref('streams/$classId').orderByChild('timestamp');
      final snapshot = await ref.get();

      final List<StreamItem> items = [];
      if (snapshot.exists && snapshot.value != null) {
        developer.log(
          'Snapshot exists for class stream $classId.',
          name: 'AuthService.fetchStreamForClass',
        );
        final itemsMap = Map<String, dynamic>.from(snapshot.value as Map);
        itemsMap.forEach((key, value) {
          final itemMap = Map<String, dynamic>.from(value as Map);
          items.add(StreamItem.fromMap(itemMap, key));
        });
      } else {
        // This log is crucial for debugging when no data is found.
        developer.log(
          'No stream data found at path: streams/$classId',
          name: 'AuthService.fetchStreamForClass',
        );
      }
      // Sort descending to show newest items first
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      developer.log(
        'Returning ${items.length} items for class $classId',
        name: 'AuthService.fetchStreamForClass',
      );
      return items;
    } catch (e) {
      developer.log(
        'Error fetching class stream',
        name: 'AuthService.fetchStreamForClass',
        error: e,
      );
      throw AuthException("Failed to load class stream.");
    }
  }

  /// Fetches only announcements for a specific class, sorted by most recent.
  /// This is a convenience method that calls `fetchStreamForClass` and filters the results.
  Future<List<StreamItem>> fetchAnnouncementsForClass(String classId) async {
    developer.log(
      'Fetching announcements for class ID: $classId',
      name: 'AuthService.fetchAnnouncementsForClass',
    );
    final allItems = await fetchStreamForClass(classId);
    // Assuming StreamItem has a 'type' property.
    final announcements =
        allItems.where((item) => item.type == 'announcement').toList();
    developer.log(
      'Filtered ${announcements.length} announcements for class $classId',
      name: 'AuthService.fetchAnnouncementsForClass',
    );
    return announcements;
  }

  /// Fetches only assignments for a specific class, sorted by most recent.
  /// This is a convenience method that calls `fetchStreamForClass` and filters the results.
  Future<List<StreamItem>> fetchAssignmentsForClass(String classId) async {
    developer.log(
      'Fetching assignments for class ID: $classId',
      name: 'AuthService.fetchAssignmentsForClass',
    );
    final allItems = await fetchStreamForClass(classId);
    // Assuming StreamItem has a 'type' property.
    final assignments =
        allItems.where((item) => item.type == 'assignment').toList();
    developer.log(
      'Filtered ${assignments.length} assignments for class $classId',
      name: 'AuthService.fetchAssignmentsForClass',
    );
    return assignments;
  }

  /// Fetches a single school class by its ID.
  Future<SchoolClass?> fetchSchoolClassById(String classId) async {
    developer.log(
      'Fetching school class with ID: $classId',
      name: 'AuthService.fetchSchoolClassById',
    );
    try {
      final ref = _db.ref('classes/$classId');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final classMap = Map<String, dynamic>.from(snapshot.value as Map);
        developer.log(
          'Found class with ID: $classId',
          name: 'AuthService.fetchSchoolClassById',
        );
        return SchoolClass.fromMap(classMap, classId);
      }
      developer.log(
        'Class with ID $classId not found.',
        name: 'AuthService.fetchSchoolClassById',
      );
      return null;
    } catch (e) {
      developer.log(
        'Error fetching school class by ID',
        name: 'AuthService.fetchSchoolClassById',
        error: e,
      );
      throw AuthException("Failed to fetch class details.");
    }
  }

  /// Returns a Stream of stream items for a specific class.
  /// This method uses a real-time listener (`onValue`) to keep the stream updated.
  Stream<List<StreamItem>> getStreamForClass(String classId) {
    if (classId.isEmpty) {
      developer.log(
        'classId is empty, cannot fetch stream. Returning empty stream.',
        name: 'AuthService.getStreamForClass',
      );
      return Stream.value([]);
    }

    developer.log(
      'Fetching stream for class ID: $classId (real-time)',
      name: 'AuthService.getStreamForClass',
    );
    final ref = _db.ref('streams/$classId').orderByChild('timestamp');

    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final List<StreamItem> items = [];

      if (snapshot.exists && snapshot.value != null) {
        developer.log(
          'Snapshot exists for class stream $classId.',
          name: 'AuthService.getStreamForClass',
        );
        final itemsMap = Map<String, dynamic>.from(snapshot.value as Map);
        itemsMap.forEach((key, value) {
          final itemMap = Map<String, dynamic>.from(value as Map);
          items.add(StreamItem.fromMap(itemMap, key));
        });
      } else {
        developer.log(
          'No stream data found at path: streams/$classId',
          name: 'AuthService.getStreamForClass',
        );
      }

      items.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp),
      ); // Newest first
      developer.log(
        'Returning ${items.length} items for class $classId',
        name: 'AuthService.getStreamForClass',
      );
      return items;
    }).handleError(
      (e) => developer.log(
        'Error in stream listener: $e',
        name: 'AuthService.getStreamForClass',
        error: e,
      ),
    );
  }

  /// Updates an existing stream item in a class.
  Future<void> updateStreamItem(StreamItem item) async {
    developer.log(
      'Updating stream item ${item.id} in class: ${item.classId}',
      name: 'AuthService.updateStreamItem',
    );
    try {
      // The StreamItem's id cannot be null or empty for an update.
      if (item.id.isEmpty) {
        // 'id' is a non-nullable String, so no need for null check
        throw AuthException("Item ID is missing. Cannot update stream item.");
      }
      final itemRef = _db.ref('streams/${item.classId}/${item.id}');
      await itemRef.update(item.toMap());
      developer.log(
        'Stream item ${item.id} updated successfully.',
        name: 'AuthService.updateStreamItem',
      );
    } catch (e) {
      developer.log(
        'Error updating stream item',
        name: 'AuthService.updateStreamItem',
        error: e,
      );
      throw AuthException("Failed to update the post.");
    }
  }

  /// Deletes an item (announcement or assignment) from a class stream.
  Future<void> deleteStreamItem(String classId, String itemId) async {
    developer.log(
      'Deleting stream item $itemId from class: $classId',
      name: 'AuthService.deleteStreamItem',
    );
    try {
      final itemRef = _db.ref('streams/$classId/$itemId');
      await itemRef.remove();
      developer.log(
        'Stream item $itemId deleted successfully.',
        name: 'AuthService.deleteStreamItem',
      );
    } catch (e) {
      developer.log(
        'Error deleting stream item',
        name: 'AuthService.deleteStreamItem',
        error: e,
      );
      throw AuthException("Failed to delete the post.");
    }
  }

  /// Assigns a student to a specific class by updating their profile.
  Future<void> assignStudentToClass(String studentId, String classId) async {
    developer.log(
      'Assigning student $studentId to class $classId',
      name: 'AuthService.assignStudentToClass',
    );
    try {
      final studentProfileRef = _db.ref('student_profiles/$studentId');
      await studentProfileRef.update({'classId': classId});
      developer.log(
        'Student $studentId successfully assigned to class $classId.',
        name: 'AuthService.assignStudentToClass',
      );
    } catch (e) {
      developer.log(
        'Error assigning student to class',
        name: 'AuthService.assignStudentToClass',
        error: e,
      );
      throw AuthException("Failed to assign student to the class.");
    }
  }

  /// Creates a new invoice.
  Future<void> createInvoice(Invoice invoice) async {
    developer.log(
      'Creating invoice for student: ${invoice.studentUid}',
      name: 'AuthService.createInvoice',
    );
    try {
      final invoiceRef =
          _db.ref('invoices').push(); // Firebase generates unique ID
      await invoiceRef.set(invoice.toMap());
      developer.log(
        'Invoice ${invoiceRef.key} created successfully.',
        name: 'AuthService.createInvoice',
      );
    } catch (e) {
      developer.log(
        'Error creating invoice for student ${invoice.studentUid}',
        name: 'AuthService.createInvoice',
        error: e,
      );
      throw AuthException("Failed to create invoice.");
    }
  }

  /// Fetches all invoices.
  Future<List<Invoice>> fetchAllInvoices() async {
    developer.log(
      'Fetching all invoices.',
      name: 'AuthService.fetchAllInvoices',
    );
    try {
      final ref = _db.ref('invoices');
      final snapshot = await ref.get();

      final List<Invoice> invoices = [];
      if (snapshot.exists && snapshot.value != null) {
        final invoicesMap = Map<String, dynamic>.from(snapshot.value as Map);
        invoicesMap.forEach((id, invoiceData) {
          final invoiceMap = Map<String, dynamic>.from(invoiceData as Map);
          invoices.add(Invoice.fromMap(invoiceMap, id));
        });
      }
      developer.log(
        'Found ${invoices.length} invoices.',
        name: 'AuthService.fetchAllInvoices',
      );
      return invoices;
    } catch (e) {
      developer.log(
        'Error fetching all invoices',
        name: 'AuthService.fetchAllInvoices',
        error: e,
      );
      throw AuthException("Failed to fetch invoices.");
    }
  }

  /// Records a new payment for an invoice.
  Future<void> recordPayment(Payment payment) async {
    developer.log(
      'Recording payment for invoice: ${payment.invoiceId}',
      name: 'AuthService.recordPayment',
    );
    try {
      final paymentRef =
          _db.ref('payments').push(); // Firebase generates unique ID
      await paymentRef.set(payment.toMap());
      developer.log(
        'Payment ${paymentRef.key} recorded successfully.',
        name: 'AuthService.recordPayment',
      );
    } catch (e) {
      developer.log(
        'Error recording payment for invoice ${payment.invoiceId}',
        name: 'AuthService.recordPayment',
        error: e,
      );
      throw AuthException("Failed to record payment.");
    }
  }

  /// Fetches all payments for a specific invoice.
  Future<List<Payment>> fetchPaymentsForInvoice(String invoiceId) async {
    developer.log(
      'Fetching payments for invoice: $invoiceId',
      name: 'AuthService.fetchPaymentsForInvoice',
    );
    try {
      final ref =
          _db.ref('payments').orderByChild('invoiceId').equalTo(invoiceId);
      final snapshot = await ref.get();

      final List<Payment> payments = [];
      if (snapshot.exists && snapshot.value != null) {
        final paymentsMap = Map<String, dynamic>.from(snapshot.value as Map);
        paymentsMap.forEach((id, paymentData) {
          final paymentMap = Map<String, dynamic>.from(paymentData as Map);
          payments.add(Payment.fromMap(paymentMap, id));
        });
      }
      payments.sort(
        (a, b) => b.paymentDate.compareTo(a.paymentDate),
      ); // Newest first
      developer.log(
        'Found ${payments.length} payments for invoice $invoiceId.',
        name: 'AuthService.fetchPaymentsForInvoice',
      );
      return payments;
    } catch (e) {
      developer.log(
        'Error fetching payments for invoice $invoiceId',
        name: 'AuthService.fetchPaymentsForInvoice',
        error: e,
      );
      throw AuthException("Failed to fetch payments for invoice.");
    }
  }

  /// Updates an existing invoice.
  Future<void> updateInvoice(Invoice invoice) async {
    developer.log(
      'Updating invoice: ${invoice.id}',
      name: 'AuthService.updateInvoice',
    );
    try {
      final invoiceRef = _db.ref('invoices/${invoice.id}');
      await invoiceRef.update(invoice.toMap());
      developer.log(
        'Invoice ${invoice.id} updated successfully.',
        name: 'AuthService.updateInvoice',
      );
    } catch (e) {
      developer.log(
        'Error updating invoice ${invoice.id}',
        name: 'AuthService.updateInvoice',
        error: e,
      );
      throw AuthException("Failed to update invoice.");
    }
  }

  /// Assigns multiple students to a specific class by updating their profiles.
  /// Uses a multi-path update for efficiency.
  Future<void> assignStudentsToClass(
    List<String> studentUids,
    String classId,
  ) async {
    developer.log(
      'Assigning ${studentUids.length} students to class $classId',
      name: 'AuthService.assignStudentsToClass',
    );
    try {
      final Map<String, dynamic> updates = {};
      for (String studentId in studentUids) {
        updates['student_profiles/$studentId/classId'] = classId;
      }

      if (updates.isNotEmpty) {
        await _db.ref().update(updates);
        developer.log(
          'Successfully assigned ${studentUids.length} students to class $classId.',
          name: 'AuthService.assignStudentsToClass',
        );
      }
    } catch (e) {
      developer.log(
        'Error assigning multiple students to class',
        name: 'AuthService.assignStudentsToClass',
        error: e,
      );
      throw AuthException("Failed to assign students to the class.");
    }
  }

  /// Removes a student from any class they are assigned to.
  Future<void> removeStudentFromClass(String studentId) async {
    developer.log(
      'Removing class assignment for student $studentId',
      name: 'AuthService.removeStudentFromClass',
    );
    try {
      final studentProfileRef = _db.ref('student_profiles/$studentId');
      // Setting classId to null removes it from the database entry.
      await studentProfileRef.update({'classId': null});
      developer.log(
        'Student $studentId successfully unassigned from class.',
        name: 'AuthService.removeStudentFromClass',
      );
    } catch (e) {
      developer.log(
        'Error removing student from class',
        name: 'AuthService.removeStudentFromClass',
        error: e,
      );
      throw AuthException("Failed to unassign student from the class.");
    }
  }

  /// Fetches all students assigned to a specific class.
  /// NOTE: This requires a database index on 'classId' in your Firebase rules.
  Future<List<StudentTable>> fetchStudentsForClass(String classId) async {
    developer.log(
      'Fetching students for class ID: $classId',
      name: 'AuthService.fetchStudentsForClass',
    );
    try {
      final ref = _db.ref('student_profiles');
      final snapshot = await ref.orderByChild('classId').equalTo(classId).get();

      final List<StudentTable> students = [];
      if (snapshot.exists && snapshot.value != null) {
        final studentsMap = Map<String, dynamic>.from(snapshot.value as Map);
        studentsMap.forEach((uid, studentData) {
          final studentMap = Map<String, dynamic>.from(studentData as Map);
          students.add(StudentTable.fromMap(studentMap, uid));
        });
      }
      students.sort((a, b) => a.fullName.compareTo(b.fullName));
      developer.log(
        'Found ${students.length} students for class ID: $classId',
        name: 'AuthService.fetchStudentsForClass',
      );
      return students;
    } catch (e) {
      developer.log(
        'Error fetching students for class',
        name: 'AuthService.fetchStudentsForClass',
        error: e,
      );
      throw AuthException("Failed to fetch students for the class.");
    }
  }

  /// Updates the roll number for a specific student.
  Future<void> updateStudentRollNumber({
    required String studentUid,
    required int? rollNumber,
  }) async {
    developer.log(
      'Updating roll number for student $studentUid to $rollNumber',
      name: 'AuthService.updateStudentRollNumber',
    );
    try {
      final studentProfileRef = _db.ref('student_profiles/$studentUid');
      // Using `null` for rollNumber will remove it from the database.
      await studentProfileRef.update({'rollNumber': rollNumber});
      developer.log(
        'Student $studentUid roll number successfully updated.',
        name: 'AuthService.updateStudentRollNumber',
      );
    } catch (e) {
      developer.log(
        'Error updating student roll number',
        name: 'AuthService.updateStudentRollNumber',
        error: e,
      );
      throw AuthException("Failed to update roll number.");
    }
  }

  /// Generates a unique student ID based on school config and an atomic counter.
  /// Returns the generated student ID.
  Future<String> generateAndAssignStudentId(String studentUid) async {
    developer.log(
      'Generating student ID for UID: $studentUid',
      name: 'AuthService.generateAndAssignStudentId',
    );

    try {
      // This logic assumes the academic year starts in April.
      // You can adjust the month (4) to fit your school's calendar.
      final now = DateTime.now();
      final academicYear = now.month < 4
          ? '${now.year - 1}-${now.year}'
          : '${now.year}-${now.year + 1}';

      // 1. Get school configuration
      final configRef = _db.ref('school_config');
      final configSnapshot = await configRef.get();
      final config = configSnapshot.exists
          ? Map<String, dynamic>.from(configSnapshot.value as Map)
          : <String, dynamic>{};
      final locationCode = config['locationCode'] as String? ?? 'NA';
      final branchCode = config['branchCode'] as String? ?? 'NA';
      final prefix = config['studentIdPrefix'] as String? ?? 'SCH';

      // 2. Atomically increment the counter for the academic year
      final counterRef = _db.ref('counters/admission_numbers/$academicYear');
      final transactionResult = await counterRef.runTransaction((currentValue) {
        int currentCount = (currentValue as int?) ?? 0;
        currentCount++;
        return Transaction.success(currentCount);
      });

      if (!transactionResult.committed) {
        throw AuthException(
            'Failed to generate student ID. Could not update counter.');
      }

      final newCount = transactionResult.snapshot.value as int;
      final formattedCount = newCount.toString().padLeft(4, '0');

      // 3. Construct the new student ID
      final newStudentId = '$prefix-$locationCode-$branchCode-S$formattedCount';

      // 4. Assign the new ID to the student's profile
      await _db
          .ref('student_profiles/$studentUid')
          .update({'studentId': newStudentId});

      developer.log(
        'Successfully assigned student ID: $newStudentId for UID: $studentUid',
        name: 'AuthService.generateAndAssignStudentId',
      );
      return newStudentId;
    } catch (e) {
      throw AuthException("Failed to generate student ID: ${e.toString()}");
    }
  }

  /// Signs out the current user from Firebase Authentication.
  Future<void> signOut() async {
    developer.log('Signing out user.', name: 'AuthService.signOut');
    try {
      await _auth.signOut();
      developer.log(
        'User signed out successfully.',
        name: 'AuthService.signOut',
      );
    } catch (e) {
      developer.log('Error signing out', name: 'AuthService.signOut', error: e);
      throw AuthException("Failed to sign out.");
    }
  }

  /// Fetches all student profiles.
  Future<List<StudentTable>> fetchAllStudents() async {
    developer.log(
      'Fetching all student profiles.',
      name: 'AuthService.fetchAllStudents',
    );
    try {
      final ref = _db.ref('student_profiles');
      final snapshot = await ref.get();

      final List<StudentTable> students = [];
      if (snapshot.exists && snapshot.value != null) {
        final studentsMap = Map<String, dynamic>.from(snapshot.value as Map);
        studentsMap.forEach((uid, studentData) {
          final studentMap = Map<String, dynamic>.from(studentData as Map);
          students.add(StudentTable.fromMap(studentMap, uid));
        });
      }
      students.sort((a, b) => a.fullName.compareTo(b.fullName)); // Sort by name
      developer.log(
        'Found ${students.length} student profiles.',
        name: 'AuthService.fetchAllStudents',
      );
      return students;
    } catch (e) {
      developer.log(
        'Error fetching all students',
        name: 'AuthService.fetchAllStudents',
        error: e,
      );
      throw AuthException("Failed to fetch student list.");
    }
  }

  /// Uploads an assignment submission file to Firebase Storage.
  /// Returns the download URL of the uploaded file.
  Future<String> uploadAssignmentSubmission(
    String classId,
    String assignmentId,
    File file,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('submissions')
          .child(classId)
          .child(assignmentId)
          .child(user.uid)
          .child(
            '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}',
          );

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      developer.log(
        'Uploaded submission for assignment $assignmentId by user ${user.uid} to $downloadUrl',
        name: 'AuthService.uploadAssignmentSubmission',
      );
      return downloadUrl;
    } catch (e) {
      developer.log(
        'Failed to upload submission for assignment $assignmentId: $e',
        name: 'AuthService.uploadAssignmentSubmission',
        error: e,
      );
      throw AuthException('Failed to upload submission: ${e.toString()}');
    }
  }

  /// Submits assignment details to Firebase Realtime Database
  Future<void> submitAssignment(String assignmentId, String fileUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated');
      }
      // Fetch student's name to denormalize data for easier display for teachers.
      final studentProfileSnapshot =
          await _db.ref('student_profiles/${user.uid}').get();
      final studentName =
          (studentProfileSnapshot.value as Map?)?['fullName'] as String? ??
              'Unknown Student';

      final submissionRef =
          _db.ref('submissions').child(assignmentId).child(user.uid);

      final submissionData = {
        'student_uid': user.uid,
        'student_name': studentName,
        'submission_timestamp': ServerValue.timestamp, // Use server timestamp
        'file_url': fileUrl,
      };

      await submissionRef.set(submissionData);

      developer.log(
        'Submitted assignment $assignmentId by user ${user.uid} with file: $fileUrl',
        name: 'AuthService.submitAssignment',
      );
    } catch (e) {
      developer.log(
        'Failed to submit assignment $assignmentId: $e',
        name: 'AuthService.submitAssignment',
        error: e,
      );
      throw AuthException('Failed to submit assignment: ${e.toString()}');
    }
  }

  /// Fetches all submissions for a given assignment.
  Future<List<Submission>> fetchSubmissionsForAssignment(
    String assignmentId,
  ) async {
    developer.log(
      'Fetching submissions for assignment ID: $assignmentId',
      name: 'AuthService.fetchSubmissionsForAssignment',
    );
    try {
      final ref = _db.ref('submissions/$assignmentId');
      final snapshot = await ref.get();

      final List<Submission> submissions = [];
      if (snapshot.exists && snapshot.value != null) {
        final submissionsMap = Map<String, dynamic>.from(snapshot.value as Map);
        submissionsMap.forEach((studentUid, submissionData) {
          final submissionMap = Map<String, dynamic>.from(
            submissionData as Map,
          );
          submissions.add(Submission.fromMap(submissionMap, studentUid));
        });
      }
      // Sort submissions by student name for easy viewing.
      submissions.sort((a, b) => a.studentName.compareTo(b.studentName));
      developer.log(
        'Found ${submissions.length} submissions for assignment $assignmentId',
        name: 'AuthService.fetchSubmissionsForAssignment',
      );
      return submissions;
    } catch (e) {
      developer.log(
        'Error fetching submissions',
        name: 'AuthService.fetchSubmissionsForAssignment',
        error: e,
      );
      throw AuthException("Failed to load submissions.");
    }
  }

  /// Grades an assignment submission by updating the grade and comments.
  Future<void> gradeSubmission(
    String assignmentId,
    String studentUid,
    String grade,
    String comments,
  ) async {
    developer.log(
      'Grading submission for student $studentUid on assignment $assignmentId',
      name: 'AuthService.gradeSubmission',
    );
    try {
      final submissionRef = _db.ref('submissions/$assignmentId/$studentUid');
      await submissionRef.update({'grade': grade, 'comments': comments});
      developer.log(
        'Successfully graded submission',
        name: 'AuthService.gradeSubmission',
      );
    } catch (e) {
      developer.log(
        'Error grading submission',
        name: 'AuthService.gradeSubmission',
        error: e,
      );
      throw AuthException("Failed to save grade.");
    }
  }

  /// Fetches a single student's submission for a specific assignment.
  Future<Submission?> fetchStudentSubmissionForAssignment(
    String assignmentId,
    String studentUid,
  ) async {
    developer.log(
      'Fetching submission for student $studentUid on assignment $assignmentId',
      name: 'AuthService.fetchStudentSubmissionForAssignment',
    );
    try {
      final ref = _db.ref('submissions/$assignmentId/$studentUid');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final submissionMap = Map<String, dynamic>.from(snapshot.value as Map);
        developer.log(
          'Found submission for student $studentUid on assignment $assignmentId',
          name: 'AuthService.fetchStudentSubmissionForAssignment',
        );
        return Submission.fromMap(submissionMap, studentUid);
      }
      developer.log(
        'No submission found for student $studentUid on assignment $assignmentId',
        name: 'AuthService.fetchStudentSubmissionForAssignment',
      );
      return null;
    } catch (e) {
      developer.log(
        'Error fetching student submission',
        name: 'AuthService.fetchStudentSubmissionForAssignment',
        error: e,
      );
      throw AuthException(
        "Failed to fetch student submission: ${e.toString()}",
      );
    }
  }

  /// Fetches attendance records for a specific student in a specific class.
  /// Attendance is stored under /student_attendance/<studentUid>/<classId>/<date>
  Future<List<AttendanceRecord>> fetchStudentAttendanceForClass(
    String studentUid,
    String classId,
  ) async {
    developer.log(
      'Fetching attendance for student $studentUid in class $classId',
      name: 'AuthService.fetchStudentAttendanceForClass',
    );
    try {
      final ref = _db.ref('student_attendance/$studentUid/$classId');
      final snapshot = await ref.get();

      final List<AttendanceRecord> attendanceRecords = [];
      if (snapshot.exists && snapshot.value != null) {
        final recordsMap = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        recordsMap.forEach((dateKey, statusData) {
          if (statusData != null) {
            String status;
            if (statusData is Map && statusData.containsKey('status')) {
              status = statusData['status'] as String;
            } else if (statusData is String) {
              status = statusData;
            } else {
              developer.log(
                'Skipping attendance record with unexpected format for date $dateKey: $statusData',
                name: 'AuthService.fetchStudentAttendanceForClass',
              );
              return; // Continue to the next iteration
            }
            attendanceRecords.add(
              AttendanceRecord.fromMap(status, classId, studentUid, dateKey),
            );
          }
        });
      }
      attendanceRecords.sort(
        (a, b) => b.date.compareTo(a.date),
      );
      developer.log(
        'Found ${attendanceRecords.length} attendance records for student $studentUid in class $classId',
        name: 'AuthService.fetchStudentAttendanceForClass',
      );
      return attendanceRecords;
    } catch (e) {
      developer.log(
        'Error fetching student attendance: $e',
        name: 'AuthService.fetchStudentAttendanceForClass',
        error: e,
      );
      throw AuthException(
        "Failed to fetch attendance records: ${e.toString()}",
      );
    }
  }

  /// Saves attendance for multiple students for a specific class and date.
  Future<void> saveAttendance(
    String classId,
    DateTime date,
    Map<String, String> attendanceData,
  ) async {
    developer.log(
      'Saving attendance for class $classId on $date',
      name: 'AuthService.saveAttendance',
    );
    try {
      final String dateKey = DateFormat('yyyy-MM-dd').format(date);
      final Map<String, dynamic> updates = {};

      attendanceData.forEach((studentUid, status) {
        // Path for each student's attendance record for the specific date
        final path = 'student_attendance/$studentUid/$classId/$dateKey';
        updates[path] = {'status': status};
      });

      if (updates.isNotEmpty) {
        await _db.ref().update(updates);
        developer.log(
          'Successfully saved attendance for ${updates.length} students.',
          name: 'AuthService.saveAttendance',
        );
      } else {
        developer.log(
          'No attendance data to save.',
          name: 'AuthService.saveAttendance',
        );
      }
    } catch (e) {
      developer.log(
        'Error saving attendance: $e',
        name: 'AuthService.saveAttendance',
        error: e,
      );
      throw AuthException("Failed to save attendance: ${e.toString()}");
    }
  }

  /// Fetches all attendance records for a specific class on a given date.
  Future<List<AttendanceRecord>> fetchAttendanceForDate(
    String classId,
    DateTime date,
  ) async {
    final String dateKey = DateFormat('yyyy-MM-dd').format(date);
    developer.log(
      'Fetching attendance for class $classId on date $dateKey',
      name: 'AuthService.fetchAttendanceForDate',
    );
    try {
      final ref = _db.ref('student_attendance');
      // This query is more complex and might be slow on large datasets without proper indexing.
      // It iterates through all students to find records for the specific class and date.
      final snapshot = await ref.get();
      final List<AttendanceRecord> records = [];

      if (snapshot.exists && snapshot.value != null) {
        final allStudentsAttendance = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        allStudentsAttendance.forEach((studentUid, studentData) {
          final studentClasses = Map<String, dynamic>.from(studentData as Map);
          if (studentClasses.containsKey(classId) &&
              studentClasses[classId].containsKey(dateKey)) {
            records.add(
              AttendanceRecord.fromMap(
                studentClasses[classId][dateKey],
                classId,
                studentUid,
                dateKey,
              ),
            );
          }
        });
      }
      return records;
    } catch (e) {
      throw AuthException(
        "Failed to fetch attendance for date: ${e.toString()}",
      );
    }
  }

  /// Fetches all attendance records for a specific class across all dates and students.
  /// Returns a map where keys are student UIDs and values are maps of dateKey -> status.
  /// This structure is suitable for processing into calendar events.
  Future<Map<String, Map<String, String>>> fetchAllAttendanceForClass(
    String classId,
  ) async {
    developer.log(
      'Fetching all attendance for class $classId',
      name: 'AuthService.fetchAllAttendanceForClass',
    );
    try {
      final ref = _db.ref('student_attendance');
      final snapshot = await ref.get();

      final Map<String, Map<String, String>> classAttendance = {};

      if (snapshot.exists && snapshot.value != null) {
        final allStudentsAttendance = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        allStudentsAttendance.forEach((studentUid, studentData) {
          final studentClasses = Map<String, dynamic>.from(studentData as Map);
          if (studentClasses.containsKey(classId)) {
            final attendanceForClass = Map<String, dynamic>.from(
              studentClasses[classId] as Map,
            );
            attendanceForClass.forEach((dateKey, statusData) {
              String status;
              if (statusData is String) {
                status = statusData;
              } else if (statusData is Map &&
                  statusData.containsKey('status')) {
                status = statusData['status'] as String;
              } else {
                status = 'unknown';
              }
              classAttendance.putIfAbsent(studentUid, () => {})[dateKey] =
                  status;
            });
          }
        });
      }
      developer.log(
        'Found attendance for ${classAttendance.keys.length} students in class $classId',
        name: 'AuthService.fetchAllAttendanceForClass',
      );
      return classAttendance;
    } catch (e) {
      throw AuthException(
        "Failed to fetch all attendance records for class: ${e.toString()}",
      );
    }
  }

  /// Fetches attendance records for a specific class within a date range.
  /// Returns a map where keys are student UIDs and values are maps of dateKey -> status.
  Future<Map<String, Map<String, String>>> fetchAttendanceSummaryForClass(
    String classId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    developer.log(
      'Fetching attendance summary for class $classId from ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}',
      name: 'AuthService.fetchAttendanceSummaryForClass',
    );
    try {
      final ref = _db.ref('student_attendance');
      final snapshot = await ref.get();

      final Map<String, Map<String, String>> classAttendanceSummary = {};

      if (snapshot.exists && snapshot.value != null) {
        final allStudentsAttendance = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        allStudentsAttendance.forEach((studentUid, studentData) {
          final studentClasses = Map<String, dynamic>.from(studentData as Map);
          if (studentClasses.containsKey(classId)) {
            final attendanceForClass = Map<String, dynamic>.from(
              studentClasses[classId] as Map,
            );

            attendanceForClass.forEach((dateKey, statusData) {
              final recordDate = DateTime.parse(dateKey);
              // Only include records within the specified date range
              if (recordDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  recordDate.isBefore(endDate.add(const Duration(days: 1)))) {
                String status;
                if (statusData is String) {
                  status = statusData;
                } else if (statusData is Map &&
                    statusData.containsKey('status')) {
                  status = statusData['status'] as String;
                } else {
                  status = 'unknown';
                }
                classAttendanceSummary.putIfAbsent(
                  studentUid,
                  () => {},
                )[dateKey] = status;
              }
            });
          }
        });
      }
      developer.log(
        'Found attendance summary for ${classAttendanceSummary.keys.length} students in class $classId',
        name: 'AuthService.fetchAttendanceSummaryForClass',
      );
      return classAttendanceSummary;
    } catch (e) {
      throw AuthException(
        "Failed to fetch attendance summary: ${e.toString()}",
      );
    }
  }

  /// Updates a user's status (e.g., 'active' or 'inactive').
  Future<void> updateUserStatus(String uid, String status) async {
    developer.log(
      'Attempting to update status for user: $uid to $status',
      name: 'AuthService.updateUserStatus',
    );
    try {
      await _db.ref('users/$uid').update({'status': status});
      developer.log(
        'User status updated successfully for UID: $uid',
        name: 'AuthService.updateUserStatus',
      );
    } catch (e) {
      developer.log(
        'Error updating user status for UID $uid: $e',
        name: 'AuthService.updateUserStatus',
        error: e,
      );
      throw AuthException("Failed to update user status: ${e.toString()}");
    }
  }

  /// Updates a user's profile data in the Realtime Database.
  /// This is used for editing details like name, username, etc.
  Future<void> updateUserProfile(Alluser user) async {
    developer.log(
      'Updating profile for user: ${user.uid}',
      name: 'AuthService.updateUserProfile',
    );
    try {
      await _db.ref('users/${user.uid}').update(user.toMap());
      developer.log(
        'User profile updated successfully for UID: ${user.uid}',
        name: 'AuthService.updateUserProfile',
      );
    } catch (e) {
      developer.log(
        'Error updating user profile for UID ${user.uid}',
        name: 'AuthService.updateUserProfile',
        error: e,
      );
      throw AuthException("Failed to update user profile.");
    }
  }

  /// Updates a student's profile data in the Realtime Database.
  Future<void> updateStudentProfile(StudentTable student) async {
    developer.log(
      'Updating student profile for UID: ${student.uid}',
      name: 'AuthService.updateStudentProfile',
    );
    try {
      await _db.ref('student_profiles/${student.uid}').update(student.toMap());
      developer.log(
        'Student profile updated successfully for UID: ${student.uid}',
        name: 'AuthService.updateStudentProfile',
      );
    } catch (e) {
      developer.log(
        'Error updating student profile for UID ${student.uid}',
        name: 'AuthService.updateStudentProfile',
        error: e,
      );
      throw AuthException("Failed to update student profile.");
    }
  }

  /// Bulk updates the status of multiple users.
  /// Takes a list of user UIDs and the new status to apply.
  Future<void> updateUsersStatus(List<String> uids, String status) async {
    developer.log(
      'Attempting to bulk update status for ${uids.length} users to $status',
      name: 'AuthService.updateUsersStatus',
    );
    try {
      final Map<String, dynamic> updates = {};
      for (String uid in uids) {
        updates['users/$uid/status'] = status;
      }

      if (updates.isNotEmpty) {
        await _db.ref().update(updates);
        developer.log(
          'Bulk status update successful for ${uids.length} users.',
          name: 'AuthService.updateUsersStatus',
        );
      }
    } catch (e) {
      developer.log(
        'Error during bulk status update: $e',
        name: 'AuthService.updateUsersStatus',
        error: e,
      );
      throw AuthException("Failed to bulk update user status.");
    }
  }

  /// Creates a new fee category.
  Future<void> createFeeCategory(FeeCategory feeCategory) async {
    developer.log(
      'Creating fee category: ${feeCategory.name}',
      name: 'AuthService.createFeeCategory',
    );
    try {
      final feeRef = _db.ref('fee_categories').push(); // Use push for unique ID
      await feeRef.set(feeCategory.toMap());
      developer.log(
        'Fee category ${feeCategory.name} created successfully.',
        name: 'AuthService.createFeeCategory',
      );
    } catch (e) {
      developer.log(
        'Error creating fee category ${feeCategory.name}',
        name: 'AuthService.createFeeCategory',
        error: e,
      );
      throw AuthException("Failed to create fee category.");
    }
  }

  /// Fetches all fee categories.
  Future<List<FeeCategory>> fetchAllFeeCategories() async {
    developer.log(
      'Fetching all fee categories.',
      name: 'AuthService.fetchAllFeeCategories',
    );
    try {
      final ref = _db.ref('fee_categories');
      final snapshot = await ref.get();

      final List<FeeCategory> feeCategories = [];
      if (snapshot.exists && snapshot.value != null) {
        final feesMap = Map<String, dynamic>.from(snapshot.value as Map);
        feesMap.forEach((id, feeData) {
          final feeMap = Map<String, dynamic>.from(feeData as Map);
          feeCategories.add(FeeCategory.fromMap(feeMap, id));
        });
      }
      developer.log(
        'Found ${feeCategories.length} fee categories.',
        name: 'AuthService.fetchAllFeeCategories',
      );
      return feeCategories;
    } catch (e) {
      developer.log(
        'Error fetching all fee categories',
        name: 'AuthService.fetchAllFeeCategories',
        error: e,
      );
      throw AuthException("Failed to fetch fee categories.");
    }
  }

  /// Updates an existing fee category.
  Future<void> updateFeeCategory(FeeCategory feeCategory) async {
    developer.log(
      'Updating fee category: ${feeCategory.id}',
      name: 'AuthService.updateFeeCategory',
    );
    try {
      final feeRef = _db.ref('fee_categories/${feeCategory.id}');
      await feeRef.update(feeCategory.toMap());
      developer.log(
        'Fee category ${feeCategory.id} updated successfully.',
        name: 'AuthService.updateFeeCategory',
      );
    } catch (e) {
      developer.log(
        'Error updating fee category ${feeCategory.id}',
        name: 'AuthService.updateFeeCategory',
        error: e,
      );
      throw AuthException("Failed to update fee category.");
    }
  }

  /// Creates a new fee structure.
  Future<void> createFeeStructure(FeeStructure feeStructure) async {
    developer.log(
      'Creating fee structure for class: ${feeStructure.classId}',
      name: 'AuthService.createFeeStructure',
    );
    try {
      // Use classId as part of the path for uniqueness per class
      final feeRef = _db.ref('fee_structures/${feeStructure.id}');
      await feeRef.set(feeStructure.toMap());
      developer.log(
        'Fee structure for class ${feeStructure.classId} created successfully.',
        name: 'AuthService.createFeeStructure',
      );
    } catch (e) {
      developer.log(
        'Error creating fee structure for class ${feeStructure.classId}',
        name: 'AuthService.createFeeStructure',
        error: e,
      );
      throw AuthException("Failed to create fee structure.");
    }
  }

  /// Fetches all fee structures.
  Future<List<FeeStructure>> fetchAllFeeStructures() async {
    developer.log(
      'Fetching all fee structures.',
      name: 'AuthService.fetchAllFeeStructures',
    );
    try {
      final ref = _db.ref('fee_structures');
      final snapshot = await ref.get();

      final List<FeeStructure> feeStructures = [];
      if (snapshot.exists && snapshot.value != null) {
        final feesMap = Map<String, dynamic>.from(snapshot.value as Map);
        feesMap.forEach((id, feeData) {
          final feeMap = Map<String, dynamic>.from(feeData as Map);
          feeStructures.add(FeeStructure.fromMap(feeMap, id));
        });
      }
      developer.log(
        'Found ${feeStructures.length} fee structures.',
        name: 'AuthService.fetchAllFeeStructures',
      );
      return feeStructures;
    } catch (e) {
      developer.log(
        'Error fetching all fee structures',
        name: 'AuthService.fetchAllFeeStructures',
        error: e,
      );
      throw AuthException("Failed to fetch fee structures.");
    }
  }

  /// Updates an existing fee structure.
  Future<void> updateFeeStructure(FeeStructure feeStructure) async {
    developer.log(
      'Updating fee structure: ${feeStructure.id}',
      name: 'AuthService.updateFeeStructure',
    );
    try {
      final feeRef = _db.ref('fee_structures/${feeStructure.id}');
      await feeRef.update(feeStructure.toMap());
      developer.log(
        'Fee structure ${feeStructure.id} updated successfully.',
        name: 'AuthService.updateFeeStructure',
      );
    } catch (e) {
      developer.log(
        'Error updating fee structure ${feeStructure.id}',
        name: 'AuthService.updateFeeStructure',
        error: e,
      );
      throw AuthException("Failed to update fee structure.");
    }
  }

  /// Deletes a fee category.
  Future<void> deleteFeeCategory(String categoryId) async {
    developer.log(
      'Deleting fee category: $categoryId',
      name: 'AuthService.deleteFeeCategory',
    );
    try {
      final feeRef = _db.ref('fee_categories/$categoryId');
      await feeRef.remove();
      developer.log(
        'Fee category $categoryId deleted successfully.',
        name: 'AuthService.deleteFeeCategory',
      );
    } catch (e) {
      developer.log(
        'Error deleting fee category $categoryId',
        name: 'AuthService.deleteFeeCategory',
        error: e,
      );
      throw AuthException("Failed to delete fee category.");
    }
  }

  /// Deletes a fee structure.
  Future<void> deleteFeeStructure(String structureId) async {
    developer.log(
      'Deleting fee structure: $structureId',
      name: 'AuthService.deleteFeeStructure',
    );
    try {
      final feeRef = _db.ref('fee_structures/$structureId');
      await feeRef.remove();
      developer.log(
        'Fee structure $structureId deleted successfully.',
        name: 'AuthService.deleteFeeStructure',
      );
    } catch (e) {
      developer.log(
        'Error deleting fee structure $structureId',
        name: 'AuthService.deleteFeeStructure',
        error: e,
      );
      throw AuthException("Failed to delete fee structure.");
    }
  }

  /// Fetches all stream items (announcements and assignments) from all classes.
  Future<List<StreamItem>> fetchAllStreamItems() async {
    developer.log(
      'Fetching all stream items.',
      name: 'AuthService.fetchAllStreamItems',
    );
    try {
      final ref = _db.ref('streams');
      final snapshot = await ref.get();

      final List<StreamItem> items = [];
      if (snapshot.exists && snapshot.value != null) {
        final allClassStreams = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        allClassStreams.forEach((classId, classStreamData) {
          final itemsMap = Map<String, dynamic>.from(classStreamData as Map);
          itemsMap.forEach((key, value) {
            final itemMap = Map<String, dynamic>.from(value as Map);
            items.add(StreamItem.fromMap(itemMap, key));
          });
        });
      }
      developer.log(
        'Found ${items.length} total stream items.',
        name: 'AuthService.fetchAllStreamItems',
      );
      return items;
    } catch (e) {
      developer.log(
        'Error fetching all stream items',
        name: 'AuthService.fetchAllStreamItems',
        error: e,
      );
      throw AuthException("Failed to load all stream items.");
    }
  }

  /// Fetches all submissions for all assignments.
  Future<List<Submission>> fetchAllSubmissions() async {
    developer.log(
      'Fetching all submissions.',
      name: 'AuthService.fetchAllSubmissions',
    );
    try {
      final ref = _db.ref('submissions');
      final snapshot = await ref.get();

      final List<Submission> submissions = [];
      if (snapshot.exists && snapshot.value != null) {
        final allAssignmentSubmissions = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        allAssignmentSubmissions.forEach((
          assignmentId,
          assignmentSubmissionsData,
        ) {
          final submissionsMap = Map<String, dynamic>.from(
            assignmentSubmissionsData as Map,
          );
          submissionsMap.forEach((studentUid, submissionData) {
            final submissionMap = Map<String, dynamic>.from(
              submissionData as Map,
            );
            submissions.add(Submission.fromMap(submissionMap, studentUid));
          });
        });
      }
      developer.log(
        'Found ${submissions.length} total submissions.',
        name: 'AuthService.fetchAllSubmissions',
      );
      return submissions;
    } catch (e) {
      developer.log(
        'Error fetching all submissions',
        name: 'AuthService.fetchAllSubmissions',
        error: e,
      );
      throw AuthException("Failed to load all submissions.");
    }
  }

  /// Bulk updates multiple invoices using a single multi-path update.
  Future<void> bulkUpdateInvoices(List<Invoice> invoices) async {
    developer.log(
      'Bulk updating ${invoices.length} invoices.',
      name: 'AuthService.bulkUpdateInvoices',
    );
    try {
      final Map<String, dynamic> updates = {};
      for (final invoice in invoices) {
        updates['/invoices/${invoice.id}'] = invoice.toMap();
      }

      if (updates.isNotEmpty) {
        await _db.ref().update(updates);
        developer.log(
          'Bulk invoice update successful.',
          name: 'AuthService.bulkUpdateInvoices',
        );
      }
    } catch (e) {
      developer.log(
        'Error during bulk invoice update: $e',
        name: 'AuthService.bulkUpdateInvoices',
        error: e,
      );
      throw AuthException("Failed to bulk update invoices.");
    }
  }

  Future<void> bulkCreateInvoices(List<Invoice> invoices) async {
    try {
      if (invoices.isEmpty) return;

      final Map<String, dynamic> updates = {};
      final invoicesRef = _db.ref('invoices');

      for (final invoice in invoices) {
        // Generate a new unique key for each invoice
        final newInvoiceRef = invoicesRef.push();
        final newInvoiceId = newInvoiceRef.key!;
        // Add the new invoice to the updates map with its new ID, using the correct toMap() method
        updates['/invoices/$newInvoiceId'] =
            invoice.copyWith(id: newInvoiceId).toMap();
      }

      await _db.ref().update(updates);
      developer.log(
        'Bulk invoice creation successful for ${invoices.length} invoices.',
        name: 'AuthService.bulkCreateInvoices',
      );
    } catch (e) {
      developer.log(
        'Error during bulk invoice creation: $e',
        name: 'AuthService.bulkCreateInvoices',
        error: e,
      );
      throw AuthException(
        'An unexpected error occurred during batch invoice creation.',
      );
    }
  }

  /// Deletes an invoice and all of its associated payments atomically.
  Future<void> deleteInvoice(String invoiceId) async {
    developer.log(
      'Deleting invoice: $invoiceId',
      name: 'AuthService.deleteInvoice',
    );
    try {
      // First, find all payments associated with this invoice.
      final paymentsToDelete = await fetchPaymentsForInvoice(invoiceId);

      final Map<String, dynamic> updates = {};
      // Mark the invoice for deletion.
      updates['/invoices/$invoiceId'] = null;

      // Mark all associated payments for deletion.
      for (final payment in paymentsToDelete) {
        updates['/payments/${payment.id}'] = null;
      }

      // Perform the multi-path update to delete everything atomically.
      await _db.ref().update(updates);
    } catch (e) {
      developer.log(
        'Error deleting invoice $invoiceId',
        name: 'AuthService.deleteInvoice',
        error: e,
      );
      throw AuthException("Failed to delete invoice and associated payments.");
    }
  }

  /// Deletes multiple invoices and all of their associated payments atomically.
  Future<void> bulkDeleteInvoices(List<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return;

    developer.log(
      'Bulk deleting ${invoiceIds.length} invoices.',
      name: 'AuthService.bulkDeleteInvoices',
    );
    try {
      final Map<String, dynamic> updates = {};

      for (final invoiceId in invoiceIds) {
        final paymentsToDelete = await fetchPaymentsForInvoice(invoiceId);
        updates['/invoices/$invoiceId'] = null;
        for (final payment in paymentsToDelete) {
          updates['/payments/${payment.id}'] = null;
        }
      }

      if (updates.isNotEmpty) {
        await _db.ref().update(updates);
      }
    } catch (e) {
      throw AuthException("Failed to bulk delete invoices.");
    }
  }

  /// Adds a new syllabus entry to the Realtime Database.
  Future<void> addSyllabus(Syllabus syllabus) async {
    developer.log(
      'Adding syllabus: ${syllabus.title}',
      name: 'AuthService.addSyllabus',
    );
    try {
      final Map<String, dynamic> syllabusData = syllabus.toMap();
      // Use a server-side timestamp for consistency
      syllabusData['createdAt'] = ServerValue.timestamp;

      await _db.ref('syllabuses').push().set(syllabusData);
      developer.log(
        'Syllabus added successfully.',
        name: 'AuthService.addSyllabus',
      );
    } catch (e) {
      developer.log(
        'Error adding syllabus',
        name: 'AuthService.addSyllabus',
        error: e,
      );
      throw AuthException("Failed to add syllabus.");
    }
  }

  /// Returns a Stream of syllabus entries for real-time updates.
  Stream<List<Syllabus>> fetchSyllabuses() {
    developer.log(
      'Fetching syllabuses (real-time)',
      name: 'AuthService.fetchSyllabuses',
    );
    final ref = _db.ref('syllabuses').orderByChild('createdAt');

    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final List<Syllabus> syllabuses = [];

      if (snapshot.exists && snapshot.value != null) {
        final itemsMap = Map<String, dynamic>.from(snapshot.value as Map);
        itemsMap.forEach((key, value) {
          syllabuses.add(
            Syllabus.fromMap(key, value as Map<dynamic, dynamic>),
          );
        });
      }
      // Sort descending to show newest items first
      syllabuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      developer.log(
        'Returning ${syllabuses.length} syllabus entries',
        name: 'AuthService.fetchSyllabuses',
      );
      return syllabuses;
    }).handleError((e) {
      developer.log(
        'Error in syllabus stream listener: $e',
        name: 'AuthService.fetchSyllabuses',
        error: e,
      );
      return <Syllabus>[]; // Return empty list on error
    });
  }

  /// Uploads a syllabus file to Firebase Storage.
  /// Returns the download URL of the uploaded file.
  Future<String> uploadSyllabusFile(File file, String syllabusTitle) async {
    developer.log(
      'Uploading syllabus file: ${file.path}',
      name: 'AuthService.uploadSyllabusFile',
    );
    try {
      // Create a unique file name to avoid conflicts.
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('syllabuses')
          .child(syllabusTitle.replaceAll(' ', '_')) // Sanitize title for path
          .child(fileName);

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      developer.log(
        'Syllabus file uploaded successfully: $downloadUrl',
        name: 'AuthService.uploadSyllabusFile',
      );
      return downloadUrl;
    } catch (e) {
      throw AuthException('Failed to upload file: ${e.toString()}');
    }
  }

  /// Uploads an attachment for a stream item to Firebase Storage.
  /// Returns a map containing the download URL and original file name.
  Future<Map<String, String>> uploadStreamAttachment(
    dynamic file,
    String classId,
    String fileName,
  ) async {
    developer.log(
      'Uploading stream attachment for class: $classId',
      name: 'AuthService.uploadStreamAttachment',
    );
    try {
      // Create a unique file name to avoid conflicts.
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('stream_attachments')
          .child(classId)
          .child(uniqueFileName);

      final TaskSnapshot snapshot;
      if (kIsWeb) {
        snapshot = await storageRef.putData(file as Uint8List);
      } else {
        snapshot = await storageRef.putFile(file as File);
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();

      developer.log(
        'Stream attachment uploaded successfully: $downloadUrl',
        name: 'AuthService.uploadStreamAttachment',
      );
      return {'url': downloadUrl, 'fileName': fileName};
    } catch (e) {
      throw AuthException('Failed to upload attachment: ${e.toString()}');
    }
  }

  /// Adds a new exam schedule to the Realtime Database.
  Future<void> addExamSchedule(ExamSchedule schedule) async {
    developer.log(
      'Adding exam schedule: ${schedule.examName}',
      name: 'AuthService.addExamSchedule',
    );
    try {
      final Map<String, dynamic> scheduleData = schedule.toMap();
      // Use a server-side timestamp for consistency
      scheduleData['createdAt'] = ServerValue.timestamp;

      await _db.ref('exam_schedules').push().set(scheduleData);
      developer.log(
        'Exam schedule added successfully.',
        name: 'AuthService.addExamSchedule',
      );
    } catch (e) {
      developer.log(
        'Error adding exam schedule',
        name: 'AuthService.addExamSchedule',
        error: e,
      );
      throw AuthException("Failed to add exam schedule.");
    }
  }

  /// Returns a Stream of exam schedules for real-time updates.
  Stream<List<ExamSchedule>> fetchExamSchedules() {
    developer.log(
      'Fetching exam schedules (real-time)',
      name: 'AuthService.fetchExamSchedules',
    );
    final ref = _db.ref('exam_schedules').orderByChild('examDate');

    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final List<ExamSchedule> schedules = [];

      if (snapshot.exists && snapshot.value != null) {
        final itemsMap = Map<String, dynamic>.from(snapshot.value as Map);
        itemsMap.forEach((key, value) {
          schedules.add(
            ExamSchedule.fromMap(key, value as Map<dynamic, dynamic>),
          );
        });
      }
      developer.log(
        'Returning ${schedules.length} exam schedules',
        name: 'AuthService.fetchExamSchedules',
      );
      return schedules;
    }).handleError((e) {
      developer.log(
        'Error in exam schedule stream listener: $e',
        name: 'AuthService.fetchExamSchedules',
        error: e,
      );
      return <ExamSchedule>[]; // Return empty list on error
    });
  }

  /// Saves or updates the subject-to-teacher mappings for a specific class.
  /// This overwrites all existing mappings for the given classId.
  Future<void> saveSubjectMappings(
    String classId,
    List<SubjectMapping> mappings,
  ) async {
    developer.log(
      'Saving subject mappings for class: $classId',
      name: 'AuthService.saveSubjectMappings',
    );
    try {
      final ref = _db.ref('subject_mappings/$classId');
      final Map<String, dynamic> updates = {};
      for (var mapping in mappings) {
        // Use subjectName as the key under the classId node.
        updates[mapping.subjectName] = mapping.toMap();
      }
      // Using `set` will overwrite all existing mappings for this classId.
      // If `updates` is empty, it will clear the node, which is desired.
      await ref.set(updates);
      developer.log(
        'Subject mappings saved successfully for class $classId.',
        name: 'AuthService.saveSubjectMappings',
      );
    } catch (e) {
      developer.log(
        'Error saving subject mappings for class $classId',
        name: 'AuthService.saveSubjectMappings',
        error: e,
      );
      throw AuthException("Failed to save subject mappings.");
    }
  }

  /// Fetches all subject mappings for a given class.
  Future<List<SubjectMapping>> fetchSubjectMappings(String classId) async {
    developer.log(
      'Fetching subject mappings for class: $classId',
      name: 'AuthService.fetchSubjectMappings',
    );
    try {
      final ref = _db.ref('subject_mappings/$classId');
      final snapshot = await ref.get();

      final List<SubjectMapping> mappings = [];
      if (snapshot.exists && snapshot.value != null) {
        final mappingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        mappingsMap.forEach((subjectName, mappingData) {
          final mappingMap = Map<String, dynamic>.from(mappingData as Map);
          mappings.add(SubjectMapping.fromMap(subjectName, mappingMap));
        });
      }
      mappings.sort((a, b) => a.subjectName.compareTo(b.subjectName));
      developer.log(
        'Found ${mappings.length} subject mappings for class $classId.',
        name: 'AuthService.fetchSubjectMappings',
      );
      return mappings;
    } catch (e) {
      developer.log(
        'Error fetching subject mappings for class $classId',
        name: 'AuthService.fetchSubjectMappings',
        error: e,
      );
      throw AuthException("Failed to fetch subject mappings.");
    }
  }

  Future<List<SubjectMapping>> fetchSubjectsForTeacherInClass(
    String teacherId,
    String classId,
  ) async {
    developer.log(
      'Fetching subjects for teacher $teacherId in class $classId',
      name: 'AuthService.fetchSubjectsForTeacherInClass',
    );
    try {
      final ref = _db.ref('subject_mappings/$classId');
      final snapshot = await ref.get();

      final List<SubjectMapping> subjects = [];
      if (snapshot.exists && snapshot.value != null) {
        final mappingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        mappingsMap.forEach((subjectName, mappingData) {
          final mappingMap = Map<String, dynamic>.from(mappingData as Map);
          if (mappingMap['teacherId'] == teacherId) {
            subjects.add(SubjectMapping.fromMap(subjectName, mappingMap));
          }
        });
      }
      developer.log(
        'Found ${subjects.length} subjects for teacher $teacherId in class $classId',
        name: 'AuthService.fetchSubjectsForTeacherInClass',
      );
      return subjects;
    } catch (e) {
      developer.log(
        'Error fetching subjects for teacher',
        name: 'AuthService.fetchSubjectsForTeacherInClass',
        error: e,
      );
      throw AuthException("Failed to fetch subjects for class.");
    }
  }

  Future<List<AttendanceRecord>> fetchAllAttendanceRecords() async {
    final List<AttendanceRecord> allRecords = [];
    try {
      // Fetch all necessary data in parallel for efficiency
      final results = await Future.wait([
        fetchAllSchoolClasses(),
        fetchAllUsers(),
      ]);

      final List<SchoolClass> allClasses = results[0] as List<SchoolClass>;
      final List<Alluser> allUsers = results[1] as List<Alluser>;

      // Create maps for quick lookups to avoid nested loops
      final studentMap = {
        for (var user in allUsers.where((u) => u.role == 'student'))
          user.uid: user.name
      };
      final classMap = {for (var c in allClasses) c.classId: c.className};

      // Fetch attendance for each class
      for (final schoolClass in allClasses) {
        // This method fetches the raw attendance map for a single class
        final classAttendanceData =
            await fetchAllAttendanceForClass(schoolClass.classId);

        // Process the raw map into structured AttendanceRecord objects
        classAttendanceData.forEach((studentUid, datesMap) {
          datesMap.forEach((dateKey, statusString) {
            allRecords.add(
              AttendanceRecord(
                studentId: studentUid,
                studentName: studentMap[studentUid] ?? 'Unknown Student',
                classId: schoolClass.classId,
                className: classMap[schoolClass.classId] ?? 'Unknown Class',
                date: DateTime.parse(dateKey),
                // Safely convert status string to enum
                status: AttendanceStatus.values.firstWhere(
                  (e) => e.name.toLowerCase() == statusString.toLowerCase(),
                  orElse: () => AttendanceStatus.absentUnexcused,
                ),
              ),
            );
          });
        });
      }
      // Sort records by date descending for a more logical default view
      allRecords.sort((a, b) => b.date.compareTo(a.date));
      return allRecords;
    } catch (e) {
      developer.log('Error fetching all attendance records: $e',
          name: 'AuthService');
      // Re-throw a more specific exception for the UI to handle
      throw AuthException('Could not fetch attendance records.');
    }
  }

  /// Generates a unique student ID based on school config and an atomic counter.
  Future<String> _generateStudentId() async {
    developer.log('Generating new student ID',
        name: 'AuthService._generateStudentId');
    try {
      final now = DateTime.now();
      final academicYear = now.month < 4
          ? '${now.year - 1}-${now.year}'
          : '${now.year}-${now.year + 1}';

      final configRef = _db.ref('school_config');
      final configSnapshot = await configRef.get();
      final config = configSnapshot.exists
          ? Map<String, dynamic>.from(configSnapshot.value as Map)
          : <String, dynamic>{};
      final locationCode = config['locationCode'] as String? ?? 'NA';
      final branchCode = config['branchCode'] as String? ?? 'NA';
      final prefix = config['studentIdPrefix'] as String? ?? 'SCH';

      final counterRef = _db.ref('counters/admission_numbers/$academicYear');
      final transactionResult = await counterRef.runTransaction((currentValue) {
        int currentCount = (currentValue as int?) ?? 0;
        currentCount++;
        return Transaction.success(currentCount);
      });

      if (!transactionResult.committed) {
        throw AuthException(
            'Failed to generate student ID. Could not update counter.');
      }

      final newCount = transactionResult.snapshot.value as int;
      final formattedCount = newCount.toString().padLeft(4, '0');
      final newStudentId = '$prefix-$locationCode-$branchCode-S$formattedCount';
      return newStudentId;
    } catch (e) {
      developer.log('Error generating student ID',
          name: 'AuthService._generateStudentId', error: e);
      throw AuthException("Failed to generate student ID: ${e.toString()}");
    }
  }

  /// Uploads a student's profile photo to Firebase Storage.
  /// Returns the download URL of the uploaded file.
  Future<String?> _uploadProfilePhoto(File photoFile, String uid) async {
    developer.log('Uploading profile photo for UID: $uid',
        name: 'AuthService._uploadProfilePhoto');
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('student_photos')
          .child('$uid.jpg'); // Use UID for a stable file name

      final uploadTask = storageRef.putFile(
        photoFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      developer.log('Photo uploaded successfully: $downloadUrl',
          name: 'AuthService._uploadProfilePhoto');
      return downloadUrl;
    } catch (e) {
      developer.log('Failed to upload profile photo for UID: $uid',
          name: 'AuthService._uploadProfilePhoto', error: e);
      // Don't throw an exception that stops the whole admission process.
      // Just return null and let the admission continue without a photo.
      return null;
    }
  }

  /// Admits a new student by creating an auth user and associated profiles.
  Future<String> admitStudent({
    required String email,
    required String password,
    required String fullName,
    required String fatherName,
    required String motherName,
    required String fatherMobile,
    required String motherMobile,
    required String classId,
    required String admissionYear,
    required String dob,
    required String gender,
    required String bloodGroup,
    File? photoFile,
  }) async {
    developer.log('Admitting new student: $email',
        name: 'AuthService.admitStudent');
    try {
      // Step 1: Call the Cloud Function with all the student data.
      final callable = _functions.httpsCallable('admitStudent');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email,
        'password': password,
        'fullName': fullName,
        'fatherName': fatherName,
        'motherName': motherName,
        'fatherMobile': fatherMobile,
        'motherMobile': motherMobile,
        'classId': classId,
        'admissionYear': admissionYear,
        'dob': dob,
        'gender': gender,
        'bloodGroup': bloodGroup,
      });

      final newStudentId = result.data['studentId'] as String?;
      final newStudentUid = result.data['uid'] as String?;

      if (newStudentId == null || newStudentUid == null) {
        throw AuthException(
            'Cloud function did not return the new student ID or UID.');
      }

      // Step 2: If a photo was provided, upload it now that we have the UID.
      if (photoFile != null) {
        final photoUrl = await _uploadProfilePhoto(photoFile, newStudentUid);
        if (photoUrl != null) {
          // Atomically update the photo URL in both profile locations.
          final Map<String, dynamic> photoUpdates = {};
          photoUpdates['/users/$newStudentUid/image'] = photoUrl;
          photoUpdates['/student_profiles/$newStudentUid/imageUrl'] = photoUrl;
          await _db.ref().update(photoUpdates);
        }
      }

      developer.log('Student admitted successfully: $email',
          name: 'AuthService.admitStudent');
      return newStudentId;
    } on FirebaseFunctionsException catch (e) {
      developer.log(
          'FirebaseFunctionsException during student admission for $email: ${e.code} - ${e.message}',
          name: 'AuthService.admitStudent',
          error: e);
      throw AuthException(e.message ?? "Failed to admit student.");
    } catch (e) {
      developer.log('General error during student admission for $email',
          name: 'AuthService.admitStudent', error: e);
      throw AuthException("An unexpected error occurred during admission.");
    }
  }

  /// Calls a cloud function to create a new Admin or Teacher user.
  Future<void> createAdminOrTeacher({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    if (role != 'admin' && role != 'teacher') {
      throw AuthException(
          'Invalid role specified. Must be "admin" or "teacher".');
    }
    developer.log('Creating new user with role: $role',
        name: 'AuthService.createAdminOrTeacher');
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createAdminOrTeacher');
      await callable.call(<String, dynamic>{
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role,
      });
    } on FirebaseFunctionsException catch (e) {
      // The user's AuthException class doesn't accept a 'code' parameter.
      // We pass a more descriptive message instead, including the code.
      throw AuthException(
          '${e.message ?? 'Failed to create user.'} (Code: ${e.code})');
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Calls a cloud function to generate a password reset link for a user.
  Future<void> createPasswordResetLink({required String email}) async {
    developer.log('Requesting password reset link for: $email',
        name: 'AuthService.createPasswordResetLink');
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createPasswordResetLink');
      await callable.call<Map<String, dynamic>>({
        'email': email,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
          '${e.message ?? 'Failed to generate reset link.'} (Code: ${e.code})');
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Changes the current user's password.
  /// Requires the user's current password for re-authentication.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    developer.log(
      'Attempting to change password for current user.',
      name: 'AuthService.changePassword',
    );
    final user = _auth.currentUser;

    if (user == null) {
      throw AuthException('No user is currently signed in.');
    }
    if (user.email == null) {
      throw AuthException('User email is not available.');
    }

    // Create a credential for re-authentication
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      // Step 1: Re-authenticate the user to verify their identity.
      await user.reauthenticateWithCredential(credential);
      developer.log(
        'User re-authenticated successfully.',
        name: 'AuthService.changePassword',
      );

      // Step 2: If re-authentication is successful, update the password.
      await user.updatePassword(newPassword);
      developer.log(
        'Password updated successfully.',
        name: 'AuthService.changePassword',
      );
    } on FirebaseAuthException catch (e) {
      developer.log(
        'FirebaseAuthException during password change: ${e.code}',
        name: 'AuthService.changePassword',
        error: e,
      );
      // Provide more user-friendly error messages
      if (e.code == 'wrong-password') {
        throw AuthException('The current password you entered is incorrect.');
      } else if (e.code == 'weak-password') {
        throw AuthException('The new password is too weak.');
      } else {
        throw AuthException(
          e.message ?? 'An unknown error occurred while changing password.',
        );
      }
    }
  }

  Future<void> updateUserFcmToken(String userId, String token) async {
    developer.log(
      'Updating FCM token for user: $userId to token: $token',
      name: 'AuthService.updateUserFcmToken',
    );
    try {
      await _db.ref('users/$userId').update({'fcmToken': token});
      developer.log(
        'FCM token updated successfully for user: $userId',
        name: 'AuthService.updateUserFcmToken',
      );
    } catch (e) {
      developer.log(
        'Error updating FCM token for user $userId: $e',
        name: 'AuthService.updateUserFcmToken',
        error: e,
      );
    }
  }
}