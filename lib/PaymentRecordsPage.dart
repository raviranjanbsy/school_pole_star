// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // import 'package:school_management/model_class/PaymentRecord.dart';
// //
// // // Define a model class for Student Info
// // class StudentInfo {
// //   final String name;
// //   final String studentClass;
// //
// //   StudentInfo({required this.name, required this.studentClass});
// //
// //   factory StudentInfo.fromJson(Map<String, dynamic> json) {
// //     return StudentInfo(
// //       name: json['name'],
// //       studentClass: json['class'],
// //     );
// //   }
// // }
// //
// // class CalculateFeesPage extends StatefulWidget {
// //   @override
// //   _CalculateFeesPageState createState() => _CalculateFeesPageState();
// // }
// //
// // class _CalculateFeesPageState extends State<CalculateFeesPage> {
// //   final _studentIdController = TextEditingController();
// //   final _feeAmountController = TextEditingController();
// //
// //   String _selectedMonth = 'July';
// //   String _selectedFeeType = 'Monthly Fee';
// //   String _selectedYear = '2024'; // New year selection
// //
// //   final List<String> _months = [
// //     'July',
// //     'August',
// //     'September',
// //     'October',
// //     'November',
// //     'December',
// //     'January',
// //     'February',
// //     'March',
// //     'April',
// //     'May',
// //     'June'
// //   ];
// //   final List<String> _feeTypes = [
// //     'Monthly Fee',
// //     'Exam Fee',
// //     'Registration Fee',
// //     'Library Fee',
// //     'Sports Fee'
// //   ];
// //   final List<String> _years = ['2024', '2023', '2022']; // Added year list
// //
// //   final Map<String, Map<String, String>> _studentData = {
// //     '108': {'name': 'Sazid Mahmud', 'class': '8th', 'section': 'A'},
// //     '101': {'name': 'Habibur Rahman', 'class': '1st', 'section': 'A'},
// //     '105': {'name': 'Obaidul Qader', 'class': '5th', 'section': 'B'},
// //     '106': {'name': 'Azizur Rahman', 'class': '6th', 'section': 'C'},
// //     '109': {'name': 'Tanzila Rahman', 'class': '9th', 'section': 'Science'},
// //     '110': {'name': 'Shahadat', 'class': '10th', 'section': 'Science'},
// //   };
// //
// //   String _studentName = '';
// //   String _studentClass = '';
// //   double _totalFee = 0.0;
// //   double _amountPaid = 0.0;
// //   double _dueAmount = 0.0;
// //   String _errorMessage = '';
// //
// //   void _fetchStudentInfo(String studentId) {
// //     if (_studentData.containsKey(studentId)) {
// //       final student = _studentData[studentId]!;
// //       setState(() {
// //         _studentName = student['name']!;
// //         _studentClass = student['class']!;
// //         _errorMessage = '';
// //       });
// //     } else {
// //       setState(() {
// //         _studentName = '';
// //         _studentClass = '';
// //         _errorMessage = 'Student ID not found.';
// //       });
// //     }
// //   }
// //
// //   void _calculateFees() {
// //     setState(() {
// //       _errorMessage = ''; // Reset error message
// //     });
// //
// //     final studentId = _studentIdController.text.trim();
// //     final feeType = _selectedFeeType;
// //     final month = _selectedMonth;
// //     final year = _selectedYear; // Added year parameter
// //     final feeAmount = double.tryParse(_feeAmountController.text.trim()) ?? 0.0;
// //
// //     if (studentId.isEmpty || feeAmount <= 0) {
// //       setState(() {
// //         _errorMessage = 'Please fill all fields correctly.';
// //       });
// //       return;
// //     }
// //
// //     double calculatedFee = 0.0;
// //
// //     // Fee calculation logic based on class and fee type
// //     if (_studentClass.contains('1st') ||
// //         _studentClass.contains('2nd') ||
// //         _studentClass.contains('3rd') ||
// //         _studentClass.contains('4th') ||
// //         _studentClass.contains('5th')) {
// //       if (feeType == 'Monthly Fee') {
// //         calculatedFee = 800.0;
// //       } else if (feeType == 'Exam Fee') {
// //         calculatedFee = 700.0;
// //       } else if (feeType == 'Registration Fee') {
// //         calculatedFee = 500.0; // Example amount for Registration Fee
// //       } else if (feeType == 'Library Fee') {
// //         calculatedFee = 300.0; // Example amount for Library Fee
// //       } else if (feeType == 'Sports Fee') {
// //         calculatedFee = 400.0; // Example amount for Sports Fee
// //       }
// //     } else if (_studentClass.contains('6th') ||
// //         _studentClass.contains('7th') ||
// //         _studentClass.contains('8th')) {
// //       if (feeType == 'Monthly Fee') {
// //         calculatedFee = 1200.0;
// //       } else if (feeType == 'Exam Fee') {
// //         calculatedFee = 700.0;
// //       } else if (feeType == 'Registration Fee') {
// //         calculatedFee = 600.0; // Example amount for Registration Fee
// //       } else if (feeType == 'Library Fee') {
// //         calculatedFee = 400.0; // Example amount for Library Fee
// //       } else if (feeType == 'Sports Fee') {
// //         calculatedFee = 500.0; // Example amount for Sports Fee
// //       }
// //     } else {
// //       // Default to 0 if class is not recognized
// //       calculatedFee = 0.0;
// //     }
// //
// //     setState(() {
// //       _totalFee = calculatedFee;
// //       _amountPaid =
// //           feeAmount; // Assuming the input fee amount is the paid amount
// //       _dueAmount = _totalFee - _amountPaid;
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Calculate Fees'),
// //         backgroundColor: Colors.teal,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             TextField(
// //               controller: _studentIdController,
// //               decoration: InputDecoration(labelText: 'Student ID'),
// //               onChanged: (value) {
// //                 if (value.isNotEmpty) {
// //                   _fetchStudentInfo(value);
// //                 }
// //               },
// //             ),
// //             SizedBox(height: 8),
// //             Text('Student Name: $_studentName'),
// //             Text('Class: $_studentClass'),
// //             SizedBox(height: 8),
// //             DropdownButtonFormField<String>(
// //               value: _selectedFeeType,
// //               onChanged: (String? newValue) {
// //                 setState(() {
// //                   _selectedFeeType = newValue!;
// //                 });
// //               },
// //               items: _feeTypes.map<DropdownMenuItem<String>>((String value) {
// //                 return DropdownMenuItem<String>(
// //                   value: value,
// //                   child: Text(value),
// //                 );
// //               }).toList(),
// //               decoration: InputDecoration(labelText: 'Fee Type'),
// //             ),
// //             SizedBox(height: 8),
// //             DropdownButtonFormField<String>(
// //               value: _selectedMonth,
// //               onChanged: (String? newValue) {
// //                 setState(() {
// //                   _selectedMonth = newValue!;
// //                 });
// //               },
// //               items: _months.map<DropdownMenuItem<String>>((String value) {
// //                 return DropdownMenuItem<String>(
// //                   value: value,
// //                   child: Text(value),
// //                 );
// //               }).toList(),
// //               decoration: InputDecoration(labelText: 'Month'),
// //             ),
// //             SizedBox(height: 8),
// //             DropdownButtonFormField<String>(
// //               value: _selectedYear,
// //               onChanged: (String? newValue) {
// //                 setState(() {
// //                   _selectedYear = newValue!;
// //                 });
// //               },
// //               items: _years.map<DropdownMenuItem<String>>((String value) {
// //                 return DropdownMenuItem<String>(
// //                   value: value,
// //                   child: Text(value),
// //                 );
// //               }).toList(),
// //               decoration: InputDecoration(labelText: 'Year'),
// //             ),
// //             SizedBox(height: 8),
// //             TextField(
// //               controller: _feeAmountController,
// //               keyboardType: TextInputType.number,
// //               decoration: InputDecoration(labelText: 'Fee Amount'),
// //             ),
// //             SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: _calculateFees,
// //               child: Text('Calculate'),
// //             ),
// //             SizedBox(height: 20),
// //             if (_errorMessage.isNotEmpty)
// //               Text(
// //                 _errorMessage,
// //                 style: TextStyle(color: Colors.red, fontSize: 16),
// //               ),
// //             if (_totalFee > 0) _buildResultTable(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildResultTable() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Fee Details',
// //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //         ),
// //         SizedBox(height: 8),
// //         Table(
// //           border: TableBorder.all(),
// //           children: [
// //             TableRow(
// //               children: [
// //                 TableCell(
// //                     child: Padding(
// //                   padding: const EdgeInsets.all(8.0),
// //                   child: Text('Total Fee'),
// //                 )),
// //                 TableCell(
// //                     child: Padding(
// //                   padding: const EdgeInsets.all(8.0),
// //                   child: Text('Amount Paid'),
// //                 )),
// //                 TableCell(
// //                     child: Padding(
// //                   padding: const EdgeInsets.all(8.0),
// //                   child: Text('Due Amount'),
// //                 )),
// //               ],
// //             ),
// //             TableRow(
// //               children: [
// //                 TableCell(
// //                     child: Padding(
// //                   padding: const EdgeInsets.all(8.0),
// //                   child: Text('\$${_totalFee.toStringAsFixed(2)}'),
// //                 )),
// //                 TableCell(
// //                     child: Padding(
// //                   padding: const EdgeInsets.all(8.0),
// //                   child: Text('\$${_amountPaid.toStringAsFixed(2)}'),
// //                 )),
// //                 TableCell(
// //                     child: Padding(
// //                   padding: const EdgeInsets.all(8.0),
// //                   child: Text('\$${_dueAmount.toStringAsFixed(2)}'),
// //                 )),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ],
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import 'package:school_management/model_class/PaymentRecord.dart';
// import 'package:school_management/studentpanel.dart';
//
// // Define a model class for Student Info
// class StudentInfo {
//   final String name;
//   final String studentClass;
//
//   StudentInfo({required this.name, required this.studentClass});
//
//   factory StudentInfo.fromJson(Map<String, dynamic> json) {
//     return StudentInfo(
//       name: json['name'],
//       studentClass: json['class'],
//     );
//   }
// }
//
// class CalculateFeesPage extends StatefulWidget {
//   @override
//   _CalculateFeesPageState createState() => _CalculateFeesPageState();
// }
//
// class _CalculateFeesPageState extends State<CalculateFeesPage> {
//   final _studentIdController = TextEditingController();
//   final _feeAmountController = TextEditingController();
//
//   String _selectedMonth = 'July';
//   String _selectedFeeType = 'Monthly Fee';
//   String _selectedYear = '2024'; // New year selection
//
//   final List<String> _months = [
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December',
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June'
//   ];
//   final List<String> _feeTypes = [
//     'Monthly Fee',
//     'Exam Fee',
//     'Registration Fee',
//     'Library Fee',
//     'Sports Fee'
//   ];
//   final List<String> _years = ['2024', '2023', '2022']; // Added year list
//
//   final Map<String, Map<String, String>> _studentData = {
//     '108': {'name': 'Sazid Mahmud', 'class': '8th', 'section': 'A'},
//     '101': {'name': 'Habibur Rahman', 'class': '1st', 'section': 'A'},
//     '105': {'name': 'Obaidul Qader', 'class': '5th', 'section': 'B'},
//     '106': {'name': 'Azizur Rahman', 'class': '6th', 'section': 'C'},
//     '109': {'name': 'Tanzila Rahman', 'class': '9th', 'section': 'Science'},
//     '110': {'name': 'Shahadat', 'class': '10th', 'section': 'Science'},
//   };
//
//   String _studentName = '';
//   String _studentClass = '';
//   double _totalFee = 0.0;
//   double _amountPaid = 0.0;
//   double _dueAmount = 0.0;
//   String _errorMessage = '';
//   double _fixedAmount = 0.0;
//
//   void _fetchStudentInfo(String studentId) {
//     if (_studentData.containsKey(studentId)) {
//       final student = _studentData[studentId]!;
//       setState(() {
//         _studentName = student['name']!;
//         _studentClass = student['class']!;
//         _errorMessage = '';
//       });
//       _updateFixedAmount();
//     } else {
//       setState(() {
//         _studentName = '';
//         _studentClass = '';
//         _errorMessage = 'Student ID not found.';
//       });
//     }
//   }
//
//   void _updateFixedAmount() {
//     double amount = 0.0;
//
//     if (_studentClass.contains('1st') ||
//         _studentClass.contains('2nd') ||
//         _studentClass.contains('3rd') ||
//         _studentClass.contains('4th') ||
//         _studentClass.contains('5th')) {
//       if (_selectedFeeType == 'Monthly Fee') {
//         amount = 800.0;
//       } else if (_selectedFeeType == 'Exam Fee') {
//         amount = 700.0;
//       } else if (_selectedFeeType == 'Registration Fee') {
//         amount = 500.0;
//       } else if (_selectedFeeType == 'Library Fee') {
//         amount = 300.0;
//       } else if (_selectedFeeType == 'Sports Fee') {
//         amount = 400.0;
//       }
//     } else if (_studentClass.contains('6th') ||
//         _studentClass.contains('7th') ||
//         _studentClass.contains('8th')) {
//       if (_selectedFeeType == 'Monthly Fee') {
//         amount = 1200.0;
//       } else if (_selectedFeeType == 'Exam Fee') {
//         amount = 700.0;
//       } else if (_selectedFeeType == 'Registration Fee') {
//         amount = 1600.0;
//       } else if (_selectedFeeType == 'Library Fee') {
//         amount = 400.0;
//       } else if (_selectedFeeType == 'Sports Fee') {
//         amount = 500.0;
//       }
//     } else if (_studentClass.contains('9th') ||
//         _studentClass.contains('10th') ||
//         _studentClass.contains('10th')) {
//       if (_selectedFeeType == 'Monthly Fee') {
//         amount = 1500.0;
//       } else if (_selectedFeeType == 'Exam Fee') {
//         amount = 1000.0;
//       } else if (_selectedFeeType == 'Registration Fee') {
//         amount = 3300.0;
//       } else if (_selectedFeeType == 'Library Fee') {
//         amount = 700.0;
//       } else if (_selectedFeeType == 'Sports Fee') {
//         amount = 500.0;
//       }
//     }
//
//     setState(() {
//       _fixedAmount = amount;
//     });
//   }
//
//   void _calculateFees() {
//     setState(() {
//       _errorMessage = ''; // Reset error message
//     });
//
//     final studentId = _studentIdController.text.trim();
//     final feeAmount = double.tryParse(_feeAmountController.text.trim()) ?? 0.0;
//
//     if (studentId.isEmpty || feeAmount <= 0) {
//       setState(() {
//         _errorMessage = 'Please fill all fields correctly.';
//       });
//       return;
//     }
//
//     setState(() {
//       _totalFee = _fixedAmount;
//       _amountPaid =
//           feeAmount; // Assuming the input fee amount is the paid amount
//       _dueAmount = _totalFee - _amountPaid;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Calculate Fees'),
//         backgroundColor: Colors.teal,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _studentIdController,
//               decoration: InputDecoration(labelText: 'Student ID'),
//               onChanged: (value) {
//                 if (value.isNotEmpty) {
//                   _fetchStudentInfo(value);
//                 }
//               },
//             ),
//             SizedBox(height: 8),
//             Text('Student Name: $_studentName'),
//             Text('Class: $_studentClass'),
//             SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               value: _selectedFeeType,
//               onChanged: (String? newValue) {
//                 setState(() {
//                   _selectedFeeType = newValue!;
//                   _updateFixedAmount(); // Update fixed amount when fee type changes
//                 });
//               },
//               items: _feeTypes.map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               decoration: InputDecoration(labelText: 'Fee Type'),
//             ),
//             SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               value: _selectedMonth,
//               onChanged: (String? newValue) {
//                 setState(() {
//                   _selectedMonth = newValue!;
//                 });
//               },
//               items: _months.map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               decoration: InputDecoration(labelText: 'Month'),
//             ),
//             SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               value: _selectedYear,
//               onChanged: (String? newValue) {
//                 setState(() {
//                   _selectedYear = newValue!;
//                 });
//               },
//               items: _years.map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               decoration: InputDecoration(labelText: 'Year'),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Payable Amount: \$${_fixedAmount.toStringAsFixed(2)}',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 8),
//             TextField(
//               controller: _feeAmountController,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(labelText: 'Fee Amount'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _calculateFees,
//               child: Text('Calculate'),
//             ),
//             SizedBox(height: 20),
//             if (_errorMessage.isNotEmpty)
//               Text(
//                 _errorMessage,
//                 style: TextStyle(color: Colors.red, fontSize: 16),
//               ),
//             if (_totalFee > 0) _buildResultTable(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildResultTable() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Fee Details',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 8),
//         Table(
//           border: TableBorder.all(),
//           children: [
//             TableRow(
//               children: [
//                 TableCell(
//                     child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text('Total Fee'),
//                 )),
//                 TableCell(
//                     child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text('Amount Paid'),
//                 )),
//                 TableCell(
//                     child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text('Due Amount'),
//                 )),
//               ],
//             ),
//             TableRow(
//               children: [
//                 TableCell(
//                     child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text('\$${_totalFee.toStringAsFixed(2)}'),
//                 )),
//                 TableCell(
//                     child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text('\$${_amountPaid.toStringAsFixed(2)}'),
//                 )),
//                 TableCell(
//                     child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text('\$${_dueAmount.toStringAsFixed(2)}'),
//                 )),
//               ],
//             ),
//           ],
//         ),
//         SizedBox(
//           height: 30,
//         ),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (context) => Studentpanel()));
//           },
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.green,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//             textStyle: TextStyle(fontSize: 18),
//           ),
//           child: Text('Save Result'),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:school_management/model_class/PaymentRecord.dart';
import 'package:school_management/studentpanel.dart';
import 'package:school_management/widgets/gradient_container.dart';

