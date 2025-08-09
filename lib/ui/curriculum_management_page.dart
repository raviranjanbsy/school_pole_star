import 'package:flutter/material.dart';
import 'package:school_management/main.dart';
import 'package:school_management/ui/exam_schedule_management_page.dart';
import 'package:school_management/ui/subject_mapping_management_page.dart';
import 'package:school_management/ui/syllabus_management_page.dart';
import 'package:school_management/ui/assign_class_teacher_page.dart';
import 'package:school_management/widgets/gradient_container.dart';

class CurriculumManagementPage extends StatelessWidget {
  const CurriculumManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Curriculum Management'),
        ),
        body: GridView.count(
          crossAxisCount: 2, // Two columns for the grid
          padding: const EdgeInsets.all(16.0),
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildManagementToolCard(
              context: context,
              icon: Icons.assignment_ind_outlined,
              label: 'Assign Class Teacher',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssignClassTeacherPage(),
                  ),
                );
              },
            ),
            _buildManagementToolCard(
              context: context,
              icon: Icons.menu_book,
              label: 'Syllabus',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SyllabusManagementPage()),
                );
              },
            ),
            _buildManagementToolCard(
              context: context,
              icon: Icons.schedule,
              label: 'Exam Schedule',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExamScheduleManagementPage()),
                );
              },
            ),
            _buildManagementToolCard(
              context: context,
              icon: Icons.link,
              label: 'Subject Mapping',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const SubjectMappingManagementPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementToolCard({
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
