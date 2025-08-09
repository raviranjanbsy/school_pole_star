import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:school_management/model_class/fee_category.dart';
import 'package:school_management/model_class/FeeStructure.dart';
import 'package:school_management/model_class/Invoice.dart';
import 'package:school_management/model_class/Payment.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/providers/auth_provider.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/ui/fee_management_page.dart'; // For InvoiceSortOption

part 'fee_management_provider.g.dart';

@immutable
class FeeManagementState extends Equatable {
  // Data from service
  final List<FeeCategory> feeCategories;
  final List<FeeStructure> feeStructures;
  final List<Invoice> allInvoices;
  final List<SchoolClass> schoolClasses;
  final List<StudentTable> students;

  // Derived/Computed Data
  final List<Invoice> displayedInvoices;
  final Map<String, StudentTable> studentMap;
  final Map<String, FeeStructure> feeStructureMap;
  final List<String> academicYears;
  final int totalFilteredInvoices;

  // UI/Filter State
  final String? selectedAcademicYear;
  final FeeCategory? selectedFeeCategoryFilter;
  final String searchQuery;
  final InvoiceSortOption selectedSortOption;
  final int currentPage;
  final Set<String> selectedInvoiceIds;

  static const int invoicesPerPage = 10;

  const FeeManagementState({
    this.feeCategories = const [],
    this.feeStructures = const [],
    this.allInvoices = const [],
    this.schoolClasses = const [],
    this.students = const [],
    this.displayedInvoices = const [],
    this.studentMap = const {},
    this.feeStructureMap = const {},
    this.academicYears = const [],
    this.totalFilteredInvoices = 0,
    this.selectedAcademicYear,
    this.selectedFeeCategoryFilter,
    this.searchQuery = '',
    this.selectedSortOption = InvoiceSortOption.issueDateDesc,
    this.currentPage = 0,
    this.selectedInvoiceIds = const {},
  });

  FeeManagementState copyWith({
    List<FeeCategory>? feeCategories,
    List<FeeStructure>? feeStructures,
    List<Invoice>? allInvoices,
    List<SchoolClass>? schoolClasses,
    List<StudentTable>? students,
    List<Invoice>? displayedInvoices,
    Map<String, StudentTable>? studentMap,
    Map<String, FeeStructure>? feeStructureMap,
    List<String>? academicYears,
    int? totalFilteredInvoices,
    String? selectedAcademicYear,
    FeeCategory? selectedFeeCategoryFilter,
    bool clearFeeCategoryFilter = false,
    String? searchQuery,
    InvoiceSortOption? selectedSortOption,
    int? currentPage,
    Set<String>? selectedInvoiceIds,
  }) {
    return FeeManagementState(
      feeCategories: feeCategories ?? this.feeCategories,
      feeStructures: feeStructures ?? this.feeStructures,
      allInvoices: allInvoices ?? this.allInvoices,
      schoolClasses: schoolClasses ?? this.schoolClasses,
      students: students ?? this.students,
      displayedInvoices: displayedInvoices ?? this.displayedInvoices,
      studentMap: studentMap ?? this.studentMap,
      feeStructureMap: feeStructureMap ?? this.feeStructureMap,
      academicYears: academicYears ?? this.academicYears,
      totalFilteredInvoices:
          totalFilteredInvoices ?? this.totalFilteredInvoices,
      selectedAcademicYear: selectedAcademicYear ?? this.selectedAcademicYear,
      selectedFeeCategoryFilter: clearFeeCategoryFilter
          ? null
          : selectedFeeCategoryFilter ?? this.selectedFeeCategoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSortOption: selectedSortOption ?? this.selectedSortOption,
      currentPage: currentPage ?? this.currentPage,
      selectedInvoiceIds: selectedInvoiceIds ?? this.selectedInvoiceIds,
    );
  }

  @override
  List<Object?> get props => [
        feeCategories,
        feeStructures,
        allInvoices,
        schoolClasses,
        students,
        displayedInvoices,
        studentMap,
        feeStructureMap,
        academicYears,
        totalFilteredInvoices,
        selectedAcademicYear,
        selectedFeeCategoryFilter,
        searchQuery,
        selectedSortOption,
        currentPage,
        selectedInvoiceIds,
      ];
}

@riverpod
class FeeManagementNotifier extends _$FeeManagementNotifier {
  AuthService get _authService => ref.read(authServiceProvider);

