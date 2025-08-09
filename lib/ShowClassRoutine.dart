import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_management/model_class/Classroutine.dart';
import 'package:school_management/model_class/ipAddress.dart';
import 'package:school_management/widgets/gradient_container.dart';

List<Classroutine> objectsFromJson(String str) => List<Classroutine>.from(
    json.decode(str).map((x) => Classroutine.fromJson(x)));

String objectsToJson(List<Classroutine> data) =>
    json.encode(List<Classroutine>.from(data.map((x) => x.toJson())));

class ShowClassRoutine extends StatefulWidget {
  const ShowClassRoutine({super.key});

  @override
  State<ShowClassRoutine> createState() => _ShowClassRoutineState();
}

class _ShowClassRoutineState extends State<ShowClassRoutine> {
  final TextEditingController _classNameController = TextEditingController();
  late Future<List<Classroutine>> _futureRoutines;

  @override
  void initState() {
    super.initState();
    _futureRoutines = Future.value([]);
  }

  Future<List<Classroutine>> showByClass(String className) async {
    Ip ip = Ip();
    final response = await http.get(
      Uri.parse('${ip.ipAddress}/searchstudentroutine/$className'),
    );

    if (response.statusCode == 200) {
      return objectsFromJson(response.body);
    } else {
      throw Exception("Failed to load data");
    }
  }

  void search() {
    setState(() {
      _futureRoutines = showByClass(_classNameController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Class Routine"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Form
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _classNameController,
                        decoration: InputDecoration(
                          labelText: 'Class Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_classNameController.text.isNotEmpty) {
                            search();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          side: BorderSide(color: Colors.teal.shade700),
                          shadowColor: Colors.teal.withOpacity(0.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 20),
                            SizedBox(width: 8.0),
                            Text("Search"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Class Routine List
            Expanded(
              child: FutureBuilder<List<Classroutine>>(
                future: _futureRoutines,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Card(
                        color: Colors.teal.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 2,
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "No data found",
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return ListView(
                      children: snapshot.data!.map((routine) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: const Text('Class Routine'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Day: ${routine.day.toString()}'),
                                Text('Section: ${routine.section.toString()}'),
                                Text('Subject: ${routine.subject.toString()}'),
                                Text(
                                    'Start Time: ${routine.startTime.toString()}'),
                                Text('End Time: ${routine.endTime.toString()}'),
                                Text('Teacher: ${routine.teacher.toString()}'),
                                Text('Room No: ${routine.roomNo.toString()}'),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
