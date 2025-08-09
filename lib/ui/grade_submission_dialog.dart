import 'package:flutter/material.dart';
import 'package:school_management/model_class/submission.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_management/widgets/gradient_container.dart';

class GradeSubmissionDialog extends StatefulWidget {
  final String assignmentId;
  final Submission submission;
  final VoidCallback onGraded;

  const GradeSubmissionDialog({
    super.key,
    required this.assignmentId,
    required this.submission,
    required this.onGraded,
  });

  @override
  State<GradeSubmissionDialog> createState() => _GradeSubmissionDialogState();
}

class _GradeSubmissionDialogState extends State<GradeSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  final _commentsController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _gradeController.text = widget.submission.grade ?? '';
    _commentsController.text = widget.submission.comments ?? '';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $url')),
      );
    }
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _authService.gradeSubmission(
        widget.assignmentId,
        widget.submission.studentUid,
        _gradeController.text.trim(),
        _commentsController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade saved successfully!')),
        );
        widget.onGraded(); // Refresh the previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save grade: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Grade: ${widget.submission.studentName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('View Submitted File'),
                leading: const Icon(Icons.link),
                onTap: () => _launchUrl(widget.submission.fileUrl),
              ),
              TextFormField(
                controller: _gradeController,
                decoration:
                    const InputDecoration(labelText: 'Grade (e.g., A+, 95%)'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a grade' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentsController,
                decoration:
                    const InputDecoration(labelText: 'Comments (Optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveGrade,
          child: Text(_isSaving ? 'Saving...' : 'Save Grade'),
        ),
      ],
    );
  }
}
