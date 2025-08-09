class Attendanceinfo {
  int? attendanceId;
  int? studentId;
  String? studentName;
  String? class1;
  String? section;
  String? attendanceDate;
  String? attendanceStatus;

  Attendanceinfo({
    required this.attendanceId,
    required this.studentId,
    required this.studentName,
    required this.class1,
    required this.section,
    required this.attendanceDate,
    required this.attendanceStatus,
  });
  factory Attendanceinfo.fromJson(Map<String, dynamic> json) => Attendanceinfo(
        attendanceId: json['attendanceId'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        class1: json['class1'],
        section: json['section'],
        attendanceDate: json['attendanceDate'],
        attendanceStatus: json['attendanceStatus'],
      );
  Map<String, dynamic> toJson() {
    return {
      "attendanceId": attendanceId,
      "studentId": studentId,
      "studentName": studentName,
      "class1": class1,
      "section": section,
      "attendanceDate": attendanceDate,
      "attendanceStatus": attendanceStatus,
    };
  }
}
