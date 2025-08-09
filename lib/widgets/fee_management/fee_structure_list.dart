import 'package:flutter/material.dart';
import 'package:school_management/model_class/FeeStructure.dart';

class FeeStructureList extends StatelessWidget {
  final List<FeeStructure> feeStructures;
  final Function(FeeStructure) onEdit;
  final Function(FeeStructure) onDelete;

  const FeeStructureList({
    super.key,
    required this.feeStructures,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (feeStructures.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No fee structures defined.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: feeStructures.length,
      itemBuilder: (context, index) {
        final fee = feeStructures[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(
              '${fee.feeCategoryName} for ${fee.className}',
            ),
            subtitle: Text(
              'Academic Year: ${fee.academicYear}\nAmount: ₹${fee.amount?.toStringAsFixed(2) ?? 'N/A'}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(fee),
                  tooltip: 'Edit Structure',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  onPressed: () => onDelete(fee),
                  tooltip: 'Delete Structure',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
