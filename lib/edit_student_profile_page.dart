import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import 'package:intl/intl.dart'; // Import for DateFormat

import 'package:school_management/model_class/student_table.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/loading_overlay.dart'; // Import the new widget
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'dart:io'; // Import File
import 'package:school_management/widgets/gradient_container.dart';

class EditStudentProfilePage extends StatefulWidget {
  final StudentTable studentProfile;

  const EditStudentProfilePage({super.key, required this.studentProfile});

  @override
  State<EditStudentProfilePage> createState() => _EditStudentProfilePageState();
}

class _EditStudentProfilePageState extends State<EditStudentProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  File? _selectedImage;
  bool _isUploading = false;
  bool _isImageRemoved = false;

  // Add a StreamSubscription and a state variable for the current profile
  StreamSubscription<DatabaseEvent>? _profileSubscription;
  late StudentTable _currentProfile;

  // TextEditingControllers for each editable field
  late TextEditingController _fullNameController;
  DateTime? _selectedDob; // To hold the selected DateTime object
  late TextEditingController _mobController;
  late TextEditingController _presentAddressController;
  // Add controllers for other fields you want to make editable
  late TextEditingController _permanentAddressController;
  late TextEditingController _dobController; // Declare _dobController

  // For password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.studentProfile;
    _initializeControllers(_currentProfile);
    _listenToProfileChanges();
  }

  void _initializeControllers(StudentTable profile) {
    _fullNameController = TextEditingController(text: profile.fullName);
    // Initialize DOB controller and _selectedDob from existing data
    if (profile.dob != null && profile.dob!.isNotEmpty) {
      try {
        _selectedDob = DateFormat('yyyy-MM-dd').parse(profile.dob!);
        _dobController = TextEditingController(text: profile.dob!);
      } catch (e) {
        /* Handle parsing error if needed */
        _dobController = TextEditingController();
      }
    } else {
      _dobController = TextEditingController();
    }
    _mobController = TextEditingController(text: profile.mob);
    _presentAddressController =
        TextEditingController(text: profile.presentAddress);
    _permanentAddressController =
        TextEditingController(text: profile.permanentAddress);
  }

  void _listenToProfileChanges() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final profileRef =
        FirebaseDatabase.instance.ref('student_profiles/${currentUser.uid}');
    _profileSubscription = profileRef.onValue.listen((DatabaseEvent event) {
      if (mounted && event.snapshot.exists && event.snapshot.value != null) {
        final newProfileData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        final newProfile =
            StudentTable.fromMap(newProfileData, currentUser.uid);

        // Compare with the current state to see if an external update occurred.
        // This relies on the `equatable` implementation in the StudentTable model.
        if (newProfile != _currentProfile) {
          _showUpdateConflictDialog(newProfile);
        }
      }
    }, onError: (error) {
      print("Error listening to profile updates: $error");
      // Optionally show a SnackBar for the error
    });
  }

  void _showUpdateConflictDialog(StudentTable newProfile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Updated'),
          content: const Text(
              'Your profile was updated elsewhere. Reload the form to see the changes? Your current edits will be lost.'),
          actions: <Widget>[
            TextButton(
                child: const Text('Keep Editing'),
                onPressed: () {
                  // User ignores the update. Update our internal state to prevent re-prompting for the same change.
                  setState(() => _currentProfile = newProfile);
                  Navigator.of(context).pop();
                }),
            TextButton(
                child: const Text('Reload'),
                onPressed: () {
                  // User wants to load the new data.
                  setState(() {
                    _currentProfile = newProfile;
                    _initializeControllers(newProfile);
                    _selectedImage = null;
                    _isImageRemoved = false;
                  });
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _profileSubscription?.cancel(); // Important: Cancel the subscription
    _fullNameController.dispose();
    _dobController.dispose();
    _mobController.dispose();
    _presentAddressController.dispose();
    _permanentAddressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    // Dispose other controllers
    super.dispose();
  }

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery); // Or ImageSource.camera

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Method to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(), // Use existing date or today
      firstDate: DateTime(1900), // Set a reasonable minimum date
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

  // Method to mark the image for removal
  void _removeImage() {
    setState(() {
      _selectedImage = null; // Clear any newly selected image
      _isImageRemoved = true; // Mark existing image for removal
    });
  }

  // Method to upload the selected image to Firebase Storage
  Future<String?> _uploadImage(String uid) async {
    if (_selectedImage == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      // Define the storage path (e.g., student_profiles_images/{uid}/profile.jpg)
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('student_profiles_images')
          .child(uid)
          .child('profile.jpg');

      // Upload the file
      final uploadTask = storageRef.putFile(_selectedImage!);

      // Wait for the upload to complete and get the download URL
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      // Handle upload errors (e.g., show a message to the user)
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Helper getter to determine the correct image provider for the CircleAvatar
  ImageProvider? get _profileImageProvider {
    if (_isImageRemoved) {
      return null; // If marked for removal, show no image
    }
    if (_selectedImage != null) {
      return FileImage(_selectedImage!); // Newly selected image
    }
    if (widget.studentProfile.imageUrl != null &&
        widget.studentProfile.imageUrl!.isNotEmpty) {
      return NetworkImage(
          widget.studentProfile.imageUrl!); // Existing network image
    }
    return null; // No image to display
  }

  // Helper to build the Date of Birth text field with a date picker
  Widget _buildDatePickerField(
      TextEditingController controller, String label, IconData icon) {
    return _buildTextField(
      controller,
      label,
      icon: icon,
      readOnly: true, // Make the text field read-only
      onTap: () => _selectDate(context), // Show date picker on tap
      customValidator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your Date of Birth.';
        }
        // Ensure the format is YYYY-MM-DD, though the picker should enforce this.
        // This adds a safeguard against manual input or unexpected data.
        try {
          DateFormat('yyyy-MM-dd').parseStrict(value);
        } catch (e) {
          return 'Invalid date format. Expected YYYY-MM-DD.';
        }
        if (_selectedDob != null && _selectedDob!.isAfter(DateTime.now())) {
          return 'Date of Birth cannot be in the future.';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
          onPressed: onVisibilityToggle,
        ),
      ),
      validator: validator,
      // It's often better to validate as the user types in a dialog
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  void _showChangePasswordDialog() {
    final passwordFormKey = GlobalKey<FormState>();
    bool isObscuredCurrent = true;
    bool isObscuredNew = true;
    bool isObscuredConfirm = true;
    bool isDialogLoading = false;

    // Clear controllers before showing the dialog
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      barrierDismissible: !isDialogLoading, // Prevent closing while loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: passwordFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDialogLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: LinearProgressIndicator(),
                        ),
                      _buildPasswordTextField(
                        controller: _currentPasswordController,
                        label: 'Current Password',
                        isObscured: isObscuredCurrent,
                        onVisibilityToggle: () => setDialogState(
                            () => isObscuredCurrent = !isObscuredCurrent),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        isObscured: isObscuredNew,
                        onVisibilityToggle: () => setDialogState(
                            () => isObscuredNew = !isObscuredNew),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password.';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        isObscured: isObscuredConfirm,
                        onVisibilityToggle: () => setDialogState(
                            () => isObscuredConfirm = !isObscuredConfirm),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password.';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (passwordFormKey.currentState!.validate()) {
                            setDialogState(() => isDialogLoading = true);
                            try {
                              await _authService.changePassword(
                                currentPassword:
                                    _currentPasswordController.text,
                                newPassword: _newPasswordController.text,
                              );
                              if (!mounted) return;
                              Navigator.of(context).pop(); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Password changed successfully!')),
                              );
                            } on AuthException catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.message}')),
                              );
                            } finally {
                              if (mounted) {
                                setDialogState(() => isDialogLoading = false);
                              }
                            }
                          }
                        },
                  child: const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Upload image first if a new one is selected
      String? newImageUrl;
      String? oldImageUrl = _currentProfile.imageUrl; // Keep track of old image

      if (_isImageRemoved) {
        newImageUrl = null; // Explicitly set to null for removal
      } else if (_selectedImage != null) {
        newImageUrl = await _uploadImage(currentUser.uid);
        if (newImageUrl == null) {
          // Image upload failed, stop saving profile
          // The _uploadImage method already shows a SnackBar, but we can add more context here.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed. Profile not saved.')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // If a new image was uploaded OR the image was removed,
      // and there was an old image, delete the old one from Storage.
      if ((newImageUrl != null || _isImageRemoved) &&
          oldImageUrl != null &&
          oldImageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
        } catch (e) {
          print("Error deleting old image: $e");
          // Non-critical error, so we can continue, but good to log.
        }
      }

      // Create an updated Studenttable object
      // Only include fields that are actually editable by the student.
      // For non-editable fields, use the existing values from widget.studentProfile
      Map<String, dynamic> updatedData = {
        // Use Map for update()
        'full_name': _fullNameController.text.trim(), // DB key is snake_case
        'dob': _dobController.text.trim(), // Use the formatted date string
        'mob': _mobController.text.trim(),
        'present_address': _presentAddressController.text.trim(),
        'permanent_address': _permanentAddressController.text.trim(),
        // Keep non-editable fields from the current profile state
        'student_id': _currentProfile.studentId,
        'email':
            _currentProfile.email, // Email should generally not be changed here
        'gender': _currentProfile.gender,
        'class1': _currentProfile.studentClass,
        'subject': _currentProfile.subject,
        'session': _currentProfile.session,
        'status': _currentProfile.status,
        'section': _currentProfile.section,
        'imageUrl': _isImageRemoved
            ? null // Explicitly set to null if removed
            : (newImageUrl ??
                _currentProfile.imageUrl), // Use new URL or existing one
      };

      try {
        DatabaseReference studentProfileRef = FirebaseDatabase.instance
            .ref('student_profiles/${currentUser.uid}');

        await studentProfileRef.update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop(true); // Pop with true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool isNumeric = false,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters, // Add inputFormatters parameter
    String? Function(String?)?
        customValidator, // Add custom validator parameter for chaining
  }) {
    // Default validation logic for empty fields and numeric types
    String? _defaultValidator(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter $label';
      }
      if (isNumeric && int.tryParse(value) == null) {
        // Simplified numeric check
        return 'Please enter a valid number';
      }
      return null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          icon: icon != null ? Icon(icon) : null, // Use the icon if provided
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters, // Apply input formatters
        validator: (value) {
          // Run default validation first
          final defaultError = _defaultValidator(value);
          if (defaultError != null) {
            return defaultError;
          }
          // If default passes, run custom validation if provided
          return customValidator?.call(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isUploading,
        message: _isUploading ? 'Uploading Image...' : 'Saving Profile...',
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Stack(
                  // Use Stack to overlay a remove button
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            _profileImageProvider, // Use the new getter
                        child: (_isImageRemoved ||
                                (_selectedImage == null &&
                                    (widget.studentProfile.imageUrl == null ||
                                        widget
                                            .studentProfile.imageUrl!.isEmpty)))
                            ? Icon(Icons.camera_alt,
                                size: 40, color: Colors.grey[600])
                            : null,
                      ),
                    ),
                    if (!_isImageRemoved &&
                        (_selectedImage != null ||
                            (widget.studentProfile.imageUrl != null &&
                                widget.studentProfile.imageUrl!.isNotEmpty)))
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 20,
                          child: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.white, size: 20),
                              onPressed: _removeImage),
                        ),
                      ),
                  ],
                ),
                // Removed the old `if (_isUploading)` CircularProgressIndicator here
                const SizedBox(height: 20),
                _buildTextField(_fullNameController, 'Full Name',
                    icon: Icons.person),
                _buildDatePickerField(
                    _dobController, 'Date of Birth', Icons.calendar_today),
                _buildTextField(
                  _mobController,
                  'Mobile Number',
                  icon: Icons.phone,
                  isNumeric: true, // Ensures numeric keyboard for mobile
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                    LengthLimitingTextInputFormatter(10), // Limit to 10 digits
                  ],
                  customValidator: (value) {
                    // Example: Validate for exactly 10 digits. Adjust regex as needed for your region.
                    if (!RegExp(r'^\d{10}').hasMatch(value ?? '')) {
                      return 'Please enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                _buildTextField(_presentAddressController, 'Present Address',
                    icon: Icons.home),
                _buildTextField(
                    _permanentAddressController, 'Permanent Address',
                    icon: Icons.location_city),
                const SizedBox(height: 20),
                // The ElevatedButton is now always visible, and the overlay handles interaction prevention
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: const Text('Save Changes'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock),
                  label: const Text('Change Password'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
