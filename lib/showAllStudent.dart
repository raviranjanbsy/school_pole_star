import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:school_management/model_class/Studenttable.dart';
import 'package:school_management/model_class/ipAddress.dart';
import 'package:school_management/widgets/gradient_container.dart';

List<Studenttable> objectsFromJson(String str) => List<Studenttable>.from(
    json.decode(str).map((x) => Studenttable.fromJson(x)));
String objectsToJson(List<Studenttable> data) =>
    json.encode(List<Studenttable>.from(data).map((x) => x.toJson()));

class ShowAllStudent extends StatefulWidget {
  const ShowAllStudent({super.key});

  @override
  State<ShowAllStudent> createState() => _ShowAllStudentState();
}

class _ShowAllStudentState extends State<ShowAllStudent> {
  Future<List<Studenttable>> showAllStudent() async {
    Ip ip = Ip();
    final response = await http.get(Uri.parse('${ip.ipAddress}/getall'));
    if (response.statusCode == 200) {
      return objectsFromJson(response.body);
    } else {
      throw Exception("Failed to load student data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Students Details"),
        backgroundColor: Colors.pink,
      ),
      body: FutureBuilder<List<Studenttable>>(
        future: showAllStudent(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                var student = snapshot.data![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              const Icon(Icons.perm_identity,
                                  color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Student ID: ${student.student_id}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Full Name: ${student.full_name}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.cake, color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Date of Birth: ${student.dob}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.email, color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Email: ${student.email}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Mobile: ${student.mob}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.wc, color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Gender: ${student.gender}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.class_, color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Class: ${student.class1}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.school, color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Session: ${student.session}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Status: ${student.status}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.group, color: Colors.pink),
                              const SizedBox(width: 10),
                              Text(
                                'Section: ${student.section}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading student data"));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    ));
  }
}