class StudentInfo {
  final String name;
  final String studentClass;

  StudentInfo({required this.name, required this.studentClass});

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      name: json['name'],
      studentClass: json['class'],
    );
  }
}

class CalculateFeesPage extends StatefulWidget {
  const CalculateFeesPage({super.key});

  @override
  _CalculateFeesPageState createState() => _CalculateFeesPageState();
}

class _CalculateFeesPageState extends State<CalculateFeesPage> {
  final _studentIdController = TextEditingController();
  final _feeAmountController = TextEditingController();

  String _selectedMonth = 'July';
  String _selectedFeeType = 'Monthly Fee';
  String _selectedYear = '2024';

  final List<String> _months = [
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June'
  ];
  final List<String> _feeTypes = [
    'Monthly Fee',
    'Exam Fee',
    'Registration Fee',
    'Library Fee',
    'Sports Fee'
  ];
  final List<String> _years = ['2024', '2023', '2022'];

  final Map<String, Map<String, String>> _studentData = {
    '108': {'name': 'Sazid Mahmud', 'class': '8th', 'section': 'A'},
    '101': {'name': 'Habibur Rahman', 'class': '1st', 'section': 'A'},
    '105': {'name': 'Obaidul Qader', 'class': '5th', 'section': 'B'},
    '106': {'name': 'Azizur Rahman', 'class': '6th', 'section': 'C'},
    '109': {'name': 'Tanzila Rahman', 'class': '9th', 'section': 'Science'},
    '110': {'name': 'Shahadat', 'class': '10th', 'section': 'Science'},
  };

