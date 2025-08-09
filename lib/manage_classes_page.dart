import 'package:flutter/material.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/gradient_container.dart';

class ManageClassesPage extends StatefulWidget {
  final String teacherId;
  const ManageClassesPage({super.key, required this.teacherId});

  @override
  State<ManageClassesPage> createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  final AuthService _authService = AuthService();
  late Future<List<SchoolClass>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = _authService.fetchAssignedClasses(widget.teacherId);
  }

  void _refreshClasses() {
    setState(() {
      _classesFuture = _authService.fetchAssignedClasses(widget.teacherId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Assigned Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshClasses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<SchoolClass>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no classes assigned.'));
          }

          final classes = snapshot.data!;
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final schoolClass = classes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(schoolClass.className),
                  ),
                  title: Text(
                      'Class ${schoolClass.className} - Section ${schoolClass.section}'),
                  subtitle:
                      Text('Subjects: ${schoolClass.subjects.join(', ')}'),
                  onTap: () {
                    // TODO: Navigate to a class detail page to see student list
                  },
                ),
              );
            },
          );
        },
      ),
    ));
  }
}
