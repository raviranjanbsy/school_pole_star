import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/exam_schedule.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/widgets/gradient_container.dart';

class ExamScheduleManagementPage extends StatefulWidget {
  const ExamScheduleManagementPage({super.key});

  @override
  State<ExamScheduleManagementPage> createState() =>
      _ExamScheduleManagementPageState();
}

class _ExamScheduleManagementPageState
    extends State<ExamScheduleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _classController = TextEditingController();
  final _subjectController = TextEditingController();
  final _examNameController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _maxMarksController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _classController.dispose();
    _subjectController.dispose();
    _examNameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _maxMarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _addExamSchedule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an exam date.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final newSchedule = ExamSchedule(
        id: '', // DB will generate this
        className: _classController.text.trim(),
        subject: _subjectController.text.trim(),
        examName: _examNameController.text.trim(),
        examDate: _selectedDate!.millisecondsSinceEpoch,
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        maxMarks: int.tryParse(_maxMarksController.text.trim()) ?? 0,
        createdAt: 0, // Server will set this
      );

      try {
        await _authService.addExamSchedule(newSchedule);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam schedule added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _classController.clear();
        _subjectController.clear();
        _examNameController.clear();
        _startTimeController.clear();
        _endTimeController.clear();
        _maxMarksController.clear();
        setState(() {
          _selectedDate = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Exam Schedule Management'),
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildExamScheduleForm(),
              const SizedBox(height: 24),
              Text('Upcoming Exams',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Divider(),
              _buildExamScheduleList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamScheduleForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Schedule',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextFormField(
            controller: _classController,
            decoration: const InputDecoration(
              labelText: 'Class Name (e.g., 10th)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a class name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject (e.g., Mathematics)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a subject' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _examNameController,
            decoration: const InputDecoration(
              labelText: 'Exam Name (e.g., Mid-Term)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter an exam name' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (e.g., 09:00 AM)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a start time' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time (e.g., 12:00 PM)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an end time' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _maxMarksController,
            decoration: const InputDecoration(
              labelText: 'Max Marks',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value!.isEmpty) return 'Please enter max marks';
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('Pick Date'),
                onPressed: _pickDate,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedDate == null
                      ? 'No date selected.'
                      : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Schedule'),
              onPressed: _addExamSchedule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamScheduleList() {
    return StreamBuilder<List<ExamSchedule>>(
      stream: _authService.fetchExamSchedules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No exam schedules found.'));
        }

        final schedules = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            final examDate =
                DateTime.fromMillisecondsSinceEpoch(schedule.examDate);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${schedule.maxMarks}'),
                ),
                title: Text(
                  '${schedule.subject} - ${schedule.examName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    '${schedule.className} | ${DateFormat.yMMMd().format(examDate)}\n${schedule.startTime} - ${schedule.endTime}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
