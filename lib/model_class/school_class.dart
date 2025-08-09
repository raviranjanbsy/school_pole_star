import 'package:equatable/equatable.dart';

/// Represents a class in the school, which contains a list of subjects.
class SchoolClass extends Equatable {
  final String classId; // A unique ID for the class, e.g., "GRADE_10"
  final String className;
  final List<String> subjects; // e.g., ['Mathematics', 'Science', 'English']

  final String status; // e.g., 'active', 'archived'
  final int createdAt;
  final String? teacherId;
  final String? teacherName;

  const SchoolClass({
    required this.classId,
    required this.className,
    required this.subjects,
    required this.status,
    required this.createdAt,
    this.teacherId,
    this.teacherName,
  });

  /// Creates a [SchoolClass] from a map snapshot from Firebase.
  /// The [id] is the key of the record in the database.
  factory SchoolClass.fromMap(Map<String, dynamic> map, String id) {
    return SchoolClass(
      classId: id,
      className: map['className'] as String? ?? 'Unnamed Class',
      // Handle list from Firebase, which might be List<dynamic>
      subjects: List<String>.from(map['subjects'] as List<dynamic>? ?? []),

      status: map['status'] as String? ?? 'active',
      createdAt: map['createdAt'] as int? ?? 0,
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
    );
  }

  /// Converts this object to a map for database storage.
  /// The classId is not included as it's the key of the database node.
  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subjects': subjects,
      'status': status,
      'createdAt': createdAt,
      'teacherId': teacherId,
      'teacherName': teacherName,
    };
  }

  SchoolClass copyWith({
    String? classId,
    String? className,
    List<String>? subjects,
    String? status,
    int? createdAt,
    String? teacherId,
    String? teacherName,
  }) {
    return SchoolClass(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjects: subjects ?? this.subjects,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      teacherId: teacherId,
      teacherName: teacherName,
    );
  }

  @override
  List<Object?> get props =>
      [classId, className, subjects, status, createdAt, teacherId, teacherName];
}
