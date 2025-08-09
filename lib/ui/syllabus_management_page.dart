import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management/model_class/syllabus.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_management/widgets/gradient_container.dart';

class SyllabusManagementPage extends StatefulWidget {
  const SyllabusManagementPage({super.key});

  @override
  State<SyllabusManagementPage> createState() => _SyllabusManagementPageState();
}

class _SyllabusManagementPageState extends State<SyllabusManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _classController = TextEditingController();
  final _subjectController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  File? _selectedFile;

  @override
  void dispose() {
    _classController.dispose();
    _subjectController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Future<void> _addSyllabus() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String? fileUrl;

      try {
        // 1. Upload file if selected
        if (_selectedFile != null) {
          fileUrl = await _authService.uploadSyllabusFile(
            _selectedFile!,
            _titleController.text.trim(),
          );
        }

        // 2. Create Syllabus object with the URL
        final newSyllabus = Syllabus(
            id: '', // DB will generate this
            className: _classController.text.trim(),
            subject: _subjectController.text.trim(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            createdAt: 0, // Server will set this
            fileUrl: fileUrl);

        // 3. Add syllabus entry to database
        await _authService.addSyllabus(newSyllabus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syllabus added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _classController.clear();
        _subjectController.clear();
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedFile = null; // Clear the selected file
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add syllabus: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syllabus Management'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSyllabusForm(),
            const SizedBox(height: 24),
            Text('Existing Syllabuses',
                style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            _buildSyllabusList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Syllabus Entry',
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
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (e.g., Chapter 1: Real Numbers)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a title' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach File'),
                onPressed: _pickFile,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedFile?.uri.pathSegments.last ?? 'No file selected.',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Syllabus'),
              onPressed: _addSyllabus,
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

  Widget _buildSyllabusList() {
    return StreamBuilder<List<Syllabus>>(
      stream: _authService.fetchSyllabuses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No syllabus entries found.'));
        }

        final syllabuses = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: syllabuses.length,
          itemBuilder: (context, index) {
            final syllabus = syllabuses[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(syllabus.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${syllabus.className} - ${syllabus.subject}\nAdded on: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(syllabus.createdAt))}'),
                isThreeLine: true,
                trailing:
                    syllabus.fileUrl != null && syllabus.fileUrl!.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'Open File',
                            onPressed: () => _launchURL(syllabus.fileUrl!),
                          )
                        : null,
              ),
            );
          },
        );
      },
    );
  }
}
