import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id; // Unique ID for the payment (Firebase generated)
  final String invoiceId; // ID of the invoice this payment is for
  final double amount;
  final int paymentDate; // Timestamp of the payment
  final String paymentMethod; // e.g., 'cash', 'bank transfer', 'online'
  final String? notes; // Any additional notes about the payment

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      invoiceId: map['invoiceId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] as int? ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? 'unknown',
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'amount': amount,
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props =>
      [id, invoiceId, amount, paymentDate, paymentMethod, notes];
}
