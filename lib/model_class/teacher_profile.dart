import 'package:equatable/equatable.dart';

/// A model class representing a teacher's profile data.
///
/// This class is immutable and uses camelCase for property names,
/// but serializes to/from snake_case to match the Firebase Realtime Database schema.
class TeacherProfile extends Equatable {
  /// The Firebase Authentication UID of the user. This is the key for the teacher's
  /// profile node in the Realtime Database.
  final String uid;
  final String name;
  final String email;
  final String? qualification;
  final String? mobileNo;
  final String role;
  final String? status;
  final String? joiningDate; // Stored as 'yyyy-MM-dd'
  final String? imageUrl;

  const TeacherProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.qualification,
    this.mobileNo,
    required this.role,
    this.status,
    this.joiningDate,
    this.imageUrl,
  });

  /// Creates a [TeacherProfile] instance from a map (e.g., from Firebase).
  ///
  /// The [uid] is the key of the database node and is passed separately.
  factory TeacherProfile.fromMap(Map<String, dynamic> map, String uid) {
    return TeacherProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      qualification: map['qualification'] as String?,
      mobileNo: map['mobileNo'] as String?,
      role: map['role'] as String? ?? 'teacher', // Default role
      status: map['status'] as String?,
      joiningDate: map['joiningDate'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  /// Converts this object into a map for database storage.
  ///
  /// Note: The `uid` is not included as it's the key of the database node.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'qualification': qualification,
      'mobileNo': mobileNo,
      'role': role,
      'status': status,
      'joiningDate': joiningDate,
      'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        qualification,
        mobileNo,
        role,
        status,
        joiningDate,
        imageUrl,
      ];
}
