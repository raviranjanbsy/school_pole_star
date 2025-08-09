import 'package:flutter/material.dart';
import 'package:school_management/main.dart';
import 'package:school_management/ui/course_analytics_widget.dart';
import 'package:school_management/ui/fee_management_page.dart';
import 'package:school_management/ui/attendance_reports_page.dart';
import 'package:school_management/ui/teacher_productivity_reports_page.dart';
import 'package:school_management/widgets/gradient_container.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildReportCategoryCard(
              context,
              icon: Icons.assessment_outlined,
              title: 'Academic Performance',
              subtitle:
                  'View student grades, assignment submissions, and class participation.',
              onTap: () {
                // Wrap the existing widget in a Scaffold to present it as a full page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Academic Performance')),
                      body: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CourseAnalyticsWidget(),
                      ),
                    ),
                  ),
                );
              },
            ),
            _buildReportCategoryCard(
              context,
              icon: Icons.payments_outlined,
              title: 'Financial Reports',
              subtitle:
                  'Track fee collections, outstanding payments, and revenue.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FeeManagementPage()),
                );
              },
            ),
            _buildReportCategoryCard(
              context,
              icon: Icons.event_available_outlined,
              title: 'Attendance Reports',
              subtitle:
                  'Monitor student and staff attendance records and trends.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceReportsPage(),
                  ),
                );
              },
            ),
            _buildReportCategoryCard(
              context,
              icon: Icons.person_search_outlined,
              title: 'Teacher Productivity',
              subtitle:
                  'Analyze assignment turnaround, class engagement, and more.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const TeacherProductivityReportsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
