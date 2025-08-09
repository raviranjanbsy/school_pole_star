import 'package:flutter/material.dart';
import 'package:school_management/model_class/Invoice.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/utils/string_extensions.dart';

class InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final Map<String, StudentTable> studentMap;
  final Set<String> selectedInvoiceIds;
  final bool isSelectionMode;
  final Function(String) onToggleSelection;
  final Function(Invoice) onManagePayment;
  final Function(Invoice) onMarkAsPaid;
  final Function(Invoice) onDelete;

  const InvoiceList({
    super.key,
    required this.invoices,
    required this.studentMap,
    required this.selectedInvoiceIds,
    required this.isSelectionMode,
    required this.onToggleSelection,
    required this.onManagePayment,
    required this.onMarkAsPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No invoices match the current filters.')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final isSelected = selectedInvoiceIds.contains(invoice.id);
        final student = studentMap[invoice.studentUid];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: isSelected ? Colors.blue.shade100 : null,
          child: ListTile(
            onTap: () {
              if (isSelectionMode) {
                onToggleSelection(invoice.id);
              } else {
                onManagePayment(invoice);
              }
            },
            onLongPress: () {
              onToggleSelection(invoice.id);
            },
            leading: isSelectionMode
                ? Icon(isSelected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank)
                : null,
            title: Text(
              'Invoice for ${student?.fullName ?? invoice.studentName}',
            ),
            subtitle: Text(
              'Class: ${invoice.className}\nAmount: ₹${invoice.amountDue.toStringAsFixed(2)} | Status: ${invoice.status.capitalize()}',
            ),
            isThreeLine: true,
            trailing: isSelectionMode
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (invoice.amountDue == invoice.amountPaid &&
                          invoice.status != 'paid')
                        IconButton(
                          icon: Icon(Icons.check_circle,
                              color: Colors.green.shade700),
                          onPressed: () => onMarkAsPaid(invoice),
                          tooltip: 'Mark as Paid',
                        ),
                      IconButton(
                        icon: const Icon(Icons.payment),
                        onPressed: () => onManagePayment(invoice),
                        tooltip: 'Manage Payments',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade400),
                        onPressed: () => onDelete(invoice),
                        tooltip: 'Delete Invoice',
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
