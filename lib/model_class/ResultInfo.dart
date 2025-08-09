class ResultInfo {
  int? resultId;
  String? studentId;
  String? class1;
  String? section;
  Map<String, double>? subjectwiseResult;
  String? passFail;
  double? totalMarks;
  double? grade;
  String? examTitle;

  ResultInfo({
    this.resultId,
    required this.studentId,
    required this.class1,
    required this.section,
    required this.subjectwiseResult,
    this.passFail,
    this.totalMarks,
    this.grade,
    required this.examTitle,
  });

  // Factory constructor to create a ResultInfo object from JSON
  factory ResultInfo.fromJson(Map<String, dynamic> json) {
    return ResultInfo(
      resultId: json['result_id'],
      studentId: json['student_id'],
      class1: json['class1'],
      section: json['section'],
      subjectwiseResult: Map<String, double>.from(json['subjectwise_result']),
      passFail: json['pass_fail'],
      totalMarks: json['total_marks'],
      grade: json['grade'],
      examTitle: json['exam_title'],
    );
  }

  // Method to convert a ResultInfo object to JSON
  Map<String, dynamic> toJson() {
    return {
      'result_id': resultId,
      'student_id': studentId,
      'class1': class1,
      'section': section,
      'subjectwise_result': subjectwiseResult,
      'pass_fail': passFail,
      'total_marks': totalMarks,
      'grade': grade,
      'exam_title': examTitle,
    };
  }
}
