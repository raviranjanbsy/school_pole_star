import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:intl/intl.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/invoice.dart';
import 'package:school_management/providers/invoice_provider.dart';
import 'package:school_management/widgets/gradient_container.dart';

class MyInvoicesPage extends ConsumerStatefulWidget {
  const MyInvoicesPage({super.key});

  @override
  ConsumerState<MyInvoicesPage> createState() => _MyInvoicesPageState();
}

class _MyInvoicesPageState extends ConsumerState<MyInvoicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsyncValue = ref.watch(myInvoicesProvider);

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Invoices'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Paid'),
            ],
          ),
        ),
        body: invoicesAsyncValue.when(
          data: (invoices) {
            final pendingInvoices = invoices
                .where((invoice) =>
                    invoice.status.toLowerCase() == 'pending' ||
                    invoice.status.toLowerCase() == 'overdue')
                .toList();
            final paidInvoices = invoices
                .where((invoice) => invoice.status.toLowerCase() == 'paid')
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesList(pendingInvoices),
                _buildInvoicesList(paidInvoices),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading invoices: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicesList(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return const Center(
        child: Text(
          'You have no invoices in this category.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        return InvoiceTile(invoice: invoices[index]);
      },
    );
  }
}

class InvoiceTile extends ConsumerWidget {
  final Invoice invoice;

  const InvoiceTile({super.key, required this.invoice});

  void _handlePayment(BuildContext tileContext, WidgetRef ref, Invoice invoice,
      NumberFormat currencyFormat) {
    // Capture the ScaffoldMessenger from the tile's context BEFORE the async gap.
    // This is safer than calling ScaffoldMessenger.of(context) after an await.
    final scaffoldMessenger = ScaffoldMessenger.of(tileContext);

    // This is where you would integrate your payment gateway SDK (e.g., Stripe, Razorpay).
    // For this example, we'll just show a confirmation dialog.
    showDialog(
      context: tileContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
            'Proceed to pay ${currencyFormat.format(invoice.amountDue)} for this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // This is a placeholder for your actual payment processing logic.
              final paymentSuccessful = await _processMockPayment();

              // Check if the dialog is still mounted before trying to pop it.
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(); // Close the dialog

              if (paymentSuccessful) {
                // On successful payment, update the invoice in Firebase.
                try {
                  await ref
                      .read(invoiceServiceProvider)
                      .processInvoicePayment(invoice.id, invoice.amountDue);

                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Payment Successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update invoice: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Payment failed. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  /// A mock payment processing function.
  /// Replace this with your actual payment gateway integration.
  Future<bool> _processMockPayment() async {
    // Simulate a network call to a payment gateway
    await Future.delayed(const Duration(seconds: 2));
    return true; // Simulate success
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData statusIcon;
    Color statusColor;
    Color statusTextColor;

    switch (invoice.status.toLowerCase()) {
      case 'paid':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusTextColor = Colors.green.shade700;
        break;
      case 'overdue':
        statusIcon = Icons.error;
        statusColor = Colors.red;
        statusTextColor = Colors.red.shade700;
        break;
      case 'pending':
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        statusTextColor = Colors.orange.shade800;
        break;
      default: // 'cancelled' or other statuses
        statusIcon = Icons.cancel;
        statusColor = Colors.grey;
        statusTextColor = Colors.grey.shade700;
    }

    final bool isPayable = invoice.status.toLowerCase() == 'pending' ||
        invoice.status.toLowerCase() == 'overdue';

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    String formattedDueDate = 'N/A';
    if (invoice.dueDate != null) {
      // Convert timestamp (int) to DateTime for formatting
      formattedDueDate = DateFormat.yMMMd()
          .format(DateTime.fromMillisecondsSinceEpoch(invoice.dueDate!));
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        isThreeLine: true,
        leading: Icon(statusIcon, color: statusColor),
        title: Text('Invoice for ${invoice.className}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Amount Due: ${currencyFormat.format(invoice.amountDue)}\n'
          '${invoice.amountPaid > 0 ? 'Amount Paid: ${currencyFormat.format(invoice.amountPaid)}\n' : ''}'
          'Due Date: $formattedDueDate',
          // Adding a small line height to improve readability of multi-line text
          style: const TextStyle(height: 1.4),
        ),
        trailing: isPayable
            ? IntrinsicWidth(
                child: ElevatedButton(
                  onPressed: () =>
                      _handlePayment(context, ref, invoice, currencyFormat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Pay Now'),
                ),
              )
            : Text(invoice.status.toUpperCase(),
                style: TextStyle(
                    color: statusTextColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
