import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/model_class/invoice.dart';
import 'package:school_management/providers/auth_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Service to handle invoice-related database operations
class InvoiceService {
  final DatabaseReference _dbRef;

  InvoiceService(this._dbRef);

  Future<void> processInvoicePayment(String invoiceId, double amountPaid) {
    return _dbRef.child(invoiceId).update({
      'status': 'paid',
      'amountPaid': amountPaid,
      'paymentDate': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

Future<String> createPaymentIntent({
  required double amount,
  required String currency,
  String? invoiceId,
}) async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
  final response = await callable.call<Map<String, dynamic>>({
    // Stripe expects the amount in the smallest currency unit (e.g., cents/paise).
    'amount': (amount * 100).toInt(),
    'currency': currency,
    'invoiceId': invoiceId,
  });

  return response.data['clientSecret'] as String;
}

// Provider for the InvoiceService
final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  final dbRef = FirebaseDatabase.instance.ref('invoices');
  return InvoiceService(dbRef);
});

// This provider will fetch the invoices for the currently logged-in student.
final myInvoicesProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final studentId = authService.getAuth().currentUser?.uid;

  if (studentId == null) {
    // If no user is logged in, return an empty stream.
    return Stream.value([]);
  }

  final dbRef = FirebaseDatabase.instance.ref('invoices');

  // Query the database for invoices where 'studentUid' matches the logged-in user.
  final query = dbRef.orderByChild('studentUid').equalTo(studentId);

  // Listen to the stream of data.
  return query.onValue.map((event) {
    final data = event.snapshot.value;
    if (data == null) {
      return <Invoice>[];
    }

    final invoicesMap = data as Map<dynamic, dynamic>;
    return invoicesMap.entries.map((entry) {
      final invoiceData = Map<String, dynamic>.from(entry.value as Map);
      return Invoice.fromMap(invoiceData, entry.key as String);
    }).toList();
  });
});
