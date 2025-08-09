import 'package:flutter/material.dart';
import 'package:school_management/widgets/gradient_container.dart';

class AddExamSchedulePage extends StatefulWidget {
  const AddExamSchedulePage({super.key});

  @override
  _AddExamSchedulePageState createState() => _AddExamSchedulePageState();
}

class _AddExamSchedulePageState extends State<AddExamSchedulePage> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String examTitle = '';
  String selectedClass = '';
  String selectedSection = '';
  String selectedSubject = '';
  String examType = '';
  String examHall = '';
  DateTime? examDate;
  TimeOfDay? examStartTime;
  TimeOfDay? examEndTime;
  String selectedInvigilator = '';

  List<String> subjectList = [];
  List<String> allTeacherNameList = [
    'Afsana Meem Ema ',
    'Sajeeb Islam',
    'Jahir Uddin'
  ];

  void _saveExamSchedule() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Exam Schedule has been set successfully!')),
      );
    }
  }

  void getSubjectList() {
    setState(() {
      if (selectedClass == '9th' || selectedClass == '10th') {
        subjectList = ['Math', 'Physics', 'Chemistry', 'Accounting', 'Finance'];
      } else {
        subjectList = ['Bangla', 'English', 'Math', 'Science'];
      }
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != examDate) {
      setState(() {
        examDate = picked;
      });
    }
  }

  Future<void> _pickTime({required bool isStartTime}) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          examStartTime = picked;
        } else {
          examEndTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add Exam Schedule'),
        backgroundColor: Colors.teal,
      ),
      body: GradientContainer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTextField('Exam Title', (value) {
                  examTitle = value ?? '';
                }),
                _buildDropdown(
                  label: 'Class',
                  value: selectedClass,
                  items: [
                    '1st',
                    '2nd',
                    '3rd',
                    '4th',
                    '5th',
                    '6th',
                    '7th',
                    '8th',
                    '9th',
                    '10th'
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedClass = value ?? '';
                      getSubjectList();
                    });
                  },
                ),
                if (selectedClass == '9th' || selectedClass == '10th')
                  _buildDropdown(
                    label: 'Section',
                    value: selectedSection,
                    items: ['Science', 'Business Studies', 'Huminities'],
                    onChanged: (value) {
                      setState(() {
                        selectedSection = value ?? '';
                        getSubjectList();
                      });
                    },
                  ),
                _buildDropdown(
                  label: 'Subject',
                  value: selectedSubject,
                  items: subjectList,
                  onChanged: (value) {
                    setState(() {
                      selectedSubject = value ?? '';
                    });
                  },
                ),
                _buildDropdown(
                  label: 'Exam Type',
                  value: examType,
                  items: ['Theory', 'Practical'],
                  onChanged: (value) {
                    setState(() {
                      examType = value ?? '';
                    });
                  },
                ),
                _buildTextField('Examination Hall', (value) {
                  examHall = value ?? '';
                }),
                _buildDateTimePicker(
                  label: 'Exam Date',
                  value: examDate == null
                      ? 'Pick Exam Date'
                      : 'Exam Date: ${examDate!.toLocal()}'.split(' ')[0],
                  onTap: _pickDate,
                ),
                _buildDateTimePicker(
                  label: 'Exam Start Time',
                  value: examStartTime == null
                      ? 'Pick Exam Start Time'
                      : 'Exam Start Time: ${examStartTime!.format(context)}',
                  onTap: () => _pickTime(isStartTime: true),
                ),
                _buildDateTimePicker(
                  label: 'Exam End Time',
                  value: examEndTime == null
                      ? 'Pick Exam End Time'
                      : 'Exam End Time: ${examEndTime!.format(context)}',
                  onTap: () => _pickTime(isStartTime: false),
                ),
                _buildDropdown(
                  label: 'Exam Invigilator',
                  value: selectedInvigilator,
                  items: allTeacherNameList,
                  onChanged: (value) {
                    setState(() {
                      selectedInvigilator = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveExamSchedule,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    textStyle: const TextStyle(fontSize: 16),
                    foregroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Set Exam Schedule'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onSaved: onSaved,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(value),
        trailing: const Icon(Icons.calendar_today),
        onTap: onTap,
        tileColor: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}