  @override
  Future<FeeManagementState> build() async {
    final results = await Future.wait([
      _authService.fetchAllFeeCategories(),
      _authService.fetchAllFeeStructures(),
      _authService.fetchAllInvoices(),
      _authService.fetchAllSchoolClasses(),
      _authService.fetchAllStudents(),
    ]);

    final feeCategories = results[0] as List<FeeCategory>;
    final feeStructures = results[1] as List<FeeStructure>;
    final allInvoices = results[2] as List<Invoice>;
    final schoolClasses = results[3] as List<SchoolClass>;
    final students = results[4] as List<StudentTable>;

    final studentMap = {for (var s in students) s.uid: s};
    final feeStructureMap = {for (var fs in feeStructures) fs.id: fs};

    final years = feeStructures
        .map((fs) => fs.academicYear)
        .where((year) => year.isNotEmpty)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));

    final initialState = FeeManagementState(
      feeCategories: feeCategories,
      feeStructures: feeStructures,
      allInvoices: allInvoices,
      schoolClasses: schoolClasses,
      students: students,
      studentMap: studentMap,
      feeStructureMap: feeStructureMap,
      academicYears: years,
      selectedAcademicYear: years.isNotEmpty ? years.first : null,
    );

    return _applyFilters(initialState);
  }

  FeeManagementState _applyFilters(FeeManagementState currentState) {
    Iterable<Invoice> filtered = currentState.allInvoices;
    // Academic Year Filter
    if (currentState.selectedAcademicYear != null) {
      filtered = filtered.where((invoice) {
        final feeStructure =
            currentState.feeStructureMap[invoice.feeStructureId];
        return feeStructure?.academicYear == currentState.selectedAcademicYear;
      });
    }
    // Fee Category Filter
    if (currentState.selectedFeeCategoryFilter != null) {
      filtered = filtered.where((invoice) {
        final feeStructure =
            currentState.feeStructureMap[invoice.feeStructureId];
        return feeStructure?.feeCategoryId ==
            currentState.selectedFeeCategoryFilter!.id;
      });
    }
    // Search Query Filter
    if (currentState.searchQuery.isNotEmpty) {
      final lowerCaseQuery = currentState.searchQuery.toLowerCase();
      filtered = filtered.where((invoice) {
        final student = currentState.studentMap[invoice.studentUid];
        return (student?.fullName.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (invoice.className.toLowerCase().contains(lowerCaseQuery)) ||
            (invoice.id.toLowerCase().contains(lowerCaseQuery));
      });
    }
    final materializedList = filtered.toList();
    // Sorting
    materializedList.sort((a, b) {
      switch (currentState.selectedSortOption) {
        case InvoiceSortOption.issueDateDesc:
          return b.issueDate.compareTo(a.issueDate);
        case InvoiceSortOption.issueDateAsc:
          return a.issueDate.compareTo(b.issueDate);
        case InvoiceSortOption.dueDateDesc:
          if (b.dueDate == null) return -1;
          if (a.dueDate == null) return 1;
          return b.dueDate!.compareTo(a.dueDate!);
        case InvoiceSortOption.dueDateAsc:
          if (a.dueDate == null) return -1;
          if (b.dueDate == null) return 1;
          return a.dueDate!.compareTo(b.dueDate!);
        case InvoiceSortOption.amountDesc:
          return b.amountDue.compareTo(a.amountDue);
        case InvoiceSortOption.amountAsc:
          return a.amountDue.compareTo(b.amountDue);
        case InvoiceSortOption.studentNameAsc:
          final nameA = currentState.studentMap[a.studentUid]?.fullName ?? '';
          final nameB = currentState.studentMap[b.studentUid]?.fullName ?? '';
          return nameA.compareTo(nameB);
        case InvoiceSortOption.studentNameDesc:
          final nameA = currentState.studentMap[a.studentUid]?.fullName ?? '';
          final nameB = currentState.studentMap[b.studentUid]?.fullName ?? '';
          return nameB.compareTo(nameA);
      }
    });
    // Pagination
    final startIndex =
        currentState.currentPage * FeeManagementState.invoicesPerPage;
    final endIndex = startIndex + FeeManagementState.invoicesPerPage;
    final paginatedList = materializedList.sublist(
        startIndex,
        endIndex > materializedList.length
            ? materializedList.length
            : endIndex);
    return currentState.copyWith(
      displayedInvoices: paginatedList,
      totalFilteredInvoices: materializedList.length,
    );
  }

  void _updateStateWithFilters(FeeManagementState newState) {
    state = AsyncData(_applyFilters(newState));
  }

  // --- Methods to be called from the UI ---
  Future<void> reloadData() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  void setSearchQuery(String query) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    _updateStateWithFilters(
        currentState.copyWith(searchQuery: query, currentPage: 0));
  }

  void setAcademicYear(String year) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    _updateStateWithFilters(
        currentState.copyWith(selectedAcademicYear: year, currentPage: 0));
  }

  void setFeeCategory(FeeCategory? category) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    _updateStateWithFilters(currentState.copyWith(
      selectedFeeCategoryFilter: category,
      clearFeeCategoryFilter: category == null,
      currentPage: 0,
    ));
  }

  void setSortOption(InvoiceSortOption option) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    _updateStateWithFilters(currentState.copyWith(selectedSortOption: option));
  }

  void setPage(int page) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    _updateStateWithFilters(currentState.copyWith(currentPage: page));
  }

  void toggleInvoiceSelection(String invoiceId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    final newSet = Set<String>.from(currentState.selectedInvoiceIds);
    if (newSet.contains(invoiceId)) {
      newSet.remove(invoiceId);
    } else {
      newSet.add(invoiceId);
    }
    state = AsyncData(currentState.copyWith(selectedInvoiceIds: newSet));
  }

  void clearSelection() {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    state = AsyncData(currentState.copyWith(selectedInvoiceIds: {}));
  }

  // --- Methods that call AuthService ---
  // These methods now just call the service and then reload the data.
  // The UI will show a loading indicator automatically.
  Future<void> addFeeCategory(FeeCategory category) async =>
      _authService.createFeeCategory(category).then((_) => reloadData());
  Future<void> updateFeeCategory(FeeCategory category) async =>
      _authService.updateFeeCategory(category).then((_) => reloadData());
  Future<void> deleteFeeCategory(String id) async =>
      _authService.deleteFeeCategory(id).then((_) => reloadData());
  Future<void> addFeeStructure(FeeStructure structure) async =>
      _authService.createFeeStructure(structure).then((_) => reloadData());
  Future<void> updateFeeStructure(FeeStructure structure) async =>
      _authService.updateFeeStructure(structure).then((_) => reloadData());
  Future<void> deleteFeeStructure(String id) async =>
      _authService.deleteFeeStructure(id).then((_) => reloadData());
  Future<void> createInvoice(Invoice invoice) async =>
      _authService.createInvoice(invoice).then((_) => reloadData());

  Future<void> updateInvoice(Invoice invoice) async {
    await _authService.updateInvoice(invoice);
    _updateSingleInvoiceInState(invoice);
  }

  Future<void> recordPaymentForInvoice(
      Payment newPayment, Invoice originalInvoice) async {
    // First, record the payment in the database.
    await _authService.recordPayment(newPayment);

    // Then, calculate the new state of the invoice.
    final updatedAmountPaid = originalInvoice.amountPaid + newPayment.amount;
    final newStatus = updatedAmountPaid >= originalInvoice.amountDue
        ? 'paid'
        : 'partially_paid';

    final updatedInvoice = originalInvoice.copyWith(
      amountPaid: updatedAmountPaid,
      status: newStatus,
      paymentDate: newStatus == 'paid'
          ? DateTime.now().millisecondsSinceEpoch
          : originalInvoice.paymentDate,
    );

    // Finally, update the invoice in the database and locally in the state.
    await updateInvoice(updatedInvoice);
  }

  Future<void> bulkUpdateInvoices(List<Invoice> invoices) async =>
      _authService.bulkUpdateInvoices(invoices).then((_) => reloadData());
  Future<void> bulkCreateInvoices(List<Invoice> invoices) async =>
      _authService.bulkCreateInvoices(invoices).then((_) => reloadData());

  Future<void> deleteInvoice(String invoiceId) async {
    await _authService.deleteInvoice(invoiceId);
    _removeSingleInvoiceFromState(invoiceId);
  }

  Future<void> bulkDeleteInvoices(List<String> invoiceIds) async {
    await _authService.bulkDeleteInvoices(invoiceIds);
    _removeMultipleInvoicesFromState(invoiceIds);
  }

  void _updateSingleInvoiceInState(Invoice updatedInvoice) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final newAllInvoices = List<Invoice>.from(currentState.allInvoices);
    final index =
        newAllInvoices.indexWhere((inv) => inv.id == updatedInvoice.id);
    if (index != -1) {
      newAllInvoices[index] = updatedInvoice;
    }

    final newState = currentState.copyWith(allInvoices: newAllInvoices);
    _updateStateWithFilters(newState);
  }

  void _removeSingleInvoiceFromState(String invoiceId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final newAllInvoices = List<Invoice>.from(currentState.allInvoices)
      ..removeWhere((inv) => inv.id == invoiceId);

    final newState = currentState
        .copyWith(allInvoices: newAllInvoices, selectedInvoiceIds: {});

    _updateStateWithFilters(newState);
  }

  void _removeMultipleInvoicesFromState(List<String> invoiceIds) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final newAllInvoices = List<Invoice>.from(currentState.allInvoices)
      ..removeWhere((inv) => invoiceIds.contains(inv.id));

    final newState = currentState
        .copyWith(allInvoices: newAllInvoices, selectedInvoiceIds: {});

    _updateStateWithFilters(newState);
  }
}
