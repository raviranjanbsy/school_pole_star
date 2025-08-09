import 'package:equatable/equatable.dart';

class Submission extends Equatable {
  final String studentUid;
  final String studentName;
  final String fileUrl;
  final DateTime submissionTimestamp;
  final String? grade;
  final String? comments;
  final String assignmentId;
  const Submission({
    required this.studentUid,
    required this.studentName,
    required this.fileUrl,
    required this.submissionTimestamp,
    this.grade,
    this.comments,
    required this.assignmentId,
  });

  factory Submission.fromMap(Map<String, dynamic> data, String studentUid) {
    return Submission(
      studentUid: studentUid,
      studentName: data['student_name'] as String? ?? 'Unknown Student',
      fileUrl: data['file_url'] as String? ?? '',
      // Handle the timestamp which is stored as milliseconds since epoch
      submissionTimestamp: data['submission_timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['submission_timestamp'])
          : DateTime.now(), // Fallback for safety
      grade: data['grade'] as String?,
      comments: data['comments'] as String?,
      assignmentId: data['assignmentId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_uid': studentUid,
      'student_name': studentName,
      'file_url': fileUrl,
      'submission_timestamp': submissionTimestamp.millisecondsSinceEpoch,
      'grade': grade,
      'comments': comments,
      'assignmentId': assignmentId,
    };
  }

  Submission copyWith({
    String? studentUid,
    String? studentName,
    String? fileUrl,
    DateTime? submissionTimestamp,
    String? grade,
    String? comments,
    String? assignmentId,
  }) {
    return Submission(
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      fileUrl: fileUrl ?? this.fileUrl,
      submissionTimestamp: submissionTimestamp ?? this.submissionTimestamp,
      grade: grade ?? this.grade,
      comments: comments ?? this.comments,
      assignmentId: assignmentId ?? this.assignmentId,
    );
  }

  @override
  List<Object?> get props => [
        studentUid,
        studentName,
        fileUrl,
        submissionTimestamp,
        grade,
        comments,
        assignmentId
      ];
}
