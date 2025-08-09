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
          child: TextFormField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search Invoices (Student Name, Class, Invoice ID)',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filter by Academic Year',
              border: OutlineInputBorder(),
            ),
            value: selectedAcademicYear,
            items: academicYears.map((year) {
              return DropdownMenuItem<String>(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: onAcademicYearChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<FeeCategory?>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filter by Fee Category',
              border: OutlineInputBorder(),
            ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<InvoiceSortOption>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sort Invoices',
              border: OutlineInputBorder(),
            ),
            value: selectedSortOption,
            items: InvoiceSortOption.values.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(getSortOptionLabel(option)),
              );
            }).toList(),
            onChanged: onSortOptionChanged,
          ),
        ),
      ],
    );
  }
}
