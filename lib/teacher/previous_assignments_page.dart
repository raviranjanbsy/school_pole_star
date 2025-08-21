import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/create_post_dialog.dart';
import 'package:school_management/widgets/stream_item_card.dart';

class PreviousAssignmentsPage extends StatefulWidget {
  final TeacherProfile teacherProfile;
  final SchoolClass schoolClass;

  const PreviousAssignmentsPage({
    super.key,
    required this.teacherProfile,
    required this.schoolClass,
  });

  @override
  State<PreviousAssignmentsPage> createState() =>
      _PreviousAssignmentsPageState();
}

class _PreviousAssignmentsPageState extends State<PreviousAssignmentsPage> {
  final AuthService _authService = AuthService();
  List<StreamItem>? _previousAssignments;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreviousAssignments();
  }

  Future<void> _loadPreviousAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final assignments = await _authService.fetchPreviousAssignments(
        widget.schoolClass.classId,
      );
      setState(() {
        _previousAssignments = assignments;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load previous assignments: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuse Previous Assignment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _previousAssignments == null || _previousAssignments!.isEmpty
                  ? const Center(child: Text('No previous assignments found.'))
                  : ListView.builder(
                      itemCount: _previousAssignments!.length,
                      itemBuilder: (context, index) {
                        final assignment = _previousAssignments![index];
                        return StreamItemCard(
                          item: assignment,
                          onTap: () {
                            showCreatePostDialog(
                              context,
                              widget.teacherProfile,
                              widget.schoolClass,
                              assignment,
                            );
                          },
                        );
                      },
                    ),
    );
  }
}