  String _studentName = '';
  String _studentClass = '';
  double _totalFee = 0.0;
  double _amountPaid = 0.0;
  double _dueAmount = 0.0;
  String _errorMessage = '';
  double _fixedAmount = 0.0;

  void _fetchStudentInfo(String studentId) {
    if (_studentData.containsKey(studentId)) {
      final student = _studentData[studentId]!;
      setState(() {
        _studentName = student['name']!;
        _studentClass = student['class']!;
        _errorMessage = '';
      });
      _updateFixedAmount();
    } else {
      setState(() {
        _studentName = '';
        _studentClass = '';
        _errorMessage = 'Student ID not found.';
      });
    }
  }

  void _updateFixedAmount() {
    double amount = 0.0;

    if (_studentClass.contains('1st') ||
        _studentClass.contains('2nd') ||
        _studentClass.contains('3rd') ||
        _studentClass.contains('4th') ||
        _studentClass.contains('5th')) {
      switch (_selectedFeeType) {
        case 'Monthly Fee':
          amount = 800.0;
          break;
        case 'Exam Fee':
          amount = 700.0;
          break;
        case 'Registration Fee':
          amount = 500.0;
          break;
        case 'Library Fee':
          amount = 300.0;
          break;
        case 'Sports Fee':
          amount = 400.0;
          break;
      }
    } else if (_studentClass.contains('6th') ||
        _studentClass.contains('7th') ||
        _studentClass.contains('8th')) {
      switch (_selectedFeeType) {
        case 'Monthly Fee':
          amount = 1200.0;
          break;
        case 'Exam Fee':
          amount = 700.0;
          break;
        case 'Registration Fee':
          amount = 1600.0;
          break;
        case 'Library Fee':
          amount = 400.0;
          break;
        case 'Sports Fee':
          amount = 500.0;
          break;
      }
    } else if (_studentClass.contains('9th') ||
        _studentClass.contains('10th')) {
      switch (_selectedFeeType) {
        case 'Monthly Fee':
          amount = 1500.0;
          break;
        case 'Exam Fee':
          amount = 1000.0;
          break;
        case 'Registration Fee':
          amount = 3300.0;
          break;
        case 'Library Fee':
          amount = 700.0;
          break;
        case 'Sports Fee':
          amount = 500.0;
          break;
      }
    }

    setState(() {
      _fixedAmount = amount;
    });
  }

