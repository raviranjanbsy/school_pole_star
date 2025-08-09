class StudentTable {
  final String uid;
  final String email;
  final String fullName;
  final String? studentId;
  final String? fatherName;
  final String? motherName;
  final String? fatherMobile; // New field
  final String? motherMobile; // New field
  final String? classId;
  final String? admissionYear;
  final String? dob;
  final String? mob;
  final String? bloodGroup;
  final String? gender;
  final String? section;
  final String? session;
  final String? subject;
  final String? presentAddress;
  final String? permanentAddress;
  final String status;
  final String? imageUrl;
  final int? rollNumber;

  StudentTable({
    required this.uid,
    required this.email,
    required this.fullName,
    this.studentId,
    this.fatherName,
    this.motherName,
    this.fatherMobile, // Add to constructor
    this.motherMobile, // Add to constructor
    this.classId,
    this.admissionYear,
    this.dob,
    this.mob,
    this.bloodGroup,
    this.gender,
    this.section,
    this.session,
    this.subject,
    this.presentAddress,
    this.permanentAddress,
    required this.status,
    this.imageUrl,
    this.rollNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'studentId': studentId,
      'fatherName': fatherName,
      'motherName': motherName,
      'fatherMobile': fatherMobile, // Add to map
      'motherMobile': motherMobile, // Add to map
      'classId': classId,
      'admissionYear': admissionYear,
      'dob': dob,
      'mob': mob,
      'bloodGroup': bloodGroup,
      'gender': gender,
      'section': section,
      'session': session,
      'subject': subject,
      'presentAddress': presentAddress,
      'permanentAddress': permanentAddress,
      'status': status,
      'imageUrl': imageUrl,
      'rollNumber': rollNumber,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory StudentTable.fromMap(Map<String, dynamic> map, String uid) {
    return StudentTable(
      uid: uid,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? 'Unknown Student',
      studentId: map['studentId'] as String?,
      fatherName: map['fatherName'] as String?,
      motherName: map['motherName'] as String?,
      fatherMobile: map['fatherMobile'] as String?,
      motherMobile: map['motherMobile'] as String?,
      classId: map['classId'] as String?,
      admissionYear: map['admissionYear'] as String?,
      dob: map['dob'] as String?,
      mob: map['mob'] as String?,
      bloodGroup: map['bloodGroup'] as String?,
      gender: map['gender'] as String?,
      section: map['section'] as String?,
      session: map['session'] as String?,
      subject: map['subject'] as String?,
      presentAddress: map['presentAddress'] as String?,
      permanentAddress: map['permanentAddress'] as String?,
      status: map['status'] as String? ?? 'inactive',
      imageUrl: map['imageUrl'] as String?,
      rollNumber: map['rollNumber'] as int?,
    );
  }

  StudentTable copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? studentId,
    String? fatherName,
    String? motherName,
    String? fatherMobile,
    String? motherMobile,
    String? classId,
    String? admissionYear,
    String? dob,
    String? mob,
    String? bloodGroup,
    String? gender,
    String? section,
    String? session,
    String? subject,
    String? presentAddress,
    String? permanentAddress,
    String? status,
    String? imageUrl,
    int? rollNumber,
  }) {
    return StudentTable(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      fatherMobile: fatherMobile ?? this.fatherMobile,
      motherMobile: motherMobile ?? this.motherMobile,
      classId: classId ?? this.classId,
      admissionYear: admissionYear ?? this.admissionYear,
      dob: dob ?? this.dob,
      mob: mob ?? this.mob,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      gender: gender ?? this.gender,
      section: section ?? this.section,
      session: session ?? this.session,
      subject: subject ?? this.subject,
      presentAddress: presentAddress ?? this.presentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      rollNumber: rollNumber ?? this.rollNumber,
    );
  }
}
