import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:intl/intl.dart';

Future<void> showCreatePostDialog(
    BuildContext context,
    TeacherProfile teacherProfile,
    SchoolClass schoolClass,
    StreamItem? existingItem) async {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = existingItem?.type ?? 'announcement';
  final TextEditingController _contentController =
      TextEditingController(text: existingItem?.content ?? '');
  final TextEditingController _titleController =
      TextEditingController(text: existingItem?.title ?? '');
  final TextEditingController _sessionController = TextEditingController(
      text: existingItem?.session ?? DateTime.now().year.toString());
  DateTime? _selectedDueDate = existingItem?.dueDate;
  String? _selectedSubject = existingItem?.subjectName;
  PlatformFile? _selectedFile;
  final AuthService _authService = AuthService();

  List<String> _subjects = [];
  try {
    final subjects = await _authService.fetchSubjectsForTeacherInClass(
      teacherProfile.uid,
      schoolClass.classId,
    );
    _subjects = subjects.map((s) => s.subjectName).toList();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load subjects: ${e.toString()}')),
    );
  }

  await showDialog<void>(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
        title:
            Text(existingItem == null ? 'Create New Post' : 'Reuse Assignment'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    if (existingItem == null)
                      SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                              value: 'announcement',
                              label: Text('Announcement'),
                              icon: Icon(Icons.campaign)),
                          ButtonSegment<String>(
                              value: 'assignment',
                              label: Text('Assignment'),
                              icon: Icon(Icons.assignment)),
                        ],
                        selected: {_selectedType},
                        onSelectionChanged: (Set<String> newSelection) {
                          dialogSetState(() {
                            _selectedType = newSelection.first;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                          labelText: _selectedType == 'announcement'
                              ? 'Announcement Title'
                              : 'Assignment Title'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please enter a title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.vertical,
                            child: child,
                          ),
                        );
                      },
                      child: _selectedType == 'assignment'
                          ? Column(
                              key: const ValueKey('assignment_fields'),
                              children: [
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _sessionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Session',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Session cannot be empty';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (_subjects.isNotEmpty)
                                  DropdownButtonFormField<String>(
                                    value: _selectedSubject,
                                    hint: const Text('Select Subject'),
                                    decoration: const InputDecoration(
                                        labelText: 'Subject'),
                                    items: _subjects.map((subject) {
                                      return DropdownMenuItem(
                                        value: subject,
                                        child: Text(subject),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      dialogSetState(
                                          () => _selectedSubject = newValue);
                                    },
                                    validator: (v) => v == null
                                        ? 'Please select a subject'
                                        : null,
                                  )
                                else
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'No subjects assigned to you for this class.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Due Date',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  child: ListTile(
                                    title: Text(_selectedDueDate == null
                                        ? 'Select a date'
                                        : DateFormat.yMMMd()
                                            .format(_selectedDueDate!)),
                                    trailing: const Icon(Icons.calendar_today),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            _selectedDueDate ?? DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2101),
                                      );
                                      if (picked != null) {
                                        dialogSetState(
                                            () => _selectedDueDate = picked);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('no_assignment_fields')),
                    ),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: _selectedType == 'announcement'
                            ? 'Announcement Content'
                            : 'Assignment Description',
                      ),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Content cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedFile == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach File'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null) {
                            dialogSetState(
                                () => _selectedFile = result.files.single);
                          }
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attachment, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFile!.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  dialogSetState(() => _selectedFile = null),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Post'),
            onPressed: (_selectedType == 'assignment' && _subjects.isEmpty)
                ? null // Disable button if no subjects for an assignment
                : () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedType == 'assignment' &&
                          _selectedDueDate == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please select a due date for the assignment.')),
                        );
                        return;
                      }
                      Navigator.of(dialogContext).pop(); // Dismiss dialog
                      await createPost(
                        context,
                        _authService,
                        schoolClass,
                        teacherProfile,
                        _selectedType,
                        _titleController.text.trim(),
                        _contentController.text.trim(),
                        _sessionController.text.trim(),
                        _selectedDueDate,
                        _selectedSubject,
                        _selectedFile,
                      );
                    }
                  },
          ),
        ],
      );
    },
  );
}

Future<void> createPost(
    BuildContext context,
    AuthService authService,
    SchoolClass schoolClass,
    TeacherProfile teacherProfile,
    String type,
    String title,
    String content,
    String session,
    DateTime? dueDate,
    String? subjectName,
    PlatformFile? attachment) async {
  try {
    String? attachmentUrl;
    String? attachmentFileName;

    if (attachment != null) {
      final uploadResult = await authService.uploadStreamAttachment(
        kIsWeb ? attachment.bytes! : File(attachment.path!),
        schoolClass.classId,
        attachment.name,
      );
      attachmentUrl = uploadResult['url'];
      attachmentFileName = uploadResult['fileName'];
    }

    final item = StreamItem(
      id: '', // Firebase will generate this
      classId: schoolClass.classId,
      authorId: teacherProfile.uid,
      authorName: teacherProfile.name,
      type: type,
      content: content,
      title: title.isNotEmpty
          ? title
          : (type == 'assignment' ? 'Assignment' : 'Announcement'),
      subjectName: type == 'assignment' ? subjectName : null,
      timestamp: DateTime.now(),
      dueDate: dueDate,
      attachmentUrl: attachmentUrl,
      attachmentFileName: attachmentFileName,
      session: session,
    );

    await authService.createStreamItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${type[0].toUpperCase() + type.substring(1)} posted successfully!')),
    );
  } on AuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to post: ${e.message}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
    );
  }
}
