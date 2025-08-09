// class Classroutine {
//   String? day;
//   String? className;
//   String? section;
//   String? subject;
//   String? startTime;
//   String? endTime;
//   String? teacher;
//   String? roomNo;
//
//   Classroutine({
//     required this.day,
//     required this.className,
//     required this.section,
//     required this.subject,
//     required this.startTime,
//     required this.endTime,
//     required this.teacher,
//     required this.roomNo,
//   });
//
//   factory Classroutine.fromJson(Map<String, dynamic> json) => Classroutine(
//     day: json['day'] as String?,
//     className: json['className'] as String?,
//     section: json['section'] as String?,
//     subject: json['subject'] as String?,
//     startTime: json['startTime'] as String?,
//     endTime: json['endTime'] as String?,
//     teacher: json['teacher'] as String?,
//     roomNo: json['roomNo'] as String?,
//   );
//
//   Map<String, dynamic> toJson() => {
//     "Day": day,
//     "Class1": className,
//     "Section": section,
//     "Subject": subject,
//     "startTime": startTime,
//     "endTime": endTime,
//     "Teacher": teacher,
//     "roomNo": roomNo,
//   };
// }

class Classroutine {
  final String day;
  final String className;
  final String section;
  final String subject;
  final String startTime;
  final String endTime;
  final String teacher;
  final String roomNo;

  Classroutine({
    required this.day,
    required this.className,
    required this.section,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.teacher,
    required this.roomNo,
  });

  factory Classroutine.fromJson(Map<String, dynamic> json) => Classroutine(
    day: json['day'] ?? '',
    className: json['className'] ?? '',
    section: json['section'] ?? '',
    subject: json['subject'] ?? '',
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
    teacher: json['teacher'] ?? '',
    roomNo: json['roomNo'] ?? '',
  );


  Map<String, dynamic> toJson() => {
    "day": day,
    "className": className,
    "section": section,
    "subject": subject,
    "startTime": startTime,
    "endTime": endTime,
    "teacher": teacher,
    "roomNo": roomNo,
  };
}
