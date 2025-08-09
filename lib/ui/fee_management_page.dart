import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/model_class/fee_category.dart';
import 'package:school_management/model_class/FeeStructure.dart';
import 'package:school_management/model_class/Invoice.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/Payment.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/utils/string_extensions.dart'; // New import for capitalize
import 'package:intl/intl.dart'; // New import for DateFormat
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/providers/auth_provider.dart';
import 'package:school_management/widgets/fee_management/fee_structure_list.dart';
import 'package:school_management/widgets/fee_management/invoice_list.dart';
import 'package:school_management/widgets/fee_management/fee_category_list.dart';
import 'package:school_management/widgets/fee_management/invoice_summary_card.dart';
import 'package:school_management/widgets/fee_management/invoice_filter_controls.dart';
import 'package:school_management/providers/fee_management_provider.dart';
import 'package:school_management/widgets/gradient_container.dart';

import 'dart:developer' as developer;

enum InvoiceSortOption {
  issueDateDesc,
  issueDateAsc,
  dueDateDesc,
  dueDateAsc,
  amountDesc,
  amountAsc,
  studentNameAsc,
  studentNameDesc,
}

class FeeManagementPage extends ConsumerStatefulWidget {
  const FeeManagementPage({super.key});

  @override
  ConsumerState<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends ConsumerState<FeeManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final notifier = ref.read(feeManagementNotifierProvider.notifier);
      final currentSearchQuery =
          ref.read(feeManagementNotifierProvider).value?.searchQuery ?? '';
      if (_searchController.text != currentSearchQuery) {
        notifier.setSearchQuery(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getSortOptionLabel(InvoiceSortOption option) {
    switch (option) {
      case InvoiceSortOption.issueDateDesc:
        return 'Sort by Issue Date (Newest First)';
      case InvoiceSortOption.issueDateAsc:
        return 'Sort by Issue Date (Oldest First)';
      case InvoiceSortOption.dueDateDesc:
        return 'Sort by Due Date (Newest First)';
      case InvoiceSortOption.dueDateAsc:
        return 'Sort by Due Date (Oldest First)';
      case InvoiceSortOption.amountDesc:
        return 'Sort by Amount (High to Low)';
      case InvoiceSortOption.amountAsc:
        return 'Sort by Amount (Low to High)';
      case InvoiceSortOption.studentNameAsc:
        return 'Sort by Student Name (A-Z)';
      case InvoiceSortOption.studentNameDesc:
        return 'Sort by Student Name (Z-A)';
    }
  }

  Future<void> _addFeeStructure(FeeManagementState state) async {
    // For simplicity, let's create a basic dialog to add a fee structure.
    // In a real app, this would be a more complex form.
    final _formKey = GlobalKey<FormState>();
    final TextEditingController academicYearController = TextEditingController(
      text: '2023-2024',
    );
    final schoolClasses = state.schoolClasses;
    final feeCategories = state.feeCategories;
    SchoolClass? selectedClass;
    FeeCategory? selectedFeeCategory;

    final result = await showDialog<FeeStructure>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Fee to Class'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<SchoolClass>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Class',
                        ),
                        value: selectedClass,
                        items: schoolClasses.map((cls) {
                          return DropdownMenuItem(
                            value: cls,
                            child: Text(cls.className,
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => selectedClass = value),
                        validator: (v) =>
                            v == null ? 'Please select a class' : null,
                      ),
                      DropdownButtonFormField<FeeCategory>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Fee Category',
                        ),
                        value: selectedFeeCategory,
                        items: feeCategories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text('${cat.name} - ₹${cat.amount}',
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => selectedFeeCategory = value),
                        validator: (v) =>
                            v == null ? 'Please select a fee category' : null,
                      ),
                      TextFormField(
                        controller: academicYearController,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Academic Year is required' : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final id =
                      '${selectedClass!.classId}_${selectedFeeCategory!.id}_${academicYearController.text.replaceAll('-', '')}';

                  Navigator.pop(
                    context,
                    FeeStructure(
                      id: id, // Using classId as fee structure ID for simplicity
                      classId: selectedClass!.classId,
                      feeCategoryId: selectedFeeCategory!.id,
                      academicYear: academicYearController.text,
                      // Denormalize data for display
                      className: selectedClass!.className,
                      feeCategoryName: selectedFeeCategory!.name,
                      amount: selectedFeeCategory!.amount,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .addFeeStructure(result);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Fee structure added!')));
      } on AuthException catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add fee structure: ${e.message}'),
            ),
          );
      }
    }
  }

  Future<void> _addFeeCategory(FeeManagementState state) async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedType = 'recurring'; // Default value

    final result = await showDialog<FeeCategory>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Fee Category'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Category Name'),
                        validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null,
                      ),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Amount is required';
                          if (double.tryParse(v) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Fee Type'),
                        value: selectedType,
                        items: ['recurring', 'one-time']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.capitalize()),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedType = value),
                        validator: (v) =>
                            v == null ? 'Please select a type' : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    FeeCategory(
                      id: '', // Firestore will generate
                      name: nameController.text,
                      amount: double.parse(amountController.text),
                      type: selectedType!,
                      isOptional: false, // Default value for new categories
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .addFeeCategory(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee category added!')),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add category: ${e.message}')),
          );
        }
      }
    }
  }

  Future<void> _editFeeStructure(
      FeeManagementState state, FeeStructure feeStructure) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController academicYearController = TextEditingController(
      text: feeStructure.academicYear,
    );
    final schoolClasses = state.schoolClasses;
    final feeCategories = state.feeCategories;
    // Safely find the initial selected class and fee category objects.
    // Using a try-catch with firstWhere is a safe way to handle cases where
    // the item might not be in the list, preventing a crash.
    SchoolClass? selectedClass;
    try {
      selectedClass = schoolClasses
          .firstWhere((cls) => cls.classId == feeStructure.classId);
    } catch (e) {
      selectedClass = null; // If not found, firstWhere throws. Set to null.
    }

    FeeCategory? selectedFeeCategory;
    try {
      selectedFeeCategory = feeCategories
          .firstWhere((cat) => cat.id == feeStructure.feeCategoryId);
    } catch (e) {
      selectedFeeCategory = null; // If not found, set to null.
    }
    final result = await showDialog<FeeStructure>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Fee Structure'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<SchoolClass>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Class',
                        ),
                        value: selectedClass,
                        items: schoolClasses.map((cls) {
                          return DropdownMenuItem(
                            value: cls,
                            child: Text(cls.className,
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => selectedClass = value),
                        validator: (v) =>
                            v == null ? 'Please select a class' : null,
                      ),
                      DropdownButtonFormField<FeeCategory>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Fee Category',
                        ),
                        value: selectedFeeCategory,
                        items: feeCategories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text('${cat.name} - ₹${cat.amount}',
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => selectedFeeCategory = value),
                        validator: (v) =>
                            v == null ? 'Please select a fee category' : null,
                      ),
                      TextFormField(
                        controller: academicYearController,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Academic Year is required' : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Create a new FeeStructure object with updated values
                  final updatedFeeStructure = feeStructure.copyWith(
                    classId: selectedClass!.classId,
                    feeCategoryId: selectedFeeCategory!.id,
                    academicYear: academicYearController.text,
                    className: selectedClass!.className,
                    feeCategoryName: selectedFeeCategory!.name,
                    amount: selectedFeeCategory!.amount,
                  );
                  Navigator.pop(context, updatedFeeStructure);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .updateFeeStructure(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee structure updated!')),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update fee structure: ${e.message}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _editFeeCategory(
      FeeManagementState state, FeeCategory categoryToEdit) async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: categoryToEdit.name);
    final amountController =
        TextEditingController(text: categoryToEdit.amount.toString());
    String? selectedType = categoryToEdit.type;

    final result = await showDialog<FeeCategory>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Fee Category'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Category Name'),
                        validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null,
                      ),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Amount is required';
                          if (double.tryParse(v) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Fee Type'),
                        value: selectedType,
                        items: ['recurring', 'one-time']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.capitalize()),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedType = value),
                        validator: (v) =>
                            v == null ? 'Please select a type' : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final updatedCategory = categoryToEdit.copyWith(
                    name: nameController.text,
                    amount: double.parse(amountController.text),
                    type: selectedType!,
                    isOptional:
                        categoryToEdit.isOptional, // Preserve existing value
                  );
                  Navigator.pop(context, updatedCategory);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .updateFeeCategory(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee category updated!')),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update category: ${e.message}')),
          );
        }
      }
    }
  }

  Future<void> _deleteFeeCategory(
      FeeManagementState state, FeeCategory category) async {
    // Dependency Check: Ensure the category is not used by any fee structure.
    final isUsed =
        state.feeStructures.any((fs) => fs.feeCategoryId == category.id);

    if (isUsed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Cannot delete: This category is used by a fee structure.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Fee Category?',
      'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
      confirmActionText: 'Delete',
    );

    if (confirmed == true) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .deleteFeeCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fee category deleted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete category: ${e.message}')),
          );
        }
      }
    }
  }

  Future<void> _deleteFeeStructure(
      FeeManagementState state, FeeStructure feeStructure) async {
    // Dependency Check: Ensure the structure is not used in any invoice.
    final isUsed =
        state.allInvoices.any((inv) => inv.feeStructureId == feeStructure.id);

    if (isUsed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Cannot delete: This structure is used in an invoice.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Fee Structure?',
      'Are you sure you want to delete the structure "${feeStructure.feeCategoryName} for ${feeStructure.className}"? This action cannot be undone.',
    );

    if (confirmed == true) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .deleteFeeStructure(feeStructure.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fee structure deleted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete structure: ${e.message}')),
          );
        }
      }
    }
  }

  Future<void> _createSingleInvoice(FeeManagementState state) async {
    final students = state.students;
    final feeCategories = state.feeCategories;
    final schoolClasses = state.schoolClasses;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students available to generate invoices for.'),
        ),
      );
      return;
    }
    if (feeCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fee categories defined. Please add one first.'),
        ),
      );
      return;
    }

    StudentTable? selectedStudent;
    FeeCategory? selectedFeeCategory;

    final result = await showDialog<Invoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate New Invoice'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<StudentTable>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Student',
                      ),
                      value: selectedStudent,
                      items: students.map((student) {
                        return DropdownMenuItem(
                          value: student,
                          child: Text('${student.fullName} (${student.email})',
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStudent = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a student' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FeeCategory>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Fee Type',
                      ),
                      value: selectedFeeCategory,
                      items: feeCategories.map((fee) {
                        return DropdownMenuItem(
                          value: fee,
                          child: Text(
                            '${fee.name} - ₹${fee.amount.toStringAsFixed(2)} (${fee.type})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedFeeCategory = value);
                      },
                      validator: (value) => value == null
                          ? 'Please select a fee structure'
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedStudent != null && selectedFeeCategory != null) {
                  Navigator.pop(
                    context,
                    Invoice(
                      id: '', // Firebase will generate this
                      studentUid: selectedStudent!.uid,
                      studentName: selectedStudent!.fullName,
                      classId: selectedStudent!.classId ??
                          '', // Use student's assigned class
                      className: schoolClasses
                          .firstWhere(
                            (cls) => cls.classId == selectedStudent!.classId,
                            orElse: () => SchoolClass(
                              classId: '',
                              className: 'Unknown',
                              subjects: const [],
                              status: '',
                              createdAt: 0,
                              teacherId: null,
                              teacherName: null,
                            ),
                          )
                          .className,
                      feeStructureId: selectedFeeCategory!.id,
                      amountDue: selectedFeeCategory!.amount,
                      status: 'pending', // Default status for new invoice
                      issueDate: DateTime.now().millisecondsSinceEpoch,
                      dueDate: DateTime.now()
                          .add(const Duration(days: 30))
                          .millisecondsSinceEpoch, // 30 days from now
                    ),
                  );
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .createInvoice(result);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice generated successfully!')),
          );
      } on AuthException catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate invoice: ${e.message}')),
          );
      }
    }
  }

  Future<void> _generateBatchInvoices(FeeManagementState state) async {
    final schoolClasses = state.schoolClasses;
    final feeStructures = state.feeStructures;
    final students = state.students;

    if (schoolClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No classes available to generate invoices for.'),
        ),
      );
      return;
    }
    if (feeStructures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fee structures defined. Please add one first.'),
        ),
      );
      return;
    }

    SchoolClass? selectedClass;
    final TextEditingController academicYearController =
        TextEditingController(text: '2023-2024'); // Default academic year

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Batch Invoices'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<SchoolClass>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                      ),
                      value: selectedClass,
                      items: schoolClasses.map((cls) {
                        return DropdownMenuItem(
                          value: cls,
                          child: Text(cls.className,
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedClass = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a class' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: academicYearController,
                      decoration: const InputDecoration(
                        labelText: 'Academic Year',
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Academic Year is required' : null,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedClass != null &&
                    academicYearController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'class': selectedClass,
                    'academicYear': academicYearController.text,
                  });
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final classToInvoice = result['class'] as SchoolClass;
      final academicYear = result['academicYear'] as String;

      // Filter fee structures relevant to the selected class and academic year
      final relevantFeeStructures = feeStructures
          .where((fs) =>
              fs.classId == classToInvoice.classId &&
              fs.academicYear == academicYear)
          .toList();

      if (relevantFeeStructures.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No fee structures found for this class and academic year.'),
            ),
          );
        }
        return;
      }

      // Filter students relevant to the selected class
      final studentsInClass =
          students.where((s) => s.classId == classToInvoice.classId).toList();

      if (studentsInClass.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No students found in the selected class.'),
            ),
          );
        }
        return;
      }

      final List<Invoice> invoicesToCreate = [];
      for (var student in studentsInClass) {
        for (var feeStructure in relevantFeeStructures) {
          final newInvoice = Invoice(
            id: '', // Firebase will generate this
            studentUid: student.uid,
            studentName: student.fullName,
            classId: classToInvoice.classId,
            className: classToInvoice.className,
            feeStructureId: feeStructure.id,
            amountDue: feeStructure.amount!,
            status: 'pending', // Default status for new invoice
            issueDate: DateTime.now().millisecondsSinceEpoch,
            dueDate: DateTime.now()
                .add(const Duration(days: 30))
                .millisecondsSinceEpoch, // 30 days from now
          );
          invoicesToCreate.add(newInvoice);
        }
      }

      try {
        // This assumes you will add a `bulkCreateInvoices` method to your Notifier and Service
        // for efficient batch writing.
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .bulkCreateInvoices(invoicesToCreate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${invoicesToCreate.length} invoices generated!'),
            ),
          );
        }
      } on AuthException catch (e) {
        developer.log('Error generating batch invoices: ${e.message}',
            name: 'FeeManagementPage');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Batch invoice generation failed: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _manageInvoicePayment(
      FeeManagementState state, Invoice invoice) async {
    final TextEditingController paymentAmountController =
        TextEditingController();
    String? selectedPaymentMethod = 'cash'; // Default payment method
    final List<String> paymentMethods = ['cash', 'bank transfer', 'online'];
    List<Payment>? paymentsHistory;
    bool isLoadingPayments = true; // Initialize to true

    try {
      // Use the provider to get the service instance
      paymentsHistory = await ref
          .read(authServiceProvider)
          .fetchPaymentsForInvoice(invoice.id);
      isLoadingPayments = false;
    } on AuthException catch (e) {
      // Catch specific AuthException
      developer.log(
        'Error fetching payment history: ${e.message}',
        name: 'FeeManagementPage',
      );
      paymentsHistory = [];
      isLoadingPayments = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payment history: ${e.message}'),
          ),
        );
      }
    } catch (e) {
      // Catch any other unexpected errors
      developer.log(
        'Unexpected error fetching payment history: $e',
        name: 'FeeManagementPage',
      );
      paymentsHistory = [];
      isLoadingPayments = false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Manage Payment for Invoice ${invoice.id}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final double remainingAmount =
                  invoice.amountDue - invoice.amountPaid;
              paymentAmountController.text = remainingAmount > 0
                  ? remainingAmount.toStringAsFixed(2)
                  : '0.00';

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice Amount: ₹${invoice.amountDue.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Amount Paid: ₹${invoice.amountPaid.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Remaining: ₹${remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: remainingAmount > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    const Divider(),
                    const Text(
                      'Record New Payment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: paymentAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                      value: selectedPaymentMethod,
                      items: paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method.capitalize()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final double amount =
                            double.tryParse(paymentAmountController.text) ??
                                0.0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter a valid payment amount.',
                              ),
                            ),
                          );
                          return;
                        }

                        // Set loading state before any async operation
                        // This setState is within the StatefulBuilder, so it will rebuild the dialog
                        setState(() {
                          isLoadingPayments = true;
                        });

                        // Perform payment and invoice updates

                        try {
                          final newPayment = Payment(
                            id: '', // Firebase will generate
                            invoiceId: invoice.id,
                            amount: amount,
                            paymentDate: DateTime.now().millisecondsSinceEpoch,
                            paymentMethod: selectedPaymentMethod!,
                          );
                          await ref
                              .read(feeManagementNotifierProvider.notifier)
                              .recordPaymentForInvoice(newPayment, invoice);

                          // After successful payment/invoice update, fetch and update history
                          final updatedPayments = await ref
                              .read(authServiceProvider)
                              .fetchPaymentsForInvoice(
                                  invoice.id); // AWAIT this call

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Payment recorded and invoice updated!',
                                ),
                              ),
                            );
                            // Update the dialog's state with new payments and hide loading
                            setState(() {
                              paymentsHistory = updatedPayments;
                              paymentAmountController
                                  .clear(); // Clear amount field
                            });
                          }
                        } on AuthException catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Payment failed: ${e.message}'),
                              ),
                            );
                        } catch (e) {
                          // Catch any other unexpected errors during payment/invoice update
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'An unexpected error occurred: ${e.toString()}'),
                              ),
                            );
                          }
                        } finally {
                          // Ensure loading is false regardless of success or failure
                          if (mounted) {
                            setState(() {
                              isLoadingPayments = false;
                            });
                          }
                        }
                      },
                      child: const Text('Record Payment'),
                    ),
                    const Divider(),
                    const Text(
                      'Payment History',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    isLoadingPayments
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: paymentsHistory!.isEmpty
                                ? [const Text('No payments recorded yet.')]
                                : paymentsHistory!.map((payment) {
                                    final paymentDate =
                                        DateTime.fromMillisecondsSinceEpoch(
                                      payment.paymentDate,
                                    );
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        '₹${payment.amount.toStringAsFixed(2)} (${payment.paymentMethod.capitalize()})',
                                      ),
                                      subtitle: Text(
                                        'on ${DateFormat('MMM dd, yyyy').format(paymentDate)}',
                                      ),
                                    );
                                  }).toList(),
                          ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markInvoiceAsPaid(
      FeeManagementState state, Invoice invoice) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Mark Invoice as Paid?',
      'Are you sure you want to mark this invoice as paid? This will update its status and payment date.',
    );

    if (confirmed == true) {
      try {
        final updatedInvoice = invoice.copyWith(
          status: 'paid',
          // Set paymentDate to now if it's being marked as paid
          paymentDate: DateTime.now().millisecondsSinceEpoch,
        );
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .updateInvoice(updatedInvoice);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice marked as paid!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark invoice as paid: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _bulkMarkAsPaid(FeeManagementState state) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Mark ${state.selectedInvoiceIds.length} Invoices as Paid?',
      'Are you sure you want to mark all selected invoices as paid?',
      confirmActionText: 'Mark as Paid',
    );

    if (confirmed == true) {
      final invoicesToUpdate = state.allInvoices
          .where((inv) => state.selectedInvoiceIds.contains(inv.id))
          .map((inv) => inv.copyWith(
                status: 'paid',
                paymentDate: DateTime.now().millisecondsSinceEpoch,
              ))
          .toList();

      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .bulkUpdateInvoices(invoicesToUpdate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${invoicesToUpdate.length} invoices marked as paid!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bulk update failed: ${e.message}')),
          );
        }
      }
    }
  }

  Future<void> _deleteInvoice(FeeManagementState state, Invoice invoice) async {
    final studentName =
        state.studentMap[invoice.studentUid]?.fullName ?? 'Unknown Student';
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Invoice?',
      'Are you sure you want to delete the invoice for $studentName (ID: ${invoice.id})? This will also delete all associated payment records and cannot be undone.',
      confirmActionText: 'Delete',
    );

    if (confirmed == true) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .deleteInvoice(invoice.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice deleted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to delete invoice: ${e.message}')));
        }
      }
    }
  }

  Future<void> _bulkDeleteInvoices(FeeManagementState state) async {
    final selectionCount = state.selectedInvoiceIds.length;
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete $selectionCount Invoices?',
      'Are you sure you want to delete all selected invoices and their associated payments? This action cannot be undone.',
      confirmActionText: 'Delete',
    );

    if (confirmed == true) {
      try {
        await ref
            .read(feeManagementNotifierProvider.notifier)
            .bulkDeleteInvoices(state.selectedInvoiceIds.toList());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$selectionCount invoices deleted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bulk delete failed: ${e.message}')));
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content,
      {String confirmActionText = 'Confirm'}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor:
                    confirmActionText == 'Delete' ? Colors.red : null),
            child: Text(confirmActionText),
          ),
        ],
      ),
    );
  }

  AppBar _buildDefaultAppBar(FeeManagementState state) {
    return AppBar(
      title: const Text('Fee Management'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(feeManagementNotifierProvider.notifier).reloadData(),
          tooltip: 'Refresh Data',
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _addFeeStructure(state),
          tooltip: 'Add Fee Structure',
        ),
        IconButton(
          icon: const Icon(Icons.category),
          onPressed: () => _addFeeCategory(state),
          tooltip: 'Add Fee Category',
        ),
        IconButton(
          icon: const Icon(Icons.receipt), // Icon for batch invoice generation
          onPressed: () => _generateBatchInvoices(state),
          tooltip: 'Generate Batch Invoices',
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long), // Icon for generating invoice
          onPressed: () => _createSingleInvoice(state),
          tooltip: 'Create Single Invoice',
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar(int selectionCount) {
    return AppBar(
      title: Text('$selectionCount selected'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(feeManagementNotifierProvider.notifier).clearSelection();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.check_circle),
          onPressed: () =>
              _bulkMarkAsPaid(ref.watch(feeManagementNotifierProvider).value!),
          tooltip: 'Mark as Paid',
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: () => _bulkDeleteInvoices(
              ref.watch(feeManagementNotifierProvider).value!),
          tooltip: 'Delete Selected',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final feeStateAsync = ref.watch(feeManagementNotifierProvider);

    return feeStateAsync.when(
      loading: () => GradientContainer(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Fee Management')),
          body: const LoadingOverlay(
            isLoading: true,
            message: 'Loading fee data...',
            child: SizedBox.shrink(),
          ),
        ),
      ),
      error: (error, stackTrace) => GradientContainer(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Fee Management')),
          body: Center(child: Text('Error: $error')),
        ),
      ),
      data: (state) {
        final isSelectionMode = state.selectedInvoiceIds.isNotEmpty;
        return GradientContainer(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: isSelectionMode
                ? _buildSelectionAppBar(state.selectedInvoiceIds.length)
                : _buildDefaultAppBar(state),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InvoiceSummaryCard(
                    allInvoices: state.allInvoices,
                    feeStructures: state.feeStructures,
                    selectedAcademicYear: state.selectedAcademicYear,
                  ),
                  Text(
                    'Fee Categories',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Divider(),
                  FeeCategoryList(
                    feeCategories: state.feeCategories,
                    onEdit: (category) => _editFeeCategory(state, category),
                    onDelete: (category) => _deleteFeeCategory(state, category),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Fee Structures',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Divider(),
                  FeeStructureList(
                    feeStructures: state.feeStructures,
                    onEdit: (structure) => _editFeeStructure(state, structure),
                    onDelete: (structure) =>
                        _deleteFeeStructure(state, structure),
                  ),
                  const SizedBox(height: 24),
                  Text('Invoices',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Divider(),
                  InvoiceFilterControls(
                    searchController: _searchController,
                    searchQuery: state.searchQuery,
                    onSearchChanged: (value) {
                      // The listener in initState handles this now.
                    },
                    academicYears: state.academicYears,
                    selectedAcademicYear: state.selectedAcademicYear,
                    onAcademicYearChanged: (newValue) {
                      if (newValue != null) {
                        ref
                            .read(feeManagementNotifierProvider.notifier)
                            .setAcademicYear(newValue);
                      }
                    },
                    feeCategories: state.feeCategories,
                    selectedFeeCategoryFilter: state.selectedFeeCategoryFilter,
                    onFeeCategoryChanged: (newValue) {
                      ref
                          .read(feeManagementNotifierProvider.notifier)
                          .setFeeCategory(newValue);
                    },
                    selectedSortOption: state.selectedSortOption,
                    onSortOptionChanged: (newValue) {
                      if (newValue != null) {
                        ref
                            .read(feeManagementNotifierProvider.notifier)
                            .setSortOption(newValue);
                      }
                    },
                    getSortOptionLabel: _getSortOptionLabel,
                  ),
                  InvoiceList(
                    invoices: state.displayedInvoices,
                    studentMap: state.studentMap,
                    selectedInvoiceIds: state.selectedInvoiceIds,
                    isSelectionMode: isSelectionMode,
                    onToggleSelection: (id) => ref
                        .read(feeManagementNotifierProvider.notifier)
                        .toggleInvoiceSelection(id),
                    onManagePayment: (invoice) =>
                        _manageInvoicePayment(state, invoice),
                    onMarkAsPaid: (invoice) =>
                        _markInvoiceAsPaid(state, invoice),
                    onDelete: (invoice) => _deleteInvoice(state, invoice),
                  ),
                  _buildPaginationControls(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(FeeManagementState state) {
    if (state.totalFilteredInvoices <= FeeManagementState.invoicesPerPage) {
      return const SizedBox.shrink();
    }

    final totalPages =
        (state.totalFilteredInvoices / FeeManagementState.invoicesPerPage)
            .ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: state.currentPage > 0
              ? () => ref
                  .read(feeManagementNotifierProvider.notifier)
                  .setPage(state.currentPage - 1)
              : null,
        ),
        Text('Page ${state.currentPage + 1} of $totalPages'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: state.currentPage < totalPages - 1
              ? () => ref
                  .read(feeManagementNotifierProvider.notifier)
                  .setPage(state.currentPage + 1)
              : null,
        ),
      ],
    );
  }
}
