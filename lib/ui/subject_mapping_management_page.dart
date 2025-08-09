import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/model_class/subject_mapping.dart';
import 'package:school_management/model_class/teacher_profile.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart';

class SubjectMappingManagementPage extends StatefulWidget {
  const SubjectMappingManagementPage({super.key});

  @override
  State<SubjectMappingManagementPage> createState() =>
      _SubjectMappingManagementPageState();
}

class _SubjectMappingManagementPageState
    extends State<SubjectMappingManagementPage> {
  final _authService = AuthService();

  bool _isLoading = true;
  List<SchoolClass> _allClasses = [];
  List<TeacherProfile> _allTeachers = [];
  SchoolClass? _selectedClass;

  // Stores the current mapping UI state: Map<SubjectName, TeacherId>
  Map<String, String> _currentMappings = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final classes = await _authService.fetchAllSchoolClasses();
      final teachers = await _authService.fetchAllTeachers();
      setState(() {
        _allClasses = classes;
        _allTeachers = teachers;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onClassSelected(SchoolClass? schoolClass) async {
    if (schoolClass == null) return;

    setState(() {
      _isLoading = true;
      _selectedClass = schoolClass;
      _currentMappings = {}; // Clear previous mappings
    });

    try {
      final existingMappings =
          await _authService.fetchSubjectMappings(schoolClass.classId);
      final newMappings = <String, String>{};
      for (var mapping in existingMappings) {
        newMappings[mapping.subjectName] = mapping.teacherId;
      }
      setState(() {
        _currentMappings = newMappings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subject mappings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveMappings() async {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<SubjectMapping> mappingsToSave = [];
      for (var entry in _currentMappings.entries) {
        final subjectName = entry.key;
        final teacherId = entry.value;
        final teacher =
            _allTeachers.where((t) => t.uid == teacherId).firstOrNull;

        // Only add the mapping if the teacher is found
        if (teacher != null) {
          mappingsToSave.add(SubjectMapping(
              subjectName: subjectName,
              teacherId: teacherId,
              teacherName: teacher.name));
        }
      }

      await _authService.saveSubjectMappings(
          _selectedClass!.classId, mappingsToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mappings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save mappings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Mapping'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClassSelector(),
              const SizedBox(height: 24),
              if (_selectedClass != null) ...[
                Text('Subjects for ${_selectedClass!.className}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Divider(),
                Expanded(child: _buildMappingList()),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Mappings'),
                    onPressed: _saveMappings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              ] else
                const Expanded(
                  child: Center(
                    child: Text('Please select a class to see its subjects.'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return DropdownButtonFormField<SchoolClass>(
      value: _selectedClass,
      hint: const Text('Select a Class'),
      isExpanded: true,
      onChanged: _onClassSelected,
      items: _allClasses.map((schoolClass) {
        return DropdownMenuItem<SchoolClass>(
          value: schoolClass,
          child: Text(schoolClass.className),
        );
      }).toList(),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildMappingList() {
    if (_selectedClass!.subjects.isEmpty) {
      return const Center(
        child: Text('This class has no subjects defined.'),
      );
    }

    return ListView.separated(
      itemCount: _selectedClass!.subjects.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final subject = _selectedClass!.subjects[index];
        final assignedTeacherId = _currentMappings[subject];

        return ListTile(
          title: Text(subject,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: DropdownButton<String>(
            value: assignedTeacherId,
            hint: const Text('Assign a Teacher'),
            isExpanded: true,
            onChanged: (teacherId) {
              if (teacherId != null) {
                setState(() {
                  _currentMappings[subject] = teacherId;
                });
              }
            },
            items: _allTeachers.map((teacher) {
              return DropdownMenuItem<String>(
                value: teacher.uid,
                child: Text(teacher.name),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
