import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/providers/auth_provider.dart';
import 'package:school_management/providers/communication_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:school_management/widgets/gradient_container.dart';

class CommunicationPage extends ConsumerStatefulWidget {
  const CommunicationPage({super.key});
  @override
  ConsumerState<CommunicationPage> createState() => CommunicationPageState();
}

class CommunicationPageState extends ConsumerState<CommunicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  List<dynamic> _selectedRecipients = []; // Can be String, SchoolClass, Alluser
  List<String> _groups = ['All Teachers', 'All Students'];
  List<SchoolClass> _classes = [];
  List<Alluser> _users = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Fetch data and update state
    await ref.read(communicationProvider.notifier).loadData();
    setState(() {
      _classes = ref.read(communicationProvider).classes;
    });
    setState(() {
      _users = ref.read(communicationProvider).users;
    });
  }

  Future<void> _showRecipientDialog() async {
    final List<dynamic>? result = await showDialog<List<dynamic>>(
      context: context,
      builder: (BuildContext context) {
        List<dynamic> selected = List.from(_selectedRecipients);
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Select Recipients'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRecipientTab(
                  'Groups',
                  _groups,
                  selected,
                  setState,
                ),
                _buildRecipientTab(
                  'Classes',
                  _classes,
                  selected,
                  setState,
                ),
                _buildRecipientTab(
                  'Individuals',
                  _users,
                  selected,
                  setState,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() => _selectedRecipients = result);
    }
  }

  Widget _buildRecipientTab(
    String title,
    List<dynamic> items,
    List<dynamic> selected,
    StateSetter setState, {
    @Deprecated('Use direct property access instead.') String displayField = '',
  }) {
    return ExpansionTile(
      title: Text(title),
      children: items.map((item) {
        final isSelected = selected.contains(item);

        String displayName;
        if (item is String) {
          displayName = item;
        } else if (item is SchoolClass) {
          displayName = item.className;
        } else if (item is Alluser) {
          displayName = item.name;
        } else {
          displayName = 'Unknown Item';
        }

        return CheckboxListTile(
          title: Text(displayName),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selected.add(item);
              } else {
                selected.remove(item);
              }
            });
          },
        );
      }).toList(),
    );
  }

  String _displayRecipients() {
    if (_selectedRecipients.isEmpty) return 'Select Recipients';
    return _selectedRecipients.map((recipient) {
      if (recipient is String) return recipient;
      if (recipient is SchoolClass) return recipient.className;
      if (recipient is Alluser) return recipient.name;
      return 'Unknown Recipient';
    }).join(', ');
  }

  String _mapRecipientToTopic(dynamic recipient) {
    if (recipient == 'All Teachers') return 'teachers';
    if (recipient == 'All Students') return 'students';
    // For classes and users, you might have a different logic or naming convention
    // This is just an example, adjust it according to your needs.
    if (recipient is SchoolClass) return 'class_\${recipient.classId}';
    // Assuming you have a way to identify the user's role to send appropriate notifications
    if (recipient is Alluser) return 'user_\${recipient.uid}';
    return 'unknown'; // Or handle unknown cases differently
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRecipients.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one recipient.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    final title = _titleController.text;
    final message = _messageController.text;
    final dbRef = FirebaseDatabase.instance.ref('announcements');

    List<String> successfulWrites = [];
    List<String> failedWrites = [];

    for (final recipient in _selectedRecipients) {
      String recipientName = 'Unknown';
      try {
        final newAnnouncementRef = dbRef.push(); // Create a new unique key
        Map<String, dynamic> announcementData = {
          'title': title,
          'body': message,
          'timestamp':
              ServerValue.timestamp, // Good practice to add a timestamp
        };

        final topic = _mapRecipientToTopic(recipient);
        developer.log(
            'Sending to user ${recipient.name} with token: ${recipient.fcmToken}');
        if (topic.startsWith('user_') &&
            recipient is Alluser &&
            recipient.fcmToken != null) {
          announcementData['fcmToken'] = recipient.fcmToken;
          recipientName = recipient.name;
        } else if (topic != 'unknown') {
          announcementData['topic'] = topic;
          if (recipient is String) {
            recipientName = recipient;
          } else if (recipient is SchoolClass) {
            recipientName = recipient.className;
          }
        } else {
          throw Exception('Unknown recipient type');
        }

        await newAnnouncementRef.set(announcementData);
        successfulWrites.add(recipientName);
      } catch (e) {
        failedWrites.add(recipientName);
        developer.log(
          'Failed to write announcement for $recipientName: $e',
          name: 'CommunicationPage._sendAnnouncement',
        );
      }
    }

    if (!mounted) return;

    // Show summary message
    String summaryMessage;
    if (failedWrites.isEmpty) {
      summaryMessage =
          'Announcement sent to all ${successfulWrites.length} recipients.';
    } else {
      summaryMessage =
          'Sent to ${successfulWrites.length}, failed for ${failedWrites.length}: ${failedWrites.join(', ')}';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(summaryMessage)),
    );

    // Reset form
    _formKey.currentState!.reset();
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _selectedRecipients.clear();
      _isSending = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Send Announcement'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(_displayRecipients()),
                  onTap: _showRecipientDialog,
                  leading: const Icon(Icons.people),
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 5,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a message' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendAnnouncement,
                  child: _isSending
                      ? const CircularProgressIndicator()
                      : const Text('Send Announcement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
