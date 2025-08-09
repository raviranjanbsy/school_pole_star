import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // For date formatting
import 'package:school_management/main.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/widgets/loading_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'dart:math';
import 'dart:developer' as developer;

class NewStudentAdmissionPage extends ConsumerStatefulWidget {
  const NewStudentAdmissionPage({super.key});

  @override
  ConsumerState<NewStudentAdmissionPage> createState() =>
      _NewStudentAdmissionPageState();
}

class _NewStudentAdmissionPageState
    extends ConsumerState<NewStudentAdmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers for form fields
  final _studentNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherMobileController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherMobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _bloodGroupController = TextEditingController();

  SchoolClass? _selectedClass;
  String? _selectedYear;
  bool _isLoading = false;
  bool _isFetchingClasses = true;
  List<SchoolClass> _classes = [];
  File? _imageFile; // To hold the selected image file
  String? _lastAdmittedStudentId; // To display the ID of the last student
  List<String> _admissionYears = [];
  DateTime? _selectedDob;
  String? _selectedGender;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _generatePassword();
    _loadInitialData();
    _populateAdmissionYears();
  }

  void _populateAdmissionYears() {
    final currentYear = DateTime.now().year;
    _admissionYears = List.generate(
      5,
      (index) => "${currentYear - index}-${currentYear - index + 1}",
    );
    _selectedYear = _admissionYears.first;
  }

  Future<void> _loadInitialData() async {
    setState(() => _isFetchingClasses = true);
    try {
      final classes = await _authService.fetchAllSchoolClasses();
      if (mounted) {
        setState(() {
          _classes = classes;
          _isFetchingClasses = false;
        });
      }
    } catch (e) {
      developer.log('Failed to load classes: $e', name: 'NewStudentAdmission');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
        setState(() => _isFetchingClasses = false);
      }
    }
  }

  void _generatePassword() {
    const length = 10;
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random();
    setState(() {
      _passwordController.text = String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
        ),
      );
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // You can also use ImageSource.camera
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _lastAdmittedStudentId = null; // Clear previous ID on new submission
      });
      try {
        // The admitStudent method now uses providers for AuthService.
        // It handles user creation in Firebase Auth and Firestore profile creation.
        final newStudentId = await _authService.admitStudent(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _studentNameController.text.trim(),
          fatherName: _fatherNameController.text.trim(),
          motherName: _motherNameController.text.trim(),
          fatherMobile: _fatherMobileController.text.trim(),
          motherMobile: _motherMobileController.text.trim(),
          classId: _selectedClass!.classId,
          admissionYear: _selectedYear!,
          dob: _dobController.text.trim(),
          gender: _selectedGender!,
          bloodGroup: _bloodGroupController.text.trim(),
          photoFile: _imageFile, // Pass the selected photo file
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student admitted successfully! ID: $newStudentId'),
            ),
          );
          _resetForm();
          // Display the new ID on the form
          setState(() => _lastAdmittedStudentId = newStudentId);
        }
      } on AuthException catch (e) {
        developer.log(
          'Admission failed: ${e.message}',
          name: 'NewStudentAdmission',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Admission failed: ${e.message}')),
          );
        }
      } catch (e) {
        developer.log('Admission failed: $e', name: 'NewStudentAdmission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _studentNameController.clear();
    _fatherNameController.clear();
    _fatherMobileController.clear();
    _motherNameController.clear();
    _motherMobileController.clear();
    _emailController.clear();
    _dobController.clear();
    _bloodGroupController.clear();
    setState(() {
      _imageFile = null; // Reset the image file
      _selectedClass = null;
      _selectedYear = _admissionYears.first;
      _generatePassword();
      _selectedDob = null;
      _selectedGender = null;
    });
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _fatherMobileController.dispose();
    _motherNameController.dispose();
    _motherMobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('New Student Admission')),
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (_lastAdmittedStudentId != null)
                  _buildSuccessIdCard(_lastAdmittedStudentId!),
                // _buildPhotoUpload(),
                _buildTextField(_studentNameController, 'Student Full Name'),
                _buildDatePickerField(
                    _dobController, 'Date of Birth', Icons.calendar_today),
                _buildGenderDropdown(),
                _buildTextField(
                    _bloodGroupController, 'Blood Group (e.g., O+)'),
                _buildTextField(_fatherNameController, "Father's Name"),
                _buildTextField(
                  _fatherMobileController,
                  "Father's Mobile Number",
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(_motherNameController, "Mother's Name"),
                _buildTextField(
                  _motherMobileController,
                  "Mother's Mobile Number",
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  _emailController,
                  'Student Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildClassDropdown(),
                _buildYearDropdown(),
                _buildPasswordField(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: const Text('Admit Student'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(), // Use existing date or today
      firstDate: DateTime(1950), // Set a reasonable minimum date
      lastDate:
          DateTime.now(), // Students are unlikely to be born in the future
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        // Format the date to YYYY-MM-DD string for the text field and saving
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildPhotoUpload() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
            child: _imageFile == null
                ? Icon(Icons.person, size: 40, color: Colors.grey.shade600)
                : null,
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Upload Photo'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIdCard(String studentId) {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Admitted Successfully!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Generated Student ID: ',
                  style: TextStyle(fontSize: 16),
                ),
                Flexible(
                  child: SelectableText(
                    studentId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy ID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: studentId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Student ID copied to clipboard'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(icon),
        ),
        readOnly: true, // Make the text field read-only
        onTap: () => _selectDate(context), // Show date picker on tap
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a $label';
          }
          // Optional: Add more specific date validation if needed
          return null;
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: const InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(),
        ),
        items: ['Male', 'Female', 'Other'].map((gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        validator: (value) => value == null ? 'Please select a gender' : null,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.phone
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10)
              ]
            : [],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label.toLowerCase().contains('email') && !value.contains('@')) {
            return 'Please enter a valid email';
          }
          if (keyboardType == TextInputType.phone && value.length != 10) {
            return 'Please enter a valid 10-digit mobile number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<SchoolClass>(
        value: _selectedClass,
        decoration: InputDecoration(
          labelText: 'Class',
          border: const OutlineInputBorder(),
          suffixIcon: _isFetchingClasses
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        items: _classes.map((schoolClass) {
          return DropdownMenuItem<SchoolClass>(
            value: schoolClass,
            child: Text(schoolClass.classId),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedClass = value;
          });
        },
        validator: (value) => value == null ? 'Please select a class' : null,
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedYear,
        decoration: const InputDecoration(
          labelText: 'Year of Admission',
          border: const OutlineInputBorder(),
        ),
        items: _admissionYears.map((year) {
          return DropdownMenuItem<String>(value: year, child: Text(year));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedYear = value;
          });
        },
        validator: (value) => value == null ? 'Please select a year' : null,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _isPasswordObscured,
        decoration: InputDecoration(
          labelText: 'Password',
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: 'Toggle Visibility',
                onPressed: () {
                  setState(() => _isPasswordObscured = !_isPasswordObscured);
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy Password',
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _passwordController.text),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password copied to clipboard'),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Generate New Password',
                onPressed: _generatePassword,
              ),
            ],
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters long';
          }
          return null;
        },
      ),
    );
  }
}
