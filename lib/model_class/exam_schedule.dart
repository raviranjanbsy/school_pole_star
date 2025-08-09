class ExamSchedule {
  final String id;
  final String className;
  final String subject;
  final String examName;
  final int examDate; // Store as millisecondsSinceEpoch
  final String startTime;
  final String endTime;
  final int maxMarks;
  final int createdAt;

  ExamSchedule({
    required this.id,
    required this.className,
    required this.subject,
    required this.examName,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.maxMarks,
    required this.createdAt,
  });

  factory ExamSchedule.fromMap(String id, Map<dynamic, dynamic> value) {
    return ExamSchedule(
      id: id,
      className: value['className'] ?? '',
      subject: value['subject'] ?? '',
      examName: value['examName'] ?? '',
      examDate: value['examDate'] ?? 0,
      startTime: value['startTime'] ?? '',
      endTime: value['endTime'] ?? '',
      maxMarks: value['maxMarks'] ?? 0,
      createdAt: value['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
      'examName': examName,
      'examDate': examDate,
      'startTime': startTime,
      'endTime': endTime,
      'maxMarks': maxMarks,
      // createdAt will be set by the server
    };
  }
}
