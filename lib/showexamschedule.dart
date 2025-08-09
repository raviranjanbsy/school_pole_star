import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:school_management/model_class/ExamSchedule.dart';
import 'package:school_management/model_class/ipAddress.dart';
import 'package:school_management/widgets/gradient_container.dart';

List<Examschedule> objectsFromJson(String str) => List<Examschedule>.from(
    json.decode(str).map((x) => Examschedule.fromJson(x)));
String objectsToJson(List<Examschedule> data) =>
    json.encode(List<Examschedule>.from(data).map((x) => x.toJson()));

class Showexamschedule extends StatefulWidget {
  const Showexamschedule({super.key});

  @override
  State<Showexamschedule> createState() => _ShowexamscheduleState();
}

class _ShowexamscheduleState extends State<Showexamschedule> {
  Future<List<Examschedule>> showExamTime() async {
    Ip ip = Ip();
    final response =
        await http.get(Uri.parse('${ip.ipAddress}/getexamschedule'));
    if (response.statusCode == 200) {
      return objectsFromJson(response.body);
    } else {
      throw Exception("Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Exam Schedule"),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Examschedule>>(
          future: showExamTime(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (BuildContext context, index) {
                  final exam = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildInfoRow('examTitle', exam.examTitle),
                          _buildInfoRow('Class', exam.class1),
                          _buildInfoRow('Subject', exam.subject),
                          _buildInfoRow('Exam Type', exam.examType),
                          _buildInfoRow('Exam Hall', exam.examHall),
                          _buildInfoRow('Exam Start Time', exam.examStart),
                          _buildInfoRow('Exam End Time', exam.examEnd),
                          _buildInfoRow(
                              'Exam Invigilator', exam.examInvigilator),
                          _buildInfoRow('Exam Date', exam.examDate),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    ));
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$title:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
