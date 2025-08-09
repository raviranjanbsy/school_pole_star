import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/Onlineadmission.dart';
import 'package:school_management/model_class/ipAddress.dart';
import 'package:school_management/widgets/gradient_container.dart';

List<Onlineadmission> objectsFromJson(String str) => List<Onlineadmission>.from(
    json.decode(str).map((x) => Onlineadmission.fromJson(x)));
String objectsToJson(List<Onlineadmission> data) =>
    json.encode(List<Onlineadmission>.from(data).map((x) => x.toJson()));

class Admissionform extends StatefulWidget {
  const Admissionform({super.key});

  @override
  State<Admissionform> createState() => _AdmissionformState();
}

class _AdmissionformState extends State<Admissionform> {
  final TextEditingController _reg_no = TextEditingController();
  final TextEditingController _full_name = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mob = TextEditingController();
  final TextEditingController _gender = TextEditingController();
  final TextEditingController _fathername = TextEditingController();
  final TextEditingController _mothername = TextEditingController();
  final TextEditingController _class1 = TextEditingController();
  final TextEditingController _section = TextEditingController();
  final TextEditingController _present_address = TextEditingController();
  final TextEditingController _permanent_address = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _session = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _images = TextEditingController();

  Future<Onlineadmission?> allStudentFormfilup() async {
    Onlineadmission s = Onlineadmission(
      reg_no: int.parse(_reg_no.text),
      full_name: _full_name.text,
      dob: _dob.text,
      email: _email.text,
      mob: _mob.text,
      gender: _gender.text,
      fathername: _fathername.text,
      mothername: _mothername.text,
      class1: _class1.text,
      section: _section.text,
      present_address: _present_address.text,
      permanent_address: _permanent_address.text,
      username: _username.text,
      session: _session.text,
      password: _password.text,
      image: _images.text,
    );
    Ip ip = Ip();
    final response = await http.post(
      Uri.parse('${ip.ipAddress}/form'),
      body: jsonEncode(s.toJson()),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return Onlineadmission.fromJson(jsonDecode(response.body));
    } else {
      print("Failed to sign up. Status code: ${response.statusCode}");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admission Form'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  buildTextField(
                      _reg_no, 'Registration No', Icons.assignment_ind),
                  buildTextField(_full_name, 'Full Name', Icons.person),
                  buildTextField(_dob, 'Date of Birth', Icons.cake),
                  buildTextField(_email, 'Email', Icons.email),
                  buildTextField(_mob, 'Mobile', Icons.phone),
                  buildTextField(_gender, 'Gender', Icons.wc),
                  buildTextField(_fathername, 'Father Name', Icons.person),
                  buildTextField(_mothername, 'Mother Name', Icons.person),
                  buildTextField(_class1, 'Class', Icons.class_),
                  buildTextField(_section, 'Section', Icons.account_tree),
                  buildTextField(
                      _present_address, 'Present Address', Icons.home),
                  buildTextField(
                      _permanent_address, 'Permanent Address', Icons.home),
                  buildTextField(_username, 'Username', Icons.account_circle),
                  buildTextField(_session, 'Session', Icons.date_range),
                  buildTextField(_password, 'Password', Icons.lock,
                      obscureText: true),
                  buildTextField(_images, 'Image URL', Icons.image),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      if (_reg_no.text.isEmpty ||
                          _full_name.text.isEmpty ||
                          _dob.text.isEmpty ||
                          _email.text.isEmpty ||
                          _mob.text.isEmpty ||
                          _gender.text.isEmpty ||
                          _fathername.text.isEmpty ||
                          _mothername.text.isEmpty ||
                          _class1.text.isEmpty ||
                          _section.text.isEmpty ||
                          _present_address.text.isEmpty ||
                          _permanent_address.text.isEmpty ||
                          _username.text.isEmpty ||
                          _session.text.isEmpty ||
                          _password.text.isEmpty ||
                          _images.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      Onlineadmission? newUser = await allStudentFormfilup();

                      if (newUser != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submit Successfully')),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyApp()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submit failed')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      TextEditingController controller, String labelText, IconData icon,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
}
