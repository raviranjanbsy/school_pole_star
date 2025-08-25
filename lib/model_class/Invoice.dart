import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  final String id; // Unique ID for the invoice
  final String studentUid;
  final String studentName; // Denormalized student name
  final String classId;
  final String className; // Denormalized class name
  final String feeStructureId; // Link to the FeeStructure
  final double amountDue;
  final String status; // e.g., 'pending', 'paid', 'overdue', 'cancelled'
  final double amountPaid; // New: Total amount paid for this invoice
  final int issueDate; // Timestamp
  final int? dueDate; // Optional timestamp
  final int? paymentDate; // Optional timestamp
  final String? studentAdmissionNumber;
  final String? academicYear;
  final String? fatherName;
  final String? motherName;
  final String? feeCategory; // Assuming a single fee category for simplicity
  final String? paymentMethod;
  final String? referenceNumber;
  final String? bankName;
  final String? amountPaidInWords;
  final String? remarks;

  const Invoice({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.feeStructureId,
    required this.amountDue,
    required this.status,
    this.amountPaid = 0.0, // Initialize to 0.0
    required this.issueDate,
    this.dueDate,
    this.paymentDate,
    this.studentAdmissionNumber, // Initialize in constructor
    this.academicYear, // Initialize in constructor
    this.fatherName, // Initialize in constructor
    this.motherName, // Initialize in constructor
    this.feeCategory, // Initialize in constructor
    this.paymentMethod, // Initialize in constructor
    this.referenceNumber, // Initialize in constructor
    this.bankName, // Initialize in constructor
    this.amountPaidInWords, // Initialize in constructor
    this.remarks, // Initialize in constructor
  });

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      feeStructureId: map['feeStructureId'] as String? ?? '',
      amountDue: (map['amountDue'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      amountPaid:
          (map['amountPaid'] as num?)?.toDouble() ?? 0.0, // Read from map
      issueDate: map['issueDate'] as int? ?? 0,
      dueDate: map['dueDate'] as int?,
      paymentDate: map['paymentDate'] as int?,
      studentAdmissionNumber:
          map['studentAdmissionNumber'] as String?, // Add this
      academicYear: map['academicYear'] as String?, // Add this
      fatherName: map['fatherName'] as String?, // Add this
      motherName: map['motherName'] as String?, // Add this
      feeCategory: map['feeCategory'] as String?, // Add this
      paymentMethod: map['paymentMethod'] as String?, // Add this
      referenceNumber: map['referenceNumber'] as String?, // Add this
      bankName: map['bankName'] as String?, // Add this
      amountPaidInWords: map['amountPaidInWords'] as String?, // Add this
      remarks: map['remarks'] as String?, // Add this
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'feeStructureId': feeStructureId,
      'amountDue': amountDue,
      'status': status,
      'amountPaid': amountPaid, // Add to map
      'issueDate': issueDate,
      'dueDate': dueDate,
      'paymentDate': paymentDate,
      'studentAdmissionNumber': studentAdmissionNumber, // Add this
      'academicYear': academicYear, // Add this
      'fatherName': fatherName, // Add this
      'motherName': motherName, // Add this
      'feeCategory': feeCategory, // Add this
      'paymentMethod': paymentMethod, // Add this
      'referenceNumber': referenceNumber, // Add this
      'bankName': bankName, // Add this
      'amountPaidInWords': amountPaidInWords, // Add this
      'remarks': remarks, // Add this
    };
  }

  @override
  List<Object?> get props => [
        id,
        studentUid,
        studentName,
        classId,
        className,
        feeStructureId,
        amountDue,
        status,
        amountPaid,
        issueDate,
        dueDate,
        paymentDate,
        studentAdmissionNumber,
        academicYear,
        fatherName,
        motherName,
        feeCategory,
        paymentMethod,
        referenceNumber,
        bankName,
        amountPaidInWords,
        remarks
      ];

  // Helper method to create a copy with updated fields
  Invoice copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? classId,
    String? className,
    String? feeStructureId,
    double? amountDue,
    String? status,
    double? amountPaid,
    int? issueDate,
    int? dueDate,
    int? paymentDate,
    String? studentAdmissionNumber,
    String? academicYear,
    String? fatherName,
    String? motherName,
    String? feeCategory, // Assuming a single fee category for simplicity
    String? paymentMethod,
    String? referenceNumber,
    String? bankName,
    String? amountPaidInWords,
    String? remarks,
  }) {
    return Invoice(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      feeStructureId: feeStructureId ?? this.feeStructureId,
      amountDue: amountDue ?? this.amountDue,
      status: status ?? this.status,
      amountPaid: amountPaid ?? this.amountPaid,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paymentDate: paymentDate ?? this.paymentDate,
      studentAdmissionNumber:
          studentAdmissionNumber ?? this.studentAdmissionNumber,
      academicYear: academicYear ?? this.academicYear,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      feeCategory: feeCategory ?? this.feeCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      bankName: bankName ?? this.bankName,
      amountPaidInWords: amountPaidInWords ?? this.amountPaidInWords,
      remarks: remarks ?? this.remarks,
    );
  }
}
