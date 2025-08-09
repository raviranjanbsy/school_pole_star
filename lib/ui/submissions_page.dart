import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management/model_class/submission.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/ui/grade_submission_dialog.dart';
import 'package:school_management/widgets/gradient_container.dart';

class SubmissionsPage extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;

  const SubmissionsPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<SubmissionsPage> createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  final AuthService _authService = AuthService();
  late Future<List<Submission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  void _loadSubmissions() {
    _submissionsFuture =
        _authService.fetchSubmissionsForAssignment(widget.assignmentId);
  }

  void _refreshSubmissions() {
    setState(() {
      _loadSubmissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignmentTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Text('Submissions', style: TextStyle(color: Colors.white70)),
        ),
      ),
      body: FutureBuilder<List<Submission>>(
        future: _submissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No submissions yet.'));
          }

          final submissions = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshSubmissions(),
            child: ListView.builder(
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final submission = submissions[index];
                return ListTile(
                  title: Text(submission.studentName),
                  subtitle: Text(
                      'Submitted on: ${DateFormat.yMMMd().add_jm().format(submission.submissionTimestamp)}'),
                  trailing: Text(submission.grade ?? 'Not Graded',
                      style: TextStyle(
                          color: submission.grade != null
                              ? Colors.green
                              : Colors.orange)),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => GradeSubmissionDialog(
                        assignmentId: widget.assignmentId,
                        submission: submission,
                        onGraded: _refreshSubmissions),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
