import 'package:flutter/material.dart';
import 'package:school_management/model_class/fee_category.dart';
import 'package:school_management/ui/fee_management_page.dart'; // For InvoiceSortOption

class InvoiceFilterControls extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  final List<String> academicYears;
  final String? selectedAcademicYear;
  final Function(String?) onAcademicYearChanged;

  final List<FeeCategory> feeCategories;
  final FeeCategory? selectedFeeCategoryFilter;
  final Function(FeeCategory?) onFeeCategoryChanged;

  final InvoiceSortOption selectedSortOption;
  final Function(InvoiceSortOption?) onSortOptionChanged;
  final String Function(InvoiceSortOption) getSortOptionLabel;

  const InvoiceFilterControls({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.academicYears,
    required this.selectedAcademicYear,
    required this.onAcademicYearChanged,
    required this.feeCategories,
    required this.selectedFeeCategoryFilter,
    required this.onFeeCategoryChanged,
    required this.selectedSortOption,
    required this.onSortOptionChanged,
    required this.getSortOptionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search Invoices (Student Name, Class, Invoice ID)',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: searchController,
                // decoration: const InputDecoration( // Removed InputDecoration
                //   labelText: 'Search Invoices (Student Name, Class, Invoice ID)',
                //   prefixIcon: Icon(Icons.search),
                //   border: OutlineInputBorder(),
                //   floatingLabelBehavior: FloatingLabelBehavior.always,
                // ),
                onChanged: onSearchChanged,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Academic Year',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                // decoration: const InputDecoration( // Removed InputDecoration
                //   labelText: 'Filter by Academic Year',
                //   labelStyle: TextStyle(color: Colors.black),
                //   border: OutlineInputBorder(),
                //   floatingLabelBehavior: FloatingLabelBehavior.always,
                // ),
                value: selectedAcademicYear,
                items: academicYears.map((year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: onAcademicYearChanged,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Fee Category',
                style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold), // Adjust style as needed
              ),
              const SizedBox(
                  height: 8.0), // Add some space between text and dropdown
              DropdownButtonFormField<FeeCategory?>(
                isExpanded: true,
                // decoration: const InputDecoration( // Removed InputDecoration
                //   labelText: 'Filter by Fee Category',
                //   border: OutlineInputBorder(),
                // ),
                value: selectedFeeCategoryFilter,
                items: [
                  const DropdownMenuItem<FeeCategory?>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...feeCategories.map((cat) {
                    return DropdownMenuItem<FeeCategory>(
                      value: cat,
                      child: Text(cat.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ],
                onChanged: onFeeCategoryChanged,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Invoices',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<InvoiceSortOption>(
                isExpanded: true,
                // decoration: const InputDecoration( // Removed InputDecoration
                //   labelText: 'Sort Invoices',
                //   labelStyle: TextStyle(color: Colors.black),
                //   border: OutlineInputBorder(),
                // ),
                value: selectedSortOption,
                items: InvoiceSortOption.values.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(getSortOptionLabel(option)),
                  );
                }).toList(),
                onChanged: onSortOptionChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
