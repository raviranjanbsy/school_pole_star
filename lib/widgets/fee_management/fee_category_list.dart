import 'package:flutter/material.dart';
import 'package:school_management/model_class/fee_category.dart';
import 'package:school_management/utils/string_extensions.dart';

class FeeCategoryList extends StatelessWidget {
  final List<FeeCategory> feeCategories;
  final Function(FeeCategory) onEdit;
  final Function(FeeCategory) onDelete;

  const FeeCategoryList({
    super.key,
    required this.feeCategories,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (feeCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No fee categories found.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: feeCategories.length,
      itemBuilder: (context, index) {
        final category = feeCategories[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(category.name),
            subtitle: Text(
                'Amount: ₹${category.amount.toStringAsFixed(2)} | Type: ${category.type.capitalize()}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(category),
                  tooltip: 'Edit Category',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  onPressed: () => onDelete(category),
                  tooltip: 'Delete Category',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
