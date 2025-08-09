import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:school_management/class_detail_page.dart';

class StreamItemCard extends StatelessWidget {
  final StreamItem item;
  final VoidCallback onTap;

  const StreamItemCard({super.key, required this.item, required this.onTap});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      developer.log('Could not launch $urlString', name: 'StreamItemCard');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment.')),
      );
    } else {
      // Use externalApplication mode to let the OS handle the file type.
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classDetailPage =
        context.findAncestorStateOfType<ClassDetailPageState>();
    final bool isTeacher = classDetailPage?.widget.userRole == 'teacher';

    final isAssignment = item.type == 'assignment';
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Main content of the card
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            isAssignment ? Colors.blueAccent : Colors.teal,
                        child: Icon(
                          isAssignment ? Icons.assignment : Icons.campaign,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title ??
                                  (isAssignment
                                      ? 'Assignment'
                                      : 'Announcement'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isAssignment && item.subjectName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Subject: ${item.subjectName!}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                '${item.authorName} • ${DateFormat.yMMMd().format(item.timestamp)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.content,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.attachmentUrl != null &&
                      item.attachmentFileName != null) ...[
                    const Divider(height: 16),
                    InkWell(
                      onTap: () => _launchURL(context, item.attachmentUrl!),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attachment,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.attachmentFileName!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Edit/Delete button for teachers
            if (isTeacher)
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'edit') {
                      classDetailPage?.showEditPostDialog(item);
                    } else if (value == 'delete') {
                      classDetailPage?.deletePost(item.classId, item.id);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
