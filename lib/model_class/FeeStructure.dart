import 'package:equatable/equatable.dart';

/// Represents the application of a specific FeeCategory to a SchoolClass for an academic year.
/// This model acts as a link between a class and a fee.
class FeeStructure extends Equatable {
  final String
      id; // Unique ID for this structure, e.g., classId_feeCategoryId_year
  final String classId; // The class this fee structure applies to
  final String feeCategoryId; // The ID of the FeeCategory being applied
  final String academicYear; // e.g., "2023-2024"

  // Denormalized data for easier display in lists.
  // This data is copied from the linked SchoolClass and FeeCategory when the structure is created.
  final String? className;
  final String? feeCategoryName;
  final double? amount;

  const FeeStructure({
    required this.id,
    required this.classId,
    required this.feeCategoryId,
    required this.academicYear,
    this.className,
    this.feeCategoryName,
    this.amount,
  });

  factory FeeStructure.fromMap(Map<String, dynamic> map, String id) {
    return FeeStructure(
      id: id,
      classId: map['classId'] as String? ?? '',
      feeCategoryId: map['feeCategoryId'] as String? ?? '',
      academicYear: map['academicYear'] as String? ?? '',
      className: map['className'] as String?,
      feeCategoryName: map['feeCategoryName'] as String?,
      amount: (map['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'feeCategoryId': feeCategoryId,
      'academicYear': academicYear,
      'className': className,
      'feeCategoryName': feeCategoryName,
      'amount': amount,
    };
  }

  @override
  List<Object?> get props => [id, classId, feeCategoryId, academicYear];
}

extension FeeStructureCopyWith on FeeStructure {
  FeeStructure copyWith({
    String? id,
    String? classId,
    String? feeCategoryId,
    String? academicYear,
    String? className,
    String? feeCategoryName,
    double? amount,
  }) {
    return FeeStructure(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      feeCategoryId: feeCategoryId ?? this.feeCategoryId,
      academicYear: academicYear ?? this.academicYear,
      className: className ?? this.className,
      feeCategoryName: feeCategoryName ?? this.feeCategoryName,
      amount: amount ?? this.amount,
    );
  }
}
