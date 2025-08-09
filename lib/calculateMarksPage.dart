import 'package:flutter/material.dart';
import 'package:school_management/widgets/gradient_container.dart';

class CalculateMarksPage extends StatefulWidget {
  const CalculateMarksPage({super.key});

  @override
  _CalculateMarksPageState createState() => _CalculateMarksPageState();
}

class _CalculateMarksPageState extends State<CalculateMarksPage> {
  final _examTitleController = TextEditingController(); //newly added

  final _studentIdController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _classController = TextEditingController();

  // Controllers for subject marks
  final Map<String, TextEditingController> _subjectControllers = {};
  final List<String> _subjects = [];

  double _totalMarks = 0.0;
  double _averageGrade = 0.0;
  String _result = '';

  // Hardcoded student data
  final Map<String, Map<String, String>> _studentData = {
    '108': {'name': 'Sazid Mahmud', 'class': '8th', 'section': 'A'},
    '101': {'name': 'Habibur Rahman', 'class': '1st', 'section': 'A'},
    '105': {'name': 'Obaidul Qader', 'class': '5th', 'section': 'B'},
    '106': {'name': 'Azizur Rahman', 'class': '6th', 'section': 'C'},
    '109': {'name': 'Tanzila Rahman', 'class': '9th', 'section': 'Science'},
    '110': {'name': 'Shahadat', 'class': '10th', 'section': 'Science'},
  };

  @override
  void initState() {
    super.initState();
    _studentIdController.addListener(_updateStudentInfo);
    _classController.addListener(_updateSubjects);
  }

  @override
  void dispose() {
    _studentIdController.removeListener(_updateStudentInfo);
    _classController.removeListener(_updateSubjects);
    _studentIdController.dispose();
    _studentNameController.dispose();
    _classController.dispose();
    _subjectControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _updateStudentInfo() {
    final examTitle = _examTitleController.text;

    final studentId = _studentIdController.text;
    final studentInfo = _studentData[studentId];

    if (studentInfo != null) {
      _studentNameController.text = studentInfo['name']!;
      _classController.text = studentInfo['class']!;
      _updateSubjects(); // Update subjects based on class
    } else {
      _studentNameController.clear();
      _classController.clear();
      _updateSubjects(); // Clear subjects if no student info
    }
  }

  void _updateSubjects() {
    final className = _classController.text;

    setState(() {
      // Clear existing subject controllers
      _subjectControllers.clear();
      _subjects.clear();

      if (className == '1st' ||
          className == '2nd' ||
          className == '3rd' ||
          className == '4th' ||
          className == '5th') {
        _subjects.addAll(['Bangla', 'English', 'Mathematics', 'Science']);
      } else if (className == '6th' ||
          className == '7th' ||
          className == '8th') {
        _subjects.addAll([
          'Bangla',
          'English',
          'Mathematics',
          'Science',
          'Religion',
          'Sociology',
          'Agriculture'
        ]);
      } else if (className == '9th') {
        // Example for science and commerce departments
        // You might need to add logic to choose department if needed
        _subjects.addAll([
          'Bangla',
          'English',
          'General Math',
          'Religion',
          'Physics',
          'Chemistry',
          'Biology'
        ]);
      } else if (className == '10th') {
        _subjects.addAll([
          'Bangla',
          'English',
          'General Math',
          'Religion',
          'Physics',
          'Chemistry',
          'Biology'
        ]);
      } else if (className == '11th' || className == '12th') {
        // Assuming 11th and 12th have separate departments
        // Add logic for commerce and science
        _subjects
            .addAll(['Bangla', 'English', 'Math', 'Finance', 'Accounting']);
      }

      // Initialize controllers for new subjects
      for (var subject in _subjects) {
        _subjectControllers[subject] = TextEditingController();
      }
    });
  }

  double _calculateGrade(double marks) {
    if (marks < 33) {
      return 0.0;
    } else if (marks >= 33 && marks <= 39)
      return 1.0;
    else if (marks >= 40 && marks <= 49)
      return 2.0;
    else if (marks >= 50 && marks <= 59)
      return 3.0;
    else if (marks >= 60 && marks <= 69)
      return 3.5;
    else if (marks >= 70 && marks <= 79) return 4.0;
    return 5.0;
  }

  void _calculateResult() {
    double totalMarks = 0.0;
    final grades = <double>[];

    _subjectControllers.forEach((subject, controller) {
      final marks = double.tryParse(controller.text) ?? 0.0;
      totalMarks += marks;
      grades.add(_calculateGrade(marks));
    });

    _totalMarks = totalMarks;
    _averageGrade =
        grades.isEmpty ? 0.0 : grades.reduce((a, b) => a + b) / grades.length;
    _result = grades.any((grade) => grade == 0.0) ? 'FAIL' : 'PASS';

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Calculate Marks and Grade'),
          backgroundColor: Colors.teal,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInputField(
                    controller: _examTitleController,
                    label: 'Exam Title'), //newly added
                _buildInputField(
                    controller: _studentIdController, label: 'Student ID'),
                _buildInputField(
                    controller: _studentNameController, label: 'Student Name'),
                _buildInputField(controller: _classController, label: 'Class'),
                ..._subjects.map((subject) => _buildInputField(
                    controller: _subjectControllers[subject]!,
                    label: '$subject Marks')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _calculateResult,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Calculate'),
                ),
                const SizedBox(height: 20),
                _buildResultTable(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement save result logic.
                    // The navigation to Teacherpanel was removed because it causes a
                    // build error. It requires a `currentUser` object which is not
                    // available in this context.
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Save Result not implemented.')));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Save Result'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      {required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildResultTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          columnWidths: const {
            0: const FlexColumnWidth(2),
            1: const FlexColumnWidth(3),
          },
          children: [
            //comment thiose i dont wanna show on UI
            // _buildTableRow('Exam Title', _examTitleController.text),//newly added
            //
            // _buildTableRow('Student ID', _studentIdController.text),
            // _buildTableRow('Student Name', _studentNameController.text),
            // _buildTableRow('Class', _classController.text),
            _buildTableRow('Total Marks', _totalMarks.toString()),
            _buildTableRow('Obtain Grade', _averageGrade.toStringAsFixed(2)),
            _buildTableRow('Result', _result),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: CalculateMarksPage(),
    theme: ThemeData(
      primarySwatch: Colors.teal,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
  ));
}
