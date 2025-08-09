class PaymentRecord {
  final String studentId;
  final String feeType;
  final String month;
  final double amountPaid;
  final double totalFee;

  PaymentRecord({
    required this.studentId,
    required this.feeType,
    required this.month,
    required this.amountPaid,
    required this.totalFee,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      studentId: json['studentId'],
      feeType: json['feeType'],
      month: json['month'],
      amountPaid: json['amountPaid'].toDouble(),
      totalFee: json['totalFee'].toDouble(),
    );
  }
}