  void _calculateFees() {
    setState(() {
      _errorMessage = '';
    });

    final studentId = _studentIdController.text.trim();
    final feeAmount = double.tryParse(_feeAmountController.text.trim()) ?? 0.0;

    if (studentId.isEmpty || feeAmount <= 0) {
      setState(() {
        _errorMessage = 'Please fill all fields correctly.';
      });
      return;
    }

    setState(() {
      _totalFee = _fixedAmount;
      _amountPaid = feeAmount;
      _dueAmount = _totalFee - _amountPaid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Calculate Fees'),
          backgroundColor: Colors.teal,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _fetchStudentInfo(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_studentName.isNotEmpty && _studentClass.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Student Name: $_studentName',
                                style: const TextStyle(fontSize: 16)),
                            Text('Class: $_studentClass',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                          ],
                        ),
                      DropdownButtonFormField<String>(
                        value: _selectedFeeType,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFeeType = newValue!;
                            _updateFixedAmount();
                          });
                        },
                        items: _feeTypes
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Fee Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedMonth,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMonth = newValue!;
                          });
                        },
                        items: _months
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedYear,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedYear = newValue!;
                          });
                        },
                        items: _years
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payable Amount: \${_fixedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _feeAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fee Amount',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _calculateFees,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text('Calculate Fees'),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      if (_totalFee > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Fee: \${_totalFee.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Amount Paid: \${_amountPaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Due Amount: \${_dueAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(context,
              //         MaterialPageRoute(builder: (context) => Studentpanel()));
              //   },
              //   style: ElevatedButton.styleFrom(
              //     foregroundColor: Colors.green,
              //     shape:
              //     RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              //     padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              //     textStyle: TextStyle(fontSize: 18),
              //   ),
              //   child: Text('Save Result'),
              // ),

              ElevatedButton(
                onPressed: () {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment submitted successfully!'),
                      duration: Duration(
                          seconds:
                              2), // The message will be displayed for 2 seconds
                    ),
                  );

                  // Navigate to the StudentPanel after showing the message
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Studentpanel()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 16),
                  foregroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Submit Payment'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
