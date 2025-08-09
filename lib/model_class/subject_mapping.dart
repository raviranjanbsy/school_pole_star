class SubjectMapping {
  final String subjectName; // The key in the database
  final String teacherId;
  final String teacherName;

  SubjectMapping({
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
  });

  // Factory to create a SubjectMapping from a map retrieved from Firebase.
  // The `subjectName` is the key of the map entry.
  factory SubjectMapping.fromMap(
      String subjectName, Map<dynamic, dynamic> value) {
    return SubjectMapping(
      subjectName: subjectName,
      teacherId: value['teacherId'] ?? '',
      teacherName: value['teacherName'] ?? '',
    );
  }

  // Method to convert a SubjectMapping object to a map for Firebase.
  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
    };
  }
}
