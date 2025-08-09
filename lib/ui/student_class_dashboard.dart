import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
import 'package:intl/intl.dart'; // For date formatting
import 'package:school_management/model_class/submission.dart'; // Import Submission model
import 'package:school_management/ui/attendance_list.dart'; // New import
import 'package:school_management/providers/class_stream_provider.dart'; // Correct provider
import 'package:school_management/providers/auth_provider.dart'; // For student UID
import 'package:school_management/ui/my_invoices_page.dart'; // New import
import 'package:school_management/providers/home_stream_provider.dart';
import 'dart:developer' as developer;
import 'package:school_management/widgets/gradient_container.dart';

class StudentClassDashboard extends StatelessWidget {
  final String classId;

  const StudentClassDashboard({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Class Dashboard')),
        body: ClassToolsGrid(classId: classId),
      ),
    );
  }
}

/// A reusable widget that displays the grid of tools for a specific class.
class ClassToolsGrid extends StatelessWidget {
  final String classId;
  const ClassToolsGrid({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _buildClassToolCard(
          context: context,
          icon: Icons.campaign,
          label: 'Announcements',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GradientContainer(
                    child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(title: const Text('Announcements')),
                  body: AnnouncementsList(classId: classId),
                )),
              ),
            );
          },
        ),
        _buildClassToolCard(
          context: context,
          icon: Icons.assignment,
          label: 'Assignments',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GradientContainer(
                    child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(title: const Text('Assignments')),
                  body: AssignmentsList(classId: classId),
                )),
              ),
            );
          },
        ),
        _buildClassToolCard(
          context: context,
          icon: Icons.calendar_today,
          label: 'Attendance',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GradientContainer(
                    child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: AttendanceList(classId: classId),
                )),
              ),
            );
          },
        ),
        _buildClassToolCard(
          context: context,
          icon: Icons.receipt_long, // An icon for invoices
          label: 'My Invoices',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Navigate to the new MyInvoicesPage
                builder: (context) => const MyInvoicesPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClassToolCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to display the list of announcements, now watching the classStreamProvider.
class AnnouncementsList extends ConsumerWidget {
  final String classId;
  const AnnouncementsList({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsyncValue = ref.watch(homePageStreamProvider(classId));
    ref.invalidate(homePageStreamProvider(classId));
    return streamAsyncValue.when(
      data: (items) {
        developer.log(
          'AnnouncementsList: Received ${items.length} items',
          name: 'StudentClassDashboard',
        );
        final announcements =
            items.where((i) => i.type == 'announcement').toList();
        developer.log(
          'AnnouncementsList: Filtered to ${announcements.length} announcements',
          name: 'StudentClassDashboard',
        );
        if (announcements.isEmpty) {
          return const Center(
            child: Text(
              'No announcements yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            return AnnouncementTile(item: announcements[index]);
          },
        );
      },
      loading: () {
        developer.log(
          'AnnouncementsList: Loading...',
          name: 'StudentClassDashboard',
        );
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        developer.log(
          'AnnouncementsList: Error: $error',
          name: 'StudentClassDashboard',
        );
        return Center(child: Text('Error: $error'));
      },
    );
  }
}

// Widget to display the list of assignments
class AssignmentsList extends ConsumerWidget {
  final String classId;
  const AssignmentsList({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsyncValue = ref.watch(homePageStreamProvider(classId));

    ref.invalidate(homePageStreamProvider(classId));
    return streamAsyncValue.when(
      data: (items) {
        developer.log(
          'AssignmentsList: Received ${items.length} items',
          name: 'StudentClassDashboard',
        );
        final assignments = items.where((i) => i.type == 'assignment').toList();
        developer.log(
          'AssignmentsList: Filtered to ${assignments.length} assignments',
          name: 'StudentClassDashboard',
        );
        if (assignments.isEmpty) {
          return const Center(
            child: Text(
              'No assignments posted.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            return AssignmentTile(item: assignments[index]);
          },
        );
      },
      loading: () {
        developer.log(
          'AssignmentsList: Loading...',
          name: 'StudentClassDashboard',
        );
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        developer.log(
          'AssignmentsList: Error: $error',
          name: 'StudentClassDashboard',
        );
        return Center(child: Text('Error: $error'));
      },
    );
  }
}

/// Returns an IconData based on the file extension.
IconData _getIconForFileType(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'doc':
    case 'docx':
      return Icons.description;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart;
    case 'ppt':
    case 'pptx':
      return Icons.slideshow;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
      return Icons.image;
    default:
      return Icons.attach_file;
  }
}

/// A simple tile to display an announcement. Customize this to your needs.
class AnnouncementTile extends StatelessWidget {
  final StreamItem item;
  const AnnouncementTile({super.key, required this.item});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open file: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // This container adds the red sidebar, similar to the orange one for assignments.
            Container(width: 6, color: Colors.red),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Broadcast Header
                    Row(
                      children: [
                        const Icon(Icons.campaign, color: Colors.red, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title ?? 'Announcement',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'BROADCAST | ${DateFormat('dd-MM-yyyy').format(item.timestamp)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Body text
                    Text(item.content, style: const TextStyle(fontSize: 14)),
                    if (item.attachmentUrl != null &&
                        item.attachmentFileName != null) ...[
                      const SizedBox(height: 16),
                      _buildAttachment(context),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Posted by: ${item.authorName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _launchUrl(context, item.attachmentUrl!),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(
                _getIconForFileType(item.attachmentFileName!),
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.attachmentFileName!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.download_for_offline_outlined,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple tile to display an assignment. Customize this to your needs.
class AssignmentTile extends StatelessWidget {
  final StreamItem item;
  const AssignmentTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: Colors.orangeAccent),
            Expanded(
              child: _AssignmentTileContent(key: ValueKey(item.id), item: item),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentTileContent extends ConsumerStatefulWidget {
  final StreamItem item;
  const _AssignmentTileContent({super.key, required this.item});

  @override
  ConsumerState<_AssignmentTileContent> createState() =>
      _AssignmentTileContentState();
}

class _AssignmentTileContentState
    extends ConsumerState<_AssignmentTileContent> {
  String? _studentUid;
  late Future<Submission?> _submissionFuture;

  @override
  void initState() {
    super.initState();
    _studentUid = ref.read(authServiceProvider).getAuth().currentUser?.uid;
    _loadSubmission();
  }

  void _loadSubmission() {
    // Calling setState is crucial here to make the FutureBuilder rebuild with the new future.
    setState(() {
      if (_studentUid != null) {
        final authService = ref.read(authServiceProvider);
        _submissionFuture = authService.fetchStudentSubmissionForAssignment(
          widget.item.id,
          _studentUid!,
        );
      } else {
        _submissionFuture = Future.value(null); // No user, no submission
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_studentUid == null) {
      return const SizedBox
          .shrink(); // Or show a message if user is not logged in
    }

    return ListTile(
      // The ListTile is being replaced with a more flexible Column layout
      // to match the structure of AnnouncementTile.
      // The content below is the new implementation.
      title: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.assignment,
                  color: Colors.orangeAccent,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title ?? 'Assignment',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      if (widget.item.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${DateFormat('dd-MM-yyyy').format(widget.item.dueDate!)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing submission button
                FutureBuilder<Submission?>(
                  future: _submissionFuture,
                  builder: (context, snapshot) {
                    final submission = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (submission != null) {
                      return IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        tooltip: 'View Submitted File',
                        onPressed: () => _launchUrl(submission.fileUrl),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            // Body text
            Text(widget.item.content, style: const TextStyle(fontSize: 14)),
            if (widget.item.attachmentUrl != null &&
                widget.item.attachmentFileName != null) ...[
              const SizedBox(height: 16),
              _buildAttachment(context),
            ],
            // Submission Status
            FutureBuilder<Submission?>(
              future: _submissionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Error loading submission: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final submission = snapshot.data;
                if (submission != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: Submitted',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (submission.grade != null &&
                            submission.grade!.isNotEmpty)
                          Text(
                            'Grade: ${submission.grade}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (submission.comments != null &&
                            submission.comments!.isNotEmpty)
                          Text(
                            'Comments: ${submission.comments}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        Text(
                          'Submitted on: ${DateFormat.yMMMd().add_jm().format(submission.submissionTimestamp)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            // Author
            Text(
              'Posted by: ${widget.item.authorName}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _launchUrl(widget.item.attachmentUrl!),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(
                _getIconForFileType(widget.item.attachmentFileName!),
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.attachmentFileName!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.download_for_offline_outlined,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open file: $url')));
      }
    }
  }
}
