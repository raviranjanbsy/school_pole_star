import 'dart:async';
import 'dart:io'; // Import File

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import 'package:intl/intl.dart'; // Import for DateFormat

import 'package:school_management/model_class/teacher_profile.dart'; // Import the TeacherProfile model
import 'package:school_management/widgets/loading_overlay.dart'; // Reusable loading overlay
import 'package:image_picker/image_picker.dart'; // Image picker
import 'package:school_management/widgets/gradient_container.dart';

class EditTeacherProfilePage extends StatefulWidget {
  final TeacherProfile teacherProfile;

  const EditTeacherProfilePage({super.key, required this.teacherProfile});

  @override
  State<EditTeacherProfilePage> createState() => _EditTeacherProfilePageState();
}

class _EditTeacherProfilePageState extends State<EditTeacherProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _selectedImage;
  bool _isUploading = false;
  bool _isImageRemoved = false;

  StreamSubscription<DatabaseEvent>? _profileSubscription;
  late TeacherProfile _currentProfile;

  // TextEditingControllers for each editable field
  late TextEditingController _nameController;
  late TextEditingController _qualificationController;
  late TextEditingController _mobileNoController;
  DateTime? _selectedJoiningDate; // To hold the selected DateTime object
  late TextEditingController _joiningDateController;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.teacherProfile;
    _initializeControllers(_currentProfile);
    _listenToProfileChanges();
  }

  void _initializeControllers(TeacherProfile profile) {
    _nameController = TextEditingController(text: profile.name);
    _qualificationController =
        TextEditingController(text: profile.qualification);
    _mobileNoController = TextEditingController(text: profile.mobileNo);

    // Initialize Joining Date controller and _selectedJoiningDate from existing data
    if (profile.joiningDate != null && profile.joiningDate!.isNotEmpty) {
      try {
        _selectedJoiningDate =
            DateFormat('yyyy-MM-dd').parse(profile.joiningDate!);
        _joiningDateController =
            TextEditingController(text: profile.joiningDate!);
      } catch (e) {
        /* Handle parsing error if needed */
        _joiningDateController = TextEditingController();
      }
    } else {
      _joiningDateController = TextEditingController();
    }
  }

  void _listenToProfileChanges() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final profileRef =
        FirebaseDatabase.instance.ref('teacher_profiles/${currentUser.uid}');
    _profileSubscription = profileRef.onValue.listen((DatabaseEvent event) {
      if (mounted && event.snapshot.exists && event.snapshot.value != null) {
        final newProfileData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        final newProfile =
            TeacherProfile.fromMap(newProfileData, currentUser.uid);

        // Compare with the current state to see if an external update occurred.
        if (newProfile != _currentProfile) {
          _showUpdateConflictDialog(newProfile);
        }
      }
    }, onError: (error) {
      print("Error listening to teacher profile updates: $error");
      // Optionally show a SnackBar for the error
    });
  }

  void _showUpdateConflictDialog(TeacherProfile newProfile) {
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
    _nameController.dispose();
    _qualificationController.dispose();
    _mobileNoController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Method to show the date picker for joining date
  Future<void> _selectJoiningDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedJoiningDate ?? DateTime.now(), // Use existing date or today
      firstDate: DateTime(1950), // Set a reasonable minimum date
      lastDate: DateTime.now()
          .add(const Duration(days: 365)), // Up to 1 year in future
    );
    if (picked != null && picked != _selectedJoiningDate) {
      setState(() {
        _selectedJoiningDate = picked;
        // Format the date to YYYY-MM-DD string for the text field and saving
        _joiningDateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
      // Define the storage path (e.g., teacher_profiles_images/{uid}/profile.jpg)
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('teacher_profiles_images')
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
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
    if (widget.teacherProfile.imageUrl != null &&
        widget.teacherProfile.imageUrl!.isNotEmpty) {
      return NetworkImage(
          widget.teacherProfile.imageUrl!); // Existing network image
    }
    return null; // No image to display
  }

  // Helper to build a date picker text field
  Widget _buildDatePickerField(
      TextEditingController controller, String label, IconData icon,
      {required Future<void> Function(BuildContext) selectDateFunction}) {
    return _buildTextField(
      controller,
      label,
      icon: icon,
      readOnly: true, // Make the text field read-only
      onTap: () => selectDateFunction(context), // Show date picker on tap
      customValidator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your $label.';
        }
        try {
          DateFormat('yyyy-MM-dd').parseStrict(value);
        } catch (e) {
          return 'Invalid date format. Expected YYYY-MM-DD.';
        }
        return null;
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

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

    String? newImageUrl;
    String? oldImageUrl = _currentProfile.imageUrl;

    if (_isImageRemoved) {
      newImageUrl = null;
    } else if (_selectedImage != null) {
      newImageUrl = await _uploadImage(currentUser.uid);
      if (newImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image upload failed. Profile not saved.')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    if ((newImageUrl != null || _isImageRemoved) &&
        oldImageUrl != null &&
        oldImageUrl.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
      } catch (e) {
        print("Error deleting old image: $e");
      }
    }

    // Create an updated map for the teacher profile
    Map<String, dynamic> updatedData = {
      'name': _nameController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'mobileNo': _mobileNoController.text.trim(),
      'joiningDate': _joiningDateController.text.trim(),
      'imageUrl':
          _isImageRemoved ? null : (newImageUrl ?? _currentProfile.imageUrl),
      // Non-editable fields from current profile state
      'email': _currentProfile.email,
      'role': _currentProfile.role,
    };

    try {
      DatabaseReference teacherProfileRef =
          FirebaseDatabase.instance.ref('teacher_profiles/${currentUser.uid}');

      await teacherProfileRef.update(updatedData);

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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool isNumeric = false,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? customValidator,
  }) {
    String? _defaultValidator(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter $label';
      }
      if (isNumeric && int.tryParse(value) == null) {
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
          icon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters,
        validator: (value) {
          final defaultError = _defaultValidator(value);
          if (defaultError != null) {
            return defaultError;
          }
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
          title: const Text('Edit Teacher Profile'),
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
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImageProvider,
                          child: (_isImageRemoved ||
                                  (_selectedImage == null &&
                                      (widget.teacherProfile.imageUrl == null ||
                                          widget.teacherProfile.imageUrl!
                                              .isEmpty)))
                              ? Icon(Icons.camera_alt,
                                  size: 40, color: Colors.grey[600])
                              : null,
                        ),
                      ),
                      if (!_isImageRemoved &&
                          (_selectedImage != null ||
                              (widget.teacherProfile.imageUrl != null &&
                                  widget.teacherProfile.imageUrl!.isNotEmpty)))
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
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, 'Full Name',
                      icon: Icons.person),
                  _buildTextField(_qualificationController, 'Qualification',
                      icon: Icons.school),
                  _buildTextField(
                    _mobileNoController,
                    'Mobile Number',
                    icon: Icons.phone,
                    isNumeric: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    customValidator: (value) {
                      if (!RegExp(r'^\d{10}').hasMatch(value ?? '')) {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                  _buildDatePickerField(
                    _joiningDateController,
                    'Joining Date',
                    Icons.calendar_today,
                    selectDateFunction: _selectJoiningDate,
                  ),
                  // Display email as read-only
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller:
                          TextEditingController(text: _currentProfile.email),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        icon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
