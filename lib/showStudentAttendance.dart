import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:school_management/model_class/AttendanceInfo.dart';
import 'package:school_management/model_class/ipAddress.dart';
import 'package:school_management/widgets/gradient_container.dart';

// Converts JSON string to List<Attendanceinfo>
List<Attendanceinfo> objectsFromJson(String str) => List<Attendanceinfo>.from(
    json.decode(str).map((x) => Attendanceinfo.fromJson(x)));

// Converts List<Attendanceinfo> to JSON string
String objectsToJson(List<Attendanceinfo> data) =>
    json.encode(List<Attendanceinfo>.from(data).map((x) => x.toJson()));

// StatefulWidget to show student attendance
class Showstudentattendance extends StatefulWidget {
  const Showstudentattendance({super.key});

  @override
  State<Showstudentattendance> createState() => _ShowstudentattendanceState();
}

class _ShowstudentattendanceState extends State<Showstudentattendance> {
  // Fetches attendance data from API
  Future<List<Attendanceinfo>> showAttendance() async {
    Ip ip = Ip();
    final response = await http.get(Uri.parse('${ip.ipAddress}/getattendance'));
    if (response.statusCode == 200) {
      return objectsFromJson(response.body);
    } else {
      throw Exception("Failed to load attendance data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Students Attendance List"),
        backgroundColor: Colors.teal, // Professional color for AppBar
      ),
      body: FutureBuilder<List<Attendanceinfo>>(
        future: showAttendance(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0), // Padding for the list view
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, index) {
                final attendance = snapshot.data![index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Attendance ID: ${attendance.attendanceId}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                        ),
                        const SizedBox(height: 8.0),
                        _buildInfoRow(
                            'Student ID', attendance.studentId.toString()),
                        _buildInfoRow(
                            'Student Name', attendance.studentName ?? 'N/A'),
                        _buildInfoRow('Class', attendance.class1 ?? 'N/A'),
                        _buildInfoRow('Section', attendance.section ?? 'N/A'),
                        _buildInfoRow('Attendance Date',
                            attendance.attendanceDate ?? 'N/A'),
                        _buildInfoRow('Attendance Status',
                            attendance.attendanceStatus ?? 'N/A'),
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
    ));
  }

  // Helper method to build information rows
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
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade800,
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
