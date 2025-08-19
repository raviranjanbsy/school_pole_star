import 'package:flutter/material.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'package:school_management/widgets/stream_item_card.dart';

class SubjectAssignmentsPage extends StatefulWidget {
  final String classId;
  final String subjectName;
  final String? session;

  const SubjectAssignmentsPage({
    super.key,
    required this.classId,
    required this.subjectName,
    this.session,
  });

  @override
  State<SubjectAssignmentsPage> createState() => _SubjectAssignmentsPageState();
}

class _SubjectAssignmentsPageState extends State<SubjectAssignmentsPage> {
  final AuthService _authService = AuthService();
  List<StreamItem>? _assignments;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _authService.fetchStreamForClass(widget.classId);
      setState(() {
        _assignments = items
            .where((item) =>
                item.type == 'assignment' &&
                item.subjectName == widget.subjectName &&
                (widget.session == null || item.session == widget.session))
            .toList();
      });
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.subjectName),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _assignments == null || _assignments!.isEmpty
                    ? const Center(
                        child: Text('No assignments for this subject yet.'))
                    : RefreshIndicator(
                        onRefresh: _loadAssignments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _assignments!.length,
                          itemBuilder: (context, index) {
                            final item = _assignments![index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: StreamItemCard(
                                item: item,
                                onTap: () {},
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}