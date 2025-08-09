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
        paymentDate
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
    );
  }
}
