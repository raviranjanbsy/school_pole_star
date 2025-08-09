import 'package:flutter/material.dart';
import 'package:school_management/model_class/FeeStructure.dart';
import 'package:school_management/model_class/Invoice.dart';

class InvoiceSummaryCard extends StatelessWidget {
  final List<Invoice> allInvoices;
  final List<FeeStructure> feeStructures;
  final String? selectedAcademicYear;

  const InvoiceSummaryCard({
    super.key,
    required this.allInvoices,
    required this.feeStructures,
    this.selectedAcademicYear,
  });

  @override
  Widget build(BuildContext context) {
    if (allInvoices.isEmpty) {
      return const SizedBox.shrink(); // Don't show card if no invoices
    }

    // Create a lookup map for fee structures for efficient access.
    final feeStructureMap = <String, FeeStructure>{};
    for (var fs in feeStructures) {
      feeStructureMap[fs.id] = fs;
    }

    // Filter invoices for the selected academic year to calculate summary
    final invoicesForSummary = selectedAcademicYear == null
        ? allInvoices // Fallback, should not happen if a year is defaulted
        : allInvoices.where((invoice) {
            final feeStructure = feeStructureMap[invoice.feeStructureId];
            return feeStructure?.academicYear == selectedAcademicYear;
          }).toList();

    if (invoicesForSummary.isEmpty && selectedAcademicYear != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Summary for $selectedAcademicYear',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(),
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No invoice data for this academic year.'),
                ))
              ],
            ),
          ),
        ),
      );
    }

    double totalAmountCollected = 0.0;
    double totalRemainingOverdue = 0.0;
    double totalRemainingNotOverdue = 0.0;

    for (var invoice in invoicesForSummary) {
      totalAmountCollected += invoice.amountPaid;

      if (invoice.status != 'paid') {
        final double remaining = invoice.amountDue - invoice.amountPaid;

        final bool isDynamicallyOverdue = invoice.dueDate != null &&
            DateTime.fromMillisecondsSinceEpoch(invoice.dueDate!)
                .isBefore(DateTime.now());

        if (isDynamicallyOverdue) {
          totalRemainingOverdue += remaining;
        } else {
          totalRemainingNotOverdue += remaining;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoice Summary for $selectedAcademicYear',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              _buildSummaryRow(
                'Total Pending:',
                '₹${totalRemainingNotOverdue.toStringAsFixed(2)}',
                color: Colors.orange.shade700,
              ),
              _buildSummaryRow(
                'Total Paid:',
                '₹${totalAmountCollected.toStringAsFixed(2)}',
                color: Colors.green.shade700,
              ),
              _buildSummaryRow(
                'Total Overdue:',
                '₹${totalRemainingOverdue.toStringAsFixed(2)}',
                color: Colors.red.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: color)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
