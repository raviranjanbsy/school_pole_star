import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Realtime Database
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:school_management/main.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/model_class/teacher_profile.dart'; // Import the new TeacherProfile model
// The Ip class and http import are no longer needed for signup
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>(); // Add a form key for validation
  final TextEditingController _username = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController(),
      _password = TextEditingController();
  final TextEditingController _confirmPassword =
      TextEditingController(); // For password confirmation
  // No longer need _image and _role TextControllers, we'll use a dropdown for role and image picker

  String _selectedRole = 'student'; // Default role
  File? _selectedImageFile; // To hold the selected image file
  bool _isLoading = false; // To show a loading indicator

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToStorage(String uid, File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images') // Folder in Firebase Storage
          .child(uid) // User-specific folder
          .child(
              'profile_${DateTime.now().millisecondsSinceEpoch}.jpg'); // Unique file name

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      // 1. Create user with Firebase Authentication
      UserCredential userCredential = await authService
          .createUserWithEmailAndPassword(_email.text.trim(), _password.text);
      User? newUser = userCredential.user;

      if (newUser == null) {
        throw Exception("User creation failed, user is null.");
      }

      // 2. Upload image to Firebase Storage (if selected)
      String imageUrl = ""; // Default to empty string or a default image URL
      if (_selectedImageFile != null) {
        imageUrl =
            await _uploadImageToStorage(newUser.uid, _selectedImageFile!) ?? "";
      }

      // 3. Create Alluser object. Use null for image if URL is empty.
      Alluser userProfile = Alluser(
        uid: newUser.uid,
        username: _username.text.trim(),
        name: _name.text.trim(),
        email: newUser.email!,
        image: imageUrl.isNotEmpty ? imageUrl : null,
        role: _selectedRole,
        status: 'active',
      );

      // 4. Save user profile to Realtime Database
      try {
        await FirebaseDatabase.instance
            .ref('users/${newUser.uid}')
            .set(userProfile.toMap());
        print("User profile saved successfully!");
      } catch (error) {
        print("Failed to save user profile: $error");
        // Inspect the 'error' object for details
      }

      // 5. If the user is a student, create an initial profile in 'student_profiles'
      // This ensures that the student panel has a profile to load upon first login.
      if (_selectedRole == 'student') {
        final initialStudentProfile = StudentTable(
          uid: newUser.uid,
          email: newUser.email!,
          fullName: _name.text.trim(),
          // Initialize other fields with default or empty values as they are nullable
          studentId: null,
          dob: null,
          mob: null,
          gender: null,
          classId: null,
          subject: null,
          presentAddress: null,
          permanentAddress: null,
          session: null,
          status: 'active', // Set a default status
          section: null,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        );

        await FirebaseDatabase.instance
            .ref('student_profiles/${newUser.uid}')
            .set(initialStudentProfile.toMap());
      }

      // 6. If the user is a teacher, create an initial profile in 'teacher_profiles'
      // This ensures that the teacher panel has a profile to load upon first login.
      if (_selectedRole == 'teacher') {
        final initialTeacherProfile = TeacherProfile(
          uid: newUser.uid,
          name: _name.text.trim(),
          email: newUser.email!,
          role: _selectedRole,
          // Initialize other fields with default or empty values as they are nullable
          qualification: null,
          mobileNo: null,
          status: 'active', // Set a default status
          joiningDate:
              null, // Or DateTime.now().toIso8601String().substring(0, 10)
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        );

        try {
          await FirebaseDatabase.instance
              .ref('teacher_profiles/${newUser.uid}')
              .set(initialTeacherProfile.toMap());
          print("Teacher profile saved successfully!");
        } catch (error) {
          print("Failed to save teacher profile: $error");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Please login.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) =>
                  const MyHomePage(title: "School Management")),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey, // Assign the form key
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _selectedImageFile != null
                        ? FileImage(_selectedImageFile!)
                        : null,
                    child: _selectedImageFile == null
                        ? Icon(Icons.camera_alt,
                            size: 40, color: Colors.grey[700])
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  controller: _username,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username.';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name.';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  controller: _confirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (value != _password.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                      labelText: 'Role', border: OutlineInputBorder()),
                  items: <String>[
                    'student',
                    'teacher'
                  ] // Add other roles if needed
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value[0].toUpperCase() + value.substring(1)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 16)),
                      child: const Text('Sign Up'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
