import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/model_class/teacher_profile.dart'; // Import TeacherProfile
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/teacherpanel.dart';
import 'package:school_management/studentpanel.dart';
import 'package:school_management/ui/submissions_page.dart';
import 'package:intl/intl.dart';
import 'package:school_management/ui/attendance_summary_page.dart'; // New import
import 'package:school_management/widgets/stream_item_card.dart';
import 'package:school_management/ui/take_attendance_page.dart';
import 'package:school_management/widgets/gradient_container.dart';

class ClassDetailPage extends StatefulWidget {
  final SchoolClass schoolClass;
  final Alluser currentUser;
  final String userRole; // 'teacher', 'student', or 'admin'
  final TeacherProfile?
      teacherProfile; // Optional: Pass teacher profile for posting

  const ClassDetailPage({
    super.key,
    required this.schoolClass,
    required this.currentUser,
    required this.userRole,
    this.teacherProfile,
  });

  @override
  State<ClassDetailPage> createState() => ClassDetailPageState();
}

class ClassDetailPageState extends State<ClassDetailPage> {
  final AuthService _authService = AuthService();
  List<StreamItem>? _streamItems;
  List<String> _subjects = [];
  String? _selectedSubjectFilter;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStream();
    _loadSubjectsForTeacher();
  }

  List<StreamItem> get _filteredStreamItems {
    if (_streamItems == null) return [];
    if (_selectedSubjectFilter == null) {
      return _streamItems!;
    }
    return _streamItems!.where((item) {
      // Always show announcements, regardless of the filter.
      if (item.type != 'assignment') return true;
      // Show assignments that match the selected subject.
      return item.subjectName == _selectedSubjectFilter;
    }).toList();
  }

  Future<void> _loadSubjectsForTeacher() async {
    if (widget.userRole != 'teacher' || widget.teacherProfile == null) {
      return;
    }
    try {
      // Note: You need to implement `fetchSubjectsForTeacherInClass` in your AuthService.
      // It should fetch the subjects a specific teacher is assigned to for a given class.
      final subjects = await _authService.fetchSubjectsForTeacherInClass(
        widget.teacherProfile!.uid,
        widget.schoolClass.classId,
      );
      if (mounted) {
        setState(() {
          _subjects = subjects.map((s) => s.subjectName).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadStream() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items =
          await _authService.fetchStreamForClass(widget.schoolClass.classId);
      setState(() {
        _streamItems = items;
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
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
          title: Text(widget.schoolClass.className),
          actions: [
            if (_subjects.isNotEmpty)
              PopupMenuButton<String?>(
                onSelected: (String? value) {
                  setState(() {
                    _selectedSubjectFilter = value;
                  });
                },
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter by subject',
                itemBuilder: (BuildContext context) {
                  // Add "All Subjects" option to clear the filter
                  final allSubjectsOption = const PopupMenuItem<String?>(
                    value: null,
                    child: Text('All Subjects'),
                  );
                  final subjectOptions = _subjects.map((String subject) {
                    return PopupMenuItem<String?>(
                        value: subject, child: Text(subject));
                  }).toList();
                  return [allSubjectsOption, ...subjectOptions];
                },
              ),
            if (widget.userRole == 'teacher')
              IconButton(
                icon: const Icon(Icons.checklist_rtl),
                tooltip: 'Take Attendance',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakeAttendancePage(
                          classId: widget.schoolClass.classId,
                          className: widget.schoolClass.className),
                    ),
                  );
                },
              ),
            if (widget.userRole == 'teacher')
              IconButton(
                icon: const Icon(Icons.summarize),
                tooltip: 'Attendance Summary',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceSummaryPage(
                        classId: widget.schoolClass.classId,
                        className: widget.schoolClass.className,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Loading stream...',
          child: _buildBody(),
        ),
        floatingActionButton: widget.userRole == 'teacher'
            ? FloatingActionButton(
                onPressed: () {
                  if (widget.teacherProfile != null) {
                    _showCreatePostDialog();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Teacher profile not available to create post.')));
                  }
                },
                child: const Icon(Icons.add),
                tooltip: 'Create Post',
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_filteredStreamItems.isEmpty) {
      if (_selectedSubjectFilter != null) {
        return Center(
            child: Text('No posts found for "${_selectedSubjectFilter}".'));
      } else {
        return const Center(child: Text('No posts in this class yet.'));
      }
    }

    return RefreshIndicator(
      onRefresh: _loadStream,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _filteredStreamItems.length,
        itemBuilder: (context, index) {
          final item = _filteredStreamItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: StreamItemCard(
              item: item,
              onTap: () {
                if (item.type == 'assignment' && widget.userRole == 'teacher') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubmissionsPage(
                        assignmentId: item.id,
                        assignmentTitle: item.title ?? 'Assignment',
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> editPost(StreamItem item) async {
    setState(() => _isLoading = true);
    try {
      final currentTeacher = widget.teacherProfile;
      if (currentTeacher == null) {
        throw AuthException("Teacher profile not available to edit post.");
      }

      await _authService.updateStreamItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${item.type[0].toUpperCase() + item.type.substring(1)} updated successfully!')),
      );
      await _loadStream(); // Refresh the stream
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> deletePost(String classId, String itemId) async {
    setState(() => _isLoading = true);
    try {
      await _authService.deleteStreamItem(classId, itemId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully!')),
      );
      await _loadStream(); // Refresh the stream
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> showEditPostDialog(StreamItem existingItem) async {
    final _formKey = GlobalKey<FormState>();
    String _selectedType = existingItem.type;
    final TextEditingController _contentController =
        TextEditingController(text: existingItem.content);
    final TextEditingController _titleController =
        TextEditingController(text: existingItem.title);
    DateTime? _selectedDueDate = existingItem.dueDate;
    String? _selectedSubject = existingItem.subjectName;
    File? _selectedFile;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Post'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: _selectedType == 'announcement'
                              ? 'Announcement Title'
                              : 'Assignment Title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Title cannot be empty';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: _selectedType == 'announcement'
                              ? 'Announcement Content'
                              : 'Assignment Description',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Content cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(); // Dismiss dialog
                  final updatedItem = StreamItem(
                    id: existingItem.id,
                    classId: existingItem.classId,
                    authorId: existingItem.authorId,
                    authorName: existingItem.authorName,
                    type: existingItem.type,
                    content: _contentController.text.trim(),
                    title: _titleController.text.trim(),
                    timestamp: existingItem.timestamp,
                    dueDate: existingItem.dueDate,
                    subjectName: existingItem.subjectName,
                    attachmentUrl: existingItem.attachmentUrl,
                    attachmentFileName: existingItem.attachmentFileName,
                  );
                  await editPost(updatedItem);
                }
              },
            ),
          ],
        );
      },
    );
  }

  String truncateString(String str, int maxLength) {
    if (str.length <= maxLength) {
      return str;
    } else {
      return str.substring(0, maxLength) + '...';
    }
  }

  Future<void> _showCreatePostDialog() async {
    final _formKey = GlobalKey<FormState>();
    String _selectedType = 'announcement';
    final TextEditingController _contentController = TextEditingController();
    final TextEditingController _titleController = TextEditingController();
    DateTime? _selectedDueDate;
    String? _selectedSubject;
    PlatformFile? _selectedFile;

    await showDialog<void>(
      // Using a barrier dismissible as false can prevent accidental closures.
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Add padding to the title for better spacing.
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
          title: const Text('Create New Post'),
          // Use content padding to give the form elements some breathing room.
          contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  // Use a Column with better spacing and structure.
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Use a SegmentedButton for a modern type selector.
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
                      // Use AnimatedSwitcher for a smooth transition.
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
                                  else if (widget.userRole == 'teacher')
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(
                                        'No subjects assigned to you for this class.',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  // Improved Due Date Picker style
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
                                      trailing:
                                          const Icon(Icons.calendar_today),
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDueDate ??
                                              DateTime.now(),
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
                            final result =
                                await FilePicker.platform.pickFiles();
                            if (result != null) {
                              dialogSetState(
                                  () => _selectedFile = result.files.single);
                            }
                          },
                        )
                      else
                        // Improved selected file display
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
          // Add padding to actions for better spacing.
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
                        await _createPost(
                          _selectedType,
                          _titleController.text.trim(),
                          _contentController.text.trim(),
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

  Future<void> _createPost(String type, String title, String content,
      DateTime? dueDate, String? subjectName, PlatformFile? attachment) async {
    setState(() => _isLoading = true);
    try {
      final currentTeacher = widget.teacherProfile;
      if (currentTeacher == null) {
        throw AuthException("Teacher profile not available to create post.");
      }

      String? attachmentUrl;
      String? attachmentFileName;

      // Upload attachment if it exists
      if (attachment != null) {
        final uploadResult = await _authService.uploadStreamAttachment(
          kIsWeb ? attachment.bytes! : File(attachment.path!),
          widget.schoolClass.classId,
          attachment.name,
        );
        attachmentUrl = uploadResult['url'];
        attachmentFileName = uploadResult['fileName'];
      }

      final item = StreamItem(
        id: '', // Firebase will generate this
        classId: widget.schoolClass.classId,
        authorId: currentTeacher.uid,
        authorName: currentTeacher.name,
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
      );

      await _authService.createStreamItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${type[0].toUpperCase() + type.substring(1)} posted successfully!')),
      );
      await _loadStream(); // Refresh the stream
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